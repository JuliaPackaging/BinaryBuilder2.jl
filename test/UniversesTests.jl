using Test, BinaryBuilder2, Pkg, JLLGenerator, Accessors

@testset "Universes" begin
    # Create a universe holding just `General`
    #dir = mktempdir(;cleanup=false); @show dir; begin
    mktempdir() do dir
        uni = Universe(dir)
        
        # Register a JLL into it; we'll use HelloWorldC_jll from JLLGenerator contrib directory:
        hwc_jll = include(joinpath(@__DIR__, "..", "JLLGenerator.jl", "contrib", "example_jllinfos", "HelloWorldC_jll.jl"))
        # Set the version to something that does not exist in our registries
        hwc_jll = @set hwc_jll.version = v"999.999.999"
        register!(uni, hwc_jll)
        Pkg.instantiate(uni)

        # Launch a Julia sub-process and ensure that we can load HelloWorldC_jll from the universe
        in_universe(uni) do env
            @test success(run(addenv(`$(Base.julia_cmd()) --project=$(BinaryBuilder2.environment_path(uni)) -e "using Pkg; Pkg.instantiate(); using HelloWorldC_jll, Test; @test success(hello_world())"`, env)))
        end
    end
end
