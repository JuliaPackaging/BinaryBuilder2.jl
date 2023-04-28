

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

# Note that this helper still takes in the `published_version`, as that is
# potentially quite useful for static analysis to know.
function PackageResult_skipped(config::PackageConfig, published_version::VersionNumber)
    return PackageResult(
        config,
        :skipped,
        published_version,
    )
end
