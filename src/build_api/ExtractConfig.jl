using Sandbox, TreeArchival, Pkg, BinaryBuilderProducts, Artifacts

export ExtractConfig, extract!

struct ExtractConfig
    # The build result we're packaging up
    build::BuildResult

    # The extraction script that we're using to copy build results out into our artifacts
    script::String

    # The products that this package will ensure are available
    products::Vector{<:AbstractProduct}

    # TODO: Add an `AuditConfig` field
    #audit::AuditConfig
    metadir::String

    # Timing
    to::TimerOutput

    function ExtractConfig(build::BuildResult,
                           script::AbstractString,
                           products::Vector{<:AbstractProduct};
                           metadir = mktempdir(builds_dir()),
                           audit_config = nothing)
        # We want to copy the metadir from the BuildConfig and add our own
        # extraction script.  We copy here so that bash history and whatnot is preserved,
        # but unique for this extraction config.
        rm(metadir)
        cp(build.mounts["/workspace/metadir"].host_path, metadir)

        extract_script_path = joinpath(metadir, "extract_script.sh")
        open(extract_script_path, write=true) do io
            println(io, "#!/bin/bash")
            println(io, "source /usr/local/share/bb/save_env_hook")
            println(io, "source /usr/local/share/bb/extraction_utils")
            println(io, script)
        end
        chmod(extract_script_path, 0o755)

        return new(
            build,
            String(script),
            products,
            #audit_config,
            metadir,
            copy(build.config.to),
        )
    end
end

function runshell(config::ExtractConfig; output_dir::String=mktempdir(builds_dir()), shell::Cmd = `/bin/bash`)
    sandbox_config = SandboxConfig(config, output_dir)
    run(config.build.exe, sandbox_config, shell)
end

function SandboxConfig(config::ExtractConfig, output_dir::String; kwargs...)
    # Insert our new metadir
    mounts = copy(config.build.mounts)
    mounts["/workspace/metadir"] = MountInfo(config.metadir, MountType.Overlayed)

    # Insert our extraction dir, which is a ReadWrite mount,
    # allowing us to pull the result back out from the overlay nest.
    mounts["/workspace/extract"] = MountInfo(output_dir, MountType.ReadWrite)

    # Insert some more environment variables on top of what was defined by the build config
    env = copy(config.build.config.env)
    env["extract_dir"] = "/workspace/extract"
    env["BB_WRAPPERS_VERBOSE"] = "true"
    return SandboxConfig(config.build.config, mounts; env, kwargs...)
end

function collect_library_products(config::ExtractConfig)
    library_products = Dict(
        config.build.name => [p for p in config.products if isa(p, LibraryProduct)]
    )

    # TODO: Collect library products for all dependencies as well
    return library_products
end

function extract!(config::ExtractConfig)
    local artifact_hash, run_status, run_exception
    @timeit config.to "extract" begin
        artifact_hash = Pkg.Artifacts.create_artifact() do artifact_dir
            sandbox_config = SandboxConfig(config, artifact_dir)
            run_status, run_exception = run_trycatch(config.build.exe, sandbox_config, `/workspace/metadir/extract_script.sh`)
        end
    end

    # Run over the extraction result, ensure that all products can be located:
    unlocatable_products = AbstractProduct[]
    for product in config.products
        if locate(product, artifact_path(artifact_hash);
                  env=config.build.env) === nothing
            push!(unlocatable_products, product)
        end
    end

    if !isempty(unlocatable_products)
        @error("Unable to locate $(length(unlocatable_products)) products:", unlocatable_products, platform=config.build.config.platform)
        error()
    end

    # Compute dependency structure for all library products
    libmap = library_products_map(config)
    library_products = collect(Iterators.flatten(values(libmap)))
    if !isempty(library_products)
        resolve_dependency_links!(library_products, artifact_path(artifact_hash), config.build.env)
    end

    result = ExtractResult(
        config,
        run_status,
        run_exception,
        artifact_hash,
        Dict{String,String}(),
    )
    config.build.meta.extractions[config] = result
    return result
end
