using SHA, Downloads, TreeArchival, BinaryBuilderGitUtils
using MultiHashParsing
using MultiHashParsing: hash_like

export FileSource, ArchiveSource

# We deal with these together so often, might as well make this a thing
abstract type FileArchiveSource <: AbstractSource; end

"""
    ArchiveSource(url, hash; target = "")
    ArchiveSource([url, mirrors...], hash; target = "")

Specify a remote archive in one of the supported archive formats (e.g.,
compressed tarballs or zip balls) to be downloaded from the Internet
from `url`.  `hash` is a `MultiHash`-compatible archive integrity hash,
typically a 64-character hexadecimal SHA256 hash.

If a vector of URLs is given, they are tried in order until one of them yields a file
with the right hash.  The first URL is the primary one: it names the source (see
`source()`) and keys its download cache, so adding mirrors does not invalidate a download.

In the builder environment, the archive will be automatically unpacked to
`\${WORKSPACE}/srcdir`, or in its subdirectory pointed to by the optional
keyword `target`, if provided.
"""
struct ArchiveSource <: FileArchiveSource
    urls::Vector{String}
    hash::MultiHash
    target::String
end
ArchiveSource(url::String, hash::MultiHash, target::String) = ArchiveSource([url], hash, target)

function ArchiveSource(url, hash; target = "")
    noabspath!(target)
    return ArchiveSource(
        to_urls(url),
        MultiHash(hash),
        string(target),
    )
end


"""
    FileSource(url, hash; target = basename(url))
    FileSource([url, mirrors...], hash; target = basename(url))

Specify a remote file to be downloaded from the Internet from `url`.  `hash` is
a `MultiHash`-compatible file integrity hash, typically a 64-character
hexadecimal SHA256 hash.

If a vector of URLs is given, they are tried in order, as for `ArchiveSource`, and
the default `target` is the basename of the first one.

In the builder environment, the file will be automatically deployed to
`\${WORKSPACE}/srcdir/\$(target)`, where `basename(url)` is 
"""

struct FileSource <: FileArchiveSource
    urls::Vector{String}
    hash::MultiHash
    target::String
end
FileSource(url::String, hash::MultiHash, target::String) = FileSource([url], hash, target)

function FileSource(url, hash; target = basename(first(to_urls(url))))
    noabspath!(target)
    return FileSource(
        to_urls(url),
        MultiHash(hash),
        string(target),
    )
end

"""
    download_cache_path(fas::FileArchiveSource, download_cache::String)

Returns the full path to the file that will be written to in `prepare(as)`.
We store the cache as `\$(short_hash(source(fas)))-\$(fas.hash)`, so that when
users update a URL but forget to update the hash, they don't accidentally
build with the old cached values.  Only the primary (first) URL is part of the key.
"""
function download_cache_path(fas::FileArchiveSource)
    return joinpath(
        source_download_cache(bytes2hex(sha256(source(fas))[end-8:end])),
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
        verify_hash(fas, source_path)

        # If verification passes, touch the cache path and continue
        touch(hash_cache_path)
    end

    # Otherwise, the hash cache file exists (and is named as the hash, so we know the content
    # of the hash last time it was created), so return true!
    @debug("Verification pass", source=fas, source_path, hash_cache_path)
    return true
end

"""
    verify_hash(fas::FileArchiveSource, path; url = nothing)

Throw an `ArgumentError` if the file at `path` does not have the hash `fas` expects.
`url` names where the file was downloaded from, for the error message.
"""
function verify_hash(fas::FileArchiveSource, path::String; url::Union{Nothing,String} = nothing)
    check_hash = open(io -> hash_like(fas.hash, io), path; read=true)
    if check_hash != fas.hash
        msg  = "Hash Mismatch for $(fas)\n"
        if url !== nothing
            msg *= "  Downloaded from: $(url)\n"
        end
        msg *= "  Expected:   $(fas.hash)\n"
        msg *= "  Calculated: $(check_hash)\n"
        throw(ArgumentError(msg))
    end
end

function retarget(fas::T, new_target::String) where {T <: FileArchiveSource}
    noabspath!(new_target)
    return T(fas.urls, fas.hash, new_target)
end

"""
    download_headers(url)

Any URL into a repository we have a token for in `BinaryBuilderGitUtils.access_tokens`
is sent it, as `git` is.  A GitHub release asset given by its API URL
(`https://api.github.com/repos/<owner>/<repo>/releases/assets/<id>`) is the way to
download one from a private repository: it also needs `Accept: application/octet-stream`.
"""
function download_headers(url::AbstractString)
    headers = Pair{String,String}[]
    if occursin(r"^https://api\.github\.com/repos/[^/]+/[^/]+/releases/assets/\d+$", url)
        push!(headers, "Accept" => "application/octet-stream")
    end
    token = url_access_token(url)
    if token !== nothing
        push!(headers, "Authorization" => "Bearer $(token)")
    end
    return headers
end

function prepare(fas::FileArchiveSource; verbose::Bool = false)
    # Only download if verification fails
    if verify(fas)
        return
    end

    download_target = download_cache_path(fas)
    with_download_lock(download_target) do
        # Another process may have downloaded it while we waited for the lock
        if verify(fas)
            return
        end

        # Try each URL in order, each with its own network retries, until one of them
        # yields a file with the right hash.
        errors = Pair{String,Any}[]
        for (idx, url) in enumerate(fas.urls)
            try
                with_network_retries("Downloading $(url)") do
                    download_verified(fas, url, download_target)
                end
                break
            catch e
                if e isa InterruptException
                    rethrow()
                end
                push!(errors, url => e)
                if idx < length(fas.urls)
                    @warn("Downloading $(url) failed, trying the next URL", exception=e)
                end
            end
        end
        if length(errors) == length(fas.urls)
            if length(errors) == 1
                throw(only(errors).second)
            end
            throw(MirrorsFailedError(errors))
        end

        # If we still don't verify properly, throw an error
        if !verify(fas)
            throw(ArgumentError("Invalid hash"))
        end
    end
end

"""
    download_verified(fas::FileArchiveSource, url, download_target)

Download `url` next to `download_target`, check that it has the hash `fas` expects, and
only then move it into place, so that nobody ever sees (and fails to verify) a partial
or wrong download, even if the download fails or we are interrupted.
"""
function download_verified(fas::FileArchiveSource, url::String, download_target::String)
    temp_target, temp_io = mktemp(dirname(download_target); cleanup=false)
    close(temp_io)
    try
        Downloads.download(url, temp_target; headers=download_headers(url))
        verify_hash(fas, temp_target; url)
        mv(temp_target, download_target; force=true)
    finally
        rm(temp_target; force=true)
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

source(fas::FileArchiveSource) = first(fas.urls)
