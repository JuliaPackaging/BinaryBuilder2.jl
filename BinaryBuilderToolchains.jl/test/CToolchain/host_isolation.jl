# Included by `runtests.jl` into a module that has already loaded `common.jl`.

@testset "CToolchain" begin
    # Use native compilers so that we can run the output.
    platform = CrossPlatform(BBHostPlatform() => HostPlatform())

    # Time for an advanced test: let's ensure that when deploying two CToolchains,
    # one for the host, and one for the target, they are individually usable.
    # In particular, we want to ensure that headers and libraries looked up by the
    # preprocessor and linker are isolated.
    @testset "target/host isolation" begin
        mktempdir() do prefix
            host_prefix = joinpath(prefix, "host")
            target_prefix = joinpath(prefix, "target")

            # Create "host toolchain" with extra flags to link against the host prefix
            # In BB, this usually points to something like `/usr/local/`
            host_ctoolchain = CToolchain(platform;
                env_prefixes=["HOST_"],
                wrapper_prefixes=["host-"],
                extra_libdirs=["$(host_prefix)/lib"],
                extra_cflags=["-I$(host_prefix)/include"],
                use_ccache=false,
            )

            # Create "target toolchain" with extra flags to link against the target prefix
            # In BB, this usually points to something like `/workspace/destdir/$(target)`
            target_ctoolchain = CToolchain(platform;
                extra_libdirs=["$(target_prefix)/lib"],
                extra_cflags=["-I$(target_prefix)/include"],
                use_ccache=false,
            )

            # Use each toolchain to build a `libfoo` with a different version embedded within:
            host_version = 1
            target_version = 2
            for (toolchains, install_prefix, cc, libfoo_version) in (
                    ([host_ctoolchain,   htt_toolchain], host_prefix,   "\${HOST_CC}", host_version),
                    ([target_ctoolchain, htt_toolchain], target_prefix, "\${CC}",      target_version))
                with_toolchains(toolchains) do prefix, env
                    cd(joinpath(testsuite_dir, "CToolchainHostIsolation", "libfoo")) do
                        @test success(setenv(Cmd(["/bin/bash", "-c", "make install CC=$(cc) prefix=$(install_prefix) VERSION=$(libfoo_version)"]), env))
                        libfoo_h_path = joinpath(install_prefix, "include", "libfoo.h")
                        @test isfile(libfoo_h_path)
                        @test contains(String(read(libfoo_h_path)), "#define LIBFOO_VERSION $(libfoo_version)")
                        @test isdir(joinpath(install_prefix, "lib"))
                    end
                end
            end

            # Next, within a single shell with _both_ toolchains installed, verify that the
            # include path searched by the preprocessor and linker is correct:
            with_toolchains([host_ctoolchain, htt_toolchain]) do _, host_env
                with_toolchains([target_ctoolchain]) do _, target_env
                    env = path_appending_merge(host_env, target_env)
                    cd(joinpath(testsuite_dir, "CToolchainHostIsolation")) do
                        for (version, install_prefix, cc) in ((host_version, host_prefix, "\${HOST_CC}"),
                                                              (target_version, target_prefix, "\${CC}"))
                            # Run preprocessor on `usesfoo.c`, print out `LIBFOO_VERSION`
                            p, output = capture_output(setenv(Cmd(["/bin/bash", "-c", "$(cc) -dM -E usesfoo.c"]), env))
                            @test success(p)
                            version_str = only(filter(l -> startswith(l, "#define LIBFOO_VERSION"), split(output, "\n")))
                            @test parse(Int, last(split(version_str," "))) == version

                            # Next, compile it and ensure that the library it tries to load ends
                            # with the right SOVERSION:
                            mkpath(joinpath(install_prefix, "bin"))
                            run(setenv(Cmd(["/bin/bash", "-c", "$(cc) -o $(install_prefix)/bin/foo -lfoo usesfoo.c"]), env))
                            p, output = capture_output(setenv(`readelf -d $(install_prefix)/bin/foo`, env))
                            @test success(p)
                            m = match(r"Shared library: \[(libfoo[^ ]+)\]", output)
                            @test m !== nothing
                            @test m.captures[1] == "libfoo.so.$(version)"
                        end
                    end
                end
            end
        end
    end
end
