using PrecompileTools

# Warm up `build_tarballs()` on a small recipe: a dry run, then a real run whose build and
# extraction are cache hits (from a build cache seeded below) so that packaging runs, and
# finally preparing and deploying JLLs as a source tree.
#
# Pass `build_tarballs()` the keyword types a real `build_tarballs.jl` does, as Julia
# specializes on them.
#
# The universe is pinned to the installed registries and Pkg is kept offline, so this
# needs no network.  Failures are ignored, as this is only a latency optimization.

function precompile_recipe()
    host_linux = Platform(arch(HostPlatform()), "linux")
    build_tarballs(;
        src_name = "precompile",
        src_version = v"1.0.0",
        sources = [GitSource("https://example.com/precompile.git", "0"^40)],
        script = "true",
        products = [LibraryProduct("libz", :libz)],
        host_toolchains = [CToolchain(;vendor=:gcc_bootstrap), HostToolsToolchain(), CMakeToolchain()],
        target_toolchains = [CToolchain(;vendor=:gcc_bootstrap), CMakeToolchain()],
        platforms = Platform[host_linux],
    )
end

"""
    installed_registry_hashes()

The tree hashes of the installed default registries, by name.
"""
function installed_registry_hashes()
    hashes = Dict{String,String}()
    for inst in Pkg.Registry.reachable_registries()
        if any(reg -> reg.uuid == inst.uuid, Pkg.Registry.DEFAULT_REGISTRIES)
            hash = installed_registry_tree_hash(inst)
            if hash !== nothing
                hashes[inst.name] = hash
            end
        end
    end
    return hashes
end

"""
    seed_precompile_build_cache!(meta::BuildMeta)

Store a build and extraction result in `meta.build_cache` for every extraction planned
in `meta`: the auditor's precompile prefix as the artifact, and empty logs.
"""
function seed_precompile_build_cache!(meta::BuildMeta)
    # The build cache only accepts entries whose artifacts are in its `artifacts_dir`
    function cached_artifact(f::Function)
        hash, path = in_universe(meta.universe) do env
            hash = Pkg.Artifacts.create_artifact(f)
            return hash, Pkg.Artifacts.artifact_path(hash)
        end
        cache_path = joinpath(meta.build_cache.artifacts_dir, bytes2hex(hash.bytes))
        if !ispath(cache_path)
            cp(path, cache_path)
        end
        return SHA1Hash(hash), path
    end
    log_artifact(name::String) = first(cached_artifact(dir -> write(joinpath(dir, name), "precompile\n")))

    for extract_config in collect(keys(meta.extractions))
        build_config = extract_config.build.config
        artifact, artifact_dir = cached_artifact() do dir
            if BinaryBuilderAuditor.precompile_audit_prefix(dir) === nothing
                error("No libz to build a precompile prefix from")
            end
        end
        audit_result = BinaryBuilderAuditor.audit!(
            artifact_dir,
            extract_config.products,
            AuditInfo();
            platform = host_if_crossplatform(extract_config.platform),
            readonly = true,
        )
        source_records = JLLSourceRecord[
            JLLSourceRecord(first(src.urls), src.hash)
            for src in build_config.source_trees[source_prefix()] if src isa GitSource
        ]
        put!(
            meta.build_cache,
            spec_hash(build_config),
            spec_hash(extract_config),
            log_artifact("$(build_config.src_name)-build.log"),
            copy(build_config.env),
            artifact,
            log_artifact("$(build_config.src_name)-extract.log"),
            audit_result.jll_lib_products,
            audit_result.runtime_requirements;
            source_records,
            dependency_versions = Dict{String,VersionNumber}(),
        )
    end
end

"""
    precompile_jll_source_tree(meta::BuildMeta)

Prepare and deploy JLLs as a source tree of the precompile build, as `deploy()` does: the
`precompile_jll` registered into `meta.universe`, and `Tar_jll` from General, which we
depend on and so is installed already.
"""
function precompile_jll_source_tree(meta::BuildMeta)
    build_config = first(keys(meta.builds))
    platform = Platform(arch(HostPlatform()), "linux")
    registries = Pkg.Registry.reachable_registries(; depots=[depot_path(meta.universe)])
    for (prefix, name) in (("/workspace/precompile-local", "precompile_jll"),
                           ("/workspace/precompile-general", "Tar_jll"))
        deps = AbstractSource[JLLSource(name, platform)]
        prepare_source_tree(build_config, prefix, deps)
        bytes2hex(sha1(string(bytes2hex.(spec_hash.(deps; registries)))))
        mktempdir() do dir
            deploy_atomically(joinpath(dir, "deployed")) do staging_path
                deploy(deps, staging_path)
            end
        end
    end
end

@setup_workload begin
    old_offline = Pkg.OFFLINE_MODE[]
    try
        Pkg.offline(true)
        withenv("JULIA_PKG_SERVER" => "") do
            mktempdir() do cache_root
                registry_hashes = installed_registry_hashes()
                build_cache = BuildCache(;
                    cache_dir = joinpath(cache_root, "database"),
                    artifacts_dir = joinpath(cache_root, "artifacts"),
                )
                local meta
                @compile_workload begin
                    meta = BuildMeta(; dry_run = Set(["build", "extract", "package"]), registry_hashes, build_cache)
                    # Recipes call `supported_platforms()` at top level
                    supported_platforms()
                    with_default_meta(precompile_recipe, meta)
                end
                try
                    seed_precompile_build_cache!(meta)
                    empty!(meta.dry_run)
                    empty!(meta.builds)
                    empty!(meta.extractions)
                    empty!(meta.packagings)
                    @compile_workload begin
                        with_default_meta(precompile_recipe, meta)
                        precompile_jll_source_tree(meta)
                    end
                finally
                    cleanup(meta.universe; silent=true)
                end
            end
        end
    catch e
        @debug("BinaryBuilder2 precompile workload failed", exception=(e, catch_backtrace()))
    finally
        Pkg.offline(old_offline)
    end
end
