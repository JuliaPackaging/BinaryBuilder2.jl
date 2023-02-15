using Sandbox

function SandboxConfig(config::BuildConfig;)
    workspace = mktempdir()
    mkpath(joinpath(workspace, "destdir"))
    
    

    config = SandboxConfig(
        Dict(
            "/" => Sandbox.debian_rootfs(),
            "/opt/$(triplet(platform.host))" => target_tool_dir,
        ),
        Dict(
            "/workspace" => workspace,
        ),
        Dict{String,String}(
            "PATH" => "/usr/local/bin:/usr/local/sbin:/usr/bin:/usr/sbin:/bin:/sbin:/opt/$(triplet(platform.host))/bin",
            "CC" => "$(triplet(platform.host))-gcc",
            "CXX" => "$(triplet(platform.host))-g++",
            "AR" => "$(triplet(platform.host))-ar",
            "LD" => "$(triplet(platform.host))-ld",
        );
        hostname = "bb8",
        pwd = "/workspace",
        stdin,
        stdout,
        stderr
    )
    with_executor() do exe
        run(exe, config, `/bin/bash`)
    end
end
