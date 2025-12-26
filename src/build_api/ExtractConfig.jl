using Sandbox, TreeArchival, Pkg, BinaryBuilderProducts, Artifacts, BinaryBuilderAuditor, Pkg, Infiltrator

export ExtractConfig, extract!


function guess_build_target(build::BuildResult)
    target = guess_target(build.config)
    if target === nothing
        throw(ArgumentError("Cannot guess target platform for $(build); you must manually specify `platform` to `ExtractConfig()`!"))
    end
    return target
end

struct ExtractConfig
    # The build result we're packaging up
    build::BuildResult

    # The extraction script that we're using to copy build results out into our artifacts
    script::String

    # The products that this package will ensure are available
    products::Vector{<:AbstractProduct}

    # A `BuildResult` can actually contain multiple output prefixes; depending on how
    # many different toolchains with different targets you ask for.  Here, you must
    # declare which toolchain you want to extract from.  We will only allow access
    # to that particular prefix when extracting.  Usually, this is just something
    # like "target", and that gives access to what `$prefix` referred to within the
    # build environment, but in the event that there were multiple build toolchains,
    # and things were installed to `$host_prefix` or similar, this may instead be
    # "host" and the extraction script must extract from `$host_prefix`, not `$prefix`.
    target_spec::BuildTargetSpec

    # In most cases, the platform of the extraction is the platform of the build config,
    # but occasionally we want to do things like build compilers, so this can be a crossplatform.
    platform::AbstractPlatform

    # A list of extraction results that we rely upon; this is used when a single
    # build generates multiple extractions, and there is a dependency relationship
    # between the outputs (e.g. the LLVM build generates `Clang_jll` as well as
    # `libLLVM_jll`, and `clang` depends on `libLLVM`, even before `libLLVM_jll.jl`
    # has been packaged).
    inter_deps::Dict{String,<:Any}

    # TODO: Add an `AuditConfig` field
    #audit::AuditConfig

    # Timing
    to::TimerOutput

    function ExtractConfig(build::BuildResult,
                           script::AbstractString,
                           products::Vector{<:AbstractProduct};
                           target_spec::BuildTargetSpec = get_default_target_spec(build.config),
                           platform::AbstractPlatform = target_spec.platform.target,
                           inter_deps::Dict{String,<:Any} = Dict{String,Any}(),
                           audit_config = nothing)
        return new(
            build,
            String(script),
            products,
            target_spec,
            platform,
            inter_deps,
            copy(build.config.to),
        )
    end
end
AbstractBuildMeta(config::ExtractConfig) = AbstractBuildMeta(config.build)
BuildConfig(config::ExtractConfig) = config.build.config

function Base.show(io::IO, config::ExtractConfig)
    build_config = BuildConfig(config)
    print(io, "ExtractConfig($(build_config.src_name), $(build_config.src_version), $(config.platform))")
end

function extract_content_hash(extract_script::String, products::Vector{<:AbstractProduct})
    # Similar to the `content_hash()` definition for `BuildConfig`, we construct
    # a string in `hash_buffer` then hash it at the end for the final `content_hash()`.
    hash_buffer = IOBuffer()

    println(hash_buffer, "[extraction_metadata]")
    println(hash_buffer, "  script_hash = $(SHA1Hash(sha1(extract_script)))")
    println(hash_buffer, "[products]")
    for product in sort(products; by = p->p.varname)
        println(hash_buffer, "  $(product.varname) = $(product.paths)")
    end
    # println(hash_buffer, "[inter_deps]")
    # for config in inter_dep_configs
    #     println(hash_buffer, "  $(config.name) - $(content_hash(config))")
    # end

    hash_buffer = String(take!(hash_buffer))
    @debug("ExtractConfig hash buffer:\n$(hash_buffer)")
    return SHA1Hash(sha1(hash_buffer))
end
function BinaryBuilderSources.content_hash(config::ExtractConfig)
    return extract_content_hash(config.script, config.products)
end

function runshell(config::ExtractConfig; output_dir::String=mktempdir(builds_dir(".")), shell::Cmd = `/bin/bash`)
    sandbox_config = SandboxConfig(config, output_dir; save_env=false)
    run(config.build.exe, sandbox_config, ignorestatus(shell))
