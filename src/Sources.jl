"""
An `AbstractSource` is something used as source to build a package.

Concrete subtypes of `AbstractSource` are:

* [`ArchiveSource`](@ref): a remote archive to download from the Internet;
* [`FileSource`](@ref): a remote file to download from the Internet;
* [`GitSource`](@ref): a remote Git repository to clone;
* [`DirectorySource`](@ref): a local directory to mount.
* [`JLLSource`](@ref): A JLL to download/extract

All `AbstractSource`` objects must support the following operations:

* prepare(::AbstractSource)
* deploy(::AbstractSource, prefix::String)
* content_hash(::AbstractSource)::SHA1Hash

Note that you must manually call `prepare()` before you call `deploy()`
or `content_hash()` upon an `AbstractSource`.

We define fallthrough methods for batch-preparing and deploying abstract
sources, but homogenous batches of certain sources (e.g. `JLLSource`s) may
define significantly more efficient methods for batch-`prepare()`.
"""
abstract type AbstractSource; end


"""
    checkprepared!(me::String, type_name::String)

Helper function to throw an `InvalidStateException` when you've tried to
perform an operation upon an `AbstractSource` that requires you calling
`prepare()` beforehand (such as `deploy()` or `content_hash()`).
"""
function checkprepared!(caller::String, x::Union{Vector{T},T}, args...) where {T <: AbstractSource}
    if !verify(x, args...)
        throw(InvalidStateException(
            string("You must `prepare()` before you `", caller, "()` an object of type $(T)"),
            :MustPrepareFirst,
        ))
    end
end

"""
    noabspath!(target)

Helper function to throw if someone 
"""
function noabspath!(target)
    if isabspath(target)
        throw(ArgumentError("Target '$(target)' is an absolute path!"))
    end
end

include("sources/FileArchiveSource.jl")
include("sources/DirectorySource.jl")
include("sources/GitSource.jl")
include("sources/JLLSource.jl")


#=
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
