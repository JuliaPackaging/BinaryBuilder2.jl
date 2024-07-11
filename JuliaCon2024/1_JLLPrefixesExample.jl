using JLLPrefixes

# Get artifact paths for `FFMPEG_jll`
@info("Collecting FFMPEG_jll and dependencies...")
artifact_paths = collect_artifact_paths(["FFMPEG_jll"])

mktempdir() do prefix
    # Deploy them all to our prefix, then run `ffmpeg -version`
    @info("Deploying...")
    deploy_artifact_paths(prefix, artifact_paths)

    run(`$(prefix)/bin/ffmpeg -version`)
    undeploy_artifact_paths(prefix, artifact_paths)
end
