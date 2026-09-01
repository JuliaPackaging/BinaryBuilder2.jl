using Test, BinaryBuilder2, Random, Sandbox
using ChromeTracing: clear_trace!, snapshot_default_buffer

if !isdefined(@__MODULE__, :TestingUtils)
    include(joinpath(pkgdir(BinaryBuilder2), "test", "TestingUtils.jl"))
end


@testset "BuildAPI" begin

@testset "@trace_function" begin
    struct TraceDisabledMeta <: BinaryBuilder2.AbstractBuildMeta end
    struct TraceEnabledMeta <: BinaryBuilder2.AbstractBuildMeta end
    BinaryBuilder2.trace_enabled(::TraceDisabledMeta) = false
    BinaryBuilder2.trace_enabled(::TraceEnabledMeta) = true
    BinaryBuilder2.trace_begin(::TraceEnabledMeta, name::AbstractString; cat::AbstractString = "bb2", args = nothing) =
        args === nothing ?
            (ChromeTracing.@tracepoint name ph="B" cat=cat) :
            (ChromeTracing.@tracepoint name ph="B" cat=cat args=args)
    BinaryBuilder2.trace_end(::TraceEnabledMeta, name::AbstractString; cat::AbstractString = "bb2", args = nothing) =
        args === nothing ?
            (ChromeTracing.@tracepoint name ph="E" cat=cat) :
            (ChromeTracing.@tracepoint name ph="E" cat=cat args=args)

    BinaryBuilder2.@trace_function meta=meta name="bb2.test_span" args=(phase="span",) function traced_with_meta(meta, x)
        return x + 1
    end

    clear_trace!()
    @test traced_with_meta(TraceDisabledMeta(), 41) == 42
    @test isempty(snapshot_default_buffer())

    clear_trace!()
    @test traced_with_meta(TraceEnabledMeta(), 41) == 42
    events = snapshot_default_buffer()
    @test length(events) == 2
    @test events[1]["name"] == "bb2.test_span"
    @test events[1]["ph"] == "B"
    @test events[1]["args"]["phase"] == "span"
    @test events[2]["name"] == "bb2.test_span"
    @test events[2]["ph"] == "E"
    @test events[2]["args"]["phase"] == "span"

    # A `config` argument gets its meta extracted automatically, and the trace
    # name defaults to the function name, prefixed with `bb2.`
    struct TracedConfig
        meta::BinaryBuilder2.AbstractBuildMeta
        to::BinaryBuilder2.TimerOutput
    end
    TracedConfig(meta) = TracedConfig(meta, BinaryBuilder2.TimerOutput())
    BinaryBuilder2.AbstractBuildMeta(config::TracedConfig) = config.meta
    BinaryBuilder2.timer_output(config::TracedConfig) = config.to

    BinaryBuilder2.@trace_function args=(phase="auto",) function traced_with_config(config, x)
        return x + 1
    end

    clear_trace!()
    @test traced_with_config(TracedConfig(TraceDisabledMeta()), 41) == 42
    @test isempty(snapshot_default_buffer())

    clear_trace!()
    @test traced_with_config(TracedConfig(TraceEnabledMeta()), 41) == 42
    @test [(e["name"], e["ph"], e["args"]["phase"]) for e in snapshot_default_buffer()] == [
        ("bb2.traced_with_config", "B", "auto"),
        ("bb2.traced_with_config", "E", "auto"),
    ]

    # A `config` that carries a `TimerOutput` gets the function timed into it as
    # well, just as a hand-written `with_trace()` zone would be
    BinaryBuilder2.@trace_function function timed_with_config(config, x)
        return x + 1
    end
    BinaryBuilder2.@trace_function timer_name="renamed" function renamed_with_config(config, x)
        return x + 1
    end

    clear_trace!()
    timed_config = TracedConfig(TraceEnabledMeta())
    @test timed_with_config(timed_config, 41) == 42
    @test renamed_with_config(timed_config, 41) == 42
    @test [(e["name"], e["ph"]) for e in snapshot_default_buffer()] == [
        ("bb2.timed_with_config", "B"),
        ("bb2.timed_with_config", "E"),
        ("bb2.renamed_with_config", "B"),
        ("bb2.renamed_with_config", "E"),
    ]
    @test haskey(timed_config.to.inner_timers, "timed_with_config")
    @test haskey(timed_config.to.inner_timers, "renamed")

    # ...and the timing happens even when the meta has tracing turned off
    untimed_config = TracedConfig(TraceDisabledMeta())
    @test timed_with_config(untimed_config, 41) == 42
    @test haskey(untimed_config.to.inner_timers, "timed_with_config")

    # A function with nothing to trace against is an error, as is a bad option
    no_options = BinaryBuilder2._parse_trace_function_options(())
    @test_throws ArgumentError BinaryBuilder2._wrap_trace_function_def(:(function f(x, y)
        return x + y
    end), no_options)
    @test_throws ArgumentError BinaryBuilder2._wrap_trace_function_def(:(x + y), no_options)
    @test_throws ArgumentError BinaryBuilder2._parse_trace_function_options((:(bogus = 1),))

    # Qualified names, `where` clauses, keyword arguments and splats all get
    # picked apart properly when generating the defaults
    @test BinaryBuilder2._trace_function_name(:(Auditor.audit!(config::T) where {T})) == "audit!"
    @test BinaryBuilder2._signature_argnames(:(f(a, b::Int, c...; d = 1, e::T = 2, kwargs...) where {T})) == [:d, :e, :kwargs, :a, :b, :c]
    @test BinaryBuilder2._default_trace_meta(:(f(x, config))) == :config
    # `meta` wins over `config`, and a function with neither gets no meta at all
    @test BinaryBuilder2._default_trace_meta(:(f(config; meta = 1))) == :meta
    @test BinaryBuilder2._default_trace_meta(:(f(x, y))) === nothing
