using Sandbox

function Sandbox.SandboxConfig(config::BuildConfig)
    # Generate temporary directories for each individual prefix
    @info("Deploying dependencies")
    ro_maps = Dict{String,String}(
        "/" => Sandbox.debian_rootfs(;platform = config.platform.host),
    )
    for (prefix, deps) in config.dep_trees
        ro_maps[prefix] = mktempdir()
        deploy(deps, ro_maps[prefix])
    end

    @info("Deploying sources")
    srcdir = mktempdir()
    for source in config.sources
        deploy(source, srcdir)
    end
    rw_maps = Dict{String,String}(
        "/workspace/srcdir" => srcdir,
    )


    config = SandboxConfig(
        ro_maps,
        rw_maps,
        Dict{String,String}(
            "PATH" => "/usr/local/bin:/usr/local/sbin:/usr/bin:/usr/sbin:/bin:/sbin:/opt/$(triplet(config.platform.target))/bin",
            "CC" => "$(triplet(config.platform.target))-gcc",
            "CXX" => "$(triplet(config.platform.target))-g++",
            "AR" => "$(triplet(config.platform.target))-ar",
            "LD" => "$(triplet(config.platform.target))-ld",
        );
        hostname = "bb8",
        pwd = "/workspace/srcdir",
        stdin,
        stdout,
        stderr,
        multiarch=[config.platform.host],
    )
    return config
end
