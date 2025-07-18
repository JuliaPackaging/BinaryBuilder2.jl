using Test, BinaryBuilderToolchains, BinaryBuilderSources

# Get `with_temp_storage_locations()`
include(joinpath(dirname(dirname(pathof(BinaryBuilderSources))), "test", "common.jl"))

function capture_output(cmd)
    output = Pipe()
    p = run(pipeline(cmd; stdout=output, stderr=output); wait=false)
    close(output.in)
    output = String(read(output))
    return p, output
end

function vendors_to_test(curr_arch = arch(BBHostPlatform()))
    # Only test the `*_bootstrap` vendors on x86_64, where I actually did the bootstrapping.
    if curr_arch == "x86_64"
        return (:auto, :gcc, :clang, :gcc_bootstrap, :clang_bootstrap)
    else
        return (:auto, :gcc, :clang)
    end
end

function toolchain_tests(prefix, env, platform, testsuite; do_cxxabi_tests::Bool = false)
    testsuite_path = joinpath(@__DIR__, "testsuite", testsuite)
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
        if do_cxxabi_tests
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
        if Sys.isexecutable(wrapper)
            @test success(setenv(`$(wrapper) --version`, env))
        end
    end
end
