using BinaryBuilderGitUtils
using BinaryBuilderGitUtils: git_authed
using Git: git
using MultiHashParsing

export GitSource

"""
    GitSource(url, hash; target = basename(url))
    GitSource([url, mirrors...], hash; target = basename(url))

Specify a remote Git repository to clone down from `url`. `hash` is a SHA1Hash,
typically a 40-character hexadecimal string.

The repository will be cloned in `\${WORKSPACE}/srcdir`, with a directory name
equal to the basename of the `url`, or in some other directory pointed to by
the optional keyword argument `target`.

If a vector of URLs is given, they are fetched into the same local clone, in order,
until one of them provides the commit `hash`; each URL is a remote of that clone.  The
first URL names the source (see `source()`) and keys its cache, so adding mirrors does
not invalidate a clone.
"""
struct GitSource <: AbstractSource
    urls::Vector{String}
    hash::SHA1Hash
    target::String
end
GitSource(url::String, hash::SHA1Hash, target::String) = GitSource([url], hash, target)

function remove_dot_git(name)
    if endswith(name, ".git")
        return name[1:end-4]
    end
    return name
end

function GitSource(url, hash; target = remove_dot_git(basename(first(to_urls(url)))))
    noabspath!(target)
    return GitSource(
        to_urls(url),
        SHA1Hash(hash),
        string(target)
    )
end

"""
    download_cache_path(gs::GitSource, download_cache::String)

Returns the full path to the local clone that will be written to in `prepare(gs)`.
Only the primary (first) URL is part of the key.
"""
function download_cache_path(gs::GitSource)
    return source_download_cache(string(
        basename(source(gs)),
        "-",
        bytes2hex(sha256(source(gs))),
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
    return GitSource(gs.urls, gs.hash, new_target)
end

"""
    remote_name(url)

The name of the remote that fetches `url` in a `GitSource`'s clone.  It depends only on
`url`, so a remote keeps its name (and its refs) however a source's URLs are ordered.
"""
remote_name(url::String) = string("mirror-", bytes2hex(sha256(url))[1:16])

"""
    set_head!(repo_path, remote, url)

Point `HEAD` of the bare clone at `repo_path` at the default branch of `remote`, so that
clones made from it check that branch out.  The branch is created under `refs/heads/`
from the remote's copy of it if the clone doesn't have it yet.
"""
function set_head!(repo_path::String, remote::String, url::String)
    symrefs = git_authed(readchomp, url, ["-C", repo_path, "ls-remote", "--symref", remote, "HEAD"])
    m = match(r"^ref: refs/heads/(\S+)\tHEAD$"m, symrefs)
    if m === nothing
        return
    end
    branch = m.captures[1]
    local_branch = "refs/heads/$(branch)"
    if !iscommit(repo_path, local_branch)
        fetched_branch = "refs/mirrors/$(remote)/heads/$(branch)"
        if !iscommit(repo_path, fetched_branch)
            return
        end
        run(git(["-C", repo_path, "update-ref", local_branch, fetched_branch]))
    end
    run(git(["-C", repo_path, "symbolic-ref", "HEAD", local_branch]))
end

"""
    fetch_url!(repo_path, url; verbose = false)

Fetch `url` into the bare clone at `repo_path`, creating the clone if it does not exist
yet.  Every URL is its own remote (see `remote_name()`), whose refs are kept under
`refs/mirrors/<remote>/` and whose tags are not fetched, so that fetching one remote
never makes the commits fetched from another one unreachable.
"""
function fetch_url!(repo_path::String, url::String; verbose::Bool = false)
    remote = remote_name(url)
    if !ispath(joinpath(repo_path, "HEAD"))
        mkpath(repo_path)
        run(git(["-C", repo_path, "init", "--bare", "--quiet"]))
    end
    remote_url!(repo_path, remote, url)
    run(git(["-C", repo_path, "config", "--replace-all", "remote.$(remote).fetch", "+refs/*:refs/mirrors/$(remote)/*"]))
    run(git(["-C", repo_path, "config", "remote.$(remote).tagOpt", "--no-tags"]))
    quiet = verbose ? String[] : ["--quiet"]
    git_authed(run, url, ["-C", repo_path, "fetch", remote, quiet...])
    if !iscommit(repo_path, "HEAD")
        set_head!(repo_path, remote, url)
    end
end

function prepare(gs::GitSource; verbose::Bool = false)
    repo_path = download_cache_path(gs)
    with_download_lock(repo_path) do
        if verify(gs)
            return
        end

        # Try each URL in order, each with its own network retries, until one of them
        # provides the commit.  `git` exits with the same status for network failures as
        # for e.g. a nonexistent repository, so every failed `git` invocation is retried.
        is_transient(e) = e isa ProcessFailedException
        had_repo = ispath(repo_path)
        errors = Pair{String,Any}[]
        for (idx, url) in enumerate(gs.urls)
            try
                with_network_retries("Fetching $(url)"; is_transient) do
                    fetch_url!(repo_path, url; verbose)
                end
                if iscommit(repo_path, gs.hash)
                    break
                end
                throw(ArgumentError("Commit $(gs.hash) not found in GitSource URL '$(url)'"))
            catch e
                if e isa InterruptException
                    rethrow()
                end
                push!(errors, url => e)
                if idx < length(gs.urls)
                    @warn("Fetching $(url) failed, trying the next URL", exception=e)
                end
            end
        end
        if length(errors) == length(gs.urls)
            # Don't leave behind a clone that we created but could not fetch anything into.
            if !had_repo && ispath(repo_path) && isempty(readchomp(git(["-C", repo_path, "for-each-ref"])))
                rm(repo_path; recursive=true, force=true)
            end
            if length(errors) == 1
                throw(only(errors).second)
            end
            throw(MirrorsFailedError(errors))
        end
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
function spec_hash(gs::GitSource; kwargs...)
    # Make the hash sensitive to our target, as that changes the layout on-disk.
    return SHA1Hash(sha1(string(
        bytes2hex(gs.hash),
        gs.target,
    )))
end

source(gs::GitSource) = first(gs.urls)
