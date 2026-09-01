using SHA, Pkg, TreeArchival
using Pkg.Registry: RegistryInstance, PkgEntry, registry_info, uuids_from_name
using JLLPrefixes: PkgSpec
using Base: UUID

# Every registered package implicitly depends on `julia`, which is not itself a
# registered package, so we never try to walk into it.
const JULIA_UUID = UUID("1222c4b2-2114-5bfd-aeef-88e4692bbb3e")

# Guards all of the memoization tables in this file.  Every one of them is keyed (at
# least in part) on a registry fingerprint, so entries never go stale; they only pile
# up, which `trim!()` deals with.
const registry_slice_lock = ReentrantLock()

# `RegistryInstance` package table -> that registry's fingerprint.  We key on
# `reg.pkgs` rather than the `RegistryInstance` itself because it is a mutable object,
# and so has the stable identity that `IdDict` needs, which an immutable `struct`
# does not.
const registry_fingerprints = IdDict{Any,String}()

# (registry fingerprint, package UUID) -> hash of that package's registry entry
const registry_entry_hashes = Dict{Tuple{String,UUID},String}()

# (fingerprints of all registries, root package UUIDs) -> slice hash
const registry_slice_hashes = Dict{Tuple{String,String},String}()

# Keep our memoization tables from growing without bound as registries get updated
# over the lifetime of a long-lived process; everything in them is cheap to recompute.
function trim!(cache::AbstractDict, max_length::Int)
    if length(cache) > max_length
        empty!(cache)
    end
    return cache
end

"""
    registry_fingerprint(reg::RegistryInstance)

Return a string that uniquely identifies the content of `reg`.

Registries that were downloaded as a compressed tarball carry the git tree hash of
their content, which is exactly what we want and costs nothing to look up.  Registries
that live as a plain directory on-disk (such as a `Universe`'s local registry) have no
such hash, so we calculate the very same thing ourselves, and memoize it: `Pkg` treats
a registry's content as constant for the lifetime of a `RegistryInstance`, and builds
a fresh instance whenever the on-disk content may have changed.
"""
function registry_fingerprint(reg::RegistryInstance)
    if reg.tree_info !== nothing
        return string(reg.uuid, "@", bytes2hex(reg.tree_info.bytes))
    end
    return lock(registry_slice_lock) do
        trim!(registry_fingerprints, 16)
        get!(registry_fingerprints, reg.pkgs) do
            # `mimic_git` so that a registry that is a git checkout hashes to the same
            # thing `git` would say its worktree is, rather than including its `.git`.
            digest = TreeArchival.treehash(SHA.SHA1_CTX, reg.path; mimic_git=true)
            return string(reg.uuid, "@", bytes2hex(digest))
        end
    end
end

"""
    registry_entry_hash(reg::RegistryInstance, entry::PkgEntry)

Hash everything the resolver can learn about a single package from a single registry:
its available versions and their tree hashes, and the dependencies and compat bounds
of each of those versions.  This is deliberately insensitive to the formatting of the
underlying `.toml` files, and to every other package in the registry.
"""
function registry_entry_hash(reg::RegistryInstance, entry::PkgEntry)
    key = (registry_fingerprint(reg), entry.uuid)
    cached = lock(() -> get(registry_entry_hashes, key, nothing), registry_slice_lock)
    cached !== nothing && return cached

    info = registry_info(entry)
    io = IOBuffer()
    println(io, entry.uuid, " ", entry.name)
    println(io, "repo = ", something(info.repo, ""), ", subdir = ", something(info.subdir, ""))
    for v in sort!(collect(keys(info.version_info)))
        vinfo = info.version_info[v]
        println(io, "  ", v, " = ", vinfo.git_tree_sha1, vinfo.yanked ? " (yanked)" : "")
    end
    # `deps`/`compat` are `Dict`s keyed by `VersionRange`, so sort them into a stable order.
    for (name, table) in (("deps", info.deps), ("compat", info.compat),
                          ("weak_deps", info.weak_deps), ("weak_compat", info.weak_compat))
        for vr in sort!(collect(keys(table)); by=string)
            entries = table[vr]
            for dep_name in sort!(collect(keys(entries)))
                println(io, "  ", name, "[", vr, "] ", dep_name, " = ", entries[dep_name])
            end
        end
    end

    entry_hash = bytes2hex(sha1(take!(io)))
    lock(registry_slice_lock) do
        trim!(registry_entry_hashes, 100_000)[key] = entry_hash
    end
    return entry_hash
