module Compressors

using p7zip_jll, Zstd_jll, Tar_jll

const compressor_magic_bytes = Dict(
    "bzip2" => [0x42, 0x5a, 0x68],
    "gzip" => [0x1f, 0x8b],
    "xz" => [0xfd, 0x37, 0x7a, 0x58, 0x5a, 0x00],
    "zip" => [0x50, 0x4b, 0x03, 0x04],
    "zstd" => [0x28, 0xb5, 0x2f, 0xfd],
    "7z" => [0x37, 0x7a, 0xbc, 0xaf, 0x27, 0x1c],
)
const max_magic_bytes_len = maximum(length.(values(compressor_magic_bytes)))

"""
    detect_compressor(header::Vector)

Looks at magic bytes at the beginning of a file to determine its compression type.
Returns `nothing` if no matching compressor could be found.
"""
function detect_compressor(header::Vector)
    for (compressor, magic) in compressor_magic_bytes
        lm = length(magic)
        if length(header) >= lm && header[1:lm] == magic
            return compressor
        end
    end
    return nothing
end
function detect_compressor(source_file::String)
    return detect_compressor(read(open(source_file; read=true), max_magic_bytes_len))
end

"""
    decompress!(source_path::String, output_dir::String; compressor = detect_compressor(source_path))

Read from `source_path`, automatically determine the compression type by inspecting the first
few bytes, then write the uncompressed result to `output_dir`.

If the compression type cannot be auto-determined, throws an error.
"""
function decompress(source_path::String, output_dir::String; compressor = detect_compressor(source_path), stderr_out=stderr)
    # Sub out to a JLL process to do the actual decompression
    local decompressor_cmd
    tar_extraction_cmd = `$(Tar_jll.tar()) x -C $(output_dir)`
    if compressor ∈ ("gzip", "bzip2", "7z", "xz")
        decompressor_cmd = pipeline(
            pipeline(`$(p7zip_jll.p7zip()) x $(source_path) -so -bso0`; stderr=stderr_out),
            pipeline(tar_extraction_cmd; stderr=stderr_out),
        )
    elseif compressor ∈ ("zstd",)
        decompressor_cmd = pipeline(
            pipeline(`$(Zstd_jll.zstd()) -d $(source_path) -c`; stderr=stderr_out),
            pipeline(tar_extraction_cmd; stderr=stderr_out),
        )
    elseif compressor ∈ ("zip",)
        decompressor_cmd = pipeline(
            `$(p7zip_jll.p7zip()) x $(source_path) -o$(output_dir) -bso0`; stderr=stderr_out
        )
    else
        error("Called decompress!() on an unknown file type!")
    end

    mkpath(output_dir)
    return success(run(decompressor_cmd))
end

function compress(source_dir::String, output_path::String, compressor::String; stderr_out=stderr)
    tar_cmd = `$(Tar_jll.tar()) c -C $(source_dir) .`
    if compressor ∈ ("gzip", "bzip2", "7z", "xz")
        # Luckily, we've named our `compressor` names the same as 7zip calls them in its `-t` flag!
        compressor_cmd = pipeline(
            pipeline(tar_cmd; stderr=stderr_out),
            pipeline(`$(p7zip_jll.p7zip()) a -y -bso0 -t$(compressor) -si $(output_path)`; stderr=stderr_out),
        )
    elseif compressor ∈ ("zstd",)
        compressor_cmd = pipeline(
            pipeline(tar_cmd; stderr=stderr_out),
            pipeline(`$(Zstd_jll.zstd()) --no-progress -q -o $(output_path)`; stderr=stderr_out),
        )
    elseif compressor ∈ ("zip",)
        compressor_cmd = pipeline(
            `$(p7zip_jll.p7zip()) a -y -bso0 -t$(compressor) $(output_path) -w $(joinpath(source_dir, "."))`; stderr=stderr_out
        )
    end
    return success(run(compressor_cmd))
end

end # module Compressors
