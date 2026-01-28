using MultiHashParsing, TOML, StructEquality
export BuildCache

"""
    BuildCacheBuildEntry

The `BuildCache` records a few pieces of information that exist per-build,
such as the build environment and the build log.  This structure is what holds
those values.  See `BuildCacheExtractEntry` for the pieces that are per-
extraction instead.
"""
@struct_hash_equal struct BuildCacheBuildEntry
    log_artifact::SHA1Hash
    env::Dict{String,String}
end


"""
    BuildCacheExtractEntry

The `BuildCache` primarily stores pieces of information related to a particular
extraction, such as the extraction artifact ID, the extraction log, the library
dependency structure, etc...  All the pieces needed to actually perform JLL
packaging without needing to run a build again.

This struct contains those pieces, see `BuildCacheBuildEntry` for the pieces
that are per build, not per extraction.
"""
@struct_hash_equal struct BuildCacheExtractEntry
    artifact::SHA1Hash
    log_artifact::SHA1Hash
    jll_lib_products::Vector{JLLLibraryProduct}
end

"""
    BuildCache

This cache stores all necessary information to skip previously successful builds.
If a previous build and extraction generated an artifact, stored its logs, analyzed
the library dependency structure, etc... all of that is stored within the
`BuildCache` so that future builds of _the exact same source_ can be skipped.
The cache keys are purposefully quite sensitive (if anything in the sources, or even
just the sources of BinaryBuilder2 changes, the build will be re-run).

The `BuildCache` is serialized to disk and loaded on future BinaryBuilder2 sessions.
Future work includes creating a networked backend to allow sharing of build cache
objects across machines (or even the internet).

To disable the BuildCache, see the `--disable-caches` argument to `build_tarballs.jl`,
or the `disabled_caches` keyword argument to `BuildMeta`.
"""
struct BuildCache
    # Where our cache database are serialized out to
    cache_dir::String

    # This is where our artifacts are stored.  For simplicity, we lock ourselves to a
    # single artifact directory rather than doing the typical depot-based lookup.
    artifacts_dir::String

    # This maps from spec_hash(::BuildConfig) -> BuildCacheBuildEntry
    build_entries::Dict{SHA1Hash,BuildCacheBuildEntry}

    # This maps from spec_hash(::ExtractConfig) -> BuildCacheExtractEntry
    extract_entries::Dict{SHA1Hash,BuildCacheExtractEntry}
end

function Base.show(io::IO, bc::BuildCache)
    println(io, "BuildCache")
    println(io, "  - database in $(bc.cache_dir)")
    println(io, "  - artifacts in $(bc.artifacts_dir)")
    println(io, "  - $(length(bc.build_entries)) builds")
    println(io, "  - $(length(bc.extract_entries)) extractions")
end

default_buildcache_dir() = @get_scratch!("buildcache_database")

function BuildCache(;cache_dir = default_buildcache_dir(), artifacts_dir = joinpath(first(Base.DEPOT_PATH), "artifacts"))
    mkpath(cache_dir)
    mkpath(artifacts_dir)
    return BuildCache(
        cache_dir,
        artifacts_dir,
        Dict{SHA1Hash,BuildCacheBuildEntry}(),
        Dict{SHA1Hash,BuildCacheExtractEntry}(),
    )
end

function Base.put!(bc::BuildCache,
                   build_hash::SHA1Hash, extract_hash::SHA1Hash,
                   b::BuildCacheBuildEntry, e::BuildCacheExtractEntry)
    bc.build_entries[build_hash] = b
    bc.extract_entries[extract_hash] = e
end

function Base.put!(bc::BuildCache,
                   build_hash::SHA1Hash, extract_hash::SHA1Hash,
                   build_log_artifact_hash::SHA1Hash, env::Dict{String,String},
                   artifact_hash::SHA1Hash, extract_log_artifact_hash::SHA1Hash, jll_lib_products::Vector{JLLLibraryProduct})
    put!(
        bc,
        build_hash, extract_hash,
        BuildCacheBuildEntry(
            build_log_artifact_hash,
            env,
        ),
        BuildCacheExtractEntry(
            artifact_hash,
            extract_log_artifact_hash,
            jll_lib_products,
        ),
    )
