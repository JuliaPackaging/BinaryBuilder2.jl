using Test, BinaryBuilder2, Random, Sandbox

if !isdefined(@__MODULE__, :TestingUtils)
    include(joinpath(pkgdir(BinaryBuilder2), "test", "TestingUtils.jl"))
end


@testset "BuildAPI" begin

using BinaryBuilder2: next_jll_version, store_ccache_log_artifact, read_metadir_ccache_statslog, artifact_path
@testset "store_ccache_log_artifact" begin
    mktempdir() do depot_path
        uni = Universe(; depot_path, persistent=false)

        # nothing and empty data both return nothing
        @test store_ccache_log_artifact(uni, nothing) === nothing
        @test store_ccache_log_artifact(uni, UInt8[]) === nothing

        # non-empty data creates an artifact and returns its hash
        data = b"Cachefile hits:    42\nCache misses:      7\n"
        hash = store_ccache_log_artifact(uni, data)
        @test hash isa SHA1Hash
        statslog_file = joinpath(artifact_path(uni, hash), "ccache-statslog")
        @test isfile(statslog_file)
        @test read(statslog_file) == data
    end
end

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
    @test occursin("Previous command 'false' exited with code 1", build_log(failing_build_result))

    # read_metadir_ccache_statslog returns nothing when ccache was never invoked
    @test failing_build_result.ccache_log_artifact === nothing

    # ccache_stats warns and returns nothing when no statslog is available
    @test_logs (:warn, r"No ccache statslog") begin
        @test ccache_stats(failing_build_result) === nothing
    end

    # ccache_stats runs ccache --show-log-stats against a real (dummy) statslog artifact
    dummy_statslog = b"cache_miss\ncache_hit(preprocessed)\n"
    dummy_ccache_artifact = store_ccache_log_artifact(meta.universe, dummy_statslog)
    dummy_result = BuildResult(
        bad_build_config,
        :success,
        nothing,
        nothing,
        Dict{String,MountInfo}(),
        failing_build_result.log_artifact,
        Dict{String,String}(),
        dummy_ccache_artifact,
    )
    buf = IOBuffer()
    @test ccache_stats(dummy_result; io=buf) === nothing
    @test !isempty(String(take!(buf)))
end

include("BuildAPITests/LowLevelBuildTests.jl")
include("BuildAPITests/ConvenienceTests.jl")
include("BuildAPITests/MultiJLLOutputTests.jl")
include("BuildAPITests/CustomSpecTests.jl")
include("BuildAPITests/BuildSelection.jl")

end # testset "BuildAPI"
