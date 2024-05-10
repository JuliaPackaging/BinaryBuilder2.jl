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

    # This maps `LibraryProduct` files to their resolved `rel_path`.
    # This is filled out by `resolve_dynamic_links!()`, not by `scan_files()`!
    library_products::Dict{LibraryProduct,String}

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

function scan_files(prefix::String, platform::AbstractPlatform; prefix_alias::String = prefix)
    prefix = safe_realpath(prefix)

    all_files = Dict{String,StatStruct}()
    binary_objects = Dict{String,ObjectHandle}()
    symlinks = Dict{String,String}()

    # If the directory does not exist, early-exit
    if !isdir(prefix)
        return ScanResult(prefix, all_files, binary_objects)
    end

    for (root, dirs, files) in walkdir(prefix)
        for f in files
            f_path = joinpath(root, f)
            f_key = relpath(f_path, prefix)
            
            # `lstat()` now, as we're going to make use of it multiple times
            all_files[f_key] = lstat(f_path)

            # Store within-prefix symlinks for quick lookup
            if islink(all_files[f_key])
                link_target = readlink(f_path)
                if startswith(link_target, prefix_alias)
                    symlinks[f_key] = relpath(link_target, prefix_alias)
                elseif !isabspath(link_target)
                    symlinks[f_key] = joinpath(dirname(f_key), link_target)
                end
            end

            # Don't `readmeta()` on symlinks
            if !islink(all_files[f_key])
                oh = get_object_handle(f_path, platform)
                if oh !== nothing
                    if haskey(binary_objects, f_key)
                        throw(ArgumentError("File $(f_key) contains multiple matching object handles"))
                    end
                    binary_objects[f_key] = oh
                end
            end
        end
    end

    return ScanResult(
        prefix,
        prefix_alias,
        platform,
        all_files,
        binary_objects,
        Dict{LibraryProduct,String}(),
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

function Base.relpath(scan::ScanResult, rel_path::AbstractString)
    while haskey(scan.symlinks, rel_path)
        new_rel_path = scan.symlinks[rel_path]
        if new_rel_path == rel_path
            break
        end
        rel_path = new_rel_path
    end
    return rel_path
end
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