end
function Base.put!(bc::BuildCache, extract_result::ExtractResult)
    build_result = extract_result.config.build
    return put!(
        bc,
        spec_hash(build_result.config),
        spec_hash(extract_result.config),
        build_result.log_artifact,
        build_result.env,
        SHA1Hash(extract_result.artifact),
        extract_result.log_artifact,
        extract_result.jll_lib_products,
    )
end

function Base.haskey(bc::BuildCache, build_hash::SHA1Hash, extract_hash::SHA1Hash)
    # Fail out if we don't have mappings for these hashes at all
    if !haskey(bc.build_entries, build_hash) || !haskey(bc.extract_entries, extract_hash)
        return false
    end

    build_entry = bc.build_entries[build_hash]
    extract_entry = bc.extract_entries[extract_hash]

    # Only return true if all of the artifacts recorded here still exist on-disk
    _isdir(hash) = isdir(joinpath(bc.artifacts_dir, bytes2hex(hash)))
    return all(_isdir.([build_entry.log_artifact, extract_entry.artifact, extract_entry.log_artifact]))
end

function Base.get(bc::BuildCache, build_hash::SHA1Hash, extract_hash::SHA1Hash)
    return (
        get(bc.build_entries, build_hash, nothing),
        get(bc.extract_entries, extract_hash, nothing),
    )
end

function Base.get(bc::BuildCache, extract_config::ExtractConfig)
    build_hash = spec_hash(extract_config.build.config)
    extract_hash = spec_hash(extract_config)
    return get(bc, build_hash, extract_hash)
end


function save_cache(bc::BuildCache)
    # Write out `artifacts_dir` so that we can persist that setting properly
    open(joinpath(bc.cache_dir, "artifacts_dir"); write=true) do io
        println(io, bc.artifacts_dir)
    end

    # Serialize out build entries
    mkpath(joinpath(bc.cache_dir, "envs"))
    open(joinpath(bc.cache_dir, "build_entries.db"); write=true) do io
        for (build_hash, b) in bc.build_entries
            println(io, "$(bytes2hex(build_hash)) $(bytes2hex(b.log_artifact))")

            # Environment mappings get saved to a separate file, to ease serialization
            env_string = serialize_env_block(b.env)
            env_path = joinpath(bc.cache_dir, "envs", "$(bytes2hex(build_hash)).env")
            if filesize(env_path) != length(env_string)
                open(env_path; write=true) do io
                    write(io, env_string)
                end
            end
        end
    end

    # Serialize out extraction output cache
    mkpath(joinpath(bc.cache_dir, "jll_lib_products"))
    open(joinpath(bc.cache_dir, "extract_entries.db"); write=true) do io
        for (extract_hash, e) in bc.extract_entries
            println(io, "$(bytes2hex(extract_hash)) $(bytes2hex(e.artifact)) $(bytes2hex(e.log_artifact))")

            # JLL library information gets saved to a separate file, to ease serialization
            toml_io = IOBuffer()
            TOML.print(
                toml_io,
                Dict("jll_lib_products" => generate_toml_dict.(e.jll_lib_products))
            )
            jll_lib_product_str = String(take!(toml_io))
            jlp_path = joinpath(bc.cache_dir, "jll_lib_products", "$(bytes2hex(extract_hash)).jlp")
            if filesize(jlp_path) != length(jll_lib_product_str)
                open(jlp_path; write=true) do jlp_io
                    write(jlp_io, jll_lib_product_str)
                end
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

function safe_open(func, file; kwargs...)
    if isfile(file)
        open(func, file; kwargs...)
    end
end

