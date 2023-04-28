module BinaryBuilderSources
using Scratch

export AbstractSource

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
* target(::AbstractSource)::String
* retarget(::AbstractSource, new_target::String)::AbstractSource

Note that you must manually call `prepare()` before you call `deploy()`
or `content_hash()` upon an `AbstractSource`.

We define fallthrough methods for batch-preparing and deploying abstract
sources, but homogenous batches of certain sources (e.g. `JLLSource`s) may
define significantly more efficient methods for batch-`prepare()`.
"""
abstract type AbstractSource; end

export prepare, deploy, content_hash, target, retarget

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

# Default fall-through batch `prepare()` and `deploy()` definitions
function prepare(sources::Vector{<:AbstractSource}; verbose::Bool = false)
    # Special-case JLL sources, as we get a material benefit when batching those:
    jlls = JLLSource[s for s in sources if isa(s, JLLSource)]
    non_jlls = [s for s in sources if !isa(s, JLLSource)]
    if !isempty(jlls)
        prepare(jlls; verbose)
    end
    prepare.(non_jlls; verbose)
end
function deploy(sources::Vector{<:AbstractSource}, prefix::String)
    # Special-case JLL sources, as we get a material benefit when batching those:
    jlls = JLLSource[s for s in sources if isa(s, JLLSource)]
    non_jlls = [s for s in sources if !isa(s, JLLSource)]
    deploy(jlls, prefix)
    deploy.(non_jlls, Ref(prefix))
end
verify(sources::Vector{<:AbstractSource}) = all(verify.(sources))
function content_hash(sources::Vector{<:AbstractSource})
    content_hashes = content_hash.(sources)
    entries = [(basename(h), hex2bytes(basename(h)), TreeArchival.mode_dir) for apath in jll.artifact_paths]
    return SHA1Hash(TreeArchival.tree_node_hash(SHA.SHA1_CTX, entries))
end

"""
    target(as::AbstractSource)

Returns the `target` that this source will unpack itself into.
TODO: determine if we should remove this function.
"""
target(as::AbstractSource) = as.target

include("FileArchiveSource.jl")
include("DirectorySource.jl")
include("GeneratedSource.jl")
include("GitSource.jl")
include("JLLSource.jl")


# These values purposefully mirror those of BB2, which will automatically keep them in-sync
_source_download_cache = Ref{String}(@get_scratch!("source_download_cache"));
source_download_cache() = _source_download_cache[]
source_download_cache(new_path::String) = _source_download_cache[] = new_path

end # module