end

function SandboxConfig(config::ExtractConfig, output_dir::String, mounts = copy(config.build.mounts); kwargs...)
    # We're going to alter the mounts of the build a bit for extraction.
    # First, we're going swap out any mounts for deployed sources in `${prefix}`
    # This results in `${prefix}` containing only the files that were added by our build
    # We drop any prefixes that do not match our `target_spec`.
    target_dest = target_prefix(config.target_spec)
    mounts = filter(mounts) do (dest, _)
        !startswith(dest, "/workspace/destdir/")
    end
    mounts[target_dest] = MountInfo(mktempdir(), MountType.OverlayedReadOnly)


    # Insert a new metadir
    metadir = mktempdir()
    # We want to copy the metadir from the BuildConfig and add our own
    # extraction script.  We copy here so that bash history and whatnot is preserved,
    # but unique for this extraction config.
    rm(metadir)
    cp(mounts[metadir_prefix()].host_path, metadir)

    extract_script_path = joinpath(metadir, "extract_script.sh")
    open(extract_script_path, write=true) do io
        println(io, "#!/bin/bash")
        println(io, "set -euo pipefail")
        println(io, "source $(scripts_prefix())/save_env_hook")
        println(io, "source $(scripts_prefix())/extraction_utils")
        println(io, config.script)
        println(io, "auto_install_license")
        println(io, "exit 0")
    end
    chmod(extract_script_path, 0o755)

    mounts[metadir_prefix()] = MountInfo(metadir, MountType.Overlayed)

    # Insert our extraction dir, which is a ReadWrite mount,
    # allowing us to pull the result back out from the overlay nest.
    mounts["/workspace/extract"] = MountInfo(output_dir, MountType.ReadWrite)

    # Insert some more environment variables on top of what was defined by the build config
    env = copy(config.build.config.env)
    env["extract_dir"] = "/workspace/extract"
    env["BB_WRAPPERS_VERBOSE"] = "true"
    env["BB_SAVE_ENV"] = "false"
    return SandboxConfig(config.build.config, mounts; env, kwargs...)
end

function load_dep_jllinfos(config::ExtractConfig)
    build_config = config.build.config
    meta = AbstractBuildMeta(config)
    jll_infos = JLLInfo[]
    prefix_alias = target_prefix(config.target_spec)
    for d in build_config.source_trees[prefix_alias]
        if isa(d, JLLSource) && platforms_match(d.platform, host_if_crossplatform(config.platform))
            jll_info = try
                parse_toml_dict(d; depot=meta.universe.depot_path)
            catch
                @error("Unable to parse JLLInfo TOML dict for dependency", dep=d)
                rethrow()
            end
            push!(jll_infos, jll_info)
        end
    end
    return jll_infos
end


function BinaryBuilderAuditor.audit!(config::ExtractConfig, artifact_dir::String; verbose::Bool = AbstractBuildMeta(config).verbose, kwargs...)
    build_config = config.build.config
    meta = AbstractBuildMeta(config)
    @timeit config.to "audit" begin
        prefix_alias = target_prefix(config.target_spec)
        # Load JLLInfo structures for each dependency
        dep_jll_infos = load_dep_jllinfos(config)
        platform = host_if_crossplatform(config.platform)

        # Get libraries for all JLL dependencies
        get_library_products(jart::JLLBuildInfo) = filter(x -> isa(x, JLLLibraryProduct), jart.products)
        get_library_products(jll::JLLInfo, platform::AbstractPlatform) = get_library_products(select_platform(jll, platform))
        dep_libs = Dict{Symbol, Vector{JLLLibraryProduct}}()
        for dep in dep_jll_infos
            dep_libs[Symbol(dep.name)] = get_library_products(dep, platform)
        end
        # Get libraries for all inter-dependencies
        for (inter_dep_name, inter_dep) in config.inter_deps
            dep_libs[Symbol(inter_dep_name)] = inter_dep.audit_result.jll_lib_products
        end
        return audit!(
            artifact_dir,
            LibraryProduct[p for p in config.products if isa(p, LibraryProduct)],
            dep_libs;
            prefix_alias,
            env = config.build.env,
            platform,
            kwargs...
        )
    end
end

