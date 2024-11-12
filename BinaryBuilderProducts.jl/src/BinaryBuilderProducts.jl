module BinaryBuilderProducts
using Base.BinaryPlatforms
using KeywordArgumentExtraction

export ExecutableProduct, FileProduct, FrameworkProduct, LibraryProduct, AbstractProduct, locate

"""
An `AbstractProduct` is an expected result after building of a package.

Examples of `Product`s include [`LibraryProduct`](@ref), [`FrameworkProduct`](@ref),
[`ExecutableProduct`](@ref) and [`FileProduct`](@ref). All `AbstractProduct` types must
define the following minimum set of functionality:

* [`locate(product::AbstractProduct, prefix::String; env::Dict)`](@ref)
  Locate a product relative to the given `prefix`, returning its location as a string.
  Templating of environment variables is performed with the given `env` dictionary.
  Returns `nothing` if location fails.

* [`variable_name(::AbstractProduct)`](@ref):
  Returns the given variable name for a product as a `Symbol`.
"""
abstract type AbstractProduct end

# Simple layouts are the best
variable_name(p::AbstractProduct)::Symbol = p.variable_name

# Prevent our users from accidentally making their lives difficult:
function check_varname(varname::Symbol)
    if isdefined(Base, varname)
        throw(ArgumentError("'$(varname)' is already defined in Base, refusing to create a product with that name!"))
    end
end

# Get a value from `env`, throwing an error if it does not exist
function env_checked_get(env, key)
    if !haskey(env, key)
        throw(ArgumentError("env must contain mapping for \${$(key)}"))
    end
    return env[key]
end

# Remove `prefix` from `path`, if `path` startswith `prefix`.
function prefix_remove(path, prefix)
    if startswith(path, prefix)
        path = lstrip(path[length(prefix)+1:end], ('/', '\\'))
    end
    return path
end

function add_default_product_dir(T, path, platform)
    if Base.applicable(default_product_dir, T, platform) && dirname(path) == ""
        return joinpath(default_product_dir(T, platform), path)
    else
        return path
    end
end

"""
    path_prefix_transformation(::Type{<:AbstractProduct}, path, prefix, env)

Performs ths transformation to alter a `path` to be relative to `prefix`.  Takes into
account templating via `env`, as well as applying `add_default_product_dir()` to products
that can have their leading directory dropped (e.g. `ExecutableProduct` and
`LibraryProduct`).
"""
function path_prefix_transformation(T::Type{<:AbstractProduct}, path, prefix, env)
    # Finally, put this relative to `prefix`
    return joinpath(
        prefix,
        # If we were given `"foo"` instead of `"${bindir}/foo`, automatically
        # add `bin/` if we're an ExecutableProduct, `bin/lib` if we're a `LibraryProduct`, etc...
        add_default_product_dir(
            T,
            # Remove `/workspace/destdir/bin` from the beginning
            prefix_remove(
                # Template `${bindir}/foo` to e.g. `/workspace/destdir/bin/foo`
                template(path, env),
                env_checked_get(env, "prefix"),
            ),
            parse(AbstractPlatform, env_checked_get(env, "bb_full_target")),
        )
    )
end

# env-block templating
function template(s, env)
    # If there are 
    for (var, val) in env
        s = replace(s, "\${$(var)}" => val)
    end
    return s
end

include("FileProduct.jl")
include("ExecutableProduct.jl")
include("LibraryProduct.jl")
include("FrameworkProduct.jl")
include("JLLGeneratorExt.jl")

end # module BinaryBuilderProducts
