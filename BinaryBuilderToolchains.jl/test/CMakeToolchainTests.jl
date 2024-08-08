using Test, BinaryBuilderToolchains
using BinaryBuilderToolchains: path_appending_merge

include("common.jl")

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
    hello_world_path = joinpath(@__DIR__, "testsuite", "CMakeToolchain", "00_hello_world")
    with_toolchains(host_toolchains) do host_prefix, host_env
        with_toolchains(target_toolchains) do target_prefix, target_env
            env = path_appending_merge(host_env, target_env)
            # Ensure that each `cmake` invokes a different compiler:
            build_check_compiler(hello_world_path, "CMAKE", true, env)
            build_check_compiler(hello_world_path, "HOST_CMAKE", false, env)
        end
    end
end
