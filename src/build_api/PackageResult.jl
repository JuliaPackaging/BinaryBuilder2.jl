export PackageResult

struct PackageResult
    # Link back to the originating Package Config
    config::PackageConfig

    # Overall status of the packaging.  One of :successful, :failed or :skipped
    status::Symbol

    # Final TimerOutput object
    to::TimerOutput

    # If we deployed this somewhere, record where
    deploy_url::Union{Nothing,String}
    deploy_rev::Union{Nothing,String}

    function PackageResult(config::PackageConfig,
                           status::Symbol,
                           to::TimerOutput,
                           deploy_url::Union{Nothing,String} = nothing,
                           deploy_rev::Union{Nothing,String} = nothing)
        return new(
            config,
            status,
            to,
            deploy_url,
            deploy_rev,
        )
    end
end
AbstractBuildMeta(result::PackageResult) = AbstractBuildMeta(result.config)

function PackageResult_skipped(config::PackageConfig)
    return PackageResult(
        config,
        :skipped,
        TimerOutput(),
    )
end

function Base.show(io::IO, result::PackageResult)
    color = status_style(result.status)
    print(io, styled"PackageResult($(result.config.name), $(result.config.version)) ({$(color):$(result.status)})")
end

function jll_dir(result::PackageResult)
    meta = AbstractBuildMeta(result.config)
    return joinpath(meta.universe.depot_path, "dev", "$(result.config.name)_jll")
end

function tarballs_dir(result::PackageResult)
    meta = AbstractBuildMeta(result.config)
    return joinpath(meta.universe.depot_path, "tarballs", string(result.config.name, "-", result.config.version))
end

using JLLGenerator: jll_specific_uuid5, uuid_package
function BinaryBuilderSources.PackageSpec(result::PackageResult)
    uuid = jll_specific_uuid5(uuid_package, "$(result.config.name)_jll_jll")
    return PackageSpec(;
        name="$(result.config.name)_jll",
        uuid,
        version=result.config.version,
        repo=Pkg.Types.GitRepo(;source=result.deploy_url, rev=result.deploy_rev),
    )
end

function collect_extractions(result::PackageResult)
    ret = ExtractResult[]
    for (name, ers) in result.config.named_extractions
        append!(ret, ers)
    end
    return ret
end

function collect_builds(result::PackageResult)
    ret = BuildResult[]
    for extract_result in collect_extractions(result)
        push!(ret, extract_result.config.build)
    end
    return ret
end
