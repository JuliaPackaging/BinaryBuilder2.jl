export BuildResult

"""
    BuildResult

A `BuildResult` represents a constructed build prefix; it contains the paths to the
binaries (typically within an artifact directory) as well as some metadata about the
audit passes and whatnot that ran upon the files.
"""
mutable struct BuildResult
    # The config that this result was built from
    config::BuildConfig

    # The overall status of the build.  One of [:successful, :failed, :errored, :skipped]
    status::Symbol

    # If `status` is `:errored`, this should contain the exception that was thrown during execution
    # This generally denotes a bug.
    exception::Union{Nothing,Exception}

    # The set of mounts used to run the build.
    exe::SandboxExecutor
    mounts::Dict{String,MountInfo}

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
                         exception::Union{Nothing,Exception},
                         exe::SandboxExecutor,
                         mounts::Dict{<:String,MountInfo},
                         logs::Dict{<:AbstractString,<:AbstractString})
                         #msgs::Vector{Test.LogRecord})
        obj = new(
            config,
            status,
            exception,
            exe,
            Dict(String(k) => v for (k, v) in mounts),
            Dict(String(k) => String(v) for (k, v) in logs),
            #msgs,
        )
        finalizer(obj) do obj
            Sandbox.cleanup(obj.exe)
        end
        return obj
    end
end

# Helper function for skipped builds
function BuildResult_skipped(config::BuildConfig)
    return BuildResult(
        config,
        :skipped,
        nothing,
        "/dev/null",
        Dict{String,String}(),
    )
end

Sandbox.SandboxConfig(result::BuildResult; verbose::Bool = false) = SandboxConfig(result.config, result.mounts; verbose)

function runshell(result::BuildResult; verbose::Bool = false, shell::Cmd = `/bin/bash`)
    run(result.exe, SandboxConfig(result; verbose), shell)
end

# TODO: construct helper to reconstruct BuildResult objects from S3-saved tarballs
