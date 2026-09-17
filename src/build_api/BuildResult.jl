using Ccache_jll
export BuildResult
export build_log, ccache_stats

"""
    BuildResult

A `BuildResult` represents a constructed build prefix; it contains the paths to the
binaries (typically within an artifact directory) as well as some metadata about the
audit passes and whatnot that ran upon the files.
"""
mutable struct BuildResult
    # The config that this result was built from
    config::BuildConfig

    # The overall status of the build.  One of [:success, :failed, :errored, :cached, :skipped]
    status::Symbol

    # If `status` is `:errored`, this should contain the exception that was thrown during execution
    # This generally denotes a bug.
    exception::Union{Nothing,Exception}

    # The executor and mounts used to run the build (also used to run the extraction)
    # These do not exist when we're restored from a cached build output.
    exe::Union{Nothing,SandboxExecutor}
    mounts::Dict{String,MountInfo}

    # Log from the build
    log_artifact::Union{Nothing,SHA1Hash}

    # The final environment of this build result.
    env::Dict{String,String}

    # ccache per-build statistics log artifact (nothing if ccache was not invoked or build was cached)
    ccache_log_artifact::Union{Nothing,SHA1Hash}

    function BuildResult(config::BuildConfig,
                         status::Symbol,
                         exception::Union{Nothing,Exception},
                         exe::Union{Nothing,SandboxExecutor},
                         mounts::Dict{String,MountInfo},
                         log_artifact::Union{Nothing,SHA1Hash},
                         env::Dict{String,String},
                         ccache_log_artifact::Union{Nothing,SHA1Hash} = nothing)
        obj = new(
            config,
            status,
            exception,
            exe,
            mounts,
            log_artifact,
            env,
            ccache_log_artifact,
        )
        # Make sure that this is cleaned up _before_ we're in a finalizer.
        push!(get_exit_hooks(), obj)
        return obj
    end
end
AbstractBuildMeta(result::BuildResult) = AbstractBuildMeta(result.config)

function Sandbox.cleanup(result::BuildResult)
    if result.exe !== nothing
        Sandbox.cleanup(result.exe)
    end
end

function BuildResult_cached(config::BuildConfig, log_artifact::Union{Base.SHA1,SHA1Hash}, env::Dict{String,String})
    return BuildResult(
        config,
        :cached,
        nothing,
        nothing,
        Dict{String,MountInfo}(),
        SHA1Hash(log_artifact),
        env,
    )
end

function BuildResult_skipped(config::BuildConfig)
    return BuildResult(
        config,
        :skipped,
        nothing,
        nothing,
        Dict{String,MountInfo}(),
        nothing,
        Dict{String,String}(),
    )
end

function Base.show(io::IO, result::BuildResult)
    config = result.config
    color = status_style(result.status)
    print(io, styled"BuildResult($(config.src_name), $(config.src_version), $(target_platform_string(config))) ({$(color):$(result.status)})")
end

function Sandbox.SandboxConfig(result::BuildResult; kwargs...)
    meta = AbstractBuildMeta(result)
    mounts = copy(result.mounts)
    mounts["/workspace/logs/build"] = MountInfo(artifact_path(meta.universe, result.log_artifact), MountType.ReadOnly)
    return SandboxConfig(result.config, mounts; kwargs...)
end

function runshell(result::BuildResult; verbose::Bool = false, shell::Cmd = `/bin/bash`)
    run(result.exe, SandboxConfig(result; verbose, result.env), ignorestatus(shell))
end

function find_mount_for_path(mounts::Dict{String,MountInfo}, path::String)
    prefix_mounts = filter(collect(keys(mounts))) do m
        return startswith(path, m)
    end
    return first(sort(prefix_mounts; by=length))
end


function Base.read(exe::SandboxExecutor, config::BuildConfig, mounts::Dict{String,MountInfo}, filepath::String)
    stdout = IOBuffer()
    stderr = IOBuffer()
    sandbox_config = SandboxConfig(
        config, mounts;
        stdout=stdout,
        stderr=stderr,
    )

    # Find `cat` within the rootfs.
    cat_path = nothing
    for bindir in ("bin", "usr/bin", "usr/local/bin")
        shard_path = find_mount_for_path(mounts, string("/", bindir))
        if isfile(joinpath(shard_path, bindir, "cat"))
            cat_path = string("/", bindir, "/cat")
            break
        end
    end
    if cat_path === nothing
        throw(ArgumentError("Unable to find a `cat` executable within the rootfs?!"))
    end

    status, exception = run_trycatch(exe, sandbox_config, `$(cat_path) $(filepath)`)
    if exception !== nothing
        throw(exception)
    end
    if status !== :success
        throw(ArgumentError("Could not read file $(filepath): $(String(take!(stderr)))"))
    end
    return take!(stdout)
end

function store_ccache_log_artifact(universe, data::Union{AbstractVector{UInt8},Nothing})
    (data === nothing || isempty(data)) && return nothing
    hash = in_universe(universe) do _
        Pkg.Artifacts.create_artifact() do artifact_dir
            open(joinpath(artifact_dir, "ccache-statslog"); write=true) do io
                write(io, data)
            end
        end
    end
    return SHA1Hash(hash)
end

function build_log(br::BuildResult)
    if br.log_artifact === nothing
        throw(ArgumentError("Skipped BuildResult's don't have a build log!"))
    end
    build_log_path = artifact_path(br.config.meta.universe, br.log_artifact)
    return String(read(joinpath(build_log_path, "$(br.config.src_name)-build.log")))
end

"""
    ccache_stats(result::BuildResult; io::IO = stdout)

Display per-build ccache statistics for the given `BuildResult`.  Statistics are
collected via `CCACHE_STATSLOG` during the build and shown using `ccache --show-log-stats`.
Returns `nothing` if ccache was not invoked during the build or if the build was cached/skipped.
"""
function ccache_stats(result::BuildResult; io::IO = stdout)
    if result.ccache_log_artifact === nothing
        @warn("No ccache statslog available for this BuildResult (build may have been cached/skipped, or ccache was not invoked)")
        return nothing
    end
    ccache_log_path = artifact_path(result.config.meta.universe, result.ccache_log_artifact)
    statslog_file = joinpath(ccache_log_path, "ccache-statslog")
    run(pipeline(
        addenv(`$(ccache()) --show-log-stats`, "CCACHE_STATSLOG" => statslog_file, "CCACHE_DIR" => ccache_cache("ccache")),
        stdout = io,
    ))
    return nothing
end

function parse_metadir_env(exe::SandboxExecutor, config::BuildConfig, mounts::Dict{String,MountInfo})
    return parse_env_block(String(read(exe, config, mounts, "$(metadir_prefix())/env")))
end

function read_metadir_ccache_statslog(exe::SandboxExecutor, config::BuildConfig, mounts::Dict{String,MountInfo})
    try
        return read(exe, config, mounts, "$(metadir_prefix())/ccache-statslog")
    catch e
        e isa ArgumentError || rethrow()
        return nothing
    end
end

function parse_env_block(env_string::AbstractString)
    env = Dict{String,String}()
    for line in split(env_string, "\n")
        sep_idx = findfirst("=", line)
        if sep_idx !== nothing
            env[line[1:first(sep_idx)-1]] = line[first(sep_idx)+1:end]
        end
    end
    return env
end

# The opposite of `parse_env_block`
function serialize_env_block(env::Dict{String,String})
    return join((string(key, "=", env[key]) for key in sort(collect(keys(env)))), "\n")
end
