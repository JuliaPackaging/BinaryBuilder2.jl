using TreeArchival, TimerOutputs

using Base.BinaryPlatforms, JLLPrefixes, Pkg, Dates
using JLLPrefixes: PkgSpec, flatten_artifact_paths

export JLLSource, deduplicate_jlls

struct JLLSource <: AbstractSource
    # The JLL that will be installed
    package::PkgSpec

    # The platform it will be installed for
    platform::AbstractPlatform

    # The subpath it will be installed to
    target::String

    # The artifacts that belong to this JLL and must be linked in.
    # This is filled out by `prepare()`
    artifact_paths::Vector{String}
end

function JLLSource(package::PkgSpec, platform::AbstractPlatform; target = "")
    noabspath!(target)
    return JLLSource(
        package,
        # Make sure our artifact matching happens as if we're a host platform,
        # e.g. `os_version` gets interpreted as a lower bound, etc...
        HostPlatform(platform),
        string(target),
        String[],
    )
end

function JLLSource(name::String, platform; target = "", kwargs...)
    noabspath!(target)
    return JLLSource(PkgSpec(;name, kwargs...), platform; target)
end

function retarget(jll::JLLSource, new_target::String)
    noabspath!(new_target)
    return JLLSource(jll.package, jll.platform, new_target, jll.artifact_paths)
end

"""
    deduplicate_jlls(jlls::Vector{JLLSource})

When we stack multiple independent resolutions of packages together into a
single prefix, we sometimes try to install dependencies more than once.  This
method deduplicates JLLs by attempting to constrain down to a single version
bound that satisfies all duplicate JLLs.  Usage:

```
jlls = deduplicate_jlls(jlls)
```

Note that `prepare(jlls)` will fail if you have not already called
`deduplicate_jlls(jlls)`; it checks upon every preparation.
"""
function deduplicate_jlls(jlls::Vector{JLLSource})
    # Point intersection, either exactly the same, or nothing at all
    function insersect_versions(v1::VersionNumber, v2::VersionNumber)
        if v1 == v2
            return v1
        else
            return Pkg.Types.VersionSpec([])
        end
    end
    insersect_versions(v1, v2) = v1 ∩ v2

    # First, deduplicate JLLs; occasionally, we are asked to install
    # the same JLL to the same prefix but with different version constraints,
    # e.g. GCC_jll requires `Zlib_jll`, and so does `Binutils_jll`.
    # We need to collapse down to a single version of `Zlib_jll` that
    # satisfies all constraints, if we can't do that, we should error here.
    seen_jlls = Dict{Tuple{String,String,AbstractPlatform},JLLSource}()
    for jll in jlls
        key = (jll.package.name, jll.target, jll.platform)
        if key ∈ keys(seen_jlls)
            # Compute new version that is the intersection of the versions
            new_version = insersect_versions(seen_jlls[key].package.version, jll.package.version)
            if !isa(new_version, VersionNumber) && isempty(new_version)
                throw(ArgumentError("Impossible constraints on $(jll.package.name): $(seen_jlls[key].package.version) ∩ $(jll.package.version)"))
            end
            seen_jlls[key].package.version = new_version
        else
            seen_jlls[key] = jll
        end
    end
    return values(seen_jlls)
end

"""
    make_depot_thin(thin_depot::String, parent_depot::String = Base.DEPOT_PATH[1])

This creates a "thin depot", which is one that shares important content stores
with its parent depot; typically the default user depot.  This allows us to have a
depot-like structure with its own registries, scratch spaces, etc... but sharing
all content-addressed pieces of information such as artifacts, packages,
compilation caches and logs.
"""
function make_thin_depot!(thin_depot::String, parent_depot::String = first(Base.DEPOT_PATH))
    mkpath(thin_depot)
    for store_name in ("artifacts", "packages", "compiled", "logs")
        store_path = joinpath(thin_depot, store_name)
        if !ispath(store_path) || !islink(store_path)
            rm(store_path; force=true)
            symlink(joinpath(parent_depot, store_name), store_path; dir_target=true)
        end
    end
end

function default_jll_source_depot()
    depot = source_download_cache("jllsource_depot")
    make_thin_depot!(depot)
    if !isdir(joinpath(depot, "registries"))
        Pkg.Registry.download_registries(devnull, copy(Pkg.Registry.DEFAULT_REGISTRIES), depot)
    end
    return depot
end

