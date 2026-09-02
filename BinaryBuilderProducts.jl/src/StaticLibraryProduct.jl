"""
    StaticLibraryProduct(paths::Vector{String};
                         varname=nothing,
                         deps=:inherit,
                         system_deps=:inherit)

Declares a `StaticLibraryProduct` that points to a static archive (e.g. `libfoo.a`)
located within the prefix.  Usually it is subordinate to a [`LibraryProduct`](@ref),
passed as its `static` keyword argument: the shared library defines the product's
identity, so no `varname` is given.  A standalone archive, for a library that only
ever ships as one, carries its own `varname`.

Each element of `paths` takes the form `[dirname/]basename[.a]`, where `dirname`
and the extension are optional.  Omitting `dirname` prepends `lib` on every
platform, since archives live in `lib` even on Windows.

`deps` (edges onto other libraries, as `"Pkg_jll.varname"` or a bare `"varname"`)
and `system_deps` (linker library names such as `"m"`) default to `:inherit`, the
lists the auditor derives from the dynamic sibling.  A vector replaces them; a
vector containing `:inherit` augments them.  Standalone archives must give both
explicitly.
"""
struct StaticLibraryProduct <: AbstractProduct
    paths::Vector{String}
    # `nothing` when subordinate to a `LibraryProduct`, which supplies the identity.
    varname::Union{Nothing,Symbol}
    deps::Union{Symbol,Vector{Union{Symbol,String}}}
    system_deps::Union{Symbol,Vector{Union{Symbol,String}}}

    function StaticLibraryProduct(paths::Vector{<:AbstractString};
                                  varname::Union{Nothing,Symbol,AbstractString} = nothing,
                                  deps = :inherit,
                                  system_deps = :inherit)
        if varname !== nothing
            varname = Symbol(varname)
            check_varname(varname)
        end
        deps = canonicalize_static_dep_spec(deps, "deps", varname)
        system_deps = canonicalize_static_dep_spec(system_deps, "system_deps", varname)
        return new(string.(paths), varname, deps, system_deps)
    end
end
StaticLibraryProduct(path::AbstractString; kwargs...) = StaticLibraryProduct([path]; kwargs...)

"""
    canonicalize_static_dep_spec(spec, kwarg_name, varname)

Normalize a `deps`/`system_deps` declaration to `:inherit` or a vector containing
at most one `:inherit` sentinel, rejecting inheritance on standalone products.
"""
function canonicalize_static_dep_spec(spec, kwarg_name::String, varname::Union{Nothing,Symbol})
    standalone = varname !== nothing
    if isa(spec, Symbol)
        if spec != :inherit
            throw(ArgumentError("Invalid `$(kwarg_name)` sentinel ':$(spec)', only ':inherit' is understood"))
        end
        if standalone
            throw(ArgumentError("Standalone StaticLibraryProduct '$(varname)' cannot use `$(kwarg_name) = :inherit`; there is no dynamic sibling to inherit from, declare the list explicitly"))
        end
        return :inherit
    end
    if !isa(spec, AbstractVector)
        throw(ArgumentError("Invalid `$(kwarg_name)` value $(repr(spec)); expected `:inherit` or a vector"))
    end

    out = Vector{Union{Symbol,String}}()
    num_sentinels = 0
    for entry in spec
        if isa(entry, Symbol)
            if entry != :inherit
                throw(ArgumentError("Invalid `$(kwarg_name)` sentinel ':$(entry)', only ':inherit' is understood"))
            end
            num_sentinels += 1
            push!(out, :inherit)
        elseif isa(entry, AbstractString)
            push!(out, String(entry))
        else
            throw(ArgumentError("Invalid `$(kwarg_name)` entry $(repr(entry)); expected a string or the `:inherit` sentinel"))
        end
    end
    if num_sentinels > 1
        throw(ArgumentError("`$(kwarg_name)` contains the `:inherit` sentinel $(num_sentinels) times, it may appear at most once"))
    end
    if standalone && num_sentinels > 0
        throw(ArgumentError("Standalone StaticLibraryProduct '$(varname)' cannot use the `:inherit` sentinel in `$(kwarg_name)`; there is no dynamic sibling to inherit from"))
    end
    return out
end

"""
    inherits_deps(spec)

Whether a canonicalized declaration folds in the inherited set.
"""
inherits_deps(spec::Symbol) = spec === :inherit
inherits_deps(spec::Vector{Union{Symbol,String}}) = any(isa(e, Symbol) for e in spec)

"""
    declared_deps(spec)

The explicitly declared entries of a canonicalized declaration.
"""
declared_deps(::Symbol) = String[]
declared_deps(spec::Vector{Union{Symbol,String}}) = String[e for e in spec if isa(e, String)]

"""
    resolve_deps(spec, inherited::Vector{String})

Apply a declaration to the inherited set, returning `(resolved, omitted)`, where
`omitted` lists inherited entries a replacing declaration dropped.
"""
function resolve_deps(spec, inherited::Vector{String})
    declared = declared_deps(spec)
    if inherits_deps(spec)
        return (unique(vcat(inherited, declared)), String[])
    end
    return (unique(declared), String[d for d in inherited if d ∉ declared])
end

"""
    static_lib_ext(platform)

The file extension of static archives on `platform`; `.a` everywhere we build.
"""
static_lib_ext(::AbstractPlatform) = "a"

# Static archives live in `lib` on every platform, unlike dynamic libraries which
# live in `bin` on Windows.
default_product_dir(::Type{StaticLibraryProduct}, platform::AbstractPlatform) = "lib"

"""
    locate(slp::StaticLibraryProduct, prefix::String; env, platform)

If the given archive exists, return its location relative to `prefix`.
"""
function locate(slp::StaticLibraryProduct, prefix::String;
                env::Dict{String,String} = Dict{String,String}(),
                platform::AbstractPlatform = parse(Platform, env_checked_get(env, "bb_full_target")))
    @debug("Locating StaticLibraryProduct", slp)
    ext = static_lib_ext(platform)
    for path in slp.paths
        path = path_prefix_transformation(StaticLibraryProduct, path, prefix, platform, env)

        # Unlike dynamic libraries, static archives are not versioned, so the only
        # fuzziness we allow is the (single, platform-defined) file extension.
        candidates = [path]
        if !endswith(path, ".$(ext)")
            push!(candidates, string(path, ".", ext))
        end

        for candidate in candidates
            rel_path = prefix_remove(candidate, prefix)
            @debug("Trying", rel_path)
            if isfile(candidate)
                @debug("Found", rel_path)
                return rel_path
            end
        end
    end
    return nothing
end
