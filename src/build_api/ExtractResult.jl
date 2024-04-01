export ExtractResult, ExtractResultSource

struct ExtractResult
    # Link back to the originating ExtractResult
    config::ExtractConfig

    # The overall status of the build.  One of [:successful, :failed, :errored, :skipped]
    status::Symbol

    # If `status` is `:errored`, this should contain the exception that was thrown during execution
    # This generally denotes a bug.
    exception::Union{Nothing,Exception}

    # Treehash that represents the packaged output for the given config
    # On a failed/skipped build, this may be the special all-zero artifact hash.
    artifact::Base.SHA1

    # Logs generated during this extraction (audit logs, mostly)
    logs::Dict{String,String}

    function ExtractResult(config::ExtractConfig,
                           status::Symbol,
                           exception::Union{Nothing,Exception},
                           artifact::Base.SHA1,
                           logs::Dict{<:AbstractString,<:AbstractString})
        return new(
            config,
            status,
            exception,
            artifact,
            Dict(String(k) => String(v) for (k,v) in logs),
        )
    end
end

Artifacts.artifact_path(result::ExtractResult) = artifact_path(result.artifact)

"""
    ExtractResultSource(result::ExtractResult)

This is an advanced source that is used to directly mount an `ExtractResult`
as a source for a further build.  This is useful when an intermediate build is
not meant to become a published JLL, but is merely intended to be used as
a target/host dependency during the build of a larger JLL.

If in a large multi-stage build you want to use some smaller JLL that is built
as a part of the larger build, you should generally use
`JLLSource(::PackageResult)` instead once the smaller piece has been packaged.
"""
function ExtractResultSource(result::ExtractResult, target::String = "")
    return DirectorySource(
        artifact_path(result.artifact);
        target,
    )
end


function ExtractResult_skipped(config::ExtractConfig)
    return ExtractResult(
        config,
        :skipped,
        Base.SHA1("0"^40),
        Dict{String,String}(),
    )
end
