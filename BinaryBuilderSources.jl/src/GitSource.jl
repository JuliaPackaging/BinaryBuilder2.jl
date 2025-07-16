using BinaryBuilderGitUtils
using MultiHashParsing

export GitSource

"""
    GitSource(url, hash; target = basename(url))

Specify a remote Git repository to clone down from `url`. `hash` is a SHA1Hash,
typically a 40-character hexadecimal string.

The repository will be cloned in `\${WORKSPACE}/srcdir`, with a directory name
equal to the basename of the `url`, or in some other directory pointed to by
the optional keyword argument `target`.
"""
struct GitSource <: AbstractSource
    url::String
    hash::SHA1Hash
    target::String
end

function GitSource(url, hash; target = basename(url))
    noabspath!(target)
    return GitSource(
        string(url),
        SHA1Hash(hash),
        string(target)
    )
end

"""
    download_cache_path(gs::GitSource, download_cache::String)

Returns the full path to the local clone that will be written to in `prepare(gs)`
"""
function download_cache_path(gs::GitSource)
    return source_download_cache(string(
        basename(gs.url),
        "-",
        bytes2hex(sha256(gs.url)),
    ))
end

function verify(gs::GitSource)
    repo_path = download_cache_path(gs)
    if !isdir(repo_path)
        @debug("Verification fast-fail; repository nonexistent", source=gs, repo_path)
        return false
    end

    commit = bytes2hex(gs.hash)
    if !iscommit(repo_path, commit)
        @debug("Commit does not exist", source=gs, repo_path, commit)
        return false
    else
        @debug("Commit found", source=gs, repo_path, commit)
        return true
    end
end

function retarget(gs::GitSource, new_target::String)
    noabspath!(new_target)
    return GitSource(gs.url, gs.hash, new_target)
end

function prepare(gs::GitSource; verbose::Bool = false)
    repo_path = download_cache_path(gs)
    clone!(gs.url, repo_path; commit=gs.hash, verbose)

    # If we can't verify after cloning/fetching, we have the wrong hash
    if !iscommit(repo_path, gs.hash)
        throw(ArgumentError("Commit $(gs.hash) not found in GitSource '$(gs.url)'"))
    end
    return repo_path
end

function deploy(gs::GitSource, prefix::String)
    checkprepared!("deploy", gs)

    # We check the git repository out into the given target
    repo_path = download_cache_path(gs)
    target_path = joinpath(prefix, gs.target)
    mkpath(dirname(target_path))
    checkout!(repo_path, target_path, gs.hash)
end

function content_hash(gs::GitSource)
    # Even though we don't have to have anything on-disk to return
    # `gs.hash`, we still verify to ensure that the treehash exists.
    checkprepared!("content_hash", gs)

    return gs.hash
end
spec_hash(gs::GitSource; kwargs...) = gs.hash

source(gs::GitSource) = string(gs.url)
