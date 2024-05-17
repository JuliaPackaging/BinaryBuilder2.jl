using BinaryBuilderProducts: @extract_kwargs
using BinaryBuilderSources: PkgSpec
export build_tarballs, BuildError

"""
    PlatformlessJLLSource

The `JLLSource` provided by `BinaryBuilderSources` requires specification
of the precise `platform` which will be downloaded and installed during the
`prepare()` and `deploy()` stages.  However, when specifying a build recipe
it is often convenient to just pass an object to `build_tarballs()` that
specifies the JLL name and version and `build_tarballs()` will impute the
platform based on whether it is passed in `target_dependencies` or
`host_dependencies`.  Note that this will not work for things like cross-
compiler toolchains or similar, where the platform story is more complex.

This object is usually created via the `JLLSource(pkg::PkgSpec)` or
`JLLSource(name::String)` type-piracy, e.g. when you omit the second
`platform` argument to the typical `JLLSource` object.  Additionally,
this object is only allowed to be passed to `build_tarballs()`, if you
are constructing a `BuildConfig` yourself manually, you must pass in
fully-concretized `JLLSource` objects, as this object is not a valid
`AbstractSource`.
"""
struct PlatformlessJLLSource
    package::PkgSpec
    target::String
end

function BinaryBuilderSources.JLLSource(pkg::PkgSpec; target="")
    return PlatformlessJLLSource(pkg, target)
end
function BinaryBuilderSources.JLLSource(name::String; target="", kwargs...)
    return JLLSource(PkgSpec(;name, kwargs...); target)
end

function apply_platform(pjs::PlatformlessJLLSource, platform::AbstractPlatform)
    return JLLSource(
        pjs.package,
        platform;
        target=pjs.target,
    )
end
apply_platform(s::AbstractSource, platform::AbstractPlatform) = s

const ConvenienceSource = Union{AbstractSource,PlatformlessJLLSource}

struct BuildError <: Exception
    message::String
    result::Union{BuildResult,ExtractResult,PackageResult}
end

function Base.showerror(io::IO, be::BuildError)
    stage_name(::BuildResult) = "build"
    stage_name(::ExtractResult) = "extract"
    stage_name(::PackageResult) = "package"

    println("BuildError ($(stage_name(be.result))): $(be.message)")
end



@warn("TODO: Write build_tarballs() adapter to split HostBuildDependencies, accept ARGS, and whatnot")
function build_tarballs(src_name::String,
                        src_version::VersionNumber,
                        sources::Vector{<:AbstractSource},
                        target_dependencies::Vector{<:ConvenienceSource},
                        host_dependencies::Vector{<:ConvenienceSource},
                        script::String,
                        platforms::Vector{<:AbstractPlatform},
                        products::Vector{<:AbstractProduct};
                        julia_compat::String = "1.6",
                        meta::AbstractBuildMeta = BuildMeta(;parse_build_tarballs_args(ARGS)...),
                        host::AbstractPlatform = default_host(),
                        extract_script::String = "extract \${prefix}/*",
                        kwargs...)
    # First, build for all platforms
    extract_results = ExtractResult[]
    for platform in platforms
        build_config = BuildConfig(
            meta,
            src_name,
            src_version,
            sources,
            apply_platform.(target_dependencies, (platform,)),
            apply_platform.(host_dependencies, (host,)),
            script,
            platform;
            @extract_kwargs(kwargs, :host, :toolchains, :allow_unsafe_flags, :lock_microarchitecture)...,
        )
        build_result = build!(build_config; @extract_kwargs(kwargs, :deploy_root, :stdout, :stderr)...)
        if build_result.status != :success
            if build_result.status == :failed
                throw(BuildError("Build script failed", build_result))
            elseif build_result.status == :errored
                throw(BuildError("Unknown error", build_result))
            end
        end
        extract_config = ExtractConfig(
            build_result,
            extract_script,
            products;
            @extract_kwargs(kwargs, :metadir)...,
        )
        extract_result = extract!(extract_config)
        if extract_result.status != :success
            if extract_result.status == :failed
                throw(BuildError("Extract script failed", extract_result))
            elseif extract_result.status == :errored
                throw(BuildError("Unknown error", extract_result))
            end
        end
        push!(extract_results, extract_result)
    end
    # Take those extractions, and group them together as a single package
    package_config = PackageConfig(extract_results; @extract_kwargs(kwargs, :jll_name, :version_series)...)
    package_result = package!(package_config)
    if package_result.status != :success
        throw(BuildError("Unknown error", package_result))
    end
    return package_result
end
