using JLLPrefixes
using JLLPrefixes: PkgSpec, flatten_artifact_paths

struct JLLSource <: AbstractSource
    # The JLL that will be installed
    package::PkgSpec

    # The platform it will be installed for
    platform::AbstractPlatform

    # The subpath it will be installed to
    subprefix::String

    # The artifacts that belong to this JLL and must be linked in.
    # This is filled out by `prepare()`
    artifact_paths::Vector{String}

    function JLLSource(package::PkgSpec, platform::AbstractPlatform; subprefix = "")
        return new(
            package,
            platform,
            string(subprefix),
            String[],
        )
    end
end

function JLLSource(name::String, platform; subprefix = "", kwargs...)
    return JLLSource(PkgSpec(;name, kwargs...), platform; subprefix)
end

"""
    prepare(jlls::Vector{JLLSource})

Ensures that all given JLL sources are downloaded and ready to be used within
the build environment.
"""
function prepare(jlls::Vector{JLLSource}; verbose::Bool = true)
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
        pkgs = [jll.package for jll in platform_jlls]
        collect_artifact_metas(pkgs; platform, verbose, pkg_depot)

        # Next, collect each JLL individually, and fill out its
        for jll in platform_jlls
            art_paths = collect_artifact_paths([jll.package]; platform, pkg_depot)
            append!(jll.artifact_paths, flatten_artifact_paths(art_paths))
        end
    end
end

function verify(jlls::Vector{JLLSource})
    return all(!isempty(jll.artifact_paths) for jll in jlls)
end

"""
    deploy(jlls::Vector{JLLSource}, prefix::String)

Deploy the previously-downloaded JLL sources to the given `prefix`.
"""
function deploy(jlls::Vector{JLLSource}, prefix::String)
    # First, check to make sure the jlls have all been downloaded:
    checkprepared!("deploy", jlls)

    # Sort paths by subprefix
    jlls_by_prefix = Dict{String,Vector{JLLSource}}()
    for jll in jlls
        if jll.subprefix ∉ keys(jlls_by_prefix)
            jlls_by_prefix[jll.subprefix] = JLLSource[]
        end
        push!(jlls_by_prefix[jll.subprefix], jll)
    end

    # Install each to their relative subprefixes
    for (subprefix, subprefix_jlls) in jlls_by_prefix
        install_path = joinpath(prefix, subprefix)
        mkpath(install_path)
        deploy_artifact_paths(install_path, vcat((jll.artifact_paths for jll in subprefix_jlls)...))
    end
end

# Compatibility; don't use these
prepare(jll::JLLSource; kwargs...) = prepare([jll]; kwargs...)
deploy(jll::JLLSource, prefix::String) = deploy([jll], prefix)
