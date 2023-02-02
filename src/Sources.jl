using LibGit2, Scratch, Downloads, SHA

export ArchiveSource, FileSource, GitSource, DirectorySource

"""
An `AbstractSource` is something used as source to build a package.

Concrete subtypes of `AbstractSource` are:

* [`ArchiveSource`](@ref): a remote archive to download from the Internet;
* [`FileSource`](@ref): a remote file to download from the Internet;
* [`GitSource`](@ref): a remote Git repository to clone;
* [`DirectorySource`](@ref): a local directory to mount.
"""
abstract type AbstractSource; end


"""
All AbstractSource objects must support the following operations:

* download(::AbstractSource)
* deploy(::AbstractSource, prefix::String)
"""

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
struct ArchiveSource <: AbstractSource
    url::String
    hash::MultiHash
    target::String
end

function noabspath!(target)
    if isabspath(target)
        throw(ArgumentError("Target '$(target)' is an absolute path!"))
    end
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

struct FileSource <: AbstractSource
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

# We deal with these together so often, might as well make this a thing
const FileArchiveSource = Union{FileSource,ArchiveSource}


"""
    download_cache_path(fas::FileArchiveSource, download_cache::String)

Returns the full path to the file that will be written to in `download(as)`
"""
function download_cache_path(fas::FileArchiveSource, download_cache::String = source_download_cache())
    return joinpath(download_cache, bytes2hex(fas.hash))
end

using MultiHashParsing: hash_like
function verify(fas::FileArchiveSource, download_cache::String = source_download_cache())
    # If the file does not exist at all, fail verification
    source_path = download_cache_path(fas, download_cache)
    if !isfile(source_path)
        @debug("Verification fast-fail; file nonexistent", source=fas, source_path)
        return false
    end

    # This is a lovely variable name
    hash_cache_path = string(source_path, ".", MultiHashParsing.hash_prefix(fas.hash))

    # If there is no cached hash file or it is stale, re-hash the file here
    # Note that `stat()` of a nonexistant file returns `0`.
    if stat(hash_cache_path).mtime < stat(source_path).mtime
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

function download(fas::FileArchiveSource)
    # Only download if verification fails
    download_cache = source_download_cache()
    if !verify(fas, download_cache)
        download_target = download_cache_path(fas, download_cache)

        # Ensure the directory that should hold this source exists, otherwise `download()` fails
        mkpath(dirname(download_target))
        Downloads.download(fas.url, download_target)

        # If we still don't verify properly, throw an error
        if !verify(fas, download_cache)
            throw(ArgumentError("Invalid hash"))
        end
    end
end

function deploy(as::ArchiveSource, prefix::String)
    download_cache = source_download_cache()
    if !verify(as, download_cache)
        throw(InvalidStateException("You must `download()` before you `deploy()` an `ArchiveSource`", :NotDownloaded))
    end

    # We unpack the archive into the desired location
    unarchive(download_cache_path(as, download_cache), joinpath(prefix, as.target))
end

function deploy(fs::FileSource, prefix::String)
    download_cache = source_download_cache()
    if !verify(fs, download_cache)
        throw(InvalidStateException("You must `download()` before you `deploy()` a `FileSource`", :NotDownloaded))
    end

    # We just copy the file into the desired location
    target_path = joinpath(prefix, fs.target)
    mkpath(dirname(target_path))
    cp(download_cache_path(fs, download_cache), target_path)
end

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

Returns the full path to the local clone that will be written to in `download(gs)`
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

function download(gs::GitSource)
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
    if !verify(gs, download_cache)
        throw(InvalidStateException("You must `download()` before you `deploy()` a `GitSource`", :NotDownloaded))
    end

    # We check the git repository out into the given target
    repo_path = download_cache_path(gs, download_cache)
    target_path = joinpath(prefix, gs.target)
    mkpath(dirname(target_path))
    LibGit2.with(LibGit2.clone(repo_path, target_path)) do repo
        LibGit2.checkout!(repo, bytes2hex(gs.hash))
    end
end

#=
"""
    DirectorySource(path::String; target::String = basename(path), follow_symlinks=false)

Specify a local directory to mount from `path`.

The content of the directory will be mounted in `\${WORKSPACE}/srcdir`, or in
its subdirectory pointed to by the optional keyword `target`, if provided.
Symbolic links are replaced by a copy of the target when `follow_symlinks` is
`true`.
"""
struct DirectorySource <: AbstractSource
    path::String
    target::String
    follow_symlinks::Bool
end
# When setting up the source, by default we won't follow symlinks.  However,
# there are cases where this is necessary, for example when we have symlink
# patchsets across multiple versions of GCC, etc...
DirectorySource(path::String; target::String = "", follow_symlinks::Bool=false) =
    DirectorySource(path, target, follow_symlinks)

# This is not meant to be used as source in the `build_tarballs.jl` scripts but
# only to set up the source in the workspace.
struct SetupSource{T<:AbstractSource}
    path::String
    hash::String
    target::String
    follow_symlinks::Bool
