# KeywordArgumentExtraction.jl

This package provides helper macros to deal with the complexity of passing keyword arguments through API layers.
Although the keyword argument splatting syntax `kwargs...` is convenient, it can be cumbersome to manually specify which pieces of a splat should be passed to various subroutines within a larger function.
This package defines `@extract_kwargs` and `@auto_extract_kwargs` to aid the process of pulling out keyword arguments that are applicable to functions being called with a larger `kwargs...` splat.

## Usage of `@extract_kwargs`

This macro allows you to succinctly specify a list of keyword argument names that should be passed to a function if they are specified in the `kwargs...` splat:

```julia
function foo(x::Int; verbose::Bool = false, force::Bool = false)
    ...
end
function bar(x::Int; verbose::Bool = false, retry_limit::Int = 3)
    ...
end
function driver(x::Int; kwargs...)
    foo(x; @extract_kwargs(kwargs, :verbose, :force)...)
    bar(x; @extract_kwargs(kwargs, :verbose, :retry_limit)...)
end
```

Note that extra keyword arguments to `driver()` will be silently ignored.
To avoid this, you can use the helper macro `@ensure_all_kwargs_consumed` on the `driver()` function definition, see its docstring for more details.

## Usage of `@auto_extract_kwargs`

It can become cumbersome to list out all keyword arguments that should be passed on to `foo()` or `bar()`.
It's also easy to forget to update lists when function signatures change.
To fix this, `@auto_extract_kwargs` will automatically analyze the function signature of the target call, and build the list of keyword arguments to extract from that.
This, combined with `@ensure_all_kwargs_consumed` provides a fully-automated way of passing only the keyword arguments that match each subroutine call, while throwing an error if extra arguments would be ignored:

```julia
@ensure_all_kwargs_consumed function driver(x::Int; kwargs...)
    @auto_extract_kwargs foo(x; kwargs...)
    @auto_extract_kwargs bar(x; kwargs...)
end
```
