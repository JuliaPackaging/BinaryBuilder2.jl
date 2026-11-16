using ObjectFile, BinaryBuilderProducts
using BinaryBuilderToolchains: path_appending_merge
using Base.Filesystem: StatStruct

export ScanResult, scan_files

struct ScanResult
    prefix::String
    prefix_alias::String
    platform::AbstractPlatform

    # Toolchain that contains things like `patchelf`, `install_name_tool`, etc...
    toolchain::AuditorToolchain
    toolchain_prefix::String

    # List of all files contained within the prefix
    files::Dict{String,StatStruct}

    # List of all binary objects contained within the prefix
    # This includes executables, shared libraries, etc...
    binary_objects::Dict{String,ObjectHandle}

    # This maps `SONAME` (e.g. `libfoo.so.1`) to resolved `rel_path`.
    soname_locator::Dict{String,String}
    missing_sonames::Vector{String}

    # This maps `basename(rel_path)` -> `SONAME`
    # It gives us a quick way to find libraries by "incorrect" `SONAME`,
    # and point to the correct `SONAME`.
    soname_forwards::Dict{String,String}

    # List of all static archives contained within the prefix (by `rel_path`)
    # Note that on Windows this includes import libraries, which are archives too.
    static_libraries::Set{String}

    # This maps `rel_path` to a library product `LibraryProduct`.  Each file is named by
    # at most one product; further names for it are that product's `aliases`.  (The same
    # holds for files, which `scan_files()` checks but does not record.)
    library_products::Dict{String,LibraryProduct}

    # This maps the `rel_path` of a static archive to its `StaticLibraryProduct`.
    static_library_products::Dict{String,StaticLibraryProduct}

    # For easy lookup of things by symlink alias; this maps the `rel_path` of every
    # symlink (to a file or a directory) to the `rel_path` it points to.
    symlinks::Dict{String,String}

    # List of all import libraries (windows-only)
    #implib_files::Vector{String}
end

function get_object_handle(path::String, platform::AbstractPlatform)
    try
        ohs = readmeta(open(path, "r"))
        for oh in ohs
            if is_for_platform(oh, platform)
                return oh
            end
        end
        return nothing
    catch e
        if isa(e, ObjectFile.MagicMismatch)
            return nothing
        end
        rethrow(e)
    end
end

"""
    is_static_archive(path::String)

Returns `true` if the file at `path` is a static archive (an `ar` archive),
judged by its contents rather than its name.  GNU thin archives are not counted,
as they only refer to their members by path, and so cannot be shipped.
"""
function is_static_archive(path::String)
    open(path) do io
        try
            return !isthin(readmeta(io, ArchiveHandle))
        catch e
            # Not an archive at all (`MagicMismatch`, `EOFError`), or a malformed one
            if isa(e, MagicMismatch) || isa(e, EOFError) || isa(e, ArgumentError)
                return false
            end
            rethrow(e)
        end
    end
end

