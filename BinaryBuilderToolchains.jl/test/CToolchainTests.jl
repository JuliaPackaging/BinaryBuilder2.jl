using Test, BinaryBuilderSources, BinaryBuilderToolchains, BinaryBuilderPlatformExtensions, Base.BinaryPlatforms, Scratch

# Enable this for lots of JLLPrefixes output
const verbose = false

function capture_output(cmd)
    output = Pipe()
    p = run(pipeline(cmd; stdout=output, stderr=output); wait=false)
    close(output.in)
    output = String(read(output))
    return p, output
end

function toolchain_tests(toolchain, prefix, env, platform)
    testsuite_path = joinpath(@__DIR__, "testsuite", "CToolchain")
    cd(testsuite_path) do
        # Run our entire test suite first
        p = run(ignorestatus(setenv(`make -s cleancheck-all`, env)))
        # If this fails, run it again, but with `make` not set to silent
        if !success(p)
            run(setenv(`make cleancheck-all`, env))
        end
        @test success(p)

        # Run the `cxx_string_abi` with `BB_WRAPPERS_VERBOSE` and ensure that we get the right
        # `cxxstring_abi` defines showing in the build log:
        if toolchain.vendor ∈ (:gcc, :gcc_bootstrap)
            @test haskey(platform.target, "cxxstring_abi")
            cxxstring_abi_define = string(
                "-D_GLIBCXX_USE_CXX11_ABI=",
                platform.target["cxxstring_abi"] == "cxx11" ? "1" : "0",
            )

            # Turn on verbose wrappers
            debug_env = copy(env)
            debug_env["BB_WRAPPERS_VERBOSE"] = "true"
            p, debug_out = capture_output(setenv(`make cleancheck-02_cxx_string_abi`, debug_env))
            @test success(p)
            @test occursin(cxxstring_abi_define, debug_out)
        end
    end

    # Ensure that every wrapper we generate actually runs (e.g. no dangling tool references)
    for wrapper in readdir(joinpath(prefix, "wrappers"); join=true)
        @test success(setenv(`$(wrapper) --version`, env))
    end
end


using BinaryBuilderToolchains: get_vendor
@testset "CToolchain" begin
    # Use native compilers so that we can run the output.
    platform = CrossPlatform(BBHostPlatform() => HostPlatform())
    mktempdir() do ccache_dir
        for use_ccache in (true, false)
            toolchain = CToolchain(platform; use_ccache)
            @test get_vendor(toolchain) ∈ (:gcc, :clang)
            if get_vendor(toolchain) == :gcc
                @test !isempty(filter(jll -> jll.package.name == "GCC_jll", toolchain.deps))
            elseif get_vendor(toolchain) == :clang
                @test !isempty(filter(jll -> jll.package.name == "Clang_jll", toolchain.deps))
            end

            # Download the toolchain, make sure it runs
            with_toolchains([toolchain]) do prefix, env
                env["CCACHE_DIR"] = ccache_dir
                toolchain_tests(toolchain, prefix, env, platform)
            end
        end
    end

    # Do the same, but with `GCCBootstrap`
    toolchain = CToolchain(platform; vendor = :bootstrap, use_ccache=false)
    with_toolchains([toolchain]) do prefix, env
        toolchain_tests(toolchain, prefix, env, platform)
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
            with_toolchains([host_ctoolchain, target_ctoolchain, hosttools_toolchain]) do prefix, env
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

    # Ensure that `$CC --version` at least works for all of our supported platforms
    for target in supported_platforms(CToolchain)
        for vendor in (:auto, :bootstrap)
            toolchain = CToolchain(CrossPlatform(BBHostPlatform() => target); vendor, use_ccache=false)
            with_toolchains([toolchain]) do prefix, env
                for tool_name in ("CC", "LD", "AS")
                    @testset "$(triplet(target)) - $(vendor) - $(tool_name)" begin
                        @test success(setenv(`bash -c "\$$(tool_name) --version"`, env))
                    end
                end
            end
        end
    end
end

@warn "TODO: test macos version min?"
@warn "TODO: test clang against libgcc!"
@warn "TODO: test dlltool determinism"
