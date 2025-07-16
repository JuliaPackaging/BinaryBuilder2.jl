module ScratchSpaceGarbageCollector
using TOML, Dates, Scratch
import Scratch: @get_scratch!
import Base: UUID

export Arena, @pkg_uuid, @get_scratch!, get_scratch!, MaxAgePolicy, MaxSizeLRUDropPolicy, garbage_collect!

macro pkg_uuid()
    return Scratch.find_uuid(__module__)
end


"""
    RetentionPolicy

A retention policy controls when things get deleted during a garbage collection.
Example RetentionPolicy types are:

- MaxAgePolicy
- MaxSizeLRUDropPolicy
"""
abstract type RetentionPolicy; end


# Within the `Arena` type, we map from key (e.g. sub-scratchspace)
# to one of these cache entry structs.  As we need to cache more
# information, just add entries onto this.
struct ArenaCacheEntry
    last_accessed::DateTime

    # Size of the entry on-disk
    size::Union{Nothing,UInt64}
end
ArenaCacheEntry() = ArenaCacheEntry(Dates.unix2datetime(0.0), nothing)
function ArenaCacheEntry(orig::ArenaCacheEntry; last_accessed=orig.last_accessed, size=orig.size)
    return ArenaCacheEntry(last_accessed, size)
end

"""
    Arena

An arena is a collection of scratch spaces that are grouped together
into a logical piece, with a set of policies applied to it.  You
garbage collect an entire arena at a time.
"""
struct Arena
    depot_path::String
    pkg_uuid::UUID
    name::String
    policies::Vector{RetentionPolicy}

    # The entries 
    entries::Dict{String,ArenaCacheEntry}
    
    function Arena(pkg_uuid::UUID, name::String, policies::Vector{<:RetentionPolicy}; depot_path::String = first(Base.DEPOT_PATH))
        arena = new(
            depot_path,
            pkg_uuid,
            name,
            policies,
            Dict{String,ArenaCacheEntry}(),
        )
        # We always `scan!()` once at the very beginning
        scan!(arena)
        return arena
    end
end

Arena(uuid::UUID, name::String, policy::RetentionPolicy; kwargs...) = Arena(uuid, name, [policy]; kwargs...)

Base.keys(arena::Arena) = keys(arena.entries)
Base.getindex(arena::Arena, key::String) = arena.entries[key]

# We differ from `scratch_dir` here in that we are locked to a particular depot
# and we automatically prepend our name in front of the key
function Scratch.scratch_dir(arena::Arena, args...)
    return abspath(arena.depot_path, "scratchspaces", string(arena.pkg_uuid), arena.name, args...)
end


function Scratch.get_scratch!(arena::Arena, key::AbstractString,
                              calling_pkg = arena.pkg_uuid;
                              time_gate::TimePeriod=Hour(24),
                              curr_time::DateTime = Dates.now())
    # Normalize this now, once.
    calling_pkg = Scratch.find_uuid(calling_pkg)

    # Get the top-level arena scratch space,
    arena_path = Scratch.get_scratch!(
        arena.pkg_uuid,
        arena.name,
        calling_pkg;
        depot_path=arena.depot_path,
        curr_time,
    )

    # Jump down to the given key:
    key = string(key)
    subscratch_path = joinpath(arena_path, key)
    mkpath(subscratch_path)

    # Track the subscratch path in the TOML as well:
    Scratch.track_scratch_access(
        calling_pkg,
        subscratch_path,
        arena.depot_path,
        time_gate,
        curr_time,
    )

    # And finally, update our own caches:
    arena.entries[key] = ArenaCacheEntry()
    update_last_accessed!(arena, key, curr_time)

    return subscratch_path
end

macro get_scratch!(arena, key)
    uuid = Base.PkgId(__module__).uuid
    return :(Scratch.get_scratch!($(esc(arena)), $(esc(key)), $(esc(uuid))))
end

function update_last_accessed!(arena::Arena, key::String, time::DateTime)
    arena.entries[key] = ArenaCacheEntry(
        arena.entries[key];
        last_accessed=max(
            arena.entries[key].last_accessed,
            time,
        )
    )
end