function load_cache(cache_dir::String = default_buildcache_dir())
    artifacts_dir = Ref(joinpath(first(Base.DEPOT_PATH), "artifacts"))

    # Iterate over `build_entries.db`, try to reconstitute `BuildCacheBuildEntry` objects
    build_entries = Dict{SHA1Hash,BuildCacheBuildEntry}()
    safe_open(joinpath(cache_dir, "build_entries.db"); read=true) do io
        for line in readlines(io)
            # Try to read this line's hashes
            build_hash, log_artifact_hash = split(line, " ")

            # Immediately look to see if we have an environment mapping
            env_path = joinpath(cache_dir, "envs", "$(build_hash).env")
            if !isfile(env_path)
                continue
            end

            # Parse them as SHA1Hash'es
            try
                build_hash = SHA1Hash(build_hash)
                log_artifact_hash = SHA1Hash(log_artifact_hash)
            catch
                continue
            end

            env = parse_env_block(String(read(env_path)))
            build_entries[build_hash] = BuildCacheBuildEntry(
                log_artifact_hash,
                env,
            )
        end
    end

    # Iterate over `extract_entries.db`, try to reconstitute `BuildCacheExtractEntry` objects
    extract_entries = Dict{SHA1Hash,BuildCacheExtractEntry}()
    safe_open(joinpath(cache_dir, "extract_entries.db"); read=true) do io
        for line in readlines(io)
            # Try to read this line's hashes
            extract_hash, artifact_hash, log_artifact_hash = split(line, " ")
            
            # Immediately look to see if we have a jll_lib_products mapping
            jlp_path = joinpath(cache_dir, "jll_lib_products", "$(extract_hash).jlp")
            if !isfile(jlp_path)
                @debug("skip: jlp nonexistent", extract_hash)
                continue
            end

            local jll_lib_products
            try
                jll_lib_products = TOML.parsefile(jlp_path)["jll_lib_products"]
            catch
                @debug("skip: jlp malformed", extract_hash)
                continue
            end

            # Parse them as SHA1Hash'es, skipping if anything isn't working
            try
                extract_hash = SHA1Hash(extract_hash)
                artifact_hash = SHA1Hash(artifact_hash)
                log_artifact_hash = SHA1Hash(log_artifact_hash)
            catch
                @debug("skip: hashes malformed", extract_hash)
                continue
            end

            extract_entries[extract_hash] = BuildCacheExtractEntry(
                artifact_hash,
                log_artifact_hash,
                parse_toml_dict.(JLLLibraryProduct, jll_lib_products),
            )
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

    bc = BuildCache(cache_dir, artifacts_dir[], build_entries, extract_entries)
    atexit() do
        try
            save_cache(bc)
        catch
        end
    end
    return bc
end

function prune!(bc::BuildCache)
    _isdir(hash) = isdir(joinpath(bc.artifacts_dir, bytes2hex(hash)))
    
    # See which artifacts are still existant
    filter!(bc.build_entries) do (build_hash, b)
        return _isdir(b.log_artifact)
    end
    filter!(bc.extract_entries) do (extract_hash, e)
        return _isdir(e.artifact) && _isdir(e.log_artifact)
    end

    function should_delete(hashes, ext, filename)
        # Delete anything that doesn't have the right extension
        if !endswith(filename, ext)
            return true
        end

        # Delete anything that isn't a hash name:
        try
            hash = SHA1Hash(filename[1:end-length(ext)])
        catch
            return true
        end

        # Delete anything that has a hash that doesn't appear in `hashes`:
        if hash ∉ hashes
            return true
        end

        # Keep everything else
        return false
    end

    function prune_aux_dir(hashes, ext, subdir)
        for filename in safe_readdir(subdir)
            if should_delete(hashes, ext, filename)
                rm(joinpath(subdir, filename); force=true)
            end
        end
    end

    # Next, prune the environments and jll_lib_products to match the hashes that are preserved
    prune_aux_dir(keys(bc.build_entries), ".env", "envs")
    prune_aux_dir(keys(bc.extract_entries), ".jlp", "jll_lib_products")
end
