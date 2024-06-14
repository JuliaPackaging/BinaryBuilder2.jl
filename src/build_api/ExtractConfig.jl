using Sandbox, TreeArchival, Pkg, BinaryBuilderProducts, Artifacts, BinaryBuilderAuditor, Pkg

export ExtractConfig, extract!

struct ExtractConfig
    # The build result we're packaging up
    build::BuildResult

    # The extraction script that we're using to copy build results out into our artifacts
    script::String

    # The products that this package will ensure are available
    products::Vector{<:AbstractProduct}

    # In most cases, the platform of the extraction is the platform of the build config,
    # but occasionally we want to do things like build compilers.
    platform::AbstractPlatform

    # TODO: Add an `AuditConfig` field
    #audit::AuditConfig

    # Timing
    to::TimerOutput

    function ExtractConfig(build::BuildResult,
                           script::AbstractString,
                           products::Vector{<:AbstractProduct};
                           platform::AbstractPlatform = build.config.platform.target,
                           audit_config = nothing)
        return new(
            build,
            String(script),
            products,
            platform,
            copy(build.config.to),
        )
    end
end

function Base.show(io::IO, config::ExtractConfig)
    build_config = config.build.config
    print(io, "ExtractConfig($(build_config.src_name), $(build_config.src_version), $(build_config.platform))")
end

function extract_content_hash(extract_script::String, products::Vector{<:AbstractProduct})
    # Similar to the `content_hash()` definition for `BuildConfig`, we construct
    # a string in `hash_buffer` then hash it at the end for the final `content_hash()`.
    hash_buffer = IOBuffer()

    println(hash_buffer, "[extraction_metadata]")
    println(hash_buffer, "  script_hash = $(SHA1Hash(sha1(extract_script)))")
    println(hash_buffer, "[products]")
    library_products = LibraryProduct[p for p in products if isa(p, LibraryProduct)]
    for product in sort(library_products; by = p->p.varname)
        println(hash_buffer, "  $(product.varname) = $(product.paths)")
    end

    return SHA1Hash(sha1(take!(hash_buffer)))
end
function BinaryBuilderSources.content_hash(config::ExtractConfig)
    return extract_content_hash(config.script, config.products)
end

function runshell(config::ExtractConfig; output_dir::String=mktempdir(builds_dir()), shell::Cmd = `/bin/bash`)
    sandbox_config = SandboxConfig(config, output_dir)
    run(config.build.exe, sandbox_config, shell)
end

function SandboxConfig(config::ExtractConfig, output_dir::String; kwargs...)
    # We're going to alter the mounts of the build a bit for extraction.
    mounts = copy(config.build.mounts)

    # First, we're going swap out any mounts for deployed sources in `${prefix}`
    # This results in `${prefix}` containing only the files that were added by our build
    for dest in keys(mounts)
        if startswith(dest, "/workspace/destdir/")
            mounts[dest] = MountInfo(mktempdir(), MountType.Overlayed)
        end
    end

    # Insert a new metadir
    metadir = mktempdir()
    # We want to copy the metadir from the BuildConfig and add our own
    # extraction script.  We copy here so that bash history and whatnot is preserved,
    # but unique for this extraction config.
    rm(metadir)
    cp(mounts["/workspace/metadir"].host_path, metadir)

    extract_script_path = joinpath(metadir, "extract_script.sh")
    open(extract_script_path, write=true) do io
        println(io, "#!/bin/bash")
        println(io, "set -euo pipefail")
        println(io, "source /usr/local/share/bb/save_env_hook")
        println(io, "source /usr/local/share/bb/extraction_utils")
        println(io, config.script)
        println(io, "auto_install_license")
        println(io, "exit 0")
    end
    chmod(extract_script_path, 0o755)

    mounts["/workspace/metadir"] = MountInfo(metadir, MountType.Overlayed)

    # Insert our extraction dir, which is a ReadWrite mount,
    # allowing us to pull the result back out from the overlay nest.
    mounts["/workspace/extract"] = MountInfo(output_dir, MountType.ReadWrite)

    # Insert some more environment variables on top of what was defined by the build config
    env = copy(config.build.config.env)
    env["extract_dir"] = "/workspace/extract"
    env["BB_WRAPPERS_VERBOSE"] = "true"
    return SandboxConfig(config.build.config, mounts; env, kwargs...)