function update_size!(arena::Arena, key::String)
    arena.entries[key] = ArenaCacheEntry(
        arena.entries[key];
        size = recursive_filesize(scratch_dir(arena, key)),
    )
end

"""
    scan!(arena::Arena)

Scans the `scratch_usage.toml` file in the arena's depot, keeping elements that
belong to the arena's UUID and name.
"""
function scan!(arena::Arena)
    usage_file_path = joinpath(arena.depot_path, "logs", "scratch_usage.toml")
    if !isfile(usage_file_path)
        return
    end

    # This code adapted from `Pkg.jl/src/API.jl` in the `gc()` function.
    for (filename, infos) in TOML.parsefile(usage_file_path)
        # Drop anything in this usage log that doesn't belong to our arena (also not the arena itself)
        arena_prefix = string(scratch_dir(arena), "/")
        if !startswith(filename, arena_prefix)
            continue
        end
        filename = filename[length(arena_prefix)+1:end]
        if !haskey(arena.entries, filename)
            arena.entries[filename] = ArenaCacheEntry()
        end

        # Return the latest log entry for this filename
        update_last_accessed!(arena, filename, maximum(DateTime(info["time"]) for info in infos))
    end
end




"""
    MaxAgePolicy

This retention policy creates a maximum age beyond which any scratch space not
accessed by that time will be deleted.
"""
struct MaxAgePolicy <: RetentionPolicy
    age::Dates.TimePeriod
end
MaxAgePolicy(age_in_seconds::Number) = MaxAgePolicy(Second(age_in_seconds))

function identify_garbage(map::MaxAgePolicy, arena::Arena, garbage::Set{String}; curr_time::DateTime = Dates.now())
    # MaxAge policy is easy, anything that hasn't been accessed
    # since our age threshold gets set as garbage.
    age_threshold = curr_time - map.age
    for key in keys(arena)
        if last_accessed(arena, key) < age_threshold
            @debug("garbage!", key, last_accessed(arena, key), age_threshold)
            push!(garbage, key)
        end
    end
end


"""
    MaxSizeLRUDropPolicy

This retention policy creates a maximum size that, once exceeded, causes the
least-recently used scratch spaces to be dropped until we fall below the size
threshold.

Nice improvements to this policy would introduct some weighted randomness,
weighting by age, size, etc...
We should also probably cache filesize for directories in a TOML somewhere,
then update them only when a file has been modified within the directory
structure, so that we don't have to scan the entire arena every time we
start up a new Julia process.
"""
struct MaxSizeLRUDropPolicy <: RetentionPolicy
    size::UInt64
end
MaxSizeLRUDropPolicy(size::Integer) = MaxSizeLRUDropPolicy(UInt64(size))

function identify_garbage(mslru::MaxSizeLRUDropPolicy, arena::Arena, garbage::Set{String}; curr_time::DateTime = Dates.now())
    arena_size = filesize(arena)
    if arena_size > mslru.size
        keys_by_oldest = sort(collect(keys(arena)); by=k->last_accessed(arena, k))
        
        # Drop keys until we get under the size limit
        while arena_size > mslru.size
            key = popfirst!(keys_by_oldest)
            arena_size -= filesize(arena, key)
            push!(garbage, key)
        end
    end
end

# Useful for a future weighted LRU policy or something
function recursive_filesize(dirpath::String)
    total = 0
    for (root,dirs,files) in walkdir(dirpath)
        for f in files
            total += filesize(joinpath(root,f))
        end
    end
    return total
end






function last_accessed(arena::Arena, key::String)
    return arena.entries[key].last_accessed
end

function Base.filesize(arena::Arena, key::String)
    if arena.entries[key].size === nothing
        update_size!(arena, key)
    end
    return arena.entries[key].size
end
Base.filesize(arena::Arena) = sum(filesize.((arena,), keys(arena)))

function garbage_collect!(arena::Arena; curr_time::DateTime = Dates.now())
    # Collect garbage according to all policies
    garbage = Set{String}()
    for policy in arena.policies
        identify_garbage(policy, arena, garbage; curr_time)
    end

    # Delete all garbage
    for key in garbage
        rm(scratch_dir(arena, key); recursive=true, force=true)
    end
end

end # module