end
# `follow_symlinks` is used only for DirectorySource, let's have a method without it.
SetupSource{T}(path::String, hash::String, target::String) where {T} =
    SetupSource{T}(path, hash, target, false)
# This is used in wizard/obtain_source.jl to automatically guess the parameter
# of SetupSource from the URL
function SetupSource(url::String, path::String, hash::String, target::String)
    if endswith(url, ".git")
        return SetupSource{GitSource}(path, hash, target)
    elseif any(endswith(url, ext) for ext in archive_extensions)
        return SetupSource{ArchiveSource}(path, hash, target)
    else
        return SetupSource{FileSource}(path, hash, target)
    end
end

struct PatchSource
    name::String
    patch::String
end

function download_source(source::T; verbose::Bool = false, downloads_dir = storage_dir("downloads")) where {T<:Union{ArchiveSource,FileSource}}
    gettarget(s::ArchiveSource) = s.target
    gettarget(s::FileSource) = s.filename
    if isfile(source.url)
        # Immediately abspath() a src_url so we don't lose track of
        # sources given to us with a relative path
        src_path = abspath(source.url)

        # And if this is a locally-sourced tarball, just verify
        verify(src_path, source.hash) || error("Verification failed")
    else
        # Otherwise, download and verify
        src_path = joinpath(downloads_dir, string(source.hash, "-", basename(source.url)))
        download_verify(source.url, source.hash, src_path)
    end
    return SetupSource{T}(src_path, source.hash, gettarget(source))
end

function cached_git_clone(url::String;
                          hash_to_check::Union{Nothing, String} = nothing,
                          downloads_dir::String = storage_dir("downloads"),
                          verbose::Bool = false,
                          )
    repo_path = joinpath(downloads_dir, "clones", string(basename(url), "-", bytes2hex(sha256(url))))
    if isdir(repo_path)
        if verbose
            @info("Using cached git repository", url, repo_path)
        end
        # If we didn't just mercilessly obliterate the cached git repo, use it!
        LibGit2.with(LibGit2.GitRepo(repo_path)) do repo
            # In some cases, we know the hash we're looking for, so only fetch() if
            # this git repository doesn't contain the hash we're seeking
            # this is not only faster, it avoids race conditions when we have
            # multiple builders on the same machine all fetching at once.
            if hash_to_check === nothing || !LibGit2.iscommit(hash_to_check, repo)
                LibGit2.fetch(repo)
            end
        end
    else
        if verbose
            @info("Cloning git repository", url, repo_path)
        end
        # If there is no repo_path yet, clone it down into a bare repository
        LibGit2.clone(url, repo_path; isbare=true)
    end
    return repo_path
end

function download_source(source::GitSource; kwargs...)
    src_path = cached_git_clone(source.url; hash_to_check=source.hash, kwargs...)
    return SetupSource{GitSource}(src_path, source.hash, source.target)
end

function download_source(source::DirectorySource; verbose::Bool = false)
    if !isdir(source.path)
        error("Could not find directory \"$(source.path)\".")
    end
    if verbose
        @info "Directory \"$(source.path)\" found"
    end
    return SetupSource{DirectorySource}(abspath(source.path), "", source.target, source.follow_symlinks)
end

"""
    download_source(source::AbstractSource; verbose::Bool = false)

Download the given `source`.  All downloads are cached within the
BinaryBuilder `downloads` storage directory.
"""
download_source

# Add JSON serialization to sources
JSON.lower(fs::ArchiveSource) = Dict("type" => "archive", extract_fields(fs)...)
JSON.lower(fs::FileSource) = Dict("type" => "file", extract_fields(fs)...)
JSON.lower(gs::GitSource) = Dict("type" => "git", extract_fields(gs)...)
JSON.lower(ds::DirectorySource) = Dict("type" => "directory", extract_fields(ds)...)

# When deserialiasing the JSON file, the sources are in the form of
# dictionaries.  This function converts the dictionary back to the appropriate
# AbstractSource.
function sourcify(d::Dict)
    if d["type"] == "directory"
        return DirectorySource(d["path"])
    elseif d["type"] == "git"
        return GitSource(d["url"], d["hash"])
    elseif d["type"] == "file"
        return FileSource(d["url"], d["hash"])
    elseif d["type"] == "archive"
        return ArchiveSource(d["url"], d["hash"])
    else
        error("Cannot convert to source")
    end
end

# XXX: compatibility functions.  These are needed until we support old-style
# Pair/String sources specifications.
coerce_source(source::AbstractSource) = source
function coerce_source(source::AbstractString)
    @warn "Using a string as source is deprecated, use DirectorySource instead"
    return DirectorySource(source)
end
function coerce_source(source::Pair)
    src_url, src_hash = source
    if endswith(src_url, ".git")
        @warn "Using a pair as source is deprecated, use GitSource instead"
        return GitSource(src_url, src_hash)
    elseif any(endswith(src_url, ext) for ext in archive_extensions)
        @warn "Using a pair as source is deprecated, use ArchiveSource instead"
        return ArchiveSource(src_url, src_hash)
    else
        @warn "Using a pair as source is deprecated, use FileSource instead"
        return FileSource(src_url, src_hash)
    end
end
=#
