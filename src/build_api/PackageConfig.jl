using BinaryBuilderProducts, JLLGenerator, MultiHashParsing

export PackageConfig, package!

struct PackageConfig
    # The name of the generated JLL; if not specified, defaults to `$(src_name)_jll`.
    # Note that by default we add `_jll` at the end, but this is not enforced in code!
    name::String

    # The JLL version that this will be published under.
    version::VersionNumber

    # A mapping of name to list of successful extractions.  Most builds only have a
    # single entry in this dictionary, but advanced builds may have a default variant,
    # a debug variant, etc...
    named_extractions::Dict{String,Vector{ExtractResult}}

    function PackageConfig(extractions::Dict{String,Vector{ExtractResult}};
                           name::Union{AbstractString,Nothing} = nothing,
                           version::VersionNumber = v"1.0.0")
        if isempty(extractions)
            throw(ArgumentError("extractions must not be empty!"))
        end

        # Ensure that each extraction comes from the same BuildMeta
        first_extract = first(first(values(extractions)))
        if any(any(e.config.build.config.meta != first_extract.config.build.config.meta for e in es) for (n,es) in extractions)
            throw(ArgumentError("Cannot package extractions from different BuildMeta objects!"))
        end

        # We allow overriding the name, but default to `src_name`
        if name === nothing
            name = first_extract.config.build.config.src_name
        end
        if !Base.isidentifier(name)
            throw(ArgumentError("Package name '$(name)' is not a valid identifier!"))
        end
        return new(name, version, extractions)
    end
end
PackageConfig(results::Vector{ExtractResult}; kwargs...) = PackageConfig(Dict("default" => results); kwargs...)
PackageConfig(result::ExtractResult; kwargs...) = PackageConfig([result]; kwargs...)
AbstractBuildMeta(config::PackageConfig) = first(values(config.named_extractions))[1].config.build.config.meta

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


function JLLGenerator.JLLArtifactInfo(name::String, result::ExtractResult)
    if result.status != :success
        throw(ArgumentError("Cannot package failing result: $(result)"))
    end
    build_config = result.config.build.config

    # TODO: get all library products from each dependency
    jll_maps = Dict{LibraryProduct,Symbol}()

    return JLLArtifactInfo(;
        src_version = build_config.src_version,
        deps = [JLLPackageDependency(d.name) for d in build_config.pkg_deps],
        # Encode all sources that are mounted in `/workspace/srcdir`
        sources = [JLLSourceRecord(s) for s in build_config.source_trees["/workspace/srcdir"]],
        platform = build_config.platform.target,
        name,
        treehash = SHA1Hash(result.artifact),
        products = [AbstractJLLProduct(p, artifact_path(result); env=build_config.env, jll_maps) for p in result.config.products],
        # TODO: Add links to our eventual deployment target
        download_sources = [],
    )
end

function package!(config::PackageConfig)
    meta = AbstractBuildMeta(config)
    artifacts = vcat(
        ([JLLArtifactInfo(name, extraction) for extraction in extractions] for (name, extractions) in config.named_extractions)...,
    )
    jll = JLLInfo(;
        name = config.name,
        version = next_jll_version(meta.universe, "$(config.name)_jll", config.version),
        artifacts,
        julia_compat = "1.7",
    )

    # Register this JLL out into our universe
    register!(meta.universe, jll)

    return PackageResult(
        config,
        :success,
        jll.version,
    )
end