end

function BinaryBuilderAuditor.audit!(config::ExtractConfig, artifact_dir::String; kwargs...)
    build_config = config.build.config
    meta = build_config.meta
    @timeit config.to "audit" begin
        prefix_alias = target_prefix(build_config.platform)
        # Load JLLInfo structures for each dependency
        dep_jll_infos = JLLInfo[parse_toml_dict(d; depot=meta.universe.depot_path) for d in build_config.source_trees[prefix_alias] if isa(d, JLLSource)]
        return audit!(
            artifact_dir,
            LibraryProduct[p for p in config.products if isa(p, LibraryProduct)],
            dep_jll_infos;
            prefix_alias,
            env = build_config.env,
            verbose = meta.verbose,
            kwargs...
        )
    end
end

function extract!(config::ExtractConfig;
                  disable_cache::Bool = false,
                  debug_modes = config.build.config.meta.debug_modes)
    local artifact_hash, run_status, run_exception, collector
    audit_result = nothing
    build_config = config.build.config
    meta = build_config.meta
    meta.extractions[config] = nothing

    if build_cache_enabled(build_config.meta) && !disable_cache
        artifact_hash, extract_log_artifact_hash, _, _ = get(meta.build_cache, config)
        if artifact_hash !== nothing
            if meta.verbose
                extract_hash = content_hash(config)
                build_hash = content_hash(config.build.config)
                @info("Extraction cached", config, extract_hash, build_hash)
            end
            result = ExtractResult_cached(config, artifact_hash, extract_log_artifact_hash)
            meta.extractions[config] = result
            return result
        end
    end

    if "extract-start" ∈ debug_modes
        @warn("Launching debug shell")
        runshell(config; verbose=meta.verbose)
    end

    extract_log_io = IOBuffer()
    @timeit config.to "extract" begin
        in_universe(meta.universe) do env
            artifact_hash = Pkg.Artifacts.create_artifact() do artifact_dir
                sandbox_config, collector = sandbox_and_collector(
                    extract_log_io, config, artifact_dir;
                    verbose=meta.verbose,
                )
                run_status, run_exception = run_trycatch(config.build.exe, sandbox_config, `/workspace/metadir/extract_script.sh`)

                # Before the artifact is sealed, we run our audit passes, as they may alter the binaries, but only if the extraction was successful
                if run_status == :success
                    audit_result = audit!(config, artifact_dir)
                end
            end
        end
    end

    # Run over the extraction result, ensure that all products can be located:
    unlocatable_products = AbstractProduct[]
    extract_prefix = artifact_path(meta.universe, artifact_hash)
    for product in config.products
        if locate(product, extract_prefix;
                  env=config.build.env) === nothing
            push!(unlocatable_products, product)
        end
    end

    if !isempty(unlocatable_products) && run_status == :success
        @error("Unable to locate $(length(unlocatable_products)) products:", unlocatable_products, platform=config.build.config.platform, run_status)
        error()
    end

    # Wait for our output collector to finish, then take the IO output
    wait(collector)
    extract_log = String(take!(extract_log_io))

    # Generate "log" artifact that will later be packaged up.
    log_artifact_hash = in_universe(meta.universe) do env
        Pkg.Artifacts.create_artifact() do artifact_dir
            open(joinpath(artifact_dir, "$(build_config.src_name)-extract.log"); write=true) do io
                write(io, extract_log)
            end
        end
    end

    result = ExtractResult(
        config,
        run_status,
        run_exception,
        artifact_hash,
        log_artifact_hash,
        audit_result,
        extract_log,
    )
    if build_cache_enabled(meta) && run_status == :success
        put!(meta.build_cache, result)
    end
    meta.extractions[config] = result
    if "extract-stop" ∈ debug_modes || ("extract-error" ∈ debug_modes && run_status != :success)
        @warn("Launching debug shell")
        runshell(result)
    end
    return result
end
