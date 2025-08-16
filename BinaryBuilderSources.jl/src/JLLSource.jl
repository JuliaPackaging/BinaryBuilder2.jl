using TreeArchival, TimerOutputs, TOML

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
            rm(store_path; recursive=true, force=true)
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
function jll_cache_name(jlls::Vector{JLLSource}, registries::Vector{Pkg.Registry.RegistryInstance})
    return bytes2hex(sha1(string(bytes2hex.(spec_hash.(jlls; registries))...)))
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
    function jll_cache_path(jlls::Vector{JLLSource})
        return joinpath(jll_resolve_cache(jll_cache_name(jlls, registries)), "cache.toml")
    end

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

        # Sort JLLs by platform, then by prefix.  JLLs in the same bucket will be resolved together.
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
            # Check to see if this slice of JLLs has been resolved before:
            cache_path = jll_cache_path(jlls_slice)

            # If we decide the cache is stale, we do this to clear it
            function clear_cache!()
                for jll in jlls_slice
                    empty!(jll.artifact_paths)
                end
                rm(cache_path; force=true)
            end

            # If `force` is set, drop any previously-stored artifact paths,
            # delete any cache files, and force resolution.
            if force || registries_outdated
                @debug("Emptying", force, registries_outdated)
                clear_cache!()
            end

            # If we have a cache path, try to load artifact paths for any JLL in the cache
            if ispath(cache_path)
                cache = TOML.parsefile(cache_path)

                for jll in jlls_slice
                    # This should be impossible since we address the cache by spec_hash, but let's be paranoid
                    if !haskey(cache, string(jll.package.uuid))
                        @error("JLLSource cache does not contain all UUIDs!  This should be impossible!", name=jll.package.name, uuid=string(jll.package.uuid), cache_path)
                        clear_cache!()
                        break
                    end

                    if isempty(jll.artifact_paths)
                        cached_paths = cache[string(jll.package.uuid)]

                        # Only use the cached paths if they actually exist on-disk (e.g. they haven't been Pkg.gc()'ed)
                        if all(isdir.(cached_paths))
                            append!(jll.artifact_paths, cached_paths)
                        end
                    end
                end
            end

            if any(isempty(jll.artifact_paths) for jll in jlls_slice)
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

                # Write out the result
                mkpath(dirname(cache_path))
                open(cache_path; write=true) do io
                    TOML.print(io, Dict(string(jll.package.uuid) => jll.artifact_paths for jll in jlls_slice))
                end
            end
        end
    end

    # Serialize all artifact paths into a hashed cache for each jll, so we don't have
    # to do this again until our next update.
    for jll in jlls
        
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
