module BinaryBuilderSources
using Scratch, Pkg, TimerOutputs
import FileWatching

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

function spec_hash(sources::Vector{<:AbstractSource}; kwargs...)
    hashes = bytes2hex.(spec_hash.(sources; kwargs...))
    return SHA1Hash(sha1(string(hashes...)))
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


include("Retry.jl")
include("FileArchiveSource.jl")
include("DirectorySource.jl")
include("GeneratedSource.jl")
include("GitSource.jl")
include("RegistrySlices.jl")
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

"""
    with_download_lock(f, path)

Run `f()` while holding an inter-process lock on the cache entry at `path` (a pidfile
named `\$(path).lock`), so that several BinaryBuilder2 processes sharing one source
download cache never download into the same location at once.  Whoever gets the lock
first does the download, and the rest block until it is done, after which they find the
source already present.  `prepare()` of every source that downloads into the shared
cache should wrap its download in this.

The lock is refreshed while it is held, and a lock left behind by a process that died
is taken over once it goes stale.  It is not reentrant: do not nest two calls on the
same `path`.
"""
function with_download_lock(f::Function, path::String)
    mkpath(dirname(path))
    return FileWatching.Pidfile.mkpidlock(f, string(path, ".lock"); stale_age=60)
end

"""
    atomic_write(f, path::String; directory::Bool = false)

Call `f(staging_path)` to write a file (or, with `directory = true`, fill a directory) at
a staging location next to `path`, then rename it into place, so that other readers
never see a partially written `path`.  Returns `path`.

With `directory = true`, an existing directory at `path` is never replaced while it is
in use: a populated directory is kept (and the staged copy discarded), and an empty
result is published with `mkdir()`, which leaves an existing directory in place.  An
existing empty directory is only replaced by a populated one.
"""
function atomic_write(f::Function, path::String; directory::Bool = false)
    parent = dirname(abspath(path))
    mkpath(parent)
    # `mktempdir()` creates a mode-0700 directory, so it only holds the staging
    # location, which `f` (or `mkdir()`) creates with the usual mode.
    staging_parent = mktempdir(parent; prefix=string(".", basename(path), ".staging-"), cleanup=false)
    try
        staging_path = joinpath(staging_parent, basename(path))
        if directory
            mkdir(staging_path)
        end
        f(staging_path)
        if directory && isempty(readdir(staging_path))
            # `rename(2)` would replace an existing empty directory, which may be
            # in use (e.g. as an overlay lower dir); `mkdir(2)` never replaces it.
            try
                mkdir(path)
            catch e
                isdir(path) || rethrow(e)
            end
            return path
        end
        try
            # `rename(2)` replaces a file or an empty directory, but fails on a
            # non-empty directory, so only the first complete directory is published.
            Base.Filesystem.rename(staging_path, path)
        catch e
            if !directory || !isdir(path) || isempty(readdir(path))
                rethrow(e)
            end
        end
    finally
        rm(staging_parent; recursive=true, force=true)
    end
    return path
end

end # module
