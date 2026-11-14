using Pkg
using Pkg.Types: PackageSpec, VersionSpec, Context, EnvCache, registry_resolve!, PRESERVE_NONE
using Pkg.API: handle_package_input!
using Pkg.Operations: targeted_resolve
using Pkg: TOML
using BinaryBuilderSources: registry_slice_hash, dev_content_hash, tracks_branch, jll_resolve_cache, atomic_write

# Bumped whenever the format of the files in the resolution cache changes
const RESOLVE_CACHE_FORMAT = 1

"""
    resolve_cache_key(pkgs, julia_version, registries)

Return the name under which `resolve()` caches its resolution of `pkgs`, or `nothing`
if that resolution must not be cached.  Resolution is a pure function of the requested
packages, the julia version (along with the running julia's stdlibs and resolver) and
the registry entries that the packages can reach, which `registry_slice_hash()`
identifies.  A package that tracks a branch can resolve differently at any moment, so
it is never cached.
"""
function resolve_cache_key(pkgs::Vector{PackageSpec}, julia_version, registries)
    io = IOBuffer()
    println(io, "format = ", RESOLVE_CACHE_FORMAT)
    println(io, "julia = ", VERSION)
    println(io, "julia_version = ", repr(julia_version))
    for pkg in pkgs
        tracks_branch(pkg) && return nothing
        println(io, "pkg = ", join((repr(getfield(pkg, f)) for f in fieldnames(PackageSpec)), " "))
        println(io, "  dev_content = ", dev_content_hash(pkg))
        println(io, "  registry_slice = ", registry_slice_hash(pkg, registries))
    end
    return bytes2hex(sha1(take!(io)))
end

resolve_cache_path(key::String) = joinpath(jll_resolve_cache(string("resolve-", key)), "resolve.toml")

# Load a resolution stored by `save_resolution()`, or return `nothing` if there is none
# (or it can't be read).
function load_resolution(path::String)
    isfile(path) || return nothing
    try
        cache = TOML.parsefile(path)
        return [PackageSpec(;
            name = entry["name"],
            uuid = Base.UUID(entry["uuid"]),
            version = VersionNumber(entry["version"]),
            tree_hash = haskey(entry, "tree_hash") ? Base.SHA1(entry["tree_hash"]) : nothing,
        ) for entry in cache["packages"]]
    catch e
        @debug("Ignoring unreadable resolution cache", path, exception=e)
        return nothing
    end
end

# Store the output of `targeted_resolve()`.  Packages from a registry come back with
# only a name, UUID, version and tree hash, so that is all we store; a resolution
# containing anything else (such as a package from a path) is not stored.
function save_resolution(path::String, pkgs::Vector{PackageSpec})
    template(pkg) = PackageSpec(; pkg.name, pkg.uuid, pkg.version, pkg.tree_hash)
    for pkg in pkgs
        pkg.version isa VersionNumber || return
        all(getfield(pkg, f) == getfield(template(pkg), f) for f in fieldnames(PackageSpec)) || return
    end
    entries = map(pkgs) do pkg
        entry = Dict{String,Any}("name" => pkg.name, "uuid" => string(pkg.uuid), "version" => string(pkg.version))
        if pkg.tree_hash !== nothing
            entry["tree_hash"] = string(pkg.tree_hash)
        end
        return entry
    end
    atomic_write(path) do staging_path
        open(io -> TOML.print(io, Dict("packages" => entries)), staging_path, "w")
    end
    return
end