function scan_files(prefix::String, platform::AbstractPlatform,
                    products::Vector{<:AbstractProduct} = AbstractProduct[],
                    env::Dict{String,String} = Dict{String,String}(
                        "prefix" => prefix,
                        "bb_full_target" => triplet(platform),
                    );
                    prefix_alias::String = prefix)
    prefix = safe_realpath(prefix)
    library_products = LibraryProduct[p for p in products if isa(p, LibraryProduct)]

    # Do a scan over the prefix, find all symlinks, binary objects, etc....
    all_files = Dict{String,StatStruct}()
    binary_objects = Dict{String,ObjectHandle}()
    static_libraries = Set{String}()
    symlinks = Dict{String,String}()
    function record_symlink!(f_path, f_key)
        link_target = readlink(f_path)
        if startswith(link_target, prefix_alias)
            symlinks[f_key] = relpath(link_target, prefix_alias)
        elseif !isabspath(link_target)
            symlinks[f_key] = normpath(joinpath(dirname(f_key), link_target))
        end
    end
    for (root, dirs, files) in walkdir(prefix)
        # `walkdir()` lists symlinks to directories (such as a framework's
        # `Versions/Current`) in `dirs`, without descending into them.
        for d in dirs
            d_path = joinpath(root, d)
            if islink(d_path)
                record_symlink!(d_path, relpath(d_path, prefix))
            end
        end
        for f in files
            f_path = joinpath(root, f)
            f_key = relpath(f_path, prefix)
            
            # `lstat()` now, as we're going to make use of it multiple times
            all_files[f_key] = lstat(f_path)

            # `readmeta()` on all binary objects and identify all static archives,
            # but ignore symlinks, we'll always resolve to the actual file when
            # dealing with it later on.
            if !islink(all_files[f_key])
                oh = get_object_handle(f_path, platform)
                if oh !== nothing
                    if haskey(binary_objects, f_key)
                        throw(ArgumentError("File $(f_key) contains multiple matching object handles"))
                    end
                    binary_objects[f_key] = oh
                elseif is_static_archive(f_path)
                    push!(static_libraries, f_key)
                end
            end

            # Store within-prefix symlinks for quick lookup
            if islink(all_files[f_key])
                record_symlink!(f_path, f_key)
            end
        end
    end

    # Build map from SONAME -> rel_path and inverse
    soname_locator = Dict{String,String}()
    missing_sonames = Vector{String}()
    for (rel_path, oh) in binary_objects
        if !islibrary(oh)
            continue
        end

        # Libraries listed in `missing_sonames` get the SONAME chosen here
        # written into them by `ensure_sonames!()`.
        soname = get_soname(oh)
        if soname === nothing
            # Without an SONAME, default to the library's filename.
            if !Sys.iswindows(platform)
                push!(missing_sonames, rel_path)
            end
            soname = basename(rel_path)
        elseif Sys.isapple(platform) && isabspath(soname)
            # An absolute install name gets replaced by an `@rpath`-relative one.
            # Keep the name the build chose (e.g. `libfoo.1.dylib` for `libfoo.1.2.dylib`)
            # when a file of that name next to the library resolves to it, otherwise
            # use the library's filename.
            push!(missing_sonames, rel_path)
            id_rel_path = joinpath(dirname(rel_path), basename(soname))
            if normpath(relpath_search(symlinks, id_rel_path)) == rel_path
                soname = basename(soname)
            else
                soname = basename(rel_path)
            end
        end

        # If this is an apple platform, and the dylib ID is something like
        # `@rpath/libfoo.dylib`, just keep track of `libfoo.dylib`.
        if Sys.isapple(platform) && startswith(soname, "@")
            soname = basename(soname)
        end
        soname_locator[soname] = rel_path
    end

    # Build map from basename(symlink_path) -> soname of target
    soname_forwards = Dict{String,String}()
    for (soname, lib_rel_path) in soname_locator
        for (sym_rel_path, sym_rel_target) in symlinks
            if sym_rel_target == lib_rel_path && basename(sym_rel_path) != soname
                soname_forwards[basename(sym_rel_path)] = soname
            end
        end
    end

    # Locate all library products
    library_product_map = Dict{String,LibraryProduct}()
    for lib in library_products
        lib_located_path = locate(lib, prefix; env, platform)
        if lib_located_path === nothing
            @error("Unable to locate library", lib, prefix, platform)
            error()
        end

        rel_path = relpath_search(symlinks, lib_located_path)
        if haskey(library_product_map, rel_path)
            duplicate_product_error(library_product_map[rel_path], lib, rel_path)
        end
        library_product_map[rel_path] = lib
    end

    # Likewise, each file is named by at most one `FileProduct`.  Executables are exempt:
    # many take their behavior from the name they are run by (e.g. `clang++`, a symlink
    # to `clang`), so each such name needs its own product.
    file_products = Dict{String,FileProduct}()
    for p in products
        isa(p, FileProduct) || continue
        located_path = locate(p, prefix; env, platform)
        # Products that cannot be located are reported before the audit
        located_path === nothing && continue
        rel_path = something(resolve_prefix_path(prefix, prefix_alias, located_path), located_path)
        if haskey(file_products, rel_path)
            duplicate_product_error(file_products[rel_path], p, rel_path)
        end
        file_products[rel_path] = p
    end

    # Locate all static library products, each of which must be one of the archives found above
    static_product_map = Dict{String,StaticLibraryProduct}()
    function locate_static(slp::StaticLibraryProduct)
        located_path = locate(slp, prefix; env, platform)
        if located_path === nothing
            @error("Unable to locate static library", slp, prefix, platform)
            error()
        end
        rel_path = relpath_search(symlinks, located_path)
        if rel_path ∉ static_libraries
            @error("Static library is not an archive", slp, rel_path, prefix, platform)
            error()
        end
        static_product_map[rel_path] = slp
    end
    for lib in library_products
        if lib.static !== nothing
            locate_static(lib.static)
        end
    end
    for slp in products
        if isa(slp, StaticLibraryProduct)
            locate_static(slp)
        end
    end

    # Get the (memoized) toolchain that holds our third-party tools
    at, at_prefix = deployed_auditor_toolchain(
        CrossPlatform(BBHostPlatform() => host_if_crossplatform(platform)),
    )

    return ScanResult(
        prefix,
        prefix_alias,
        platform,
        at,
        at_prefix,
        all_files,
        binary_objects,
        soname_locator,
        missing_sonames,
        soname_forwards,
        static_libraries,
        library_product_map,
        static_product_map,
        symlinks,
    )
end

"""
    hardlinks(scan::ScanResult, rel_path::String)

Return the paths of all binary objects in `scan` that are the same file on disk as
`rel_path` (including `rel_path` itself), sorted.  Build systems sometimes install
one file under several names (e.g. binutils' `bin/ld` and `bin/ld.bfd`), and a tool
that modifies one of them in place (`patchelf`, `install_name_tool`) modifies all.
"""
function hardlinks(scan::ScanResult, rel_path::String)
    st = scan.files[rel_path]
    return sort!([p for p in keys(scan.binary_objects)
                  if (scan.files[p].device, scan.files[p].inode) == (st.device, st.inode)])
