# musl's dynamic loader doesn't let a library find its dependencies among the libraries
# that were loaded by path, as JLLs load all of them
# (https://github.com/JuliaLang/julia/issues/40556).  It matches a `DT_NEEDED` name only
# against libraries that were themselves loaded by name.  Otherwise it searches
# `LD_LIBRARY_PATH` (read once at startup), the RUNPATHs of the library and of those that
# needed it, and the system directories, none of which contains another JLL's artifact.
#
# The search does reuse a loaded library when it finds the same file (by device and inode),
# and `$ORIGIN` expands to the directory a library was opened from, without resolving
# symlinks.  So on musl each library is opened through a directory of symlinks to the files
# in its own directory and to every library loaded so far, under each of the names that
# resolve to it.  `$ORIGIN`, which BinaryBuilder puts in the RUNPATH of libraries with
# dependencies, then finds them.  Since the loaded libraries are taken from `dllist()`,
# this works across JLLs from JLLWrappers and LazyJLLWrappers.

const is_musl = Sys.islinux() && occursin("musl", Sys.MACHINE)

const musl_lock = ReentrantLock()
# The directory that holds one symlink directory per library directory
const musl_root = Ref("")
# The symlink directory for each library directory
const musl_linkdirs = Dict{String,String}()
# The loaded libraries already linked into each symlink directory
const musl_linked = Dict{String,Set{String}}()
# For each directory of a loaded library: the names of its files, by the file they resolve to
const musl_aliases = Dict{String,Dict{String,Vector{String}}}()

function musl_symlink(linkdir::String, name::String, target::String)
    link = joinpath(linkdir, name)
    islink(link) || ispath(link) || symlink(target, link)
end

# The names in its directory that resolve to the library file `path`, e.g. `libz.so`,
# `libz.so.1` and `libz.so.1.3.1`, so that the library is found by its SONAME
function musl_names(path::String)
    file = realpath(path)
    dir = dirname(file)
    aliases = get!(musl_aliases, dir) do
        aliases = Dict{String,Vector{String}}()
        for f in readdir(dir)
            target = try
                realpath(joinpath(dir, f))
            catch
                continue
            end
            push!(get!(Vector{String}, aliases, target), f)
        end
        aliases
    end
    return dir, get(aliases, file, [basename(file)])
end

function musl_dlopen_path(path::String)
    libdir = dirname(path)
    return lock(musl_lock) do
        linkdir = get!(musl_linkdirs, libdir) do
            isempty(musl_root[]) && (musl_root[] = mktempdir(; prefix="jll_musl_"))
            linkdir = joinpath(musl_root[], string(length(musl_linkdirs) + 1))
            mkdir(linkdir)
            # A directory's own files take precedence
            for f in readdir(libdir)
                musl_symlink(linkdir, f, joinpath(libdir, f))
            end
            linkdir
        end
        # Then every library loaded so far, in load order, as with glibc's matching by
        # SONAME.  This includes those loaded through other symlink directories.
        linked = get!(Set{String}, musl_linked, linkdir)
        for lib in Base.Libc.Libdl.dllist()
            isabspath(lib) && !(lib in linked) || continue
            push!(linked, lib)
            dir, names = try
                musl_names(lib)
            catch
                continue
            end
            for name in names
                musl_symlink(linkdir, name, joinpath(dir, name))
            end
        end
        joinpath(linkdir, basename(path))
    end
end

"""
    dlopen_path(path)

The path through which to `dlopen` the library at `path`: `path` itself, except on musl,
where it is a symlink that lets the library find the libraries of other JLLs that it
depends on.  Falls back to `path` if the symlink can't be created.
"""
function dlopen_path(path::AbstractString)
    path = String(path)
    if is_musl
        try
            return musl_dlopen_path(path)
        catch e
            @debug "Cannot create symlinks to load $(path) on musl" exception=e
        end
    end
    return path
end

"""
    MuslLibraryPath(path)

A library path for a `LazyLibrary` that converts via `string` to [`dlopen_path`](@ref) of
`path`, which may itself be a `LazyLibraryPath`.
"""
struct MuslLibraryPath{T}
    path::T
end
Base.string(p::MuslLibraryPath) = dlopen_path(string(p.path))
Base.print(io::IO, p::MuslLibraryPath) = print(io, string(p.path))
Base.show(io::IO, p::MuslLibraryPath) = show(io, p.path)

# The path to give a `LazyLibrary`
lazy_library_path(path) = is_musl ? MuslLibraryPath(path) : path
