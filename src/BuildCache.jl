using MultiHashParsing, TOML
export BuildCache

struct BuildCache
    cache_dir::String
    # This maps from content_hash(::BuildConfig, extract_args...) -> artifact hash
    extractions::Dict{Tuple{SHA1Hash,SHA1Hash},SHA1Hash}
    # This maps from content_hash(::BuildConfig, extract_args...) -> extract log artifact hash
    extract_logs::Dict{Tuple{SHA1Hash,SHA1Hash},SHA1Hash}
    # This maps from content_hash(::BuildConfig) -> build log artifact hash
    build_logs::Dict{SHA1Hash,SHA1Hash}
    # This maps from content_hash(::BuildConfig) -> env dict
    envs::Dict{SHA1Hash,Dict{String,String}}

    # This is where our artifacts are stored.  For simplicity, we lock ourselves to a
    # single artifact directory rather than doing the typical depot-based lookup.
    artifacts_dir::String
end

function Base.show(io::IO, bc::BuildCache)
    println(io, "BuildCache")
    println(io, "  - database path in $(bc.cache_dir)")
    println(io, "  - $(length(bc.extractions)) extractions")
    println(io, "  - $(length(bc.build_logs)) build logs, $(length(bc.extract_logs)) extraction logs")
    println(io, "  - $(length(bc.envs)) environment maps")
    println(io, "  - artifacts in $(bc.artifact_dir)")
end

default_buildcache_dir() = @get_scratch!("buildcache_database")

function BuildCache(;cache_dir = default_buildcache_dir(), artifacts_dir = joinpath(first(Base.DEPOT_PATH), "artifacts"))
    mkpath(cache_dir)
    mkpath(artifacts_dir)
    return BuildCache(
        cache_dir,
        Dict{Tuple{SHA1Hash,SHA1Hash},SHA1Hash}(),
        Dict{Tuple{SHA1Hash,SHA1Hash},SHA1Hash}(),
        Dict{SHA1Hash,SHA1Hash}(),
        Dict{SHA1Hash,Dict{String,String}}(),
        artifacts_dir,
    )
end

function Base.put!(bc::BuildCache, build_hash::SHA1Hash, extract_hash::SHA1Hash,
                   artifact_hash::SHA1Hash, extract_log_artifact_hash::SHA1Hash, build_log_artifact_hash::SHA1Hash, env::Dict{String,String})
    bc.extractions[(build_hash, extract_hash)] = artifact_hash
    bc.extract_logs[(build_hash, extract_hash)] = extract_log_artifact_hash
    bc.build_logs[build_hash] = build_log_artifact_hash
    bc.envs[build_hash] = env
end
function Base.put!(bc::BuildCache, extract_result::ExtractResult)
    build_result = extract_result.config.build
    return put!(
        bc,
        content_hash(build_result.config),
        content_hash(extract_result.config),
        SHA1Hash(extract_result.artifact),
        extract_result.log_artifact,
        build_result.log_artifact,
        build_result.env,
    )
end

function Base.haskey(bc::BuildCache, build_hash::SHA1Hash, extract_hash::SHA1Hash)
    function haskeydir(dict, arg)
        return haskey(dict, arg) && isdir(joinpath(bc.artifacts_dir, bytes2hex(dict[arg])))
    end
    return haskeydir(bc.extractions, (build_hash, extract_hash)) &&
           haskeydir(bc.extract_logs, (build_hash, extract_hash)) &&
           haskeydir(bc.build_logs, build_hash) &&
           haskey(bc.envs, build_hash)
end
function Base.get(bc::BuildCache, build_hash::SHA1Hash, extract_hash::SHA1Hash)
    if !haskey(bc, build_hash, extract_hash)
        return nothing, nothing, nothing, nothing
    end
    artifact_hash = bc.extractions[(build_hash, extract_hash)]
    extract_log_artifact_hash = bc.extract_logs[(build_hash, extract_hash)]
    build_log_artifact_hash = bc.build_logs[build_hash]
    env = bc.envs[build_hash]
    return artifact_hash, extract_log_artifact_hash, build_log_artifact_hash, env
end

function Base.get(bc::BuildCache, extract_config::ExtractConfig)
    extract_hash = content_hash(extract_config)
    build_hash = content_hash(extract_config.build.config)
    return get(bc, build_hash, extract_hash)
end


