using TimerOutputs

# All of our trace zones live under a common prefix/category, so that traces
# from BB2 are easily distinguishable from anything else in the same trace file.
const TRACE_NAME_PREFIX = "bb2."
const TRACE_CATEGORY = "bb2"

# Argument names that we automatically pull an `AbstractBuildMeta` out of when
# no explicit `meta=` is given to `@trace_function`, in order of preference.
const TRACE_META_ARGNAMES = (:meta, :config)

"""
    _trace_function_name(sig)

Return the bare name of the function defined by the signature expression `sig`.
"""
function _trace_function_name(sig)
    if sig isa Symbol
        return string(sig)
    elseif sig isa Expr
        if sig.head ∈ (:call, :where)
            return _trace_function_name(sig.args[1])
        elseif sig.head == :.
            # Qualified names such as `BinaryBuilderAuditor.audit!` carry their
            # final name as a `QuoteNode`
            name = sig.args[end]
            return string(name isa QuoteNode ? name.value : name)
        end
    end
    throw(ArgumentError("@trace_function can only be applied to named functions"))
end

"""
    _collect_argnames!(names, arg)

Push the name(s) bound by the function argument expression `arg` onto `names`,
peeling off type assertions, default values, splats and keyword blocks.
"""
function _collect_argnames!(names::Vector{Symbol}, arg)
    if arg isa Symbol
        push!(names, arg)
    elseif arg isa Expr
        if arg.head == :parameters
            # The keyword argument block holds a whole list of arguments
            for kwarg in arg.args
                _collect_argnames!(names, kwarg)
            end
        elseif arg.head ∈ (:kw, :...) || (arg.head == :(::) && length(arg.args) == 2)
            # `x = default`, `x...` and `x::T` all hide their name one level down
            # (note that a nameless `::T` has only a single argument)
            _collect_argnames!(names, arg.args[1])
        end
    end
    return names
end

"""
    _signature_argnames(sig)

Return the names of all arguments (positional and keyword) of the function
signature expression `sig`.
"""
function _signature_argnames(sig)
    while sig isa Expr && sig.head == :where
        sig = sig.args[1]
    end
    names = Symbol[]
    if sig isa Expr && sig.head == :call
        # `sig.args[1]` is the function name itself, skip it
        for arg in sig.args[2:end]
            _collect_argnames!(names, arg)
        end
    end
    return names
end

"""
    _default_trace_meta(sig)

Return the first argument of `sig` named one of `TRACE_META_ARGNAMES`, or
`nothing` if the function takes no such argument.  We hand the argument itself
to `with_trace()` (rather than its `AbstractBuildMeta()`) so that it can serve
as the source of both the meta and the `TimerOutput`.
"""
function _default_trace_meta(sig)
    argnames = _signature_argnames(sig)
    for name in TRACE_META_ARGNAMES
        if name ∈ argnames
            return name
        end
    end
    return nothing
end

"""
    _parse_trace_function_options(opts)

Parse the `key=value` options given to `@trace_function`; `missing` marks an
option that was not given, and which we therefore fill in ourselves.
"""
function _parse_trace_function_options(opts)
    parsed = Dict{Symbol,Any}(
        :meta => missing,
        :name => missing,
        :cat => TRACE_CATEGORY,
        :args => nothing,
        :to => missing,
        :timer_name => missing,
    )

    for opt in opts
        if !(opt isa Expr && opt.head == :(=) && opt.args[1] ∈ keys(parsed))
            throw(ArgumentError("@trace_function options must assign one of $(join(sort(collect(keys(parsed))), ", ")), as in `name=\"bb2.foo\"`"))
        end
        parsed[opt.args[1]] = opt.args[2]
    end

    return parsed
end

