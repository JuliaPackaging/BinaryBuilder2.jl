# Included by `runtests.jl` into a module that has already loaded `common.jl`.

@testset "CToolchain" begin
    # Ensure that `strip` is deterministic for macOS and does not warn about code signatures
    @testset "macos strip determinism" begin
        for macos_target in filter(Sys.isapple, supported_platforms(CToolchain))
            macos_cp = CrossPlatform(BBHostPlatform() => macos_target)
            toolchains = [CToolchain(macos_cp), htt_toolchain]
            with_toolchains(toolchains) do prefix, env
                cd(joinpath(testsuite_dir, "CToolchain", "08_strip_determinism")) do
                    @test success(setenv(Cmd(["/bin/bash", "-c", "make clean; make check"]), env))
                end
            end
        end
    end
end
