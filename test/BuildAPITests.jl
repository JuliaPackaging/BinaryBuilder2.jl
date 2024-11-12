using Test, BinaryBuilder2, Random

if !isdefined(@__MODULE__, :TestingUtils)
    include(joinpath(pkgdir(BinaryBuilder2), "test", "TestingUtils.jl"))
end


@testset "BuildAPI" begin

using BinaryBuilder2: next_jll_version
@testset "next_jll_version" begin
    versions = [
        v"1.0.0",
        v"1.1.0",
        v"1.1.1",
        v"1.2.0",
    ]
    @test next_jll_version(versions, v"0.9.0") == v"0.9.0"
    @test next_jll_version(versions, v"1.1.0") == v"1.1.2"
    @test next_jll_version(versions, v"1.2.0") == v"1.2.1"
    @test next_jll_version(versions, v"1.3.0") == v"1.3.0"
    @test next_jll_version(nothing, v"1.2.0") == v"1.2.0"
end

@testset "Failing build" begin
    # This build explicitly fails because it runs `false`
    meta = BuildMeta(; verbose=false)
    bad_build_config = BuildConfig(
        meta,
        "foo",
        v"1.0.0",
        [],
        apply_spec_plan(spec_plan, native_linux, native_linux),
        raw"""
        env_val=pre
        false
        env_val=post
        """,
    );
    failing_build_result = build!(bad_build_config)
    @test failing_build_result.status == :failed
    @test failing_build_result.env["env_val"] == "pre"
    @test occursin("Previous command 'false' exited with code 1", failing_build_result.build_log)
end

include("BuildAPITests/LowLevelBuildTests.jl")
include("BuildAPITests/ConvenienceTests.jl")
include("BuildAPITests/MultiJLLOutputTests.jl")
include("BuildAPITests/CustomSpecTests.jl")

end # testset "BuildAPI"