function save_cache(bc::BuildCache)
    # Serialize out extraction output cache
    open(joinpath(bc.cache_dir, "extractions_cache.db"); write=true) do io
        for ((build_hash, extract_hash), artifact_hash) in bc.extractions
            println(io, "$(bytes2hex(build_hash)) $(bytes2hex(extract_hash)) $(bytes2hex(artifact_hash))")
        end
    end

    # Serialize out log caches
    open(joinpath(bc.cache_dir, "extract_log_cache.db"); write=true) do io
        for ((build_hash, extract_hash), log_artifact_hash) in bc.extract_logs
            println(io, "$(bytes2hex(build_hash)) $(bytes2hex(extract_hash)) $(bytes2hex(log_artifact_hash))")
        end
    end
    open(joinpath(bc.cache_dir, "build_log_cache.db"); write=true) do io
        for (build_hash, log_artifact_hash) in bc.build_logs
            println(io, "$(bytes2hex(build_hash)) $(bytes2hex(log_artifact_hash))")
        end
    end
    open(joinpath(bc.cache_dir, "artifacts_dir"); write=true) do io
        println(io, bc.artifacts_dir)
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
    artifacts_dir = Ref(joinpath(first(Base.DEPOT_PATH), "artifacts"))
    cache = Dict{Tuple{SHA1Hash,SHA1Hash},SHA1Hash}()
    extract_logs = Dict{Tuple{SHA1Hash,SHA1Hash},SHA1Hash}()
    build_logs = Dict{SHA1Hash,SHA1Hash}()
    envs = Dict{SHA1Hash,Dict{String,String}}()

    function safe_open(func, file; kwargs...)
        if isfile(file)
            open(func, file; kwargs...)
        end
    end

    # Parse extractions artifact mapping cache
    safe_open(joinpath(cache_dir, "extractions_cache.db"); read=true) do io
        for line in readlines(io)
            build_hash, extract_hash, artifact_hash = split(line, " ")
            cache[(SHA1Hash(build_hash), SHA1Hash(extract_hash))] = SHA1Hash(artifact_hash)
        end
    end

    # Parse logs artifact mapping cache
    safe_open(joinpath(cache_dir, "extract_log_cache.db"); read=true) do io
        for line in readlines(io)
            build_hash, extract_hash, log_artifact_hash = split(line, " ")
            extract_logs[(SHA1Hash(build_hash), SHA1Hash(extract_hash))] = SHA1Hash(log_artifact_hash)
        end
    end
    safe_open(joinpath(cache_dir, "build_log_cache.db"); read=true) do io
        for line in readlines(io)
            build_hash, log_artifact_hash = split(line, " ")
            build_logs[SHA1Hash(build_hash)] = SHA1Hash(log_artifact_hash)
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

    safe_open(joinpath(cache_dir, "artifacts_dir"); read=true) do io
        new_artifacts_dir = first(readlines(io))

        # We had a bug for a while that wrote out an empty string here, which is totally busted.
        # Let's reject that to get things working without having to fix all the installs manually.
        if !isempty(new_artifacts_dir)
            artifacts_dir[] = new_artifacts_dir
        end
    end

    bc = BuildCache(cache_dir, cache, extract_logs, build_logs, envs, artifacts_dir[])
    atexit() do
        try
            save_cache(bc)
        catch
        end
    end
    return bc
end

function prune!(bc::BuildCache)
    function artifact_exists((_, h),)
        return isdir(joinpath(bc.artifacts_dir, bytes2hex(h)))
    end
    # See which artifacts are still existant
    filter!(artifact_exists, bc.extractions)
    filter!(artifact_exists, bc.extract_logs)
    filter!(artifact_exists, bc.build_logs)
    build_hashes = intersect(
        Set{SHA1Hash}(build_hash for (build_hash, _) in keys(bc.extractions)),
        Set{SHA1Hash}(build_hash for (build_hash, _) in keys(bc.extract_logs)),
        Set{SHA1Hash}(keys(bc.build_logs)),
    )

    # Drop any items in our cache that are partially deleted
    filter!((((build_hash, _), _),) -> build_hash ∈ build_hashes, bc.extractions)
    filter!((((build_hash, _), _),) -> build_hash ∈ build_hashes, bc.extract_logs)
    filter!(((build_hash, _),) -> build_hash ∈ build_hashes, bc.build_logs)

    # Next, prune the environments to match the build hashes that are preserved
    for filename in safe_readdir(joinpath(bc.cache_dir, "envs"))
        if !endswith(filename, ".env")
            continue
        end
        try
            build_hash = SHA1Hash(filename[1:end-4])
            if build_hash ∉ build_hashes
                rm(joinpath(bc.cache_dir, "envs", filename); force=true)
            end
        catch
            continue
        end
    end
    filter!(((build_hash, _),) -> build_hash ∈ build_hashes, bc.envs)
end