function find_unlocatable_products(config::ExtractConfig, prefix)
    unlocatable_products = []
    for product in config.products
        if locate(product, prefix;
                  env=config.build.env,
                  platform=host_if_crossplatform(config.platform)) === nothing
            push!(unlocatable_products, product)
        end
    end
    return unlocatable_products
end

function extract!(config::ExtractConfig;
                  disable_cache::Bool = !build_cache_enabled(AbstractBuildMeta(config)),
                  debug_modes = config.build.config.meta.debug_modes,
                  verbose::Bool = AbstractBuildMeta(config).verbose)
    local artifact_hash, run_status, run_exception, collector
    audit_result = nothing
    build_config = BuildConfig(config)
    meta = AbstractBuildMeta(config)
    meta.extractions[config] = nothing

    # If we're asking for a dry run, skip out
    if "extract" ∈ meta.dry_run
        if verbose
            @info("Dry-run extraction", config)
        end
        result = ExtractResult_skipped(config)
        meta.extractions[config] = result
        return result
    end
    @assert config.build.status != :skipped

    # Hit our build cache and see if we've already done this exact extraction.
    if !disable_cache
        artifact_hash, extract_log_artifact_hash, _, _ = get(meta.build_cache, config)
        if artifact_hash !== nothing
            if verbose
                extract_hash = content_hash(config)
                build_hash = content_hash(config.build.config)
                @info("Extraction cached", config, extract_hash, build_hash, path=artifact_path(artifact_hash))
            end
            try
                result = ExtractResult_cached(config, artifact_hash, extract_log_artifact_hash)
                meta.extractions[config] = result
                return result
            catch exception
                @error("Error while reading from build cache", exception=(exception, catch_backtrace()))
            end
        else
            extract_hash = content_hash(config)
            build_hash = content_hash(config.build.config)
            @debug("Extraction not cached", config, extract_hash, build_hash)
        end
    end

    if "extract-start" ∈ debug_modes
        @warn("Launching debug shell")
        runshell(config)
    end

    extract_log_io = IOBuffer()
    @timeit config.to "extract" begin
        in_universe(meta.universe) do env
            artifact_hash = Pkg.Artifacts.create_artifact() do artifact_dir
                sandbox_config, collector = sandbox_and_collector(extract_log_io, config, artifact_dir; verbose)
                run_status, run_exception = run_trycatch(config.build.exe, sandbox_config, `$(metadir_prefix())/extract_script.sh`)

                # Run over the extraction result, ensure that all products can be located:
                if run_status == :success
                    unlocatable_products = find_unlocatable_products(config, artifact_dir)
                    if length(unlocatable_products) > 0
                        @error("""
                            Unable to locate $(length(unlocatable_products)) products!
                            names: $(join([p.varname for p in unlocatable_products], ", "))
                            Running again with debugging enabled, then erroring out!
                            """,
                            platform=host_if_crossplatform(config.platform),
                            run_status,
                        )

                        withenv("JULIA_DEBUG" => "all") do
                            find_unlocatable_products(config, artifact_dir)
                        end
                        run_status = :failed
                    end
                end

                if run_status == :success
                    # Before the artifact is sealed, we run our audit passes, as they may alter the binaries, but only if the extraction was successful
                    try
                        audit_result = audit!(config, artifact_dir)
                        if !success(audit_result)
                            @error("Audit failed, Running again with debugging enabled, then erroring out!")
                            show(audit_result)
                            withenv("JULIA_DEBUG" => "all") do
                                audit!(config, artifact_dir)
                            end
                            run_status = :failed
                        end
                    catch exception
                        # this shouldn't happen, but there's a lot going on in the audit, so let's be defensive
                        @error("Audit errored", exception=(exception, catch_backtrace()))
                        run_status = :errored
                        run_exception = exception
                    end
                end
            end
        end
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
            if audit_result !== nothing
                open(joinpath(artifact_dir, "$(build_config.src_name)-audit.log"); write=true) do io
                    show(io, audit_result)
                end
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
        @warn("""
        Dropping into Julia REPL, variables of interest include `meta::BuildMeta`, `config::ExtractConfig` and `result::ExtractResult`
        Use `runshell(result; verbose)` to enter debug shell within extraction environment.
        """)
        @infiltrate
    end
    return result
end
