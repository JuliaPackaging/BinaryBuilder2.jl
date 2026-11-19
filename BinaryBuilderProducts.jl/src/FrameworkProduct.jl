"""
    FrameworkProduct(framework_names::Vector{String}, varname::Symbol; kwargs...)

Declares a library that is shipped as a macOS framework bundle.  This is a
[`LibraryProduct`](@ref) whose paths are the framework bundles
`[dirname/]name.framework`, so `FrameworkProduct("QtCore", :libqtcore)` is the
same as `LibraryProduct("QtCore.framework", :libqtcore)`.  The keyword arguments
are those of `LibraryProduct`.

As the product consists only of framework paths, it is found only on macOS.  To
describe a library that is a framework on macOS and an ordinary shared library
elsewhere, list both kinds of path in a `LibraryProduct`, e.g.
`LibraryProduct(["QtCore.framework", "libQt5Core"], :libqt5core)`.
"""
function FrameworkProduct(framework_names::Vector{<:AbstractString}, varname::Symbol; kwargs...)
    if isempty(framework_names)
        throw(ArgumentError("FrameworkProduct '$(varname)' must name at least one framework"))
    end
    paths = [string(strip_framework_ext(name), ".framework") for name in framework_names]
    return LibraryProduct(paths, varname; kwargs...)
end
FrameworkProduct(name::AbstractString, args...; kwargs...) = FrameworkProduct([name], args...; kwargs...)

is_framework_path(path::AbstractString) = endswith(path, ".framework")
strip_framework_ext(name::AbstractString) = is_framework_path(name) ? name[1:end-length(".framework")] : name

"""
    framework_binary(bundle_dir::String)

Returns the path of the binary inside the framework bundle `bundle_dir`
(`Name.framework/Versions/Current/Name`, or `Name.framework/Name` for a bundle
without versions) with all symlinks resolved, or `nothing` if there is none.
"""
function framework_binary(bundle_dir::AbstractString)
    name = strip_framework_ext(basename(bundle_dir))
    for candidate in (joinpath(bundle_dir, "Versions", "Current", name), joinpath(bundle_dir, name))
        if isfile(candidate)
            return realpath(candidate)
        end
    end
    return nothing
end

"""
    locate_framework(bundle_dir::String, prefix::String)

Returns the prefix-relative path of the binary inside the framework bundle
`bundle_dir`, with symlinks such as `Versions/Current` resolved (e.g.
`lib/QtCore.framework/Versions/5/QtCore`), or `nothing` if the bundle does not
exist or its binary is not within `prefix`.
"""
function locate_framework(bundle_dir::AbstractString, prefix::AbstractString)
    if !isdir(bundle_dir)
        @debug("Skipping non-existant framework", bundle=prefix_remove(bundle_dir, prefix))
        return nothing
    end
    real_prefix = realpath(prefix)
    binary = framework_binary(bundle_dir)
    if binary === nothing || !startswith(binary, real_prefix * "/")
        @debug("Framework has no binary within the prefix", bundle=prefix_remove(bundle_dir, prefix))
        return nothing
    end
    rel_path = prefix_remove(binary, real_prefix)
    @debug("Found", rel_path)
    return rel_path
end