# This is different from `content_hash()` in that it represents all the _inputs_
# for this `JLLSource`, but not the _output_ of resolution.  This is used to
# build a mapping from inputs to outputs for caching.
function spec_hash(jll::JLLSource; registries::Vector{Pkg.Registry.RegistryInstance})
    pkg = jll.package
    return SHA1Hash(sha1(string(
        # These pieces of information are meant to be sensitive to anything that
        # could cause us to resolve to a different `artifact_path`, regardless of
        # changes to the registry.
        pkg.name,
        pkg.version != Pkg.Types.VersionSpec() ? string(pkg.version) : "",
        something(pkg.path, ""),
        something(pkg.tree_hash, ""),
        something(pkg.repo.source, ""),
        something(pkg.repo.rev, ""),
        triplet(jll.platform),
        # And then we add in registry information to be sensitive to that as well.
        bytes2hex.([reg.tree_info.bytes for reg in registries if reg.tree_info !== nothing])...,
    )))
end
function jll_cache_name(jll::JLLSource, registries::Vector{Pkg.Registry.RegistryInstance})
    return string(jll.package.name, "-", bytes2hex(spec_hash(jll; registries)))
end

"""
    prepare(jlls::Vector{JLLSource}; verbose=false, force=false)

Ensures that all given JLL sources are downloaded and ready to be used within
the build environment.  JLLs that already have `artifact_paths` filled out from
a previous invocation of `prepare()` will not be re-prepared, unless `force` is
set to `true`.
"""
function prepare(jlls::Vector{JLLSource};
                 project_dir::String = mktempdir(),
                 depot::String = default_jll_source_depot(),
                 verbose::Bool = false,
                 force::Bool = false,
                 registries::Vector{Pkg.Registry.RegistryInstance} = Pkg.Registry.reachable_registries(; depots=[depot]),
                 registry_refresh_interval::TimePeriod = Hour(1),
                 to::TimerOutput = TimerOutput())
    # Split JLLs by platform:
    jlls_by_platform_by_prefix = Dict{AbstractPlatform,Dict{String,Vector{JLLSource}}}()

    # Look up our extant registries immediately, and mark if they're out of date.
    if isempty(registries)
        # This should never happen, because `default_jll_source_depot()` should
        # automatically fill it out, so this only happens if someone gives us something weird.
        error("No reachable registries in depot '$(depot)'?")
    end

    time_thresh = Dates.datetime2unix(Dates.now() - registry_refresh_interval)
    registries_outdated = any(stat(reg.path).mtime < time_thresh for reg in registries)

    # We're going to cache the jlls by serializing the output of this preparation process
    # (that is, the `artifact_paths`) into a file named by the input of this preparation
    # process (that is, a hash of everything coming in).  While the output depends on
    # the state of the registry as well, we will avoid updating that (and thus invalidating
    # the results) unless the registry hasn't been updated in a while.
    function jll_cache_path(jll::JLLSource)
        return joinpath(jll_resolve_cache(jll_cache_name(jll, registries)), "cache.list")
    end
    jll_cache_paths = Dict{JLLSource,String}()

    for jll in jlls
        # If this JLL does not yet have a UUID, resolve it by name with respect
        # to the given depot.  Ideally the user would have filled this in, but
        # we don't always get what we want.
        if jll.package.uuid === nothing
            jll.package.uuid = Pkg.Types.registered_uuid(registries, jll.package.name)
            if jll.package.uuid === nothing
                throw(ArgumentError("Cannot specify a non-registered JLL ($(jll.package.name)) without also specifying its UUID!"))
            end
        end

        jll_cache_paths[jll] = jll_cache_path(jll)

        # If `force` is set, drop any previously-stored artifact paths,
        # delete any cache files, and force resolution.
        if force || registries_outdated
            @debug("Emptying", force, registries_outdated)
            empty!(jll.artifact_paths)

        # If we don't already have artifact_paths, try to load them from the cache file,
        # but only if our registries are not outdated.
        elseif isempty(jll.artifact_paths)
            if ispath(jll_cache_paths[jll])
                append!(jll.artifact_paths, filter(!isempty, readlines(jll_cache_paths[jll])))
                @debug("Loaded cache", jll)
            else
                @debug("No cache available", jll, jll_cache_paths[jll])
            end
        else
            # this case is that we have artifact paths that were previously
            # stored in the object, and we're good to try and use them.
            @debug("Attempting to re-use", jll)
        end

        # Check the `artifact_paths` to ensure none have been GC'ed while we weren't looking.
        if any(!isdir(art_path) for art_path in jll.artifact_paths)
            @debug("Emptying", jll, [isdir(art_path) for art_path in jll.artifact_paths])
            empty!(jll.artifact_paths)
        end

        # If we made it through the above with `jll.artifact_paths` filled, we can skip resolution
        if !isempty(jll.artifact_paths)
            @debug("Skipping resolution", jll)
            continue
        end

        # Otherwise, add this `jll` into the datastructures to be resolved below.
        if jll.platform ∉ keys(jlls_by_platform_by_prefix)
            jlls_by_platform_by_prefix[jll.platform] = Dict{String,Vector{JLLSource}}()
        end
        jlls_by_prefix = jlls_by_platform_by_prefix[jll.platform]
        if jll.target ∉ keys(jlls_by_prefix)
            jlls_by_prefix[jll.target] = JLLSource[]
        end
        push!(jlls_by_prefix[jll.target], jll)
    end

    # For each group of platforms and sharded by prefix, we are able to download as a group:
    # We can't do it all together because it's totally valid for us to try and download
    # two different versions of the same JLL to different prefixes.
    for (platform, platform_jlls_by_prefix) in jlls_by_platform_by_prefix
        for (prefix, jlls_slice) in platform_jlls_by_prefix
            @timeit to "collect_artifact_paths" begin
                art_paths = collect_artifact_paths([jll.package for jll in jlls_slice]; platform, project_dir, pkg_depot=depot, verbose)
            end
            for jll in jlls_slice
                @debug("Prepared", jll, cache_key=jll_cache_paths[jll])
                pkg = only([pkg for (pkg, _) in art_paths if pkg.uuid == jll.package.uuid])
                # Update `jll.package` with things from `pkg`
                if pkg.version != Pkg.Types.VersionSpec()
                    jll.package.version = pkg.version
                end
                if pkg.path !== nothing
                    jll.package.path = pkg.path
                end
                if pkg.tree_hash !== nothing
                    jll.package.tree_hash = pkg.tree_hash
                end
                if pkg.repo.source !== nothing || pkg.repo.rev !== nothing
                    jll.package.repo = pkg.repo
                end
                append!(jll.artifact_paths, art_paths[pkg])
            end
        end
    end

    # Serialize all artifact paths into a hashed cache for each jll, so we don't have
    # to do this again until our next update.
    for jll in jlls
        mkpath(dirname(jll_cache_paths[jll]))
        open(jll_cache_paths[jll]; write=true) do io
            truncate(io, 0)
            for art_path in jll.artifact_paths
                println(io, realpath(art_path))
            end
        end
    end
