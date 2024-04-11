using Test, BinaryBuilder2, Pkg, JLLGenerator, Accessors

@testset "Universes" begin
    # Create a universe holding just `General`
    mktempdir() do dir
        uni = Universe(dir)
        
        # Register a JLL into it; we'll use HelloWorldC_jll from JLLGenerator contrib directory,
        # but we'll name it `HelloWorldC2_jll` so that it is created as a new entry in the registry
        hwc_jll = include(joinpath(@__DIR__, "..", "JLLGenerator.jl", "contrib", "example_jllinfos", "HelloWorldC_jll.jl"))
        hwc_jll = @set hwc_jll.name = "HelloWorldC2"
        hwc_jll = @set hwc_jll.artifacts = map(hwc_jll.artifacts) do art
            @set art.name = "HelloWorldC2"
        end
        register!(uni, hwc_jll)
        Pkg.instantiate(uni)

        # Launch a Julia sub-process and ensure that we can load HelloWorldC_jll from the universe
        in_universe(uni) do env
            @test success(run(addenv(`$(Base.julia_cmd()) --project=$(BinaryBuilder2.environment_path(uni)) -e "using Pkg; Pkg.instantiate(); using HelloWorldC2_jll, Test; @test success(hello_world())"`, env)))
        end
    end
end