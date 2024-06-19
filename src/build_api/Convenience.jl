using BinaryBuilderProducts: @extract_kwargs
using BinaryBuilderSources: PkgSpec
export build_tarballs, BuildError, run_build_tarballs, extract_build_tarballs

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


const _default_meta = Ref{Union{Nothing,AbstractBuildMeta}}(nothing)
function get_default_meta()
    if _default_meta[] === nothing
        return BuildMeta(;parse_build_tarballs_args(ARGS)...)
    end
    return _default_meta[]
end

function with_default_meta(f::Function, meta::AbstractBuildMeta)
    old_default_meta = _default_meta[]
    try
        _default_meta[] = meta
        f()
    finally
        _default_meta[] = old_default_meta
    end
end


function build_tarballs(src_name::String,
                        src_version::Union{String,VersionNumber},
                        sources::Vector,
                        target_dependencies::Vector,
                        host_dependencies::Vector,
                        script::String,
                        products::Vector;
                        meta::AbstractBuildMeta = get_default_meta(),
                        platforms::Vector = supported_platforms(),
                        host::AbstractPlatform = default_host(),
                        extract_script::String = "extract \${prefix}/*",
                        ignore_meta_target_list::Bool = false,
                        toolchain_builder::Function = default_toolchains,
                        toolchain_kwargs::Dict{Symbol,<:Any} = Dict{Symbol,Any}(),
                        kwargs...)
    # Ensure that our vectors can be properly typed
    sources = Vector{AbstractSource}(sources)
    target_dependencies = Vector{ConvenienceSource}(target_dependencies)
    host_dependencies = Vector{ConvenienceSource}(host_dependencies)
    platforms = Vector{AbstractPlatform}(platforms)
    products = Vector{AbstractProduct}(products)

    # By default, we always take the `meta.target_list` as the most
    # important, as the user should be able to override the platform list
    # if one is specified on the command-line.
    if !ignore_meta_target_list
        if !isempty(meta.target_list)
            platforms = meta.target_list
        end
    end

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
            target_if_crossplatform(platform);
            host,
            toolchains = toolchain_builder(CrossPlatform(host, target_if_crossplatform(platform)); toolchain_kwargs...),
            @extract_kwargs(kwargs, :allow_unsafe_flags, :lock_microarchitecture)...,
        )
        build_result = build!(
            build_config;
            extract_arg_hints = [(extract_script, products)],
            @extract_kwargs(kwargs, :deploy_root, :stdout, :stderr, :debug_modes, :disable_cache)...,
        )
        if build_result.status != :success
            if build_result.status == :failed
                throw(BuildError("Build script failed", build_result))
            elseif build_result.status == :errored
                throw(BuildError("Unknown error", build_result))
            elseif build_result.status == :skipped
                # do nothing, it's just a skipped build
            else
                throw(BuildError("Unexpected BuildResult status", build_result))
            end
        end
        extract_config = ExtractConfig(
            build_result,
            extract_script,
            products;
            platform,
            @extract_kwargs(kwargs, :metadir)...,
        )
        extract_result = extract!(
            extract_config;
            @extract_kwargs(kwargs, :debug_modes, :disable_cache)...,
        )
        if extract_result.status != :success
            if extract_result.status == :failed
                throw(BuildError("Extract script failed", extract_result))
            elseif extract_result.status == :errored
                throw(BuildError("Unknown error", extract_result))
            elseif extract_result.status == :skipped
                # do nothing
            else
                throw(BuildError("Unexpected ExtractResult status", extract_result))
            end
        end
        push!(extract_results, extract_result)

        # In the background, cleanup the previous build result
        Threads.@spawn cleanup(build_result)
    end
    # Take those extractions, and group them together as a single package
    package_config = PackageConfig(
        extract_results;
        @extract_kwargs(kwargs, :jll_name, :version_series, :julia_compat)...,
    )
    package_result = package!(package_config)
    if package_result.status ∉ (:success, :skipped)
        throw(BuildError("Unknown error", package_result))
    end
    save_cache(meta.build_cache)
    return package_result
end

# For those that like to use keyword arguments to name everything
function build_tarballs(;src_name::String,
                         src_version::Union{String,VersionNumber},
                         sources::Vector,
                         script::String,
                         products::Vector,
                         target_dependencies::Vector = [],
                         host_dependencies::Vector = [],
                         kwargs...)
    return build_tarballs(
        src_name,
        src_version,
        sources,
        target_dependencies,
        host_dependencies,
        script,
        products;
        kwargs...
    )
end

"""
    run_build_tarballs(build_tarballs_path::String; ARGS::Vector{String} = ARGS)

Helper function to evaluate a `build_tarballs.jl` script within a new anonymous module.
Attempts to return a dictionary of `PackageConfig` => `PackageResult` objects from the
build, by either assuming that the script ends with `build_tarballs()`, or that there
is a top-level `meta` object.  If neither are true this method will error out.

The `ARGS` keyword argument allows overriding the parameters sent to the
`build_tarballs.jl` script.  Most notably, one can pass `--dry-run` as part of `ARGS` to
skip all builds and simply return the "shape" of the computation within the
`build_tarballs.jl` script.
"""
function run_build_tarballs(meta::AbstractBuildMeta, build_tarballs_path::AbstractString; dry_run::Bool = false)
    # If `dry_run` is set, we need to toggle `dry_run` in `meta`, but only
    # for the duration of this call:
    old_dry_run = copy(meta.dry_run)
    if dry_run
        empty!(meta.dry_run)
        push!.((meta.dry_run,), (:build, :extract, :package))
    end
    try
        with_default_meta(meta) do
            Core.include(Module(), build_tarballs_path)
        end
    finally
        empty!(meta.dry_run)
        push!.((meta.dry_run,), old_dry_run)
    end
