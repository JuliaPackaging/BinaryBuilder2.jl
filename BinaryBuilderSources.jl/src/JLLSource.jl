using TreeArchival, TimerOutputs, TOML

using Base.BinaryPlatforms, JLLPrefixes, Pkg
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

    # Defaults to `true`, turn this off for collections of JLLs that
    # you know will clobber eachother, such as the bootstrap variants
    # of JLLs, which we don't control the contents of that closely.
    warn_on_overwrite::Bool

    # Defaults to `false`.  Turn this on for JLLs that are requested for a platform
    # carrying a strict tag (see `strict_tags`) but are by design not built once per
    # value of that tag, such as the target runtime libraries and sysroots that a
    # toolchain installs.  These get resolved as if the platform lacked the strict tags.
    exempt_from_strict_tags::Bool
end

function JLLSource(package::PkgSpec, platform::AbstractPlatform; target = "",
                   warn_on_overwrite::Bool = true, exempt_from_strict_tags::Bool = false)
    noabspath!(target)
    return JLLSource(
        package,
        # Make sure our artifact matching happens as if we're a host platform,
        # e.g. `os_version` gets interpreted as a lower bound, etc...
        HostPlatform(platform),
        string(target),
        String[],
        warn_on_overwrite,
        exempt_from_strict_tags,
    )
end

function JLLSource(name::String, platform; target = "", warn_on_overwrite = true,
                   exempt_from_strict_tags = false, kwargs...)
    noabspath!(target)
    return JLLSource(PkgSpec(;name, kwargs...), platform; target, warn_on_overwrite, exempt_from_strict_tags)
end

function retarget(jll::JLLSource, new_target::String)
    noabspath!(new_target)
    return JLLSource(jll.package, jll.platform, new_target, jll.artifact_paths,
                     jll.warn_on_overwrite, jll.exempt_from_strict_tags)
end

"""
    strict_tags()

Platform tags that change how a build's code is generated (e.g. `sanitize`), so that an
artifact may only stand in for a platform that has the same value for each of them,
including the tag being absent on both sides, rather than a tag present on only one side
being ignored as usual.  This is `Base.BinaryPlatforms.strict_presence_tags`
(JuliaLang/julia#63647), read on every use.  Julia versions without it can't build for
platforms with such tags (see `check_strict_tags_supported`).
"""
strict_tags() = isdefined(Base.BinaryPlatforms, :strict_presence_tags) ?
    Base.BinaryPlatforms.strict_presence_tags : ()

"""
    check_strict_tags_supported(platform::AbstractPlatform)

Error if `platform` has a `sanitize` tag but this Julia's platform matching does not
implement strict tags: it would select uninstrumented artifacts for it.
"""
function check_strict_tags_supported(platform::AbstractPlatform)
    if !isdefined(Base.BinaryPlatforms, :strict_presence_tags) && haskey(tags(platform), "sanitize")
        error("Resolving JLLs for $(triplet(platform)) needs a Julia whose platform matching ",
              "implements strict tags (`Base.BinaryPlatforms.strict_presence_tags`, ",
              "JuliaLang/julia#63647); Julia $(VERSION) does not.")
    end
end

"""
    drop_strict_tags(platform::AbstractPlatform)

Return a copy of `platform` without any of the `strict_tags()`.
"""
function drop_strict_tags(platform::AbstractPlatform)
    if !any(haskey(tags(platform), tag) for tag in strict_tags())
        return platform
    end
    platform = deepcopy(platform)
    for tag in strict_tags()
        delete!(tags(platform), tag)
    end
    return platform
end