"""
    _wrap_trace_function_def(def, options)

Rebuild the function definition `def` with its body wrapped in a
`with_trace()` zone, as configured by `options`.
"""
function _wrap_trace_function_def(def::Expr, options)
    if def.head ∉ (:function, :(=))
        throw(ArgumentError("@trace_function must wrap a function definition"))
    end
    sig, body = def.args

    meta = coalesce(options[:meta], _default_trace_meta(sig))
    if meta === nothing || meta === :nothing
        throw(ArgumentError("@trace_function needs something to trace against; pass `meta=`, or take an argument named $(join(TRACE_META_ARGNAMES, " or "))"))
    end

    # Only pass along the options we were actually given, so that `with_trace()`
    # gets to fill in its own defaults for the rest.
    kwargs = Any[
        Expr(:kw, :cat, options[:cat]),
        Expr(:kw, :args, options[:args]),
    ]
    for key in (:to, :timer_name)
        if options[key] !== missing
            push!(kwargs, Expr(:kw, key, options[key]))
        end
    end

    name = coalesce(options[:name], string(TRACE_NAME_PREFIX, _trace_function_name(sig)))
    body_ref = gensym(:trace_body)
    return Expr(def.head, sig, quote
        local $body_ref = () -> begin
            $body
        end
        BinaryBuilder2.with_trace($body_ref, $meta, $name; $(kwargs...))
    end)
end

"""
    @trace_function args=(src_name=config.src_name,) function prepare(config)
        ...
    end

    @trace_function meta=config.build name="bb2.audit" function audit!(config)
        ...
    end

Run a function's body inside a `with_trace()` zone, so that it is both traced
and timed (see `with_trace()` for what that entails).  By default the zone name
is the function name prefixed with `$(TRACE_NAME_PREFIX)` (so `prepare()` traces
as `$(TRACE_NAME_PREFIX)prepare`), and the zone is opened on the first argument
named $(join(string.("`", TRACE_META_ARGNAMES, "`"), " or ")); a function with
no such argument must name what to trace against with `meta=`.  The `name=`,
`cat=`, `args=`, `to=` and `timer_name=` options are all passed through to
`with_trace()`.
"""
macro trace_function(args...)
    if isempty(args) || !(args[end] isa Expr)
        throw(ArgumentError("@trace_function must wrap a function definition"))
    end
    options = _parse_trace_function_options(args[1:(end - 1)])
    return esc(_wrap_trace_function_def(args[end], options))
end

AbstractBuildMeta(meta::AbstractBuildMeta) = meta

trace_enabled(::AbstractBuildMeta) = false

function trace_begin(::AbstractBuildMeta, ::AbstractString; kwargs...)
    return nothing
end

function trace_end(::AbstractBuildMeta, ::AbstractString; kwargs...)
    return nothing
end

function trace_event(::AbstractBuildMeta, ::AbstractString; kwargs...)
    return nothing
end

"""
    timer_output(x)

Return the `TimerOutput` that trace zones opened on `x` should be timed into, or
`nothing` if `x` has no timer associated with it.  Objects that carry a timer
(such as `BuildConfig` and `ExtractConfig`) add methods to this.
"""
timer_output(::Any) = nothing

"""
    trace_timer_name(name)

Return the default `TimerOutput` label used for a trace zone named `name`; we
strip the `bb2.` prefix that all our trace zone names share, as the timer tree
is already scoped to a single build.
"""
trace_timer_name(name::AbstractString) = String(chopprefix(name, TRACE_NAME_PREFIX))

"""
    with_trace(f::Function, x, name::AbstractString; cat, args, to, timer_name)

Run `f()` within a trace zone named `name`, and simultaneously within a
`@timeit` zone in the `TimerOutput` associated with `x` (see `timer_output()`).
`x` is anything that can name a build meta (an `AbstractBuildMeta` itself, a
`BuildConfig`, an `ExtractConfig`, etc...); the timer can be overridden with the
`to` kwarg, and its label with `timer_name`.  Passing `to=nothing` or
`timer_name=nothing` disables the timing half of the zone, while a `meta` that
has tracing disabled skips the tracing half.
"""
function with_trace(f::Function, x, name::AbstractString;
                    cat::AbstractString = TRACE_CATEGORY,
                    args = nothing,
                    to::Union{Nothing,TimerOutput} = timer_output(x),
                    timer_name::Union{Nothing,AbstractString} = trace_timer_name(name))
    meta = AbstractBuildMeta(x)

    # Run `f()` within its `@timeit` zone (if we have a timer to record into) so
    # that every trace zone shows up in the timer tree as well.
    timed_f() = to === nothing || timer_name === nothing ? f() : @timeit to timer_name f()

    if !trace_enabled(meta)
        return timed_f()
    end
    trace_begin(meta, name; cat, args)
    try
        return timed_f()
    finally
        trace_end(meta, name; cat, args)
    end
end

start_trace_session!(::AbstractBuildMeta) = nothing
finish_trace_session!(::AbstractBuildMeta; status::AbstractString = "success") = nothing
