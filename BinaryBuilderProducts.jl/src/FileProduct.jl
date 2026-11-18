"""
    FileProduct(paths::Vector{String}, varname::Symbol; aliases = Symbol[])

Declares a [`FileProduct`](@ref) that points to a file located relative to the root of
a `Prefix`, must simply exist to be satisfied.

If the file is also installed under other names (e.g. a symlink to it), list those
names in `aliases`: the JLL exports each of them as the very same path as `varname`.
Declaring a separate `FileProduct` that resolves to the same path instead is an error.
"""
struct FileProduct <: AbstractProduct
    paths::Vector{String}
    varname::Symbol
    aliases::Vector{Symbol}

    function FileProduct(paths, varname; aliases::Vector{Symbol} = Symbol[])
        varname = Symbol(varname)
        check_varname(varname)
        return new(string.(paths), varname, check_aliases(varname, aliases))
    end
end

FileProduct(path::AbstractString, varname::Symbol; kwargs...) = FileProduct([path], varname; kwargs...)

"""
    locate(fp::FileProduct, prefix::String; env, verbose = false)

If the file product exists at any of its search paths, return that path.
"""
function locate(fp::FileProduct, prefix::String;
                env::Dict{String,String} = Dict{String,String}(),
                platform::AbstractPlatform = parse(Platform, env_checked_get(env, "bb_full_target")))
    @debug("Locating FileProduct", fp)
    for path in fp.paths
        path = path_prefix_transformation(FileProduct, path, prefix, platform, env)
        rel_path = prefix_remove(path, prefix)
        @debug("Trying", rel_path)
        if ispath(path)
            @debug("Found", rel_path)
            return rel_path
        end
    end
    return nothing
end
