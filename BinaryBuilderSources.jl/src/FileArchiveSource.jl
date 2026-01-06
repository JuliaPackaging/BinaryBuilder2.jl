using SHA, Downloads, TreeArchival
using MultiHashParsing
using MultiHashParsing: hash_like

export FileSource, ArchiveSource

# We deal with these together so often, might as well make this a thing
abstract type FileArchiveSource <: AbstractSource; end

"""
    ArchiveSource(url, hash; target = "")

Specify a remote archive in one of the supported archive formats (e.g.,
compressed tarballs or zip balls) to be downloaded from the Internet
from `url`.  `hash` is a `MultiHash`-compatible archive integrity hash,
typically a 64-character hexadecimal SHA256 hash.

In the builder environment, the archive will be automatically unpacked to
`\${WORKSPACE}/srcdir`, or in its subdirectory pointed to by the optional
keyword `target`, if provided.
"""
struct ArchiveSource <: FileArchiveSource
    url::String
    hash::MultiHash
    target::String
end

function ArchiveSource(url, hash; target = "")
    noabspath!(target)
    return ArchiveSource(
        string(url),
        MultiHash(hash),
        string(target)
    )
end


"""
    FileSource(url, hash; target = basename(url))

Specify a remote file to be downloaded from the Internet from `url`.  `hash` is
a `MultiHash`-compatible file integrity hash, typically a 64-character
hexadecimal SHA256 hash.

In the builder environment, the file will be automatically deployed to
`\${WORKSPACE}/srcdir/\$(target)`, where `basename(url)` is 
"""

struct FileSource <: FileArchiveSource
    url::String
    hash::MultiHash
    target::String
end

function FileSource(url, hash; target = basename(url))
    noabspath!(target)
    return FileSource(
        string(url),
        MultiHash(hash),
        string(target),
    )
end

"""
    download_cache_path(fas::FileArchiveSource, download_cache::String)

Returns the full path to the file that will be written to in `prepare(as)`.
We store the cache as `\$(short_hash(fas.url))-\$(fas.hash)`, so that when
users update a URL but forget to update the hash, they don't accidentally
build with the old cached values.
"""
function download_cache_path(fas::FileArchiveSource)
    return joinpath(
        source_download_cache(bytes2hex(sha256(fas.url)[end-8:end])),
        bytes2hex(fas.hash),
    )
end

function verify(fas::FileArchiveSource)
    # If the file does not exist at all, fail verification
    source_path = download_cache_path(fas)
    if !isfile(source_path)
        @debug("Verification fast-fail; file nonexistent", source=fas, source_path)
        return false
    end

    # This is a lovely variable name
    hash_cache_path = string(source_path, ".", MultiHashParsing.hash_prefix(fas.hash))

    # If there is no cached hash file or it is stale, re-hash the file here
    # Note that `stat()` of a nonexistant file returns `0`.
    if stat(hash_cache_path).mtime < stat(source_path).mtime
        @debug("Re-hashing", source=fas, source_path, hash_cache_path)
        check_hash = open(io -> hash_like(fas.hash, io), source_path; read=true)
        if check_hash != fas.hash 
            # Verification failed!
            msg  = "Hash Mismatch for $(fas)\n"
            msg *= "  Expected:   $(fas.hash)\n"
            msg *= "  Calculated: $(check_hash)\n"
            throw(ArgumentError(msg))
        end

        # If verification passes, touch the cache path and continue
        touch(hash_cache_path)
    end

    # Otherwise, the hash cache file exists (and is named as the hash, so we know the content
    # of the hash last time it was created), so return true!
    @debug("Verification pass", source=fas, source_path, hash_cache_path)
    return true
end

function retarget(fas::T, new_target::String) where {T <: FileArchiveSource}
    noabspath!(new_target)
    return T(fas.url, fas.hash, new_target)
end

function prepare(fas::FileArchiveSource; verbose::Bool = false)
    # Only download if verification fails
    if !verify(fas)
        download_target = download_cache_path(fas)

        # Ensure the directory that should hold this source exists, otherwise `download()` fails
        mkpath(dirname(download_target))
        Downloads.download(fas.url, download_target)

        # If we still don't verify properly, throw an error
        if !verify(fas)
            throw(ArgumentError("Invalid hash"))
        end
    end
end

function deploy(as::ArchiveSource, prefix::String)
    checkprepared!("deploy", as)

    # We unpack the archive into the desired location
    unarchive(
        download_cache_path(as),
        joinpath(prefix, as.target);
        overwrite=true,
    )
end

function deploy(fs::FileSource, prefix::String)
    checkprepared!("deploy", fs)

    # We just copy the file into the desired location
    target_path = joinpath(prefix, fs.target)
    mkpath(dirname(target_path))
    cp(download_cache_path(fs), target_path)
end

# We key only off of the hash of the source and the target
function spec_hash(fas::FileArchiveSource; kwargs...)
    return SHA1Hash(sha1(string(
        bytes2hex(fas.hash),
        fas.target,
    )))
end


function content_hash(as::ArchiveSource)
    checkprepared!("content_hash", as)

    # Note that we pass `ignore_unstable_formats` through here,
    # which will bubble up a `@warn` to the user if they use `.zip`
    # files as their source files.
    return SHA1Hash(treehash(download_cache_path(as);
                             ignore_unstable_formats=true))
end


function content_hash(fs::FileSource)
    checkprepared!("content_hash", fs)
    # We re-use `TreeArchival's`'s `blob_hash` here:
    path = download_cache_path(fs)
    return SHA1Hash(TreeArchival.blob_hash(SHA1_CTX, path))
end

source(fas::FileArchiveSource) = fas.url