"""
    resolution_platform(jll::JLLSource)

The platform that `jll`'s artifacts are selected for: its own platform, without the
`strict_tags()` if `jll.exempt_from_strict_tags` is set.
"""
resolution_platform(jll::JLLSource) = jll.exempt_from_strict_tags ? drop_strict_tags(jll.platform) : jll.platform

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
    # We use a Tuple[] here instead of a `Dict` because we need this function
    # to be stably-sorted.
    seen_jlls = Tuple{Tuple{String,String,AbstractPlatform},JLLSource}[]
    for jll in jlls
        key = (jll.package.name, jll.target, resolution_platform(jll))
        k_idx = findfirst(((k,j),) -> k == key, seen_jlls)
        if k_idx !== nothing
            seen_jll = seen_jlls[k_idx][2]
            # Compute new version that is the intersection of the versions
            new_version = insersect_versions(seen_jll.package.version, jll.package.version)
            if !isa(new_version, VersionNumber) && isempty(new_version)
                throw(ArgumentError("Impossible constraints on $(jll.package.name): $(seen_jll.package.version) ∩ $(jll.package.version)"))
            end
            seen_jll.package.version = new_version
        else
            push!(seen_jlls, (key, jll))
        end
    end
    return [jll for (_, jll) in seen_jlls]
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
        # A JLL developed by path (as a `Universe` does with what it builds) changes in
        # place when it is rebuilt: its path alone would keep stale caches alive.
        dev_content_hash(pkg),
        something(pkg.tree_hash, ""),
        something(pkg.repo.source, ""),
        something(pkg.repo.rev, ""),
        triplet(resolution_platform(jll)),
        # Which tags are strict decides which artifacts may be selected, and the list
        # can change at runtime (see `strict_tags()`).
        join(strict_tags(), ","),
        jll.target,
        # And then we add in registry information to be sensitive to that as well.  We
        # only mix in the slice of the registries that this JLL can actually resolve
        # against, so that the constant churn of unrelated packages in `General` doesn't
        # invalidate our caches.
        registry_slice_hash(pkg, registries),
    )))
end
function dev_content_hash(pkg)
    pkg.path === nothing && return ""
    h = ""
    for f in ("Project.toml", "Artifacts.toml")
        path = joinpath(pkg.path, f)
        h *= isfile(path) ? bytes2hex(sha1(read(path))) : "-"
    end
    return h
end

"""
    tracks_branch(pkg::PkgSpec)

Return `true` if `pkg` is added from a git repository by branch (or by the repository's
default branch) rather than by a commit, meaning that what it resolves to can change at
any moment.  Note that we treat any `rev` that isn't a full commit hash (such as a tag)
as a branch.
"""
function tracks_branch(pkg::PkgSpec)
    pkg.repo.source === nothing && return false
    return pkg.repo.rev === nothing || !occursin(r"^[0-9a-f]{40}$", pkg.repo.rev)
end

