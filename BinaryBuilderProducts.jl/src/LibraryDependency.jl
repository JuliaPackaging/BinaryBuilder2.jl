"""
    LibraryDependency(pkg, varname)
    LibraryDependency(varname)

A recipe's reference to a library product: `pkg` is the JLL it belongs to (as a
module name such as `:Zlib_jll`), or is omitted for a library of the JLL being
built; the JLL being built is never named.  It is what a
[`StaticLibraryProduct`](@ref) declares in its `deps`; the
pipeline resolves it, against the build's declared dependencies and the JLL the
extraction is packaged into, before anything is recorded.
"""
struct LibraryDependency
    pkg::Union{Nothing,Symbol}
    varname::Symbol

    LibraryDependency(pkg::Union{Nothing,Symbol,AbstractString}, varname::Union{Symbol,AbstractString}) =
        new(pkg === nothing ? nothing : Symbol(pkg), Symbol(varname))
end
LibraryDependency(varname::Union{Symbol,AbstractString}) = LibraryDependency(nothing, varname)
