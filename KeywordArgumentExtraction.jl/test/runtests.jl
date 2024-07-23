using KeywordArgumentExtraction, Test

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

# Test driver for when we pass a kwarg with the shorthand name
function driver_matched_name(x::Int; verbose::Bool = false, kwargs...)
    @auto_extract_kwargs foo_simple(x; verbose, kwargs...)
    @auto_extract_kwargs bar_simple(x; verbose, kwargs...)
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

@testset "Simple cases" begin
    test_call_log(make_call_log(0, true, true, 3)) do
        driver_simple_explicit(0; verbose=true, force=true, retry_limit=3)
    end
    test_call_log(make_call_log(0, true, true, 3)) do
        driver_simple_automatic(0; verbose=true, force=true, retry_limit=3)
    end

    test_call_log(make_call_log(0, true, true, 3)) do
        driver_matched_name(0; verbose=true, force=true, retry_limit=3)
    end

    # Test that extra kwargs are silently ignored
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

# This function errors if kwargs are passed that are not consumed by `@auto_extract_kwargs`
@ensure_all_kwargs_consumed function driver_simple_checked(x::Int; kwargs...)
    @auto_extract_kwargs foo_simple(x; kwargs...)
    @auto_extract_kwargs bar_simple(x; kwargs...)
end

function driver_complex_checked(x::Int; kwargs...)
    @ensure_all_kwargs_consumed_header()
    @auto_extract_kwargs foo_simple(x; kwargs...)
    @auto_extract_kwargs bar_simple(x; kwargs...)
    @ensure_all_kwargs_consumed_check(kwargs)
end

@ensure_all_kwargs_consumed function driver_explicit_checked(x::Int; kwargs...)
    foo_simple(x; @extract_kwargs(kwargs, :verbose, :force)...)
    bar_simple(x; @extract_kwargs(kwargs, :verbose, :retry_limit)...)
end

@testset "Consumption" begin
    # Test that extra kwargs cause an error if the function is checking
    test_call_log(make_call_log(1, false, false, 2)) do
        driver_simple_checked(1; verbose=false, force=false, retry_limit=2)
    end
    @test_throws ErrorException driver_simple_checked(1; verbose=false, this_will="error")

    test_call_log(make_call_log(1, false, false, 2)) do
        driver_complex_checked(1; verbose=false, force=false, retry_limit=2)
    end
    @test_throws ErrorException driver_complex_checked(1; verbose=false, this_will="error")

    # Also test with `@extract_kwargs`
    test_call_log(make_call_log(1, false, false, 2)) do
        driver_explicit_checked(1; verbose=false, force=false, retry_limit=2)
    end
    @test_throws ErrorException driver_explicit_checked(1; verbose=false, this_will="error")
end

function foo_no_kwargs(x::Int)
    push!(call_log, ["foo_no_kwargs", x])
end

function driver_no_kwargs(x::Int; kwargs...)
    @auto_extract_kwargs foo_no_kwargs(x; kwargs...)
end

@testset "Edge cases" begin
    # Test case where we use `@auto_extract_kwargs` on something that has no kwargs
    test_call_log([["foo_no_kwargs", 1]]) do
        driver_no_kwargs(1; ignore_me=true)
    end
end
