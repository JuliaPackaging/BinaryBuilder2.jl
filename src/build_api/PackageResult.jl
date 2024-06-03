export PackageResult

struct PackageResult
    # Link back to the originating Package Config
    config::PackageConfig

    # Overall status of the packaging.  One of :successful, :failed or :skipped
    status::Symbol

    # The version number this package result is getting published under
    # (may disagree with `src_version`).
    published_version::VersionNumber

    function PackageResult(config::PackageConfig,
                           status::Symbol,
                           published_version::VersionNumber)
        return new(
            config,
            status,
            published_version,
        )
    end
end

function jll_path(result::PackageResult)
    return joinpath(meta.universe.depot_path, "dev", "$(result.config.jll_name)_jll")
end
