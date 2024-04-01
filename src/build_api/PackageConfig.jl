using BinaryBuilderProducts, JLLGenerator, MultiHashParsing

export PackageConfig, package!

struct PackageConfig
    # The name of the generated JLL; if not specified, defaults to `$(src_name)_jll`.
    # Note that by default we add `_jll` at the end, but this is not enforced in code!
    name::String

    # The JLL version that this will be published under.
    version::VersionNumber

    # The list of successful extractions that we're going to combine
    # together into a single package
    extractions::Vector{ExtractResult}

    function PackageConfig(extractions::Vector{ExtractResult}; name::Union{AbstractString,Nothing} = nothing, version::VersionNumber = v"1.0.0")
        #=
        # I'm not sure this is actually necessary
        if !isempty(extractions) && any(e.config.builds[1].name != extractions[1].config.builds[1].name for e in extractions)
            throw(ArgumentError("Cannot package extractions from different builds!"))
        end
        =#

        # We allow overriding the name, but default to `$(src_name)_jll`
        if name === nothing
            name = string(extractions[1].config.build.config.src_name, "_jll")
        end
        if !Base.isidentifier(name)
            throw(ArgumentError("Package name '$(name)' is not a valid identifier!"))
        end
        return new(name, version, extractions)
    end
end
PackageConfig(result::ExtractResult; kwargs...) = PackageConfig([result]; kwargs...)

"""
    next_jll_version(majmin::VersionNumber; registry = nothing)
"""
function next_jll_version(base::VersionNumber; registry = nothing)
    return v"1.0.0"
end


function JLLGenerator.JLLArtifactInfo(result::ExtractResult)
    if result.status != :success
        throw(ArgumentError("Cannot package failing result: $(result)"))
    end
    build_config = result.config.build.config
    return JLLArtifactInfo(
        src_version = build_config.src_version,
        deps = [JLLPackageDependency(d.name) for d in build_config.pkg_deps],
        # Encode all sources that are mounted in `/workspace/srcdir`
        sources = [JLLSourceRecord(s) for s in build_config.source_trees["/workspace/srcdir"]],
        platform = build_config.platform.target,
        name = build_config.src_name,
        treehash = SHA1Hash(result.artifact),
        products = [AbstractJLLProduct(p, artifact_path(result); env=build_config.env) for p in result.config.products],
        # No download sources yet
        download_sources = [],
    )
end

function package!(meta::AbstractBuildMeta, config::PackageConfig)
    jll = JLLInfo(;
        name = config.name,
        version = config.version,
        artifacts = JLLArtifactInfo.(config.extractions),
        julia_compat = "1.7",
    )

    generate_jll()
end
