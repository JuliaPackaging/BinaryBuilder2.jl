using TreeArchival

using Base.BinaryPlatforms, JLLPrefixes
using JLLPrefixes: PkgSpec, flatten_artifact_paths

export JLLSource

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
    prepare(jlls::Vector{JLLSource})

Ensures that all given JLL sources are downloaded and ready to be used within
the build environment.
"""
function prepare(jlls::Vector{JLLSource}; verbose::Bool = false)
    # Split JLLs by platform and prefix:
    jlls_by_platform = Dict{AbstractPlatform,Vector{JLLSource}}()
    for jll in jlls
        if jll.platform ∉ keys(jlls_by_platform)
            jlls_by_platform[jll.platform] = JLLSource[]
        end
        push!(jlls_by_platform[jll.platform], jll)
    end

    # We store our downloaded JLL artifacts and whatnot in here
    pkg_depot = joinpath(source_download_cache(), "jllsource_depot")

    # For each group of platforms, we are able to download as a group:
    for (platform, platform_jlls) in jlls_by_platform
        # First, download everyone together, to give `JLLPrefixes` the
        # opportunity to parallelize downloads (we are not doing that
        # in `Pkg.add()` as of the time of this writing)
        pkgs = [deepcopy(jll.package) for jll in platform_jlls]
        collect_artifact_metas(pkgs; platform, verbose, pkg_depot)

        # Next, collect each JLL individually, and fill out its
        for jll in platform_jlls
            art_paths = collect_artifact_paths([jll.package]; platform, pkg_depot)
            append!(jll.artifact_paths, flatten_artifact_paths(art_paths))
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
    checkprepared!("deploy", jlls)

    # Sort paths by target
    jlls_by_prefix = Dict{String,Vector{JLLSource}}()
    for jll in jlls
        if jll.target ∉ keys(jlls_by_prefix)
            jlls_by_prefix[jll.target] = JLLSource[]
        end
        push!(jlls_by_prefix[jll.target], jll)
    end

    # Install each to their relative targetes
    for (target, target_jlls) in jlls_by_prefix
        install_path = joinpath(prefix, target)
        mkpath(install_path)
        deploy_artifact_paths(install_path, vcat((jll.artifact_paths for jll in target_jlls)...))
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

