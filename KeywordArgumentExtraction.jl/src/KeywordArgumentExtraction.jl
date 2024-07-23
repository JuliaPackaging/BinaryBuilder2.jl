module KeywordArgumentExtraction

export @extract_kwargs, @auto_extract_kwargs

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
        Dict(k => v for (k, v) in pairs($(esc(kwargs))) if k in [$(keys...)])
    end
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
    kwargs_idxs = findall(a -> Meta.isexpr(a, Symbol("...")), parameters.args)
    if length(kwargs_idxs) != 1
        throw(ArgumentError("Function call must have exactly one `kwargs....` splat (found $(length(kwargs_idxs)))"))
    end
    kwargs_name = only(parameters.args[kwargs_idxs[1]].args)
    kwargs_args = [a for a in parameters.args if !Meta.isexpr(a, Symbol("..."))]

    # Split these, as I don't know how to get `esc()` to work with a list of pairs, etc...
    kwargs_args_keys = [a.args[1] for a in kwargs_args]
    kwargs_args_vals = [esc(a.args[2]) for a in kwargs_args]

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

        # Insert these sub_kwargs into a new call to our function:
        $(func_name)($(non_kwargs_args...); kwargs..., sub_kwargs...)
    end
end


end # module
