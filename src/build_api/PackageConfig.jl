using BinaryBuilderProducts, JLLGenerator, MultiHashParsing

export PackageConfig, package!

struct PackageConfig
    # The name of the generated JLL; if not specified, defaults to `$(src_name)`. (no `_jll` at the end!)
    name::String

    # The JLL version this package will be published under
    version::VersionNumber

    # A mapping of name to list of extractions.  Most builds only have a
    # single entry in this dictionary, but advanced builds may have a default variant,
    # a debug variant, etc...
    named_extractions::Dict{String,Vector{ExtractResult}}

    # Extra JLL dependencies that are not implicit in the `ExtractResult`.
    # Often used for inter-build dependencies in complicated builds.
    extra_deps::Vector{PackageSpec}

    # Julia compat specification for this JLL
    julia_compat::String

    function PackageConfig(extractions::Dict{String,Vector{ExtractResult}};
                           jll_name::AbstractString = default_jll_name(extractions),
                           version_series::VersionNumber = default_jll_version_series(extractions),
                           extra_deps::Vector{PackageSpec} = PackageSpec[],
                           julia_compat::AbstractString = "1.6",
                           duplicate_extraction_handling::Symbol = :error)
        if isempty(extractions)
            throw(ArgumentError("extractions must not be empty!"))
        end

        # Ensure that each extraction comes from the same BuildMeta
        first_extract = first(first(values(extractions)))
        if any(any(e.config.build.config.meta != first_extract.config.build.config.meta for e in es) for (n,es) in extractions)
            throw(ArgumentError("Cannot package extractions from different BuildMeta objects!"))
        end

        if !Base.isidentifier(jll_name)
            throw(ArgumentError("Package name '$(jll_name)' is not a valid identifier!"))
        end

        if jll_name ∉ keys(extractions)
            throw(ArgumentError("One of the extractions must have the same name as the JLL itself!"))
        end

        valid_deh_values = (:error, :ignore_all, :ignore_identical)
        if duplicate_extraction_handling ∉ valid_deh_values
            throw(ArgumentError("Invalid `duplicate_extraction_handling` value, must be one of: $(valid_deh_values)"))
        end

        # Check to make sure we don't have "duplicate extractions" listed here:
        for (name, extract_results) in extractions
            duplicate_extractions = ExtractResult[]
            unique_extractions = Dict{AbstractPlatform,ExtractResult}()
            for extract_result in extract_results
                # If this extract result's platform is already in `unique_extractions`,
                # we push it onto `duplicate_extractions` according to our handling behavior
                if extract_result.config.platform ∈ keys(unique_extractions)
                    if duplicate_extraction_handling == :ignore_all
                        # If ignoring, do nothing
                    elseif duplicate_extraction_handling == :ignore_identical
                        # If ignoring identical, only push if not identical
                        if unique_extractions[extract_result.config.platform].artifact != extract_result.artifact && extract_result.artifact !== nothing
                            push!(duplicate_extractions, extract_result)
                        end
                    else
                        # Otherwise always push
                        push!(duplicate_extractions, extract_result)
                    end
                else
                    unique_extractions[extract_result.config.platform] = extract_result
                end
            end
            filter!(r -> r ∈ values(unique_extractions), extract_results)

            if !isempty(duplicate_extractions)
                @error("Duplicate extractions found!  Maybe set `duplicate_extraction_handling` keyword argument?", name, duplicate_extractions)
                throw(ArgumentError("Duplicate extractions"))
            end
        end

        # Calculate the next version number immediately
        meta = AbstractBuildMeta(extractions)
        version = next_jll_version(meta.universe, "$(jll_name)_jll", version_series)

        return new(jll_name, version, extractions, extra_deps, string(julia_compat))
    end
end

# Helper functions for quickly packaging a few ExtractResults
PackageConfig(results::Vector{ExtractResult}; jll_name::AbstractString = default_jll_name(results), kwargs...) = PackageConfig(Dict(jll_name => results); kwargs...)
PackageConfig(result::ExtractResult; kwargs...) = PackageConfig([result]; kwargs...)
AbstractBuildMeta(config::PackageConfig) = AbstractBuildMeta(config.named_extractions)
AbstractBuildMeta(named_extractions::Dict{String,Vector{ExtractResult}}) = AbstractBuildMeta(first(first(values(named_extractions))))