end

@testset "with_trace" begin
    struct TimedMeta <: BinaryBuilder2.AbstractBuildMeta
        to::BinaryBuilder2.TimerOutput
        traced::Bool
    end
    BinaryBuilder2.trace_enabled(meta::TimedMeta) = meta.traced
    BinaryBuilder2.timer_output(meta::TimedMeta) = meta.to
    BinaryBuilder2.trace_begin(::TimedMeta, name::AbstractString; cat::AbstractString = "bb2", args = nothing) =
        args === nothing ?
            (ChromeTracing.@tracepoint name ph="B" cat=cat) :
            (ChromeTracing.@tracepoint name ph="B" cat=cat args=args)
    BinaryBuilder2.trace_end(::TimedMeta, name::AbstractString; cat::AbstractString = "bb2", args = nothing) =
        args === nothing ?
            (ChromeTracing.@tracepoint name ph="E" cat=cat) :
            (ChromeTracing.@tracepoint name ph="E" cat=cat args=args)

    # Even with tracing disabled, we still record the zone in `to`
    meta = TimedMeta(BinaryBuilder2.TimerOutput(), false)
    clear_trace!()
    @test BinaryBuilder2.with_trace(() -> 41 + 1, meta, "bb2.spec_hash") == 42
    @test isempty(snapshot_default_buffer())
    @test haskey(meta.to.inner_timers, "spec_hash")

    # With tracing enabled, we get both, and nested zones nest in `to` as well
    meta = TimedMeta(BinaryBuilder2.TimerOutput(), true)
    clear_trace!()
    BinaryBuilder2.with_trace(meta, "bb2.outer"; args=(phase="span",)) do
        BinaryBuilder2.with_trace(() -> nothing, meta, "bb2.inner"; timer_name="custom")
    end
    events = snapshot_default_buffer()
    @test [(e["name"], e["ph"]) for e in events] == [
        ("bb2.outer", "B"),
        ("bb2.inner", "B"),
        ("bb2.inner", "E"),
        ("bb2.outer", "E"),
    ]
    @test events[1]["args"]["phase"] == "span"
    @test haskey(meta.to.inner_timers, "outer")
    @test haskey(meta.to.inner_timers["outer"].inner_timers, "custom")

    # A meta without a timer (or an explicit `to=nothing`) just traces
    meta = TimedMeta(BinaryBuilder2.TimerOutput(), true)
    BinaryBuilder2.with_trace(() -> nothing, meta, "bb2.untimed"; to=nothing)
    @test isempty(meta.to.inner_timers)
end

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
