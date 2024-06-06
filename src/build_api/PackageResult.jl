export PackageResult

struct PackageResult
    # Link back to the originating Package Config
    config::PackageConfig

    # Overall status of the packaging.  One of :successful, :failed or :skipped
    status::Symbol

    function PackageResult(config::PackageConfig,
                           status::Symbol)
        return new(
            config,
            status,
        )
    end
end

function Base.show(io::IO, result::PackageResult)
    color = status_style(result.status)
    println(io, styled"PackageResult($(result.config.name), $(result.config.version)) ({$(color):$(result.status)})")
end

function jll_dir(result::PackageResult)
    meta = AbstractBuildMeta(result.config)
    return joinpath(meta.universe.depot_path, "dev", "$(result.config.name)_jll")
end

function tarballs_dir(result::PackageResult)
    meta = AbstractBuildMeta(result.config)
    return joinpath(meta.universe.depot_path, "tarballs", string(result.config.name, "-", result.config.version))
end
