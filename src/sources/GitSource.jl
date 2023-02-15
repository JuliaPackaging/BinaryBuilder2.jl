using LibGit2

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
function download_cache_path(gs::GitSource, download_cache::String = source_download_cache())
    return joinpath(download_cache, bytes2hex(sha256(gs.url)))
end

function verify(gs::GitSource, download_cache::String = source_download_cache())
    repo_path = download_cache_path(gs, download_cache)
    if !isdir(repo_path)
        @debug("Verification fast-fail; repository nonexistent", source=gs, repo_path)
        return false
    end

    commit = bytes2hex(gs.hash)
    commit_exists = LibGit2.with(LibGit2.GitRepo(repo_path)) do repo
        LibGit2.iscommit(commit, repo)
    end

    if !commit_exists
        @debug("Commit does not exist", source=gs, repo_path, commit)
        return false
    else
        @debug("Commit found", source=gs, repo_path, commit)
        return true
    end
end

function prepare(gs::GitSource)
    download_cache = source_download_cache()
    repo_path = download_cache_path(gs, download_cache)
    if isdir(repo_path)
        # It's a little awkard to re-use `verify()` here; we just inline the pieces we need
        @debug("Using cached git repository", gs, repo_path)
        LibGit2.with(LibGit2.GitRepo(repo_path)) do repo
            if !LibGit2.iscommit(bytes2hex(gs.hash), repo)
                @debug("Fetching repository to try and find commit", gs, repo_path)
                LibGit2.fetch(repo)
            end
        end
    else
        @debug("Cloning git repository", gs, repo_path)
        LibGit2.clone(gs.url, repo_path; isbare=true)
    end

    # If we can't verify after cloning/fetching, we have the wrong hash
    if !verify(gs, download_cache)
        throw(ArgumentError("Commit $(gs.hash) not found in GitSource '$(gs.url)'"))
    end
    return repo_path
end

function deploy(gs::GitSource, prefix::String)
    download_cache = source_download_cache()
    checkprepared!("deploy", gs, download_cache)

    # We check the git repository out into the given target
    repo_path = download_cache_path(gs, download_cache)
    target_path = joinpath(prefix, gs.target)
    mkpath(dirname(target_path))
    LibGit2.with(LibGit2.clone(repo_path, target_path)) do repo
        LibGit2.checkout!(repo, bytes2hex(gs.hash))
    end
end

function content_hash(gs::GitSource)
    # Even though we don't have to have anything on-disk to return
    # `gs.hash`, we still verify to ensure that the treehash exists.
    download_cache = source_download_cache()
    checkprepared!("content_hash", gs, download_cache)

    return gs.hash
end
