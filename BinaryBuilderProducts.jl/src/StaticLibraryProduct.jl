"""
    StaticLibraryProduct(paths::Vector{String};
                         varname=nothing,
                         deps=:inherit,
                         system_deps=:inherit)

Declares a `StaticLibraryProduct` that points to a static archive (e.g. `libfoo.a`)
located within the prefix.  Usually it is subordinate to a [`LibraryProduct`](@ref),
and is provided via the `static` keyword argument.

Each element of `paths` takes the form `[dirname/]basename[.ext]`, where `dirname`
and the extension are optional.  Omitting `dirname` prepends `lib` on every
platform, since archives live in `lib` even on Windows.  The extension is `.a`, or on
Windows also `.lib` (as MSVC-style toolchains name their archives).

If left to the default value of `:inherit`, `deps` and `system_deps` are taken from
the containing LibraryProduct (the dynamic variant of this library). Standalone
static archives must provide these explicitly: `deps` as a vector of
[`LibraryDependency`](@ref), `system_deps` as a vector of linker library names.

An archive subordinate to a `LibraryProduct` takes that product's `varname` when
the `LibraryProduct` is constructed, so every archive the pipeline sees is named;
`varname` is `nothing` only on an archive not yet attached to its `LibraryProduct`.
"""
struct StaticLibraryProduct <: AbstractProduct
    paths::Vector{String}
    varname::Union{Nothing,Symbol}

    # If `nothing`, these are each inherited from the parent `LibraryProduct`.
    deps::Union{Nothing,Vector{LibraryDependency}}
    system_deps::Union{Nothing,Vector{String}}

    function StaticLibraryProduct(paths::Vector{<:AbstractString};
                                  varname::Union{Nothing,Symbol,AbstractString} = nothing,
                                  deps = :inherit,
                                  system_deps = :inherit)
        if varname !== nothing
            varname = Symbol(varname)
            check_varname(varname)
        end
        function normalize_deps(declared, name, T, what)
            if declared isa AbstractVector && all(e -> e isa T, declared)
                T[e for e in declared]
            elseif declared === :inherit
                nothing
            else
                throw(ArgumentError("Invalid `$(name)` value $(repr(declared)); expected `:inherit` or a vector of $(what)"))
            end
        end
        deps = normalize_deps(deps, "deps", LibraryDependency, "`LibraryDependency`")
        system_deps = normalize_deps(system_deps, "system_deps", String, "linker library names")
        return new(string.(paths), varname, deps, system_deps)
    end

    # The same archive, named: how a `LibraryProduct` claims its subordinate archive.
    StaticLibraryProduct(product::StaticLibraryProduct, varname::Symbol) =
        new(product.paths, varname, product.deps, product.system_deps)
end
StaticLibraryProduct(path::AbstractString; kwargs...) = StaticLibraryProduct([path]; kwargs...)

"""
    generate_default_static_lib_paths(paths::Vector{String})

Derive the paths of a library's static archive from the `paths` of its dynamic
variant, as used by `LibraryProduct(...; static=:auto)`.  Any versioned dynamic
library extension (`.so.6`, `.6.dylib`, `-6.dll`, ...) is removed from each
basename, and a leading `\${libdir}` or `\${bindir}` is dropped, since archives
live in `lib` on every platform (whereas `\${libdir}` is `bin` on Windows).  Any
other directory is kept as declared.
"""
function generate_default_static_lib_paths(paths::Vector{<:AbstractString})
    static_paths = String[]
    for path in paths
        dir, name = dirname(path), basename(path)
        if dir in ("\${libdir}", "\${bindir}")
            dir = ""
        end
        # The platform is not known yet, so iterate them all.
        for os in ("linux", "macos", "windows", "freebsd")
            try
                name = first(parse_dl_name_version(name, os))
                break
            catch e
                isa(e, ArgumentError) || rethrow()
            end
        end
        static_path = isempty(dir) ? name : joinpath(dir, name)
        static_path in static_paths || push!(static_paths, static_path)
    end
    return static_paths
end

static_lib_exts(platform::AbstractPlatform) = Sys.iswindows(platform) ? String["a", "lib"] : String["a"]

# Unlike dynamic libraries, static archives live in `lib` on every platform (even Windows)
default_product_dir(::Type{StaticLibraryProduct}, platform::AbstractPlatform) = "lib"

"""
    locate(product::StaticLibraryProduct, prefix::String; env, platform)

If the given archive exists, return its location relative to `prefix`.
"""
function locate(product::StaticLibraryProduct, prefix::String;
                env::Dict{String,String} = Dict{String,String}(),
                platform::AbstractPlatform = parse(Platform, env_checked_get(env, "bb_full_target")))
    @debug("Locating StaticLibraryProduct", product)
    exts = static_lib_exts(platform)
    for path in product.paths
        path = path_prefix_transformation(StaticLibraryProduct, path, prefix, platform, env)

        # Static libraries are not typically versioned, so just look for the direct `.a` / `.lib`
        # extensions here.
        candidates = [path]
        if !any(ext -> endswith(path, ".$(ext)"), exts)
            append!(candidates, string(path, ".", ext) for ext in exts)
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