end

"""
    extract_build_tarballs(package_config::PackageConfig)
    extract_build_tarballs(package_result::PackageResult)

This analyzes the information embedded within the provided `PackageConfig`, determines if
it could have possibly come from a single `build_tarballs()` call, and if it could have,
returns a dict of the arguments to be passed to a `build_tarballs()` call to replicate
the build.

One exception to the faithful recreation is the `dry_run` property of the `BuildMeta` the
`build_tarballs()` call will create; because this function is often used in conjunction
with `run_build_tarballs(build_tarballs_path; ARGS=["--dry-run"])` to parse out the build
arguments of another `build_tarballs.jl` script without actually runnin the build.  Due
to this, the `dry_run` property is always disabled.
"""
function extract_build_tarballs(package_config::PackageConfig)
    # Explore tree of extractions/builds, ensure that all important settings are the same:
    extract_configs = ExtractConfig[]
    for (name, extractions) in package_config.named_extractions
        for extraction in extractions
            push!(extract_configs, extraction.config)
        end
    end

    # Try to have consistent failure messages
    fail_out(msg) = throw(ArgumentError("Cannot extract build_tarballs(): $(msg)"))

    for extract_config in extract_configs[2:end]
        # First, check to make sure the extract configs are all identical
        for prop in (:script, :products)
            if getproperty(extract_config, prop) != getproperty(extract_configs[1], prop)
                fail_out("ExtractionConfig objects do not agree on '$(prop)' property!")
            end
        end

        # Next, check to make sure the build configs are all identical
        build_config = extract_config.build.config
        build_config1 = extract_configs[1].build.config
        for prop in (:src_name, :src_version, :script)
            if getproperty(build_config, prop) != getproperty(build_config1, prop)
                fail_out("BuildConfig objects do not agree on '$(prop)' property!")
            end
        end

        # Special checks on dependencies
        source_prefixes = Dict(
            "source" => config -> config.source_trees[source_prefix(config)],
            "target" => config -> config.source_trees[target_prefix(config)],
            "host" => config -> config.source_trees[host_prefix(config)],
        )
        for (name, getter) in source_prefixes
            if getter(build_config) != getter(build_config1)
                fail_out("BuildConfig objects do not match on $(name) dependencies!")
            end
        end

        # Check that the host of the build is the same for all builds
        if build_config.platform.host != build_config1.platform.host
            fail_out("BuildConfig objects have different host platforms!")
        end
    end

    # Check that all extraction's platforms are the builds' platforms
    for extract_config in extract_configs
        if target_if_crossplatform(extract_config.platform) != extract_config.build.config.platform.target
            fail_out("Extract and Build configs do not match on platform!")
        end
    end

    # Once we're convinced that everything matches up, extract all the various pieces
    # necessary to fill out all `build_tarballs()` arguments:
    extract_config = first(extract_configs)
    build_config = extract_config.build.config

    # Do not inherit `--dry-run` modes
    meta = AbstractBuildMeta(build_config)
    empty!(meta.dry_run)

    return Dict{Symbol,Any}(
        :src_name => build_config.src_name,
        :src_version => build_config.src_version,
        :sources => build_config.source_trees[source_prefix(build_config)],
        :target_dependencies => build_config.source_trees[target_prefix(build_config)],
        :host_dependencies => build_config.source_trees[host_prefix(build_config)],
        :script => build_config.script,
        :products => extract_config.products,
        :meta => meta,
        :platforms => getproperty.(extract_configs, :platform),
        :toolchains => build_config.toolchains,
        :host => build_config.platform.host,
        :extract_script => extract_config.script,
        :allow_unsafe_flags => build_config.allow_unsafe_flags,
        :lock_microarchitecture => build_config.lock_microarchitecture,
        :jll_name => package_config.name,
        :version_series => VersionNumber(package_config.version.major, package_config.version.minor),
        :julia_compat => package_config.julia_compat,
    )
end
extract_build_tarballs(result::PackageResult) = extract_build_tarballs(result.config)

"""
    extract_build_tarballs(packagings::Dict{PackageConfig,PackageResult})

Helper for running `extract_build_tarballs(run_build_tarballs(path; ARGS=["--dry-run"]))`
"""
function extract_build_tarballs(packagings::Dict{PackageConfig,<:Union{Nothing,PackageResult}})
    if length(packagings) == 0
        throw(ArgumentError("No packagings to extract a build_tarballs argument list from!"))
    end
    if length(packagings) != 1
        throw(ArgumentError("Cannot guess which packaging to analyze; manually select one!"))
    end
    return extract_build_tarballs(only(keys(packagings)))
end
AbstractBuildMeta(packagings::Dict{PackageConfig,<:Union{Nothing,PackageResult}}) = AbstractBuildMeta(first(keys(packagings)))
