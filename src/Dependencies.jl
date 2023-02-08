using JLLPrefixes
using JLLPrefixes: PkgSpec, flatten_artifact_paths

export JLLDependency

struct JLLDependency
    # The JLL that will be installed
    package::PkgSpec

    # The platform it will be installed for
    platform::AbstractPlatform

    # The subpath it will be installed to
    subprefix::String

    # The artifacts that belong to this JLL and must be linked in.
    # This is filled out by `download()`
    artifact_paths::Vector{String}

    function JLLDependency(package::PkgSpec, platform::AbstractPlatform; subprefix = "")
        return new(
            package,
            platform,
            string(subprefix),
            String[],
        )
    end
end

function JLLDependency(package::String, platform; subprefix = "")
    return JLLDependency(PkgSpec(;name = package), platform; subprefix)
end

"""
    download(deps::Vector{JLLDependency})

Ensures that all given dependencies are downloaded and ready to be used within
the build environment.
"""
function download(deps::Vector{JLLDependency}; verbose::Bool = true)
    # Split deps by platform and prefix:
    deps_by_platform = Dict{AbstractPlatform,Vector{JLLDependency}}()
    for dep in deps
        if dep.platform ∉ keys(deps_by_platform)
            deps_by_platform[dep.platform] = JLLDependency[]
        end
        push!(deps_by_platform[dep.platform], dep)
    end

    # For each group of platforms, we are able to download as a group:
    for (platform, platform_deps) in deps_by_platform
        # First, download everyone together, to give `JLLPrefixes` the
        # opportunity to parallelize downloads (we are not doing that
        # in `Pkg.add()` as of the time of this writing)
        pkgs = [dep.package for dep in platform_deps]
        collect_artifact_metas(pkgs; platform, verbose, pkg_depot=dependency_depot())

        # Next, collect each dep individually, and fill out its
        for dep in platform_deps
            art_paths = collect_artifact_paths([dep.package]; platform, pkg_depot=dependency_depot())
            append!(dep.artifact_paths, flatten_artifact_paths(art_paths))
        end
    end
end

"""
    deploy(prefix::String, deps::Vector{JLLDependency})

Deploy the previously-downloaded 
"""
function deploy(prefix::String, deps::Vector{JLLDependency})
    # First, check to make sure the deps have all been downloaded:
    if any(isempty(dep.artifact_paths) for dep in deps)
        throw(InvalidStateException("You must `download()` before you `deploy()` `JLLDependency`s", :NotDownloaded))
    end

    # Sort paths by subprefix
    deps_by_prefix = Dict{String,Vector{JLLDependency}}()
    for dep in deps
        if dep.subprefix ∉ keys(deps_by_prefix)
            deps_by_prefix[dep.subprefix] = JLLDependency[]
        end
        push!(deps_by_prefix[dep.subprefix], dep)
    end

    # Install each to their relative subprefixes
    for (subprefix, subprefix_deps) in deps_by_prefix
        install_path = joinpath(prefix, subprefix)
        mkpath(install_path)
        deploy_artifact_paths(install_path, vcat((dep.artifact_paths for dep in subprefix_deps)...))
    end
end