end

verify(jll::JLLSource) = !isempty(jll.artifact_paths)

"""
    deploy(jlls::Vector{JLLSource}, prefix::String)

Deploy the previously-downloaded JLL sources to the given `prefix`.
"""
function deploy(jlls::Vector{JLLSource}, prefix::String)
    # First, check to make sure the jlls have all been downloaded:
    for jll in jlls
        checkprepared!("deploy", jll)
    end

    # Sort paths by target
    jlls_by_prefix = Dict{String,Vector{JLLSource}}()
    for jll in jlls
        if jll.target ∉ keys(jlls_by_prefix)
            jlls_by_prefix[jll.target] = JLLSource[]
        end
        push!(jlls_by_prefix[jll.target], jll)
    end

    # Install each to their relative targets
    for (target, target_jlls) in jlls_by_prefix
        install_path = joinpath(prefix, target)
        mkpath(install_path)
        paths = unique(vcat((jll.artifact_paths for jll in target_jlls)...))
        try
            deploy_artifact_paths(install_path, paths)
        catch
            @error("Failed to deploy", install_path, paths)
            rethrow()
        end
    end
end

# Calculate the content hash as if all the `artifact_paths` within the
# JLLSources are in a directory together.
function content_hash(jll::JLLSource)
    checkprepared!("content_hash", jll)
    
    entries = [(basename(apath), hex2bytes(basename(apath)), TreeArchival.mode_dir) for apath in jll.artifact_paths]
    return SHA1Hash(TreeArchival.tree_node_hash(SHA.SHA1_CTX, entries))
end

# Compatibility; don't use these
prepare(jll::JLLSource; kwargs...) = prepare([jll]; kwargs...)
deploy(jll::JLLSource, prefix::String) = deploy([jll], prefix)

function source(jll::JLLSource)
    if jll.package.version != Pkg.Types.VersionSpec("*")
        return string(jll.package.name, "@v", jll.package.version)
    else
        return jll.package.name
    end
end