# We allow overriding the name, but default to `build_config.src_name`.
default_jll_name(result::ExtractResult) = result.config.build.config.src_name
default_jll_name(results::Vector{ExtractResult}) = default_jll_name(first(results))
default_jll_name(extractions::Dict{String,Vector{ExtractResult}}) = default_jll_name(first(values(extractions)))

# We allow overriding the version series, but default to `src_version`, if available.
function default_jll_version_series(result::ExtractResult)
    src_version = result.config.build.config.src_version
    try
        src_version = parse(VersionNumber, src_version)
    catch
        throw(ArgumentError("Cannot parse '$(src_version)' as a VersionNumber, must manually specify `version_series`"))
    end
    return VersionNumber(
        src_version.major,
        src_version.minor,
        0,
    )
end
default_jll_version_series(results::Vector{ExtractResult}) = default_jll_version_series(first(results))
default_jll_version_series(extractions::Dict{String,Vector{ExtractResult}}) = default_jll_version_series(first(values(extractions)))

function Base.show(io::IO, config::PackageConfig)
    print(io, "PackageConfig($(config.name), $(config.version))")
end

"""
    next_jll_version(universe::Universe, name::String, base::VersionNumber)

Given a JLL package name, look up the set of versions registered in the given `universe`
and choose the next available version according to the provided `base`.  The `base` is
a `VersionNumber` that specifies a major and minor series.  This function will then
return a `VersionNumber` with the same major and minor numbers, but a new `patch`
number that is not yet registered.  As an example, if the following versions are
registered in the given universe:

- v1.0.0
- v1.1.0
- v1.1.1
- v1.2.0

And the `base` is `v1.1.0`, the return value will be `v1.1.2`.  If the `base` is
given to be `v1.3.0`, the return value will be `v1.3.0`.
"""
function next_jll_version(universe::Universe, name::String, base::VersionNumber)
    # Get list of all registered versions
    return next_jll_version(
        get_package_versions(universe, name),
        base,
    )
end

function next_jll_version(versions::Union{Nothing,Vector{VersionNumber}}, base::VersionNumber)
    # If this JLL didn't exist before, return `base`
    if versions === nothing
        return base
    end

    # Find version numbers of the same series:
    same_series = filter(v -> v.major == base.major && v.minor == base.minor, versions)
    if isempty(same_series)
        # If there are no other version numbers of the same series, just return `base`
        return base
    end

    # Otherwise, take the maximum version, add one to the patch, and return that.
    max_ver = maximum(same_series)
    return VersionNumber(
        max_ver.major,
        max_ver.minor,
        max_ver.patch + 1,
    )
end

function JLLPackageDependencies(result::ExtractResult, extra_deps::Vector{PackageSpec})
    # Get list of JLLSources installed in this target's prefix
    build_config = result.config.build.config
    target_jll_deps = filter(d -> isa(d, JLLSource), get_default_target_spec(build_config).dependencies)
    deps = [JLLPackageDependency(jll.package.name, jll.package.uuid) for jll in target_jll_deps]
    for pkg in extra_deps
        push!(deps, JLLPackageDependency(pkg.name, pkg.uuid))
    end
    return deps
end

function JLLSourceRecords(result::ExtractResult)
    build_config = result.config.build.config
    return [JLLSourceRecord(s) for s in build_config.source_trees[source_prefix()]]
end

function JLLProducts(result::ExtractResult)
    products = AbstractJLLProduct[]
    for product in result.config.products
        # Skip library products, as those were translated by the auditor
        if isa(product, LibraryProduct)
            continue
        end

        push!(products, 
            # Convert from ExecutableProduct/FileProduct to JLLProduct types
            AbstractJLLProduct(
                product,
                artifact_path(result);
                # Use the environment block from our BuildResult to locate them
                env=result.config.build.env,
                # If we've built some kind of compiler, look for binaries
                # that match the host platform.
                platform=host_if_crossplatform(result.config.platform)
            )
        )
    end

    # Copy over the LibraryProducts that were translated by the auditor
    append!(products, result.jll_lib_products)
    return products
end

function JLLBuildLicenses(result::ExtractResult)
    licenses_dir = joinpath(artifact_path(result), "share", "licenses")
    if !isdir(licenses_dir)
        throw(ArgumentError("No `share/licenses/` directory in extraction!"))
    end

    package_name = readdir(licenses_dir)
    if length(package_name) != 1
        throw(ArgumentError("More than one directory in `share/licenses/`: $(package_name)"))
    end
    package_name = only(package_name)

    filenames = readdir(joinpath(licenses_dir, package_name))
    return [JLLBuildLicense(f, String(read(joinpath(licenses_dir, package_name, f)))) for f in filenames]