"""
    project_dep_uuids(pkg::PkgSpec)

Return the UUIDs of the dependencies listed in the `Project.toml` of a package that
is developed by path.  Returns `nothing` for any other package, or if it has no
`Project.toml`.
"""
function project_dep_uuids(pkg::PkgSpec)
    pkg.path === nothing && return nothing
    for name in Base.project_names
        path = joinpath(pkg.path, name)
        if isfile(path)
            deps = get(TOML.parsefile(path), "deps", Dict{String,Any}())
            return [Base.UUID(uuid) for uuid in values(deps)]
        end
    end
    return nothing
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
                 to::TimerOutput = TimerOutput(),
                 ignore_empty_registries::Bool = false)
    # Split JLLs by platform:
    jlls_by_platform_by_prefix = Dict{AbstractPlatform,Dict{String,Vector{JLLSource}}}()

    # Look up our extant registries immediately.
    if isempty(registries) && !ignore_empty_registries
        # This should never happen, because `default_jll_source_depot()` should
        # automatically fill it out, so this only happens if someone gives us something weird.
        @warn("No reachable registries in depot '$(depot)'?")
    end

    # We're going to cache the jlls by serializing the output of this preparation process
    # (that is, the `artifact_paths`) into a file named by the input of this preparation
    # process (that is, a hash of everything coming in).  That input hash covers the
    # registry entries of these JLLs and their dependencies (see `registry_slice_hash()`),
    # so a cache hit means the registries still describe the same resolution problem;
    # there is no need to second-guess it based on how long ago we last downloaded them.
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
        platform = resolution_platform(jll)
        if platform ∉ keys(jlls_by_platform_by_prefix)
            jlls_by_platform_by_prefix[platform] = Dict{String,Vector{JLLSource}}()
        end
        jlls_by_prefix = jlls_by_platform_by_prefix[platform]
        if jll.target ∉ keys(jlls_by_prefix)
            jlls_by_prefix[jll.target] = JLLSource[]
        end
        push!(jlls_by_prefix[jll.target], jll)
    end

    # Load UUIDs contained within our project, which were previously built by us
    built_uuids = Set{Base.UUID}()
    project_path = Pkg.Types.projectfile_path(project_dir)
    if isfile(project_path)
        project_deps = get(TOML.parsefile(project_path), "deps", String[])
        for (_, uuid) in project_deps
            push!(built_uuids, Base.UUID(uuid))
        end
    end

    # For each group of platforms and sharded by prefix, we are able to download as a group:
    # We can't do it all together because it's totally valid for us to try and download
    # two different versions of the same JLL to different prefixes.
    for (platform, platform_jlls_by_prefix) in jlls_by_platform_by_prefix
        check_strict_tags_supported(platform)
        for (prefix, jlls_slice) in platform_jlls_by_prefix
            # Check to see if this slice of JLLs has been resolved before:
            cache_path = jll_cache_path(jlls_slice)

            # A JLL that tracks a branch must be resolved by `Pkg` every time, so a slice
            # containing one is neither loaded from the cache nor stored into it.  Its `spec_hash()`
            # only knows the branch name, so the cache would happily hand us whatever the
            # branch pointed to back when we first resolved it.
            slice_tracks_branch = any(tracks_branch(jll.package) for jll in jlls_slice)

            # If we decide the cache is stale, we do this to clear it
            function clear_cache!()
                for jll in jlls_slice
                    empty!(jll.artifact_paths)
                end
                rm(cache_path; force=true)
            end

            # If `force` is set, drop any previously-stored artifact paths,
            # delete any cache files, and force resolution.
            if force
                @debug("Emptying", force)
                clear_cache!()
            end

            # If we have a cache path, try to load artifact paths for any JLL in the cache
            if ispath(cache_path) && !slice_tracks_branch
                cache = TOML.parsefile(cache_path)

                # Whether to load this cache. Either way the slice is resolved below if any
                # JLL in it is still without artifact paths (so never `continue` out of here).
                use_cache = true
                if !haskey(cache, "dep_uuids")
                    @debug("JLLSource cache lacks dep_uuids!  Cache corrupt or out of date!")
                    clear_cache!()
                    use_cache = false
                else
                    cached_dep_uuids = Set{Base.UUID}()
                    for uuid in cache["dep_uuids"]
                        push!(cached_dep_uuids, Base.UUID(uuid))
                    end

                    # Don't use the cache (but don't drop it) if any of the dep_uuids are in
                    # our universe (e.g. they were built by us previously). Decided for the
                    # whole slice before loading anything: a JLL that got its cached paths
                    # before we noticed would keep them, and resolution appends to them.
                    overridden_deps = intersect(built_uuids, cached_dep_uuids)
                    if !isempty(overridden_deps)
                        @debug("Universe overrides some deps, rejecting cache!", overridden_deps)
                        use_cache = false
                    end
                end

                for jll in (use_cache ? jlls_slice : JLLSource[])
                    # This should be impossible since we address the cache by spec_hash, but let's be paranoid
                    if !haskey(cache, string(jll.package.uuid))
                        @debug("JLLSource cache does not contain all UUIDs!  This should be impossible!", name=jll.package.name, uuid=string(jll.package.uuid), cache_path)
                        clear_cache!()
                        break
                    end

                    # Drop the package cache if has the wrong structure (this is how we gracefully deal with Elliot adding new fields)
                    package_cache = cache[string(jll.package.uuid)]
                    if !haskey(package_cache, "artifact_paths") || !haskey(package_cache, "tree_hash")
                        @debug("JLLSource cache lacks artifact paths or tree_hash!  Cache corrupt?", name=jll.package.name, uuid=string(jll.package.uuid), cache_path)
                        clear_cache!()
                        break
                    end

                    if isempty(jll.artifact_paths) || jll.package.tree_hash === nothing
                        cached_paths = package_cache["artifact_paths"]
                        tree_hash = Base.SHA1(package_cache["tree_hash"])

                        if !isa(cached_paths, Vector{<:AbstractString})
                            @debug("cached_paths is not a String[], clearing", name=jll.package.name, uuid=string(jll.package.uuid), cache_path, typeof(cached_paths))
                            clear_cache!()
                            break
                        end

                        # Only use the cached paths if they actually exist on-disk (e.g. they haven't been Pkg.gc()'ed)
                        if all(isdir.(cached_paths)) && isdir(Pkg.Operations.find_installed(jll.package.name, jll.package.uuid, tree_hash))
                            @debug("Loaded for $(jll.package.name)", cached_paths=basename.(cached_paths), platform, prefix)
                            append!(jll.artifact_paths, cached_paths)
                            jll.package.tree_hash = tree_hash
                        end
                    end
                end
            end

            if any(isempty(jll.artifact_paths) for jll in jlls_slice)
                @timeit to "collect_artifact_metas" begin
                    slice_deps = [jll.package for jll in jlls_slice]
                    artifact_metas = collect_artifact_metas(slice_deps; platform, project_dir, pkg_depot=depot, verbose)
                    check_missing_strict_artifacts(artifact_metas, platform; depot)
                    art_paths = collect_artifact_paths(artifact_metas, slice_deps)
                end
                for jll in jlls_slice
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
                    @debug("Prepared", jll, pkg, cache_path, prefix, platform)
                end

                # Write out the result into a cache so we don't have to go through this resolution again.
                # Only do that if all jll's had a `tree_hash`:
                if !slice_tracks_branch && all(jll.package.tree_hash !== nothing for jll in jlls_slice)
                    # Record here all recursive dependencies of the slice_deps, so that if we know one of
                    # these is changed (e.g. by being built as part of the current universe), then we
                    # invalidate this entire slice.
                    slice_uuids = union([m["dep_uuids"] for m in values(artifact_metas)]...)

                    mkpath(dirname(cache_path))
                    open(cache_path; write=true) do io
                        cache_entry = Dict(
                            # We record both the artifact path and the gitsha as those are the primary outputs
                            # of our resolution and artifact meta collection.
                            (string(jll.package.uuid) => Dict(
                                # Useful for debugging
                                "name" => jll.package.name,
                                "artifact_paths" => jll.artifact_paths,
                                "tree_hash" => string(jll.package.tree_hash),
                            )
                            for jll in jlls_slice)...,

                            # We also record a full set of UUIDs involved in this resolution, so that if we
                            # come back in the future but have rebuilt one of these as part of the build
                            # process, we can reject the cache (because we have overridden that UUID).
                            "dep_uuids" => string.(slice_uuids),
                        )
                        TOML.print(io, cache_entry)
                    end
                end
            end
        end
    end