end

# Used to denote that we've made a modification to a binary file.  Our `ObjectHandle`s
# keep the file open and cache its headers, so the handles of every name of the file
# must be re-read.
function refresh!(scan::ScanResult, rel_path::String)
    if rel_path ∈ keys(scan.binary_objects)
        for p in hardlinks(scan, rel_path)
            oh = get_object_handle(abspath(scan, p), scan.platform)
            if oh === nothing
                delete!(scan.binary_objects, p)
            else
                scan.binary_objects[p] = oh
            end
        end
    end
end

"""
    relpath_search(symlinks::Dict{String,String}, rel_path::AbstractString)

Resolves the symlinks in `rel_path` (relative to the prefix) using `symlinks`, the
map from each symlink's `rel_path` to its target's.  Every leading component is
resolved, so a path through a directory symlink, such as a framework's
`Foo.framework/Versions/Current/Foo`, is followed to the real file.  Links that
leave the prefix or loop are left unresolved.
"""
function relpath_search(symlinks::Dict{String,String}, rel_path::AbstractString)
    rel_path = String(rel_path)
    # Each link can be followed at most once on the way to the real file
    for _ in 0:length(symlinks)
        parts = splitpath(rel_path)
        resolved = false
        for idx in 1:length(parts)
            target = get(symlinks, joinpath(parts[1:idx]...), nothing)
            if target === nothing
                continue
            end
            new_rel_path = normpath(joinpath(target, parts[idx+1:end]...))
            if new_rel_path == rel_path || first(splitpath(new_rel_path)) == ".."
                return rel_path
            end
            rel_path = new_rel_path
            resolved = true
            break
        end
        if !resolved
            return rel_path
        end
    end
    return rel_path
end

"""
    resolve_prefix_path(prefix, prefix_alias, rel_path)

The path, relative to `prefix`, that `rel_path` names once every symlink along it is
followed, including symlinked directories.  Symlinks may be relative, or absolute
within `prefix_alias`.  Returns `nothing` if the path leads out of the prefix.
"""
function resolve_prefix_path(prefix::AbstractString, prefix_alias::AbstractString, rel_path::AbstractString;
                             max_links::Int = 64)
    pending = splitpath(rel_path)
    resolved = String[]
    num_links = 0
    while !isempty(pending)
        part = popfirst!(pending)
        if part == "."
            continue
        elseif part == ".."
            isempty(resolved) && return nothing
            pop!(resolved)
            continue
        end
        path = joinpath(prefix, resolved..., part)
        if islink(path)
            num_links += 1
            num_links > max_links && return nothing
            target = readlink(path)
            if isabspath(target)
                if target != prefix_alias && !startswith(target, rstrip(prefix_alias, '/') * "/")
                    return nothing
                end
                target = relpath(target, prefix_alias)
                empty!(resolved)
            end
            prepend!(pending, splitpath(target))
        else
            push!(resolved, part)
        end
    end
    return isempty(resolved) ? "." : joinpath(resolved...)
end

function duplicate_product_error(first::AbstractProduct, second::AbstractProduct, rel_path::AbstractString)
    kind = nameof(typeof(first))
    @error("$(kind)s resolve to the same path; declare one as an alias of the other, e.g. `$(kind)(..., :$(first.varname); aliases=[:$(second.varname)])`",
           path=rel_path, products=(first.varname, second.varname))
    error("$(kind)s '$(first.varname)' and '$(second.varname)' both resolve to '$(rel_path)'")
end

Base.relpath(scan::ScanResult, rel_path::AbstractString) = relpath_search(scan.symlinks, rel_path)
Base.abspath(scan::ScanResult, rel_path::AbstractString) = joinpath(scan.prefix, relpath(scan, rel_path))

function patchelf_flags(p::AbstractPlatform)
    flags = String[]

    # ppc64le and aarch64 have 64KB page sizes, don't muck up the ELF section load alignment
    if arch(p) in ("powerpc64le", "aarch64")
        append!(flags, ["--page-size", "65536"])
    end

    # We return arrays so that things interpolate into Cmd objects properly
    return flags
end

function patchelf_path(scan::ScanResult)
    return joinpath(scan.toolchain_prefix, "bin", patchelf_filename(scan.toolchain))
end

function patchelf(scan::ScanResult, cmd::Cmd)
    env = path_appending_merge(ENV, toolchain_env(scan.toolchain, scan.toolchain_prefix))
    addenv(`$(patchelf_path(scan)) $(patchelf_flags(scan.platform)) $(cmd)`, env)
end

function install_name_tool_path(scan::ScanResult)
    return joinpath(scan.toolchain_prefix, "bin", install_name_tool_filename(scan.toolchain))
end

function install_name_tool(scan::ScanResult, cmd::Cmd)
    env = path_appending_merge(ENV, toolchain_env(scan.toolchain, scan.toolchain_prefix))
    addenv(`$(install_name_tool_path(scan)) $(cmd)`, env)
end
