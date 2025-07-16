using Test, BinaryBuilder2, Pkg, JLLGenerator, Accessors
using BinaryBuilder2: register_jll!, get_package_versions, reset_timeline!

@testset "Universes" begin
    # Create a universe holding just `General`
    mktempdir() do dir
        uni = Universe("bb2_tests"; depot_path=dir)
        
        # Register a JLL into it; we'll use HelloWorldC_jll from JLLGenerator contrib directory,
        # but we'll name it `HelloWorldC2_jll` so that it is created as a new entry in the registry
        hwc_jll = include(joinpath(pkgdir(JLLGenerator), "contrib", "example_jllinfos", "HelloWorldC_jll.jl"))
        hwc_jll = @set hwc_jll.name = "HelloWorldC2"
        hwc_jll = @set hwc_jll.version = v"1.3.0"
        hwc_jll = @set hwc_jll.builds = map(hwc_jll.builds) do build
            build = @set build.src_version = v"1.3.0"
            build = @set build.name = "HelloWorldC2"
            return build
        end
        register_jll!(uni, hwc_jll; skip_artifact_export=true)
        @test get_package_versions(uni, "HelloWorldC2_jll") == [v"1.3.0"]

        # Launch a Julia sub-process and ensure that we can load HelloWorldC_jll from the universe
        in_universe(uni) do env
            @test success(run(addenv(`$(Base.julia_cmd()) --project=$(BinaryBuilder2.environment_path(uni)) -e "using Pkg; Pkg.instantiate(); using HelloWorldC2_jll, Test; @test success(hello_world())"`, env)))
        end

        # Re-create `uni`, ensure that our build of `hwc_jll` still exists:
        uni = Universe("bb2_tests"; depot_path=dir)
        @test get_package_versions(uni, "HelloWorldC2_jll") == [v"1.3.0"]

        # Register a second version of HelloWorldC2_jll, to ensure that we can stack multiple builds,
        # as long as the `src_version`'s in the builds are different:
        hwc_jll = @set hwc_jll.version = v"1.4.0"
        hwc_jll = @set hwc_jll.builds = map(hwc_jll.builds) do build
            build = @set build.src_version = v"1.4.0"
            return build
        end
        register_jll!(uni, hwc_jll; skip_artifact_export=true)

        hwc_versions = get_package_versions(uni, "HelloWorldC2_jll")
        @test sort(hwc_versions) == [v"1.3.0", v"1.4.0"]

        # Test that `reset_timeline!` eliminates our registrations:
        reset_timeline!(uni)
        @test isempty(get_package_versions(uni, "HelloWorldC2_jll"))
    end
end