end

"""
    check_missing_strict_artifacts(artifact_metas::Dict, platform::AbstractPlatform; depot)

Platform matching leaves a JLL without an artifact for `platform` if it only has one for
`platform` without its `strict_tags()` (e.g. an uninstrumented build for a
`sanitize+memory` platform).  That is an error rather than a silently empty dependency;
`JLLSource`s that legitimately need the latter set `exempt_from_strict_tags`.
"""
function check_missing_strict_artifacts(artifact_metas::Dict, platform::AbstractPlatform; depot::String)
    unstrict_platform = drop_strict_tags(platform)
    if unstrict_platform === platform
        return artifact_metas
    end
    platform_tags = tags(platform)
    for (pkg, meta) in artifact_metas
        if !isempty(meta["paths"])
            continue
        end
        artifacts_toml = find_artifacts_toml(pkg, depot)
        if artifacts_toml === nothing
            continue
        end
        unstrict_meta = Pkg.Artifacts.artifact_meta(pkg.name[1:end-4], artifacts_toml; platform=unstrict_platform)
        if unstrict_meta !== nothing
            present = join(("`$(tag)=$(platform_tags[tag])`" for tag in strict_tags() if haskey(platform_tags, tag)), ", ")
            error("$(pkg.name) has no artifact for $(triplet(platform)), only for $(triplet(unstrict_platform)); ",
                  "$(present) must match exactly (see `BinaryBuilderSources.strict_tags`, ",
                  "and `exempt_from_strict_tags` for JLLs that are not built per value of these tags)")
        end
    end
    return artifact_metas
