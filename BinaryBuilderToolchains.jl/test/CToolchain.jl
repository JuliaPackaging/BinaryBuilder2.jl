using Test, BinaryBuilderSources, BinaryBuilderToolchains, Base.BinaryPlatforms, Scratch

function capture_output(cmd)
    output = Pipe()
    p = run(pipeline(cmd; stdout=output, stderr=output); wait=false)
    close(output.in)
    output = String(read(output))
    return p, output
end

@testset "CToolchain" begin
    # Use native compilers so that we can run the output.
    platform = CrossPlatform(HostPlatform() => HostPlatform())
    toolchain = CToolchain(platform; default_ctoolchain = true)
    testsuite_path = joinpath(@__DIR__, "testsuite", "CToolchain")
    @test toolchain.vendor ∈ (:gcc, :clang)
    @test !isempty(filter(jll -> jll.package.name == "GCC_jll", toolchain.deps))

    # Download the toolchain, make sure it runs
    srcs = toolchain_sources(toolchain)
    prepare(srcs; verbose=true)
    mktempdir(@get_scratch!("tempdirs")) do prefix
        deploy(srcs, prefix)

        env = toolchain_env(toolchain, prefix)
        cd(testsuite_path) do
            # Run our entire test suite first
            p = run(addenv(`make cleancheck-all`, env))
            @test success(p)

            # Run the `cxx_string_abi` with `BB_WRAPPERS_VERBOSE` and ensure that we get the right
            # `cxxstring_abi` defines showing in the build log:
            @test haskey(platform.target, "cxxstring_abi")
            cxxstring_abi_define = string(
                "-D_GLIBCXX_USE_CXX11_ABI=",
                platform.target["cxxstring_abi"] == "cxx11" ? "1" : "0",
            )

            # Turn on verbose wrappers, and ensure we're using `g++` on all platforms
            debug_env = copy(env)
            debug_env["BB_WRAPPERS_VERBOSE"] = "true"
            debug_env["CXX"] = "g++"
            p, debug_out = capture_output(addenv(`make cleancheck-02_cxx_string_abi`, debug_env))
            @test success(p)
            @test occursin(cxxstring_abi_define, debug_out)
        end
    end
end

@warn "TODO: test macos version min?"
@warn "TODO: test clang against libgcc!"
