using KeywordArgumentExtraction, Test

# Simple case; just take in a few arguments
call_log = []
function foo_simple(x::Int; verbose::Bool = false, force::Bool = false)
    push!(call_log, ["foo_simple", x, verbose, force])
end
function bar_simple(x::Int; verbose::Bool = false, retry_limit::Int = 0)
    push!(call_log, ["bar_simple", x, verbose, retry_limit])
end

function driver_simple_explicit(x::Int; kwargs...)
    foo_simple(x; @extract_kwargs(kwargs, :verbose, :force)...)
    bar_simple(x; @extract_kwargs(kwargs, :verbose, :retry_limit)...)
end

function driver_simple_automatic(x::Int; kwargs...)
    @auto_extract_kwargs foo_simple(x; kwargs...)
    @auto_extract_kwargs bar_simple(x; kwargs...)
end

function test_call_log(f::Function, reference_call_log)
    empty!(call_log)
    f()
    for (l1, l2) in zip(call_log, reference_call_log)
        if l1 != l2
            @error("Call logs differ", l1, l2)
        end
        @test l1 == l2
    end
end

function make_call_log(x, verbose, force, retry_limit)
    return [
        ["foo_simple", x, verbose, force],
        ["bar_simple", x, verbose, retry_limit],
    ]
end

@testset "simple cases" begin
    test_call_log(make_call_log(0, true, true, 3)) do
        driver_simple_explicit(0; verbose=true, force=true, retry_limit=3)
    end
    test_call_log(make_call_log(0, true, true, 3)) do
        driver_simple_automatic(0; verbose=true, force=true, retry_limit=3)
    end

    #Test that extra kwargs are silently ignored
    test_call_log(make_call_log(1, false, false, 2)) do
        driver_simple_explicit(1; verbose=false, force=false, retry_limit=2, ignore_me=true)
    end
    test_call_log(make_call_log(1, false, false, 2)) do
        driver_simple_automatic(1; verbose=false, force=false, retry_limit=2, ignore_me=true)
    end

    # Test that default values leak through
    test_call_log(make_call_log(1, false, false, 2)) do
        driver_simple_explicit(1; retry_limit=2)
    end
    test_call_log(make_call_log(1, false, false, 2)) do
        driver_simple_automatic(1; retry_limit=2)
    end

    # Test that we get a TypeError if we try to pass an incorrect value
    @test_throws TypeError driver_simple_explicit(1; verbose="true")
    @test_throws TypeError driver_simple_automatic(1; verbose="true")
end

# Nested case; where we're passing through pretty much everything
function driver_nested(x::Int; num_runs = 1, kwargs...)
    for idx in 1:num_runs
        @auto_extract_kwargs driver_simple_automatic(x; kwargs...)
    end
end

function make_nested_call_log(x, num_runs, verbose, force, retry_limit)
    ret = []
    for idx in 1:num_runs
        append!(ret, make_call_log(x, verbose, force, retry_limit))
    end
    return ret
end

@testset "Nesting" begin
    test_call_log(make_nested_call_log(0, 1, false, false, 0)) do
        driver_nested(0)
    end

    test_call_log(make_nested_call_log(0, 2, true, true, 3)) do
        driver_nested(0; num_runs=2, verbose=true, force=true, retry_limit=3)
    end
end

