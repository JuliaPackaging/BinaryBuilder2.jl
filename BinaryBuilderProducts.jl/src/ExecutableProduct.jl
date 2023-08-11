using Base.BinaryPlatforms

"""
    ExecutableProduct(names::Vector{String}, varname::Symbol; dir_path = nothing)

On all platforms, an `ExecutableProduct` checks for existence of the file.  On
Windows platforms, it will check that the file ends with ".exe", (adding it on
automatically to the search paths, if it is not already present).
"""
struct ExecutableProduct <: AbstractProduct
    paths::Vector{String}
    varname::Symbol

    function ExecutableProduct(paths, varname)
        varname = Symbol(varname)
        check_varname(varname)
        return new(string.(paths), varname)
    end
end
ExecutableProduct(path::AbstractString, varname) = ExecutableProduct([path], varname)

function default_product_dir(::Type{ExecutableProduct}, platform::AbstractPlatform)
    return "bin"
end

"""
    locate(ep::ExecutableProduct, prefix::String;
           verbose::Bool = false)

If the given executable file exists and is executable, return its path.

On all platforms, an [`ExecutableProduct`](@ref) checks for existence of the
file.  On non-Windows platforms, it will check for the executable bit being set.
On Windows platforms, it will check that the file ends with ".exe", (adding it
on automatically, if it is not already present).
"""
function locate(ep::ExecutableProduct, prefix::String;
                env::Dict{String,String} = Dict{String,String}())
    platform = parse(Platform, env_checked_get(env, "bb_full_target"))
    for path in ep.paths
        path = path_prefix_transformation(ExecutableProduct, path, prefix, env)

        # On windows, we always slap an .exe onto the end if it doesn't already
        # exist, as Windows won't execute files that don't have a .exe at the end.
        if Sys.iswindows(platform) && !endswith(path, ".exe")
            path = string(path, ".exe")
        end

        if isfile(path)
            # If the file is not executable, fail out
            if !Sys.isexecutable(path)
                continue
            end
            return prefix_remove(path, prefix)
        end
    end
    return nothing
end
