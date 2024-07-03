module TreeArchival

using p7zip_jll, Zstd_jll, Tar
export archive, unarchive, treehash

# This tracks the offset and magic bytes for each compression type we support
const compressor_magic_bytes = Dict(
    "bzip2" => (0, [0x42, 0x5a, 0x68]),
    "gzip" => (0, [0x1f, 0x8b]),
    "xz" => (0, [0xfd, 0x37, 0x7a, 0x58, 0x5a, 0x00]),
    "zip" => (0, [0x50, 0x4b, 0x03, 0x04]),
    "zstd" => (0, [0x28, 0xb5, 0x2f, 0xfd]),
    "7z" => (0, [0x37, 0x7a, 0xbc, 0xaf, 0x27, 0x1c]),

    # This isn't really a compression, it's more like "no compression"
    # but we might as well support it.
    "tar" => (257, [0x75, 0x73, 0x74, 0x61, 0x72]),
)
const max_magic_bytes_len = maximum(first.(values(compressor_magic_bytes))) +
                            maximum(length.(last.(values(compressor_magic_bytes))))

"""
    detect_compressor(header::Vector)

Looks at magic bytes at the beginning of a file to determine its compression type.
Returns `nothing` if no matching compressor could be found.
"""
function detect_compressor(header::Vector)
    for (compressor, (offset, magic)) in compressor_magic_bytes
        lm = length(magic)
        if length(header) >= (offset + lm) && header[(offset+1):(offset+lm)] == magic
            return compressor
        end
    end
    @warn("detect_compressor didn't recognize magic bytes!", header)
    return nothing
end
function detect_compressor(source_file::String)
    if isfile(source_file)
        return detect_compressor(read(open(source_file; read=true), max_magic_bytes_len))
    end
    return nothing
end

function decompress_cmd(source_path::String;
                        compressor = detect_compressor(source_path),
                        stderr_out=stderr)
    if compressor ∈ ("gzip", "bzip2", "7z", "xz")
        return pipeline(
            `$(p7zip_jll.p7zip()) x $(source_path) -so -bso0`;
            stderr=stderr_out,
        )
    elseif compressor ∈ ("zstd",)
        return pipeline(
            `$(Zstd_jll.zstd()) -d $(source_path) -c`;
            stderr=stderr_out,
        )
    elseif compressor ∈ ("zip", "tar")
        throw(ArgumentError("Cannot decompress() a $(compressor) file; use unarchive()!"))
    else
        throw(ArgumentError("Called decompress() on an unknown file type, autodetected as '$(compressor)'!"))
    end
end

function compress_cmd(output_path::String, compressor::String;
                      compression_level::Union{Int, Nothing} = nothing,
                      stderr_out = stderr)
    # Luckily, we've named our `compressor` names the same as 7zip calls them in its `-t` flag!
    if compressor ∈ ("gzip", "bzip2", "7z", "xz")
        p7zip_opts = [
            # Add to this archive
            "a", output_path,

            # Yes to all questions
            "-y",

            # Silence non-error output
            "-bso0",

            # Read from standard input, write to standard output
            "-si",

            # Select compression algorithm
            "-t$(compressor)",
        ]
        if compression_level !== nothing
            push!(p7zip_opts, "-mx$(compression_level)")
        end

        return pipeline(`$(p7zip_jll.p7zip()) $(p7zip_opts)`; stderr=stderr_out)
    elseif compressor ∈ ("zstd",)
        zstd_opts = [
            # Output to this path
            "-o", output_path,

            # Silence non-error output
            "--no-progress", "-q",
        ]
        if compression_level !== nothing
            push!(zstd_opts, "-$(compression_level)")
        end
        return pipeline(`$(Zstd_jll.zstd()) $(zstd_opts)`; stderr=stderr_out)
    elseif compressor ∈ ("tar",)
        throw(ArgumentError("Cannot compress() a $(compressor) file; use archive()"))
    else
        throw(ArgumentError("Called compress() with an unknown compression type '$(compressor)'"))
    end
end

function copy_tree(src::AbstractString, dest::AbstractString)
    for (root, dirs, files) in walkdir(src)
        # Create all directories
        for d in dirs
            dest_dir = joinpath(dest, relpath(root, src), d)
            if ispath(dest_dir) && !isdir(realpath(dest_dir))
                # We can't create a directory if the destination exists and
                # is not a directory or a symlink to a directory.
                throw(ArgumentError("Directory $(d) is not an artifact in $(dest)"))
            end
            mkpath(dest_dir)
        end

        # Copy all files
        for f in files
            src_file = joinpath(root, f)
            dest_file = joinpath(dest, relpath(root, src), f)
            cp(src_file, dest_file; force=true)
        end
    end
end

