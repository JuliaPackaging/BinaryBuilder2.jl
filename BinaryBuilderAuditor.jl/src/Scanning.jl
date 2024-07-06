using ObjectFile, BinaryBuilderProducts, Patchelf_jll
using Base.Filesystem: StatStruct

export ScanResult, scan_files

struct ScanResult
    prefix::String
    prefix_alias::String
    platform::AbstractPlatform

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

    # This maps `rel_path` to a library product `LibraryProduct`
    library_products::Dict{String,LibraryProduct}

    # For easy lookup of things by symlink alias
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

function scan_files(prefix::String, platform::AbstractPlatform,
                    library_products::Vector{LibraryProduct} = LibraryProduct[],
                    env::Dict{String,String} = Dict{String,String}(
                        "prefix" => prefix,
                        "bb_full_target" => triplet(platform),
                    );
                    prefix_alias::String = prefix)
    prefix = safe_realpath(prefix)

    # Do a scan over the prefix, find all symlinks, binary objects, etc....
    all_files = Dict{String,StatStruct}()
    binary_objects = Dict{String,ObjectHandle}()
    symlinks = Dict{String,String}()
    for (root, dirs, files) in walkdir(prefix)
        for f in files
            f_path = joinpath(root, f)
            f_key = relpath(f_path, prefix)
            
            # `lstat()` now, as we're going to make use of it multiple times
            all_files[f_key] = lstat(f_path)

            # `readmeta()` on all binary objects, but ignore symlinks, we'll
            # always resolve to the actual file when dealing with it later on.
            if !islink(all_files[f_key])
                oh = get_object_handle(f_path, platform)
                if oh !== nothing
                    if haskey(binary_objects, f_key)
                        throw(ArgumentError("File $(f_key) contains multiple matching object handles"))
                    end
                    binary_objects[f_key] = oh
                end
            end

            # Store within-prefix symlinks for quick lookup
            if islink(all_files[f_key])
                link_target = readlink(f_path)
                if startswith(link_target, prefix_alias)
                    symlinks[f_key] = relpath(link_target, prefix_alias)
                elseif !isabspath(link_target)
                    symlinks[f_key] = joinpath(dirname(f_key), link_target)
                end
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

        # If something doesn't have an SONAME, we default to `basename(rel_path)`
        # This will be fixed by `ensure_sonames!()`.
        soname = get_soname(oh)
        if soname === nothing
            if !Sys.iswindows(platform)
                push!(missing_sonames, rel_path)
            end
            soname = basename(rel_path)
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
            @error("Unable to locate library", lib, prefix)
            error()
        end

        library_product_map[relpath_search(symlinks, lib_located_path)] = lib
    end

    return ScanResult(
        prefix,
        prefix_alias,
        platform,
        all_files,
        binary_objects,
        soname_locator,
        missing_sonames,
        soname_forwards,
        library_product_map,
        symlinks,
    )
end

# Used to denote that we've made a modification to a binary file
function refresh!(scan::ScanResult, rel_path::String)
    if rel_path ∈ keys(scan.binary_objects)
        oh = get_object_handle(abspath(scan, rel_path), scan.platform)
        if oh === nothing
            delete!(scan.binary_objects, rel_path)
        else
            scan.binary_objects[rel_path] = oh
        end
    end
end

function relpath_search(symlinks::Dict{String,String}, rel_path::AbstractString)
    while haskey(symlinks, rel_path)
        new_rel_path = symlinks[rel_path]
        if new_rel_path == rel_path
            break
        end
        rel_path = new_rel_path
    end
    return rel_path
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

Patchelf_jll.patchelf(scan::ScanResult, cmd::Cmd) = `$(patchelf()) $(patchelf_flags(scan.platform)) $(cmd)`
