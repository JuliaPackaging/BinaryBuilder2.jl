# Included by `runtests.jl` into a module that has already loaded `common.jl`.
# `target` is defined by `runtests.jl`.

# Ensure that we can compile all CMake tests for every toolchain vendor targeting `target`
@testset "CMakeToolchain compile-all" begin
    target_platform = CrossPlatform(BBHostPlatform() => target)
    for vendor in vendors_to_test()
        c_toolchain = CToolchain(target_platform; vendor, use_ccache=false)
        cmake_toolchain = CMakeToolchain(target_platform)
        hosttools_toolchain = HostToolsToolchain(target_platform)
        with_toolchains([c_toolchain, cmake_toolchain, hosttools_toolchain]) do prefix, env
            @testset "$(triplet(target)) - $(vendor)" begin
                # First, run `$CMAKE --version`
                p, output = capture_output(setenv(`bash -c "\$CMAKE --version"`, env))
                if !success(p)
                    println(output)
                end
                @test success(p)

                # Next, run `make compile-all`
                cd(joinpath(testsuite_dir, "CMakeToolchain")) do
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