end

# Locate the (Stdlib)Artifacts.toml of a JLL installed by `collect_artifact_metas()`
function find_artifacts_toml(pkg::PkgSpec, depot::String)
    if pkg.path !== nothing
        pkg_dirs = [pkg.path]
    elseif pkg.tree_hash !== nothing && pkg.uuid !== nothing
        slug = Base.version_slug(pkg.uuid, pkg.tree_hash)
        pkg_dirs = [joinpath(d, "packages", pkg.name, slug) for d in unique([depot; Base.DEPOT_PATH])]
    else
        return nothing
    end
    for pkg_dir in pkg_dirs, name in ("Artifacts.toml", "StdlibArtifacts.toml")
        if isfile(joinpath(pkg_dir, name))
            return joinpath(pkg_dir, name)
        end
    end
    return nothing
end

verify(jll::JLLSource) = !isempty(jll.artifact_paths)

function find_duplicate_artifact_paths(artifact_paths::Vector{String})
    seen_files = Dict{String,Any}()
    for art_path in artifact_paths
        for (root, dirs, files) in walkdir(art_path)
            for file in files
                rel_path = relpath(joinpath(root, file), art_path)
                if !haskey(seen_files, rel_path)
                    seen_files[rel_path] = []
                end
                push!(seen_files[rel_path], art_path)
            end
        end
    end

    # Only keep files that are listed in more than one artifact path
    filter!(seen_files) do (file, art_paths)
        length(art_paths) > 1
    end
    return seen_files
end

function find_overlapping_jlls(jlls::Vector{JLLSource})
    paths = unique(vcat((jll.artifact_paths for jll in jlls)...))
    dup_files = find_duplicate_artifact_paths(paths)

    conflicting_sets = Set{Set{String}}()
    for (file, art_paths) in dup_files
        push!(conflicting_sets, Set{String}(art_paths))
    end

    function find_jlls_for_art_path(art_path)
        jll_names = String[]
        for jll in jlls
            if art_path ∈ jll.artifact_paths
                push!(jll_names, jll.package.name)
            end
        end
        return jll_names
    end

    for conflicting_set in conflicting_sets
        @warn("Conflicting JLLs found:")
        for jll in jlls
            jll_arts = filter(p -> p ∈ jll.artifact_paths, collect(conflicting_set))
            if !isempty(jll_arts)
                println("$(jll.package.name):")
                for art in jll_arts
                    println("  - $(art)")
                    for (file, art_paths) in dup_files
                        if art ∈ art_paths
                            println("    - $(file)")
                        end
                    end
                end
            end
        end
    end
end

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
        # For debugging only
        #find_overlapping_jlls(target_jlls)

        install_path = joinpath(prefix, target)
        mkpath(install_path)
        paths = unique(vcat((jll.artifact_paths for jll in target_jlls)...))

        # If all JLLs in this prefix are marked as "do not warn on overwrite", then
        # pass that through to `deploy_artifact_paths(;verbose)`.
        warn_on_overwrite = any(jll.warn_on_overwrite for jll in target_jlls)
        try
            deploy_artifact_paths(install_path, paths; verbose = warn_on_overwrite)
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
