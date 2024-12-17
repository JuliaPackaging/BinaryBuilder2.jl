using Test, BinaryBuilderSources, BinaryBuilderToolchains, BinaryBuilderPlatformExtensions, Base.BinaryPlatforms, Scratch
using BinaryBuilderToolchains: path_appending_merge

# Enable this for lots of JLLPrefixes output
const verbose = false

include("common.jl")

using BinaryBuilderToolchains: get_vendor
@testset "CToolchain" begin
    # Use native compilers so that we can run the output.
    platform = CrossPlatform(BBHostPlatform() => HostPlatform())
    mktempdir() do ccache_dir
        for use_ccache in (false, true), vendor in (:auto, :gcc, :clang)
            toolchain = CToolchain(platform; vendor, use_ccache)
            @test get_vendor(toolchain) ∈ (:gcc, :clang)
            if get_vendor(toolchain) == :gcc
                @test !isempty(filter(jll -> jll.package.name == "GCC_jll", toolchain.deps))
            elseif get_vendor(toolchain) == :clang
                @test !isempty(filter(jll -> jll.package.name == "Clang_jll", toolchain.deps))
            end

            # Download the toolchain, make sure it runs
            @info("CToolchain tests", vendor, use_ccache)
            with_toolchains([toolchain, HostToolsToolchain(BBHostPlatform())]) do prefix, env
                env["CCACHE_DIR"] = ccache_dir
                toolchain_tests(prefix, env, platform, "CToolchain"; do_cxxabi_tests=true)
            end
        end
    end

    # Do the same, but with `GCCBootstrap`
    toolchain = CToolchain(platform; vendor=:gcc_bootstrap, use_ccache=false)
    @info("CToolchain tests", vendor=:gcc_bootstrap, use_ccache=false)
    with_toolchains([toolchain]) do prefix, env
        toolchain_tests(prefix, env, platform, "CToolchain"; do_cxxabi_tests=true)
    end

    # Do the same again, but with `LLVMBootstrap_Clang`
    toolchain = CToolchain(platform; vendor=:clang_bootstrap, use_ccache=false)
    @info("CToolchain tests", vendor=:clang_bootstrap, use_ccache=false)
    with_toolchains([toolchain]) do prefix, env
        toolchain_tests(prefix, env, platform, "CToolchain"; do_cxxabi_tests=true)
    end

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
                extra_ldflags=["-L$(host_prefix)/lib"],
                extra_cflags=["-I$(host_prefix)/include"],
                use_ccache=false,
            )

            # Create "target toolchain" with extra flags to link against the target prefix
            # In BB, this usually points to something like `/workspace/destdir/$(target)`
            target_ctoolchain = CToolchain(platform;
                extra_ldflags=["-L$(target_prefix)/lib"],
                extra_cflags=["-I$(target_prefix)/include"],
                use_ccache=false,
            )

            # We'll need things like `make` etc...
            hosttools_toolchain = HostToolsToolchain(platform)

            # Use each toolchain to build a `libfoo` with a different version embedded within:
            host_version = 1
            target_version = 2
            for (toolchains, install_prefix, cc, libfoo_version) in (
                    ([host_ctoolchain,   hosttools_toolchain], host_prefix,   "\${HOST_CC}",  host_version),
                    ([target_ctoolchain, hosttools_toolchain], target_prefix, "\${CC}",      target_version))
                with_toolchains(toolchains) do prefix, env
                    cd(joinpath(@__DIR__, "testsuite", "CToolchainHostIsolation", "libfoo")) do
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
            with_toolchains([host_ctoolchain, hosttools_toolchain]) do _, host_env
                with_toolchains([target_ctoolchain]) do _, target_env
                    env = path_appending_merge(host_env, target_env)
                    cd(joinpath(@__DIR__, "testsuite", "CToolchainHostIsolation")) do
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

    # Ensure that `make compile-all` works for all toolchains
    @info("Running `\$CC --version` for $(length(supported_platforms(CToolchain))) platforms")
    for target in supported_platforms(CToolchain)
        for vendor in (:auto, :gcc, :clang, :gcc_bootstrap, :clang_bootstrap)
            toolchain = CToolchain(CrossPlatform(BBHostPlatform() => target); vendor, use_ccache=false)
            with_toolchains([toolchain]) do prefix, env
                @testset "$(triplet(target)) - $(vendor)" begin
                    # First, run `$CC --version` for everything
                    for tool_name in ("CC", "LD", "AS")
                        @testset "$(tool_name)" begin
                            p, output = capture_output(setenv(`bash -c "\$$(tool_name) --version"`, env))
                            if !success(p)
                                println(output)
                            end
                            @test success(p)
                        end
                    end

                    # Next, run `make compile-all`
                    cd(joinpath(@__DIR__, "testsuite", "CToolchain")) do
                        p, output = capture_output(setenv(Cmd(["/bin/bash", "-c", "make clean-all && make compile-all"]), env))
                        if !success(p)
                            println(output)
                        end
                        @test success(p)
                    end
                end
            end
        end
    end

    # Ensure that `strip` works for macOS without needing to resign
    macos_cp = CrossPlatform(BBHostPlatform() => Platform("aarch64", "macos"))
    toolchains = [HostToolsToolchain(macos_cp), CToolchain(macos_cp)]
    with_toolchains(toolchains) do prefix, env
        cd(joinpath(@__DIR__, "testsuite", "CToolchain", "08_strip_resigning")) do
            @test success(setenv(Cmd(["/bin/bash", "-c", "make clean; make check"]), env))
        end
    end
end

@warn "TODO: test macos version min?"
@warn "TODO: test clang against libcxx and compiler_rt!"
@warn "TODO: test dlltool determinism"
