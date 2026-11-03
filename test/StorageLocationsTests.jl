using Test, BinaryBuilder2

if !isdefined(@__MODULE__, :TestingUtils)
    include(joinpath(pkgdir(BinaryBuilder2), "test", "TestingUtils.jl"))
end

@testset "Storage locations" begin
    orig_path = BinaryBuilder2.source_download_cache("x")

    @testset "with_storage_locations" begin
        mktempdir() do depot
            with_storage_locations(Dict(:source_download_cache => depot)) do
                path = BinaryBuilder2.source_download_cache("x")
                @test startswith(path, depot)
                @test isdir(path)
            end
        end
        @test BinaryBuilder2.source_download_cache("x") == orig_path

        @test_throws ErrorException with_storage_locations(() -> nothing, Dict(:not_a_storage_location => "/"))
    end

    @testset "with_temp_storage_locations" begin
        with_temp_storage_locations() do
            for (var, arena) in BinaryBuilder2.storage_locations
                path = getproperty(BinaryBuilder2, var)("x")
                @test !startswith(path, first(Base.DEPOT_PATH))
                @test occursin(string(var), path)
            end
        end
        @test BinaryBuilder2.source_download_cache("x") == orig_path
    end
end
