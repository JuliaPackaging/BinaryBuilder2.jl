using MultiHashParsing, TOML
export BuildCache

struct BuildCache
    cache_dir::String
    # This maps from content_hash(::BuildConfig, extract_args...) -> artifact hash
    cache::Dict{Tuple{SHA1Hash,SHA1Hash},SHA1Hash}
    # This maps from content_hash(::BuildConfig) -> build log
    logs::Dict{SHA1Hash,String}
    # This maps from content_hash(::BuildConfig) -> env dict
    envs::Dict{SHA1Hash,Dict{String,String}}
end

default_buildcache_dir() = @get_scratch!("buildcache_database")

function BuildCache(;cache_dir = default_buildcache_dir())
    return BuildCache(
        cache_dir,
        Dict{Tuple{SHA1Hash,SHA1Hash},SHA1Hash}(),
        Dict{SHA1Hash,String}(),
        Dict{SHA1Hash,Dict{String,String}}(),
    )
end

function Base.put!(bc::BuildCache, build_hash::SHA1Hash, extract_hash::SHA1Hash,
                   artifact_hash::SHA1Hash, log::String, env::Dict{String,String})
    bc.cache[(build_hash, extract_hash)] = artifact_hash
    bc.logs[build_hash] = log
    bc.envs[build_hash] = env
end
function Base.put!(bc::BuildCache, extract_result::ExtractResult)
    build_result = extract_result.config.build
    return put!(
        bc,
        content_hash(build_result.config),
        content_hash(extract_result.config),
        SHA1Hash(extract_result.artifact),
        build_result.build_log,
        build_result.env,
    )
end

function Base.haskey(bc::BuildCache, build_hash::SHA1Hash, extract_hash::SHA1Hash)
    return haskey(bc.cache, (build_hash, extract_hash)) &&
           haskey(bc.logs, build_hash) &&
           haskey(bc.envs, build_hash)
end
function Base.get(bc::BuildCache, build_hash::SHA1Hash, extract_hash::SHA1Hash)
    try
        artifact_hash = bc.cache[(build_hash, extract_hash)]
        log = bc.logs[build_hash]
        env = bc.envs[build_hash]
        return artifact_hash, log, env
    catch
        return nothing, nothing, nothing
    end
end

function Base.get(bc::BuildCache, extract_config::ExtractConfig)
    extract_hash = content_hash(extract_config)
    build_hash = content_hash(extract_config.build.config)
    return get(bc, build_hash, extract_hash)
end


function save_cache(bc::BuildCache)
    open(joinpath(bc.cache_dir, "build_cache.db"); write=true) do io
        for ((build_hash, extract_hash), artifact_hash) in bc.cache
            println(io, "$(bytes2hex(build_hash)) $(bytes2hex(extract_hash)) $(bytes2hex(artifact_hash))")
        end
    end

    # Serialize out logs
    mkpath(joinpath(bc.cache_dir, "logs"))
    for (build_hash, log) in bc.logs
        log_path = joinpath(bc.cache_dir, "logs", "$(bytes2hex(build_hash)).log")
        if filesize(log_path) != length(log)
            open(log_path; write=true) do io
                write(io, log)
            end
        end
    end

    # Serialize out environment blocks
    mkpath(joinpath(bc.cache_dir, "envs"))
    for (build_hash, env) in bc.envs
        env_string = serialize_env_block(env)
        env_path = joinpath(bc.cache_dir, "envs", "$(bytes2hex(build_hash)).env")
        if filesize(env_path) != length(env_string)
            open(env_path; write=true) do io
                write(io, env_string)
            end
        end
    end
end

function safe_readdir(path::AbstractString; kwargs...)
    try
        return readdir(path; kwargs...)
    catch
        return String[]
    end
end

function load_cache(cache_dir::String = default_buildcache_dir())
    cache = Dict{Tuple{SHA1Hash,SHA1Hash},SHA1Hash}()
    logs = Dict{SHA1Hash,String}()
    envs = Dict{SHA1Hash,Dict{String,String}}()
    try
        # Parse artifact mapping cache
        open(joinpath(cache_dir, "build_cache.db"); read=true) do io
            for line in readlines(io)
                build_hash, extract_hash, artifact_hash = split(line, " ")
                cache[(SHA1Hash(build_hash), SHA1Hash(extract_hash))] = SHA1Hash(artifact_hash)
            end
        end

        # Parse logs
        for log_filename in safe_readdir(joinpath(cache_dir, "logs"))
            if !endswith(log_filename, ".log")
                continue
            end
            local build_hash
            try
                build_hash = SHA1Hash(log_filename[1:end-4])
                logs[build_hash] = String(read(joinpath(cache_dir, "logs", log_filename)))
            catch
                # Just silently skip log files we can't read or who have an improper name
                @debug("Can't read logfile $(log_filename)")
                continue
            end
        end

        # Parse environment blocks
        for env_filename in safe_readdir(joinpath(cache_dir, "envs"))
            if !endswith(env_filename, ".env")
                continue
            end
            local build_hash
            try
                build_hash = SHA1Hash(env_filename[1:end-4])
                
                env_string = String(read(joinpath(cache_dir, "envs", env_filename)))
                envs[build_hash] = parse_env_block(env_string)
            catch
                # Just silently skip env files we can't read or who have an improper name
                @debug("Can't read envfile $(env_filename)")
                continue
            end
        end
    catch e
        if !(isa(e, SystemError) && e.errnum == Base.Libc.ENOENT)
            rethrow(e)
        end
    end
    bc = BuildCache(cache_dir, cache, logs, envs)
    atexit() do
        try
            save_cache(bc)
        catch
        end
    end
    return bc
end

function prune!(bc::BuildCache, depots::Vector{String} = Base.DEPOT_PATH)
    filter!(bc.cache) do (_, artifact_hash)
        return any(isdir(joinpath(depot, "artifacts", bytes2hex(artifact_hash))) for depot in depots)
    end

    # Next, delete any logs or envs that do not have a matching `build_hash` in `bc.cache`
    build_hashes = Set{SHA1Hash}(build_hash for (build_hash, _) in keys(bc.cache))

    function prune_dir(build_hashes, name, ext)
        for filename in safe_readdir(joinpath(bc.cache_dir, name))
            if !endswith(filename, ext)
                continue
            end
            local build_hash
            try
                build_hash = SHA1Hash(filename[1:end-length(ext)])
            catch
                continue
            end
            if build_hash ∉ build_hashes
                rm(joinpath(bc.cache_dir, name, filename); force=true)
            end
        end
    end

    prune_dir(build_hashes, "logs", ".log")
    prune_dir(build_hashes, "envs", ".env")

    filter!(bc.logs) do (build_hash, _)
        return build_hash ∈ build_hashes
    end
    filter!(bc.envs) do (build_hash, _)
        return build_hash ∈ build_hashes
    end
end
