using BinaryBuilderProducts, JLLGenerator, MultiHashParsing

export PackageConfig, package!

struct PackageConfig
    # The name of the generated JLL; if not specified, defaults to `$(src_name)_jll`.
    # Note that by default we add `_jll` at the end, but this is not enforced in code!
    name::String

    # The JLL version this package will be published under
    version::VersionNumber

    # A mapping of name to list of successful extractions.  Most builds only have a
    # single entry in this dictionary, but advanced builds may have a default variant,
    # a debug variant, etc...
    named_extractions::Dict{String,Vector{ExtractResult}}

    function PackageConfig(extractions::Dict{String,Vector{ExtractResult}};
                           jll_name::AbstractString = default_jll_name(extractions),
                           version_series::VersionNumber = v"1.0.0")
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

        # Calculate the next version number immediately
        meta = AbstractBuildMeta(extractions)
        version = next_jll_version(meta.universe, "$(jll_name)_jll", version_series)

        return new(jll_name, version, extractions)
    end
end
PackageConfig(results::Vector{ExtractResult}; jll_name::AbstractString = default_jll_name(results), kwargs...) = PackageConfig(Dict(jll_name => results); kwargs...)
PackageConfig(result::ExtractResult; kwargs...) = PackageConfig([result]; kwargs...)
AbstractBuildMeta(config::PackageConfig) = AbstractBuildMeta(config.named_extractions)
AbstractBuildMeta(named_extractions::Dict{String,Vector{ExtractResult}}) = first(first(values(named_extractions))).config.build.config.meta

# We allow overriding the name, but default to `build_config.src_name`.
default_jll_name(result::ExtractResult) = result.config.build.config.src_name
default_jll_name(results::Vector{ExtractResult}) = default_jll_name(first(results))
default_jll_name(extractions::Dict{String,Vector{ExtractResult}}) = default_jll_name(first(values(extractions)))

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


function JLLGenerator.JLLBuildInfo(name::String, result::ExtractResult)
    if result.status ∉ (:success, :cached)
        throw(ArgumentError("Cannot package failing result: $(result)"))
    end
    build_config = result.config.build.config

    # First, translate all non-library products to JLLProducts
    products = AbstractJLLProduct[
        AbstractJLLProduct(p, artifact_path(result); env=build_config.env) for p in result.config.products if !isa(p, LibraryProduct)
    ]
    # Then, append the JLLLibraryProducts that were filled out by the auditor:
    append!(products, result.audit_result.jll_lib_products)

    return JLLBuildInfo(;
        src_version = build_config.src_version,
        deps = [JLLPackageDependency(d.name) for d in build_config.pkg_deps],
        # Encode all sources that are mounted in `/workspace/srcdir`
        sources = [JLLSourceRecord(s) for s in build_config.source_trees["/workspace/srcdir"]],
        platform = result.config.platform,
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
        products,
    )
end

function package!(config::PackageConfig)
    meta = AbstractBuildMeta(config)
    builds = vcat(
        ([JLLBuildInfo(name, extraction) for extraction in extractions] for (name, extractions) in config.named_extractions)...,
    )
    jll = JLLInfo(;
        name = config.name,
        version = config.version,
        builds,
        julia_compat = "1.7",
    )

    # Register this JLL out into our universe
    register_jll!(meta.universe, jll)

    return PackageResult(
        config,
        :success,
    )
end
