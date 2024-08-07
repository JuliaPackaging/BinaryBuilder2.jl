module KeywordArgumentExtraction
using ExprTools

export @extract_kwargs, @auto_extract_kwargs, @ensure_all_kwargs_consumed, @ensure_all_kwargs_consumed_header, @ensure_all_kwargs_consumed_check

"""
    @extract_kwargs(kwargs, keys...)

Helper macro to extract a subset of keyword arguments from `kwargs`, identified
by the variable number of arguments in `keys`.  Example usage:

    result = foo(
        config;
        @extract_kwargs(kwargs, :debug_modes, :disable_cache)...,
    )

This takes `kwargs` and, if `debug_modes` or `disable_cache` are set within it,
extracts them and creates a new `Dict{Symbol}` to contain those mappings to pass
on to the function call `foo()`.
"""
macro extract_kwargs(kwargs, keys...)
    quote
        begin
            if $(esc(Expr(:isdefined, :consumed_kwargs)))
                for k in [$(keys...)]
                    push!($(esc(:consumed_kwargs)), k)
                end
            end
            Dict(k => v for (k, v) in pairs($(esc(kwargs))) if k in [$(keys...)])
        end
    end
end

function find_kwargs_splat(kwargs)
    splat_idxs = findall(a -> Meta.isexpr(a, Symbol("...")), kwargs)
    if length(splat_idxs) != 1
        throw(ArgumentError("Function call must have exactly one `kwargs....` splat (found $(length(splat_idxs)))"))
    end
    return only(kwargs[splat_idxs[1]].args)
end

"""
    @auto_extract_kwargs(ex)

Macro to automatically extract all keyword arguments from a `kwargs...` that are
applicable to the target function call.  Example:

    function foo(config::Config; verbose = false, fooify = true)
        ...
    end

    function bar(Config::Config; verbose = false, barbar = true )
        ...
    end

    function driver(config::Config; kwargs...)
        @auto_extract_kwargs foo(config; kwargs...)
        @auto_extract_kwargs bar(config; kwargs...)
    end

    driver(config; verbose=true, fooify=false, barbar=false)

Note that method matching is performed using only positional arguments.
"""
macro auto_extract_kwargs(ex)
    # Ensure we've been given a function call
    if ex.head != :call
        throw(ArgumentError("Expression must be a function call"))
    end
    func_name = esc(ex.args[1])

    # Find the `:parameters` argument, which holds all our kwargs stuff
    parameters_idxs = findall(a -> Meta.isexpr(a, :parameters), ex.args)
    if length(parameters_idxs) != 1
        throw(ArgumentError("Function call must have a `kwargs....` splat"))
    end

    # Find the `kwargs...` splat (there must be exactly one).  This is what we
    # will extract matching keyword arguments from.
    parameters = ex.args[parameters_idxs[1]]
    kwargs_name = find_kwargs_splat(parameters.args)
    kwargs_args = [a for a in parameters.args if !Meta.isexpr(a, Symbol("..."))]

    # Split these, as I don't know how to get `esc()` to work with a list of pairs, etc...
    get_kwarg_key(s::Symbol) = s
    get_kwarg_key(s::Expr) = s.args[1]
    get_kwarg_value(s::Symbol) = esc(s)
    get_kwarg_value(s::Expr) = esc(s.args[2])
    kwargs_args_keys = get_kwarg_key.(kwargs_args)
    kwargs_args_vals = get_kwarg_value.(kwargs_args)

    # Get the non-keyword arguments.  We'll use these to find the correct method to analyze.
    non_kwargs_args = esc.(filter(a -> !Meta.isexpr(a, :parameters), ex.args[2:end]))
    return quote
        # Extract the types of the non-kwargs args, look up all matching methods
        ts = Base.typesof($(non_kwargs_args...))
        ms = methods($(func_name), ts)

        # Error out if there's any ambiguity
        if length(ms) != 1
            throw(ArgumentError(string(
                "@auto_extract_kwargs() invoked on ambiguous call site ",
                $(func_name),
                "(",
                [string(a, "::", t, ", ") for (a, t) in zip(collect($(non_kwargs_args...)), ts.types)]...,
                "): ",
                length(ms),
                " methods found instead of 1.",
            )))
        end

        # Get the keyword arguments that were defined in the call itself
        kwargs = Dict(zip($(kwargs_args_keys), [$(kwargs_args_vals...)]))

        # Get the keyword arguments from the `Method`, load them into a sub-kwargs
        # If the method has a `kwargs...` splat within it, we just pass _all_ kwargs on.
        method_kwargs_names = Base.kwarg_decl(ms[1])
        if any(endswith.(string.(method_kwargs_names), ("...",)))
            sub_kwargs = $(esc(kwargs_name))
        else
            sub_kwargs = Dict(k => $(esc(kwargs_name))[k] for k in method_kwargs_names if haskey($(esc(kwargs_name)), k))
        end

        if $(esc(Expr(:isdefined, :consumed_kwargs)))
            for k in keys(sub_kwargs)
                push!($(esc(:consumed_kwargs)), k)
            end
        end

        # Insert these sub_kwargs into a new call to our function:
        $(func_name)($(non_kwargs_args...); kwargs..., sub_kwargs...)
    end
end

macro ensure_all_kwargs_consumed_header()
    return quote
        $(esc(:consumed_kwargs)) = Set{Symbol}()
    end
end

function check_kwargs_consumed(consumed_kwargs, kwargs)
    unconsumed_kwargs = setdiff(keys(kwargs), consumed_kwargs)
    if !isempty(unconsumed_kwargs)
        error("Did not consume all keyword arguments: $(unconsumed_kwargs)")
    end
end

macro ensure_all_kwargs_consumed_check(kwargs_splat_name)
    return quote
        $(check_kwargs_consumed)($(esc(:consumed_kwargs)), $(esc(kwargs_splat_name)))
    end
end

"""
    @ensure_all_kwargs_consumed(ex)

Helper macro to be applied to function definitions.  Wraps the function body in
code to ensure that all keyword arguments in a `kwargs...` splat are actually
used when passed to `@auto_extract_kwargs` invocations.  If a keyword argument
is not consumed, an error is raised.  The wrapped code will look like:

    function foo(; kwargs...)
        @ensure_all_kwargs_consumed_header()
        try
            ...
        finally
            @ensure_all_kwargs_consumed_check(kwargs)
        end
    end

For functions with more complex control flow, you can use the two sub-macros
`@ensure_all_kwargs_consumed_header()` and `@ensureall_kwargs_consumed_check()`
at the appropriate entry and exit points in your function to assert that no
mis-spelled keyword arguments are being ignored.
"""
macro ensure_all_kwargs_consumed(ex)
    data = splitdef(ex)
    # Find name of kwargs splat (usually `kwargs`)
    kwargs_splat_name = find_kwargs_splat(data[:kwargs])

    data[:body] = quote
        begin
            @ensure_all_kwargs_consumed_header()
            try
                $(data[:body])
            finally
                @ensure_all_kwargs_consumed_check($(kwargs_splat_name))
            end
        end
    end
    return esc(combinedef(data))
end


end # module
