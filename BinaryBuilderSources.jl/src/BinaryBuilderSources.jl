module BinaryBuilderSources
using Scratch, Pkg, TimerOutputs

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
* spec_hash(::AbstractSource; kwargs...)::SHA1Hash
* content_hash(::AbstractSource)::SHA1Hash
* target(::AbstractSource)::String
* retarget(::AbstractSource, new_target::String)::AbstractSource
* source(::AbstractSource)::String

Note that you must manually call `prepare()` before you call `deploy()`
or `content_hash()` upon an `AbstractSource`, whereas you do not need to
call `prepare()` before you call `spec_hash()`.

We define fallthrough methods for batch-preparing and deploying abstract
sources, but homogenous batches of certain sources (e.g. `JLLSource`s) may
define significantly more efficient methods for batch-`prepare()`. Note
that batches of JLLSources in particular should have `deduplicate_jlls()`
applied to them before `prepare()` is even called.
"""
abstract type AbstractSource; end

export prepare, deploy, spec_hash, content_hash, target, retarget, source

"""
    checkprepared!(me::String, x::AbstractSource)

Helper function to throw an `InvalidStateException` when you've tried to
perform an operation upon an `AbstractSource` that requires you calling
`prepare()` beforehand (such as `deploy()` or `content_hash()`).
"""
function checkprepared!(caller::String, x::AbstractSource, args...; kwargs...)
    if !verify(x, args...; kwargs...)
        throw(InvalidStateException(
            string("You must `prepare()` before you `", caller, "()` an object of type $(typeof(x)): $(x)"),
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
function prepare(sources::Vector{<:AbstractSource};
                 verbose::Bool = false,
                 force::Bool = false,
                 depot::String = default_jll_source_depot(),
                 registries::Vector{Pkg.Registry.RegistryInstance} = Pkg.Registry.reachable_registries(; depots=[depot]),
                 project_dir::String = mktempdir(),
                 to::TimerOutput = TimerOutput())
    # Special-case JLL sources, as we get a material benefit when batching those:
    jlls = JLLSource[s for s in sources if isa(s, JLLSource)]
    non_jlls = [s for s in sources if !isa(s, JLLSource)]
    if !isempty(jlls)
        prepare(jlls; verbose, project_dir, depot, registries, force, to)
    end
    prepare.(non_jlls; verbose)
    return nothing
end
function deploy(sources::Vector{<:AbstractSource}, prefix::String)
    # Special-case JLL sources, as we get a material benefit when batching those:
    jlls = JLLSource[s for s in sources if isa(s, JLLSource)]
    non_jlls = [s for s in sources if !isa(s, JLLSource)]
    deploy(jlls, prefix)
    deploy.(non_jlls, Ref(prefix))
    return nothing
end
verify(sources::Vector{<:AbstractSource}) = all(verify.(sources))
function content_hash(sources::Vector{<:AbstractSource})
    content_hashes = content_hash.(sources)
    entries = [(bytes2hex(h), collect(h.data), TreeArchival.mode_dir) for h in content_hashes]
    return SHA1Hash(TreeArchival.tree_node_hash(SHA.SHA1_CTX, entries))
end

"""
    target(as::AbstractSource)

Returns the `target` that this source will unpack itself into.
TODO: determine if we should remove this function.
"""
target(as::AbstractSource) = as.target

"""
    source(as::AbstractSource)

Return a `String` representation of the source `as` stems from.
This is typically some kind of `URL`.  Pair this with `content_hash(as)`
for reproducible source tracking.
"""
function source end

"""
    content_hash(as::AbstractSource)

Return a `SHA1Hash` representing the content hash of the given source.  This requires
that you have called `prepare(as)`, as it generally relies upon having the actual bits
of the source on-disk.  Use `spec_hash(as)` for a hash that depends only on the
specification of the source.
"""
function content_hash end


include("FileArchiveSource.jl")
include("DirectorySource.jl")
include("GeneratedSource.jl")
include("GitSource.jl")
include("JLLSource.jl")

# This is purposefully a Ref{Function} so that it can be replaced by `BinaryBuilder2`,
# which will replace it with an `Arena` object from `ScratchSpaceGarbageCollector`.
# Would be nice to replace this with something stronger (TypedCallable?) so that we
# can enforce a return type guarantee.
_source_download_cache = Ref{Function}(name -> joinpath(@get_scratch!("source_download_cache"), name))
_generated_source_cache = Ref{Function}(name -> joinpath(@get_scratch!("generated_source_cache"), name))
_jll_resolve_cache = Ref{Function}(name -> joinpath(@get_scratch!("jll_resolve_cache"), name))

source_download_cache(name::String) = _source_download_cache[](name)
generated_source_cache(name::String) = _generated_source_cache[](name)
jll_resolve_cache(name::String) = _jll_resolve_cache[](name)

end # module