end



"""
    add_os_version(platform::AbstractPlatform, target_spec::BuildTargetSpec)

Adds an `os_version` tag to `platform` according to the runtimes built against
in `target_spec`.  Currently this is only done for macOS and FreeBSD but
it is very possible this will be extended to glibc Linux in the future.

This is done automatically as part of the `package!()` call.  There does not
yet exist a way to opt out of this.
"""
function add_os_version(platform::Platform, target_spec::BuildTargetSpec)
    if os_version(platform) !== nothing
        return platform
    end

    # Make a copy, since we actually modify `platform` here.
    platform = parse(Platform, triplet(platform))

    if Sys.isapple(platform)
        libc_jll_name = "macOSSDK_jll"
        version_map = macos_kernel_version
    elseif Sys.isfreebsd(platform)
        libc_jll_name = "FreeBSDSysroot_jll"
    else
        # Other platforms don't do versioning yet
        return platform
    end

    for toolchain in target_spec.toolchains
        if !isa(toolchain, CToolchain) && !isa(toolchain, BinutilsToolchain)
            continue
        end

        tenv = toolchain_env(toolchain, "")
        if haskey(tenv, "MACOSX_DEPLOYMENT_TARGET")
            # Get the version that the JLL corresponds to, and return!
            platform["os_version"] = string(version_map(tenv["MACOSX_DEPLOYMENT_TARGET"]))
            return platform
        end

        if haskey(tenv, "FREEBSD_TARGET_SDK")
            platform["os_version"] = tenv["FREEBSD_TARGET_SDK"]
            return platform
        end
    end

    # Unable to find an OS version, that's fine!
    return platform
end
add_os_version(any::AnyPlatform, ::BuildTargetSpec) = any
function add_os_version(cp::CrossPlatform, target_spec::BuildTargetSpec)
    return CrossPlatform(add_os_version(cp.host, target_spec) => cp.target)
end

function JLLGenerator.JLLBuildInfo(name::String, result::ExtractResult, extra_deps::Vector{PackageSpec})
    if result.status ∉ (:success, :cached)
        throw(ArgumentError("Cannot package failing result: $(result)"))
    end
    build_config = result.config.build.config

    return JLLBuildInfo(;
        src_version = build_config.src_version,
        deps = JLLPackageDependencies(result, extra_deps),
        # Encode all sources that are mounted in `/workspace/srcdir`
        sources = JLLSourceRecords(result),
        platform = add_os_version(result.config.platform, result.config.target_spec),
        name,
        # TODO: Add links to our eventual deployment target
        artifact = JLLArtifactBinding(
            treehash = SHA1Hash(result.artifact),
            download_sources = [],
        ),
        # Add our "auxilliary artifacts"
        auxilliary_artifacts = Dict(
            "build_log" => JLLArtifactBinding(;
                treehash = result.config.build.log_artifact,
                download_sources = []
            ),
            "extract_log" => JLLArtifactBinding(;
                treehash = result.log_artifact,
                download_sources = []
            ),
        ),
        licenses = JLLBuildLicenses(result),
        products = JLLProducts(result),
    )
end

function package!(config::PackageConfig)
    meta = AbstractBuildMeta(config)
    meta.packagings[config] = nothing

    if should_skip(config, meta.verbose)
        result = PackageResult_skipped(config)
        meta.packagings[config] = result
        return result
    end

    # Merge all our timer outputs into a single, final, timer output.
    to = TimerOutput()
    for (_, extractions) in config.named_extractions
        for extraction in extractions
            merge!(to, extraction.config.to)
        end
    end

    @timeit to "package" begin
        builds = vcat(
            ([JLLBuildInfo(name, extraction, config.extra_deps) for extraction in extractions] for (name, extractions) in config.named_extractions)...,
        )
        jll = JLLInfo(;
            name = config.name,
            version = config.version,
            builds,
            julia_compat = config.julia_compat,
        )

        @timeit to "register_jll!" begin
            # Register this JLL out into our universe
            register_jll!(meta.universe, jll; verbose=meta.verbose)
        end
    end

    # Finalize the timer by stopping the clock, and inserting complements
    TimerOutputs.disable_timer!(to)
    TimerOutputs.complement!(to)

    result = PackageResult(
        config,
        :success,
        to,
    )
    meta.packagings[config] = result
    return result
end
