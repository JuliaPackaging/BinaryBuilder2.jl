# Included by `runtests.jl` into a module that has already loaded `common.jl`.

@testset "CMakeToolchain" begin
    platform = CrossPlatform(BBHostPlatform() => BBHostPlatform())
    toolchains = [
        CToolchain(platform),
        HostToolsToolchain(platform),
        CMakeToolchain(platform),
    ]
    # First, simple toolchain tests
    with_toolchains(toolchains) do prefix, env
        toolchain_tests(prefix, env, platform, "CMakeToolchain")
    end

    # Ensure that the `cmake` wrapper passes our toolchain file only when configuring,
    # and that the non-configure modes (`--build`, `--install`, `-E`) still work.
    @testset "cmake modes" begin
        hello_world_path = joinpath(testsuite_dir, "CMakeToolchain", "00_hello_world")
        with_toolchains(toolchains) do prefix, env
            env = copy(env)
            env["BB_WRAPPERS_VERBOSE"] = "true"
            mktempdir() do dir
                build_dir = joinpath(dir, "build")
                install_dir = joinpath(dir, "install")
                function run_cmake(args)
                    p, output = capture_output(setenv(`bash -c "\$CMAKE $(args)"`, env))
                    if !success(p)
                        println(output)
                    end
                    @test success(p)
                    return output
                end

                output = run_cmake("-S$(hello_world_path) -B$(build_dir)")
                @test occursin("-DCMAKE_TOOLCHAIN_FILE=", output)

                output = run_cmake("--build $(build_dir)")
                @test !occursin("-DCMAKE_TOOLCHAIN_FILE=", output)
                @test isfile(joinpath(build_dir, "hello"))

                output = run_cmake("--install $(build_dir) --prefix $(install_dir)")
                @test !occursin("-DCMAKE_TOOLCHAIN_FILE=", output)
                @test isfile(joinpath(install_dir, "bin", "hello"))

                output = run_cmake("-E echo cmake-echo-works")
                @test !occursin("-DCMAKE_TOOLCHAIN_FILE=", output)
                @test occursin("cmake-echo-works", output)
            end
        end
    end

    # Next, test that we can hook up multiple `CMakeToolchain`s
    # with their respective `CToolchain`'s, we'll switch the c++ string ABI
    # version between our "host" and "target" toolchains:
    function BBHostPlatformCxxTag(cxx11::Bool)
        p = BBHostPlatform()
        p["cxxstring_abi"] = cxx11 ? "cxx11" : "cxx03"
        return p
    end
    host_platform = CrossPlatform(BBHostPlatform() => BBHostPlatformCxxTag(false))
    host_ctoolchain = CToolchain(
        host_platform;
        env_prefixes=["HOST_"],
        wrapper_prefixes=["host-"],
        use_ccache=false,
    )
    host_cmaketoolchain = CMakeToolchain(host_platform;
        env_prefixes=["HOST_"],
        wrapper_prefixes=["host-"],
    )

    # The host toolchain file must take its sysroot and install prefix from the host
    # `CToolchain` and prefix, not from the default (target) ones.
    host_toolchain_file = sprint(io -> BinaryBuilderToolchains.generate_cmake_toolchain_file(host_cmaketoolchain, io))
    @test occursin("\$ENV{HOST_CC} -print-sysroot", host_toolchain_file)
    @test occursin("set(CMAKE_INSTALL_PREFIX \$ENV{host_prefix})", host_toolchain_file)

    target_platform = CrossPlatform(BBHostPlatform() => BBHostPlatformCxxTag(true))
    target_ctoolchain = CToolchain(
        target_platform;
        use_ccache=false,
    )
    target_cmaketoolchain = CMakeToolchain(target_platform)

    # Deploy host to one directory, target to another:
    host_toolchains = [
        host_ctoolchain,
        host_cmaketoolchain,
        HostToolsToolchain(host_platform),
    ]
    target_toolchains = [
        target_ctoolchain,
        target_cmaketoolchain,
    ]
    function build_check_compiler(project_dir, cmake_var, cxx11, env)
        env["BB_WRAPPERS_VERBOSE"]="true"
        mktempdir() do build_dir
            p, output = capture_output(setenv(`bash -c "\$$(cmake_var) -B$(build_dir) -S$(project_dir)"`, env))
            if !success(p)
                @error("\$$(cmake_var) failed:")
                println(output)
            end
            @test success(p)
            @test occursin("-D_GLIBCXX_USE_CXX11_ABI=$(cxx11 ? "1" : "0")", output)
        end
    end
    hello_world_path = joinpath(testsuite_dir, "CMakeToolchain", "00_hello_world")
    with_toolchains(host_toolchains) do host_prefix, host_env
        with_toolchains(target_toolchains) do target_prefix, target_env
            env = path_appending_merge(host_env, target_env)
            # Ensure that each `cmake` invokes a different compiler:
            build_check_compiler(hello_world_path, "CMAKE", true, env)
            build_check_compiler(hello_world_path, "HOST_CMAKE", false, env)
        end
    end
end