"""
    unarchive(source_path::String, output_dir::String;
              compressor = detect_compressor(source_path),
              stderr_out = stderr,
              overwrite::Bool = false)

Read from `source_path`, automatically determine the compression type by inspecting the first
few bytes, then write the unarchived result to `output_dir`.

If the compression type cannot be auto-determined, throws an error.

If `overwrite` is set to `true`, does not require `output_dir`
to be empty/missing.
"""
function unarchive(source_path::String, output_dir::String;
                   compressor = detect_compressor(source_path),
                   stderr_out=stderr,
                   overwrite::Bool = false)
    # Sub out to a JLL process to do the actual decompression
    mkpath(output_dir)

    output_dir_empty = isempty(readdir(output_dir))
    if !overwrite && !output_dir_empty
        throw(ArgumentError("output_dir ($(output_dir)) is not empty, must set `overwrite=true`!"))
    end

    # .zip files get special treatment, no `Tar.jl` involvement at all
    if compressor ∈ ("zip",)
        decompressor_cmd = pipeline(
            `$(p7zip_jll.p7zip()) x $(source_path) -o$(output_dir) -bso0`; stderr=stderr_out
        )
        success(run(decompressor_cmd))
        return nothing
    end

    # If we're dealing with a compressed tarball, create a decompression layer
    if compressor ∈ ("gzip", "bzip2", "7z", "xz", "zstd")
        extract_source = decompress_cmd(source_path; compressor)
    elseif compressor ∈ ("tar",)
        extract_source = source_path
    else
        throw(ArgumentError("Called unarchive() on an unknown file type, autodetected as '$(compressor)'!"))
    end

    # `Tar.jl` does not support unpacking to a directory that is not empty, so
    # for these `Tar.jl`-powered unpackings, if `overwrite` is set to `true`,
    # we unpack to a temporary directory, then copy everything over.  :(
    if !output_dir_empty
        mktempdir(output_dir) do temp_dir
            Tar.extract(extract_source, temp_dir)
            copy_tree(temp_dir, output_dir)
        end
    else
        # If the directory is not empty, we can just extract into it directly.
        Tar.extract(extract_source, output_dir)
    end
    return nothing
end


"""
    archive(source_dir::String, output_path::String, compressor::String;
            stderr_out = stderr)

Read from `source_path`, automatically determine the compression type by inspecting the first
few bytes, then write the unarchived result to `output_dir`.

If the compression type cannot be auto-determined, throws an error.
"""
function archive(source_dir::String, output_path::String, compressor::String; kwargs...)
    if compressor ∈ ("gzip", "bzip2", "7z", "xz", "zstd")
        Tar.create(
            source_dir,
            compress_cmd(output_path, compressor; kwargs...);
            portable=true,
        )
    elseif compressor ∈ ("tar",)
        Tar.create(source_dir, output_path; portable=true)
    elseif compressor ∈ ("zip",)
        throw(ArgumentError("zip balls are not treehash-stable, so we don't allow archiving them!"))
    else
        throw(ArgumentError("Unknown compression type '$(compressor)'!"))
    end
    return nothing
end

"""
    treehash(source_file::String; compressor::String = detect_compressor(source_file),
                                  ignore_unstable_formats::Bool = false)

Treehash the archive given in `source_file`, automatically determining the compression
type by inspecting the first few bytes.  Returns a vector of bytes.

If the compression type cannot be auto-determined, throws an error.

If `source_file` is a `.zip` file, throws an error unless `ignore_unstable_formats`
is set to `true`.  Even then, it prints out a warning.
"""
function treehash(source_file::String; compressor = detect_compressor(source_file),
                                       ignore_unstable_formats::Bool = false,
                                       kwargs...)
    if !ispath(source_file)
        # Throw a typical "file does not exist" error.
        open(source_file)
    end

    if isdir(source_file)
        # Sub off to the other `treehash()` implementation in `TreeHashing.jl`
        return treehash(SHA.SHA1_CTX, source_file; kwargs...)
    end

    if compressor ∈ ("gzip", "bzip2", "7z", "xz", "zstd")
        return hex2bytes(Tar.tree_hash(decompress_cmd(source_file; compressor)))
    elseif compressor ∈ ("tar",)
        return hex2bytes(Tar.tree_hash(source_file))
    elseif compressor ∈ ("zip",)
        # By default, we refuse to do this
        if !ignore_unstable_formats
            throw(ArgumentError("Refusing to tree hash a $(compressor) file without `ignore_unstable_formats` set!"))
        end

        # Even if you force us, complain.
        @warn("Treehashing an unstable archive format!", source_file, compressor)
        mktempdir() do dir
            unarchive(source_file, dir; compressor)
            return treehash(dir)
        end
    else
        throw(ArgumentError("Unknown compression type '$(compressor)'"))
    end
end

include("TreeHashing.jl")

end # module