end

"""
    slice_roots(pkg::PkgSpec, registries)

Return the UUIDs within `registries` that `pkg` could resolve to, or `nothing` if
`pkg` is not registered at all.  We look packages up by name (rather than by UUID)
because `pkg.uuid` is only filled out once `prepare()` has run, and `spec_hash()`
must not depend on whether that has happened yet.
"""
function slice_roots(pkg::PkgSpec, registries::Vector{RegistryInstance})
    if pkg.name !== nothing
        roots = UUID[]
        for reg in registries
            append!(roots, uuids_from_name(reg, pkg.name))
        end
        if !isempty(roots)
            return unique!(roots)
        end
    end
    if pkg.uuid !== nothing && any(haskey(reg.pkgs, pkg.uuid) for reg in registries)
        return [pkg.uuid]
    end
    return nothing
end

"""
    full_registries_hash(registries)

Hash the entirety of every registry, such that any change to any of them shows up.
This is our conservative fallback for packages we can't slice; see
[`registry_slice_hash`](@ref).
"""
function full_registries_hash(registries::Vector{RegistryInstance})
    return bytes2hex(sha1(string((registry_fingerprint(reg) for reg in registries)...)))
end

"""
    registry_slice_hash(pkg::PkgSpec, registries)

Hash only the pieces of `registries` that can change how `pkg` resolves: the registry
entries of `pkg` itself and, transitively, of everything it can depend on.  This is
what lets our JLL resolution caches (and everything keyed off of them, such as
`spec_hash(::JLLSource)`) survive a registry update that didn't touch any package we
care about.  `General` picks up new commits every few minutes, so hashing the whole
registry meant throwing away those caches on essentially every build.

We walk dependencies of *every* version of *every* package we reach, not just the
versions that happen to resolve today, because a new version of any of them is exactly
the kind of registry change that should invalidate the cache.  In practice these
closures are small: a leaf JLL reaches a handful of packages, and a heavy one like
`Qt6Base_jll` reaches a few dozen.

If `pkg` isn't registered anywhere we can't compute a closure, so we fall back to
hashing the registries in their entirety.
"""
function registry_slice_hash(pkg::PkgSpec, registries::Vector{RegistryInstance})
    roots = slice_roots(pkg, registries)
    if roots === nothing
        return full_registries_hash(registries)
    end

    fingerprints = join(registry_fingerprint(reg) for reg in registries)
    cache_key = (fingerprints, join(sort(string.(roots)), ","))
    cached = lock(() -> get(registry_slice_hashes, cache_key, nothing), registry_slice_lock)
    cached !== nothing && return cached

    # Breadth-first walk over the dependency graph as the registries describe it,
    # collecting a hash of each `(registry, package)` pair we touch along the way.
    entry_hashes = Tuple{String,String}[]
    seen = Set{UUID}(roots)
    frontier = copy(roots)
    while !isempty(frontier)
        uuid = pop!(frontier)
        for reg in registries
            entry = get(reg.pkgs, uuid, nothing)
            entry === nothing && continue
            push!(entry_hashes, (string(reg.uuid, "/", uuid), registry_entry_hash(reg, entry)))

            info = registry_info(entry)
            for table in (info.deps, info.weak_deps)
                for (_, deps) in table
                    for (_, dep_uuid) in deps
                        if dep_uuid != JULIA_UUID && dep_uuid ∉ seen
                            push!(seen, dep_uuid)
                            push!(frontier, dep_uuid)
                        end
                    end
                end
            end
        end
    end

    # The walk order depends on `Dict` iteration order, so sort before hashing.
    sort!(entry_hashes)
    slice_hash = bytes2hex(sha1(string(("$(k) = $(v)\n" for (k, v) in entry_hashes)...)))
    lock(registry_slice_lock) do
        trim!(registry_slice_hashes, 10_000)[cache_key] = slice_hash
    end
    return slice_hash
end
