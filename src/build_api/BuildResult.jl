"""
    BuildResult

A `BuildResult` represents a constructed build prefix; it contains the paths to the
binaries (typically within an artifact directory) as well as some metadata about the
audit passes and whatnot that ran upon the files.
"""
struct BuildResult
    # The config that this result was built from
    config::BuildConfig

    # The overall status of the build.  One of [:successful, :failed, :skipped]
    status::Symbol

    # The location of the build prefix on-disk (typically an artifact directory)
    # For a failed or skipped build, this may be empty or only partially filled.
    prefix::String

    # Logs that are generated from build invocations and audit passes.
    # Key name is an identifier for the operation, value is the log content.
    # Example: ("audit-libfoo-relink_to_rpath").
    logs::Dict{String,String}

    # These are `@info`/`@warn`/`@error` messages that get emitted during the build/audit
    # we may eventually want to make this more structured, e.g. organize them by audit
    # pass and whatnot.  These messages are not written out to disk during packaging.
    #msgs::Vector{Test.LogRecord}

    ## TODO: merge `logs` and `msgs` with a better, more structured logging facility?

    function BuildResult(config::BuildConfig,
                         status::Symbol,
                         prefix::AbstractString,
                         logs::Dict{AbstractString,AbstractString})
                         #msgs::Vector{Test.LogRecord})
        return new(
            config,
            status,
            String(prefix),
            Dict(String(k) => String(v) for (k, v) in logs),
            #msgs,
        )
    end
end

# Helper function for skipped builds
function BuildResult_skipped(config::BuildConfig)
    return BuildResult(
        config,
        :skipped,
        "/dev/null",
        Dict{String,String}(),
    )
end

# TODO: construct helper to reconstruct BuildResult objects from S3-saved tarballs
