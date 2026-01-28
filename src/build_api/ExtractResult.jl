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

    # The audit result.  It can be nothing if this is a failed or cached build
    audit_result::Union{Nothing,AuditResult}

    # The JLL library product structure, comes from `audit_result`.
    jll_lib_products::Vector{JLLLibraryProduct}

    # Logs generated during this extraction (audit logs, mostly)
    extract_log::String

    function ExtractResult(config::ExtractConfig,
                           status::Symbol,
                           exception::Union{Nothing,Exception},
                           artifact::Union{Base.SHA1,SHA1Hash,Nothing},
                           log_artifact::Union{Base.SHA1,SHA1Hash,Nothing},
                           audit_result::Union{Nothing,AuditResult},
                           jll_lib_products::Vector{JLLLibraryProduct},
                           extract_log::String)
        return new(
            config,
            status,
            exception,
            artifact !== nothing ? SHA1Hash(artifact) : nothing,
            log_artifact !== nothing ? SHA1Hash(log_artifact) : nothing,
            audit_result,
            jll_lib_products,
            extract_log,
        )
    end
end
AbstractBuildMeta(result::ExtractResult) = AbstractBuildMeta(result.config)

function ExtractResult_cached(config::ExtractConfig, artifact::Union{Base.SHA1,SHA1Hash}, log_artifact::Union{Base.SHA1,SHA1Hash}, jll_lib_products::Vector{JLLLibraryProduct})
    build_config = config.build.config
    extract_log = joinpath(artifact_path(build_config.meta.universe, log_artifact), "$(build_config.src_name)-extract.log")
    return ExtractResult(
        config,
        :cached,
        nothing,
        artifact,
        log_artifact,
        nothing,
        jll_lib_products,
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
        JLLLibraryProduct[],
        "",
    )
end

function Base.show(io::IO, result::ExtractResult)
    build_config = result.config.build.config
    color = status_style(result.status)
    print(io, styled"ExtractResult($(build_config.src_name), $(build_config.src_version), $(target_platform_string(build_config))) ({$(color):$(result.status)})")
end

Artifacts.artifact_path(result::ExtractResult) = artifact_path(result.config.build.config.meta.universe, result.artifact)
function Sandbox.SandboxConfig(result::ExtractResult; kwargs...)
    meta = AbstractBuildMeta(result)
    mounts = copy(result.config.build.mounts)
    mounts["/workspace/logs/build"] = MountInfo(artifact_path(meta.universe, result.config.build.log_artifact), MountType.ReadOnly)
    mounts["/workspace/logs/extract"] = MountInfo(artifact_path(meta.universe, result.log_artifact), MountType.ReadOnly)
    return SandboxConfig(result.config, artifact_path(result), mounts; env=result.config.build.env)
end
function runshell(result::ExtractResult; verbose::Bool = false, shell::Cmd = `/bin/bash`)
    run(result.config.build.exe, SandboxConfig(result; verbose), ignorestatus(shell))
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

