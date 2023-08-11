using JLLGenerator: default_rtld_flags

"""
    LibraryProduct(paths::Vector{String}, varname::Symbol;
                   deps = Dict{PackageSpec, Vector{LibraryProduct}}(),
                   dlopen_flags=Symbol[])

Declares a `LibraryProduct` that points to a library located within the prefix.
`paths` contain valid paths for this library, `varname` is the name of the
variable in the JLL package that can be used to call into the library.  The
flags to pass to `dlopen` can be specified as a vector of `Symbols` with the
`dlopen_flags` keyword argument.

Each element of `path` takes the form `[dirname/]basename[.versioned-ext]`
where `dirname` and `versioned-ext` are optional and can be omitted.
Accordingly, the following three paths will all find the same library:

* `lib/libnettle.so.6`
* `lib/libnettle`
* `libnettle.so.6`
* `libnettle`

On non-Windows targets, omitting `dirname` will automatically prepend `lib`,
while on Windows targets `bin` will be prepended.  Omitting the versioned
extension will allow any version of the library to be used (usually not a
problem as there's typically only one version of a library at a time).
"""
struct LibraryProduct <: AbstractProduct
    paths::Vector{String}
    varname::Symbol
    dlopen_flags::typeof(default_rtld_flags)

    function LibraryProduct(paths::Vector{<:AbstractString},
                            varname::Symbol;
                            dlopen_flags::Union{Vector{Symbol},typeof(default_rtld_flags)} = default_rtld_flags)
        if isa(dlopen_flags, Vector{Symbol})
            dlopen_flags = symbols_to_flags(dlopen_flags)
        end
        if isdefined(Base, varname)
            error("`$(varname)` is already defined in Base")
        end
        return new(string.(paths), varname, dlopen_flags)
    end
end
LibraryProduct(path::AbstractString, args...; kwargs...) = LibraryProduct([path], args...; kwargs...)

function dlopen_flags_str(p::LibraryProduct)
    return join(" | ", string.(flags_to_symbols(p.dlopen_flags)))
end

"""
    valid_dl_path(path, platform)

Returns `true` if `path` represents a valid dynamic library path (e.g. `libfoo.so.X` on
Linux/FreeBSD, `libfoo-X.dll` on Windows, `libfoo.X.dylib` on macOS) as specified by
`Base.BinaryPlatforms.parse_dl_name_version()`.  Returns `false` otherwise
"""
function valid_dl_path(path, platform)
    try
        parse_dl_name_version(path, os(platform))
        return true
    catch
        return false
    end
end

function default_product_dir(::Type{LibraryProduct}, platform::AbstractPlatform)
    if Sys.iswindows(platform)
        return "bin"
    else
        return "lib"
    end
end

"""
    locate(lp::LibraryProduct, prefix::Prefix;
           env::Dict{String,String},
           verbose::Bool = false)

If the given library exists (under any reasonable name) and is `dlopen()`able,
(assuming it was built for the current platform) return its location.  Note
that the `dlopen()` test is only run if the current platform matches the given
`platform` keyword argument, as cross-compiled libraries cannot be `dlopen()`ed
on foreign platforms.
"""
function locate(lp::LibraryProduct, prefix::String;
                env::Dict{String,String} = Dict{String,String}())
    platform = parse(Platform, env_checked_get(env, "bb_full_target"))
    for path in lp.paths
        path = path_prefix_transformation(LibraryProduct, path, prefix, env)
        libname = basename(path)

        # Skip non-existant directories
        path_dir = dirname(path)
        if !isdir(path_dir)
            continue
        end

        for f in readdir(path_dir)
            # Skip any names that aren't a valid dynamic library for the given
            # platform (note this will cause problems if something compiles a `.so`
            # on OSX, for instance)
            if !valid_dl_path(f, platform)
                continue
            end

            parsed_libname, parsed_version = parse_dl_name_version(f, os(platform))
            if parsed_libname == libname
                return prefix_remove(path, prefix)
            end
        end
    end
    return nothing
end