function resolve(pkgs::Vector{PackageSpec}; julia_version::Union{Nothing,VersionNumber}=VERSION)
    any_unresolved(pkgs) = any(pkg.uuid === nothing for pkg in pkgs)
    # There doesn't seem to be a better way to get an "empty" `EnvCache`
    # than to construct it off of an empty directory, so that's what we do
    mktempdir() do dir
        ctx = Context(;env=EnvCache(dir))

        # Don't mutate the user's input
        pkgs = deepcopy(pkgs)

        # Normalize each pkg
        handle_package_input!.(pkgs)

        cache_key = resolve_cache_key(pkgs, julia_version, ctx.registries)
        if cache_key !== nothing
            cached = load_resolution(resolve_cache_path(cache_key))
            cached !== nothing && return cached
        end

        # If any are unresolved, try to resolve them:
        if any_unresolved(pkgs)
            registry_resolve!(ctx.registries, pkgs)

            # If any are still unresolved, try updating the registry
            if any_unresolved(pkgs)
                specs = [Pkg.Registry.RegistrySpec(;name=r.name, uuid=r.uuid, url=r.repo, path=r.path) for r in ctx.registries]
                Pkg.Registry.update(specs; force=true)
                # Re-create `ctx` to get the new registry states
                ctx = Context(;env=EnvCache(dir))
                # The registries changed underneath the key we computed above
                cache_key = nothing
                registry_resolve!(ctx.registries, pkgs)

                # If any are _still_ unresolved, error out
                for pkg in pkgs
                    if pkg.uuid === nothing
                        throw(ArgumentError("Unable to resolve '$(pkg.name)', is it registered?"))
                    end
                end
            end
        end

        # Resolve to get versions
        pkgs, deps_map = Pkg.Operations.targeted_resolve(
            ctx.env,
            ctx.registries,
            pkgs,
            PRESERVE_NONE,
            julia_version,
        )
        if cache_key !== nothing
            save_resolution(resolve_cache_path(cache_key), pkgs)
        end
        return pkgs
    end
end

# Calls `resolve()` but only returns pkgs we asked for, in a Dict
function resolve_versions(pkgs::Vector{PackageSpec}; julia_version::Union{Nothing,VersionNumber}=VERSION)
    # Force all pkgs to have a UUID, so we can match them afterward
    registry_resolve!(Context().registries, pkgs)

    pkgs_uuids = Set(p.uuid for p in pkgs)
    pkgs = resolve(pkgs; julia_version)
    return Dict{String,PackageSpec}(pkg.name => pkg for pkg in pkgs if pkg.uuid ∈ pkgs_uuids)
end

"""
    update_pkgspec_versions_and_uuids!(pkgs::Vector{PackageSpec}, new_versions::Dict{String,PackageSpec})

Allows updating (in place!) a set of `PackageSpec`s with new versions and UUIDS.
Used to update the internal `PackageSpec` objects of `JLLSource`s with new results
from `resolve_pkg_versions()`.
"""
function update_pkgspec_versions_and_uuids!(pkgs::Vector{PackageSpec}, new_versions::Dict{String,PackageSpec})
    for pkg in pkgs
        if haskey(new_versions, pkg.name)
            pkg.version = new_versions[pkg.name].version
            pkg.uuid = new_versions[pkg.name].uuid
        end
    end
    return
end

"""
    resolve_versions!(jlls::Vector{JLLSource}; julia_version)

Given a vector of `JLLSource`'s, resolve any that are not already concretized
down to a specific version, 
"""
function resolve_versions!(jlls::Vector{JLLSource}; julia_version::Union{Nothing,VersionNumber}=VERSION)
    # Get a new set of versions for the jlls' package specs
    # Ignore any package that already has a `treehash` or a `repo` field.
    already_resolved(p) = p.tree_hash !== nothing ||
                         (p.repo !== nothing && p.repo.rev !== nothing)
    jll_pkgs = [jll.package for jll in jlls if !already_resolved(jll.package)]

    # Resolve these into a new set of versions
    resolved_pkgs = resolve_versions(jll_pkgs; julia_version)

    # Apply them to the JLLSource objects.  This relies on the fact that we are
    # updating the `PackageSpec`'s `version` field in-place!
    update_pkgspec_versions_and_uuids!(jll_pkgs, resolved_pkgs)
end

function filter_illegal_versionspecs!(pkgs::Vector{PackageSpec})
    for pkg in pkgs
        if pkg.repo.source !== nothing || pkg.repo.rev !== nothing
            pkg.version = VersionSpec()
        end
    end
end
