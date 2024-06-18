export ExtractResult, ExtractResultSource

struct ExtractResult
    # Link back to the originating ExtractResult
    config::ExtractConfig

    # The overall status of the build.  One of [:successful, :failed, :errored, :cached, :skipped]
    status::Symbol

    # If `status` is `:errored`, this should contain the exception that was thrown during execution
    # This generally denotes a bug.
    exception::Union{Nothing,Exception}

    # Treehash that represents the packaged output for the given config
    # On a failed/skipped build, this may be the special all-zero artifact hash.
    artifact::Union{Nothing,SHA1Hash}

    # Treehash that represents the packaged log files for the given config
    log_artifact::Union{Nothing,SHA1Hash}

    # The audit result.  It can be nothing if the build itself failed.
    audit_result::Union{Nothing,AuditResult}

    # Logs generated during this extraction (audit logs, mostly)
    extract_log::String

    function ExtractResult(config::ExtractConfig,
                           status::Symbol,
                           exception::Union{Nothing,Exception},
                           artifact::Union{Base.SHA1,SHA1Hash,Nothing},
                           log_artifact::Union{Base.SHA1,SHA1Hash,Nothing},
                           audit_result::Union{Nothing,AuditResult},
                           extract_log::String)
        return new(
            config,
            status,
            exception,
            artifact !== nothing ? SHA1Hash(artifact) : nothing,
            log_artifact !== nothing ? SHA1Hash(log_artifact) : nothing,
            audit_result,
            extract_log,
        )
    end
end
AbstractBuildMeta(result::ExtractResult) = AbstractBuildMeta(result.config)

function ExtractResult_cached(config::ExtractConfig, artifact::Union{Base.SHA1,SHA1Hash}, log_artifact::Union{Base.SHA1,SHA1Hash})
    build_config = config.build.config
    extract_log = joinpath(artifact_path(build_config.meta.universe, log_artifact), "$(build_config.src_name)-extract.log")
    audit_result = audit!(config, artifact_path(build_config.meta.universe, artifact); readonly=true)
    return ExtractResult(
        config,
        :cached,
        nothing,
        artifact,
        log_artifact,
        audit_result,
        String(read(extract_log)),
    )
end

function ExtractResult_skipped(config::ExtractConfig)
    return ExtractResult(
        config,
        :skipped,
        nothing,
        nothing,
        nothing,
        nothing,
        "",
    )
end

function Base.show(io::IO, result::ExtractResult)
    build_config = result.config.build.config
    color = status_style(result.status)
    print(io, styled"ExtractResult($(build_config.src_name), $(build_config.src_version), $(build_config.platform)) ({$(color):$(result.status)})")
end

Artifacts.artifact_path(result::ExtractResult) = artifact_path(result.config.build.config.meta.universe, result.artifact)
Sandbox.SandboxConfig(result::ExtractResult; kwargs...) = SandboxConfig(result.config, artifact_path(result); env=result.config.build.env)
function runshell(result::ExtractResult; verbose::Bool = false, shell::Cmd = `/bin/bash`)
    run(result.config.build.exe, SandboxConfig(result; verbose), shell)
end


"""
    ExtractResultSource(result::ExtractResult)

This is an advanced source that is used to directly mount an `ExtractResult`
as a source for a further build.  This is useful when an intermediate build is
not meant to become a published JLL, but is merely intended to be used as
a target/host dependency during the build of a larger JLL.

If in a large multi-stage build you want to use some smaller JLL that is built
as a part of the larger build, you should generally use
`JLLSource(::PackageResult)` instead once the smaller piece has been packaged.
This works because all packaged JLLs are registered into the same universe.
"""
function ExtractResultSource(result::ExtractResult, target::String = "")
    return DirectorySource(
        artifact_path(result);
        target,
    )
end

