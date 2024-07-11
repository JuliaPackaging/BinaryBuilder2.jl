using JLLPrefixes, Sandbox, Base.BinaryPlatforms

# Get artifact paths for `FFMPEG_jll`, but for a foreign platform!
foreign_plat = Platform(Sys.ARCH == :aarch64 ? "x86_64" : "aarch64", "linux")
@info("Collecting FFMPEG_jll and dependencies...")
artifact_paths = collect_artifact_paths(["FFMPEG_jll"]; platform=foreign_plat)

mktempdir() do prefix
    # Deploy them all to our prefix, then run `ffmpeg -version`
    @info("Deploying...")
    deploy_artifact_paths(prefix, artifact_paths)

    config = SandboxConfig(
        # Mounts
        Dict(
            # Mount a rootfs for our foreign platform
            "/" => MountInfo(Sandbox.debian_rootfs(;platform=foreign_plat), MountType.Overlayed),
            "/ffmpeg" => MountInfo(prefix, MountType.Overlayed),
        ),
        # Environment
        Dict(
            "PATH" => "/ffmpeg/bin:/usr/local/bin:/usr/bin:/bin",
        );
        # Hook up stdin and stdout
        stdin,
        stdout,
        multiarch=[foreign_plat],
    )
    with_executor() do exe
        run(exe, config, `/bin/bash -c "ffmpeg -version"`)
    end
end
