using TreeArchival

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
end

function JLLSource(package::PkgSpec, platform::AbstractPlatform; target = "")
    noabspath!(target)
    return JLLSource(
        package,
        platform,
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

function default_jll_source_depot()
    depot = joinpath(source_download_cache(), "jllsource_depot")
    if !isdir(joinpath(depot, "registries"))
        Pkg.Registry.download_registries(devnull, copy(Pkg.Registry.DEFAULT_REGISTRIES), depot)
    end
    return depot
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
                 force::Bool = false)
    # Split JLLs by platform:
    jlls_by_platform_by_prefix = Dict{AbstractPlatform,Dict{String,Vector{JLLSource}}}()
    registries = nothing

    for jll in jlls
        # If this JLL does not yet have a UUID, resolve it by name with respect
        # to the given depot.  Ideally the user would have filled this in, but
        # we don't always get what we want.
        if jll.package.uuid === nothing
            if registries === nothing
                registries = Pkg.Registry.reachable_registries(; depots=[depot])
            end
            jll.package.uuid = Pkg.Types.registered_uuid(registries, jll.package.name)
            if jll.package.uuid === nothing
                throw(ArgumentError("Cannot specify a non-registered JLL ($(jll.package.name)) without also specifying its UUID!"))
            end
        end

        # If this JLL has been previously prepared, don't bother to prepare it
        # again, unless we've set `force` to re-prepare the source.
        if !isempty(jll.artifact_paths)
            if force
                empty!(jll.artifact_paths)
            else
                continue
            end
        end

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
            art_paths = collect_artifact_paths([jll.package for jll in jlls_slice]; platform, project_dir, pkg_depot=depot, verbose)
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
        deploy_artifact_paths(install_path, unique(vcat((jll.artifact_paths for jll in target_jlls)...)))
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
