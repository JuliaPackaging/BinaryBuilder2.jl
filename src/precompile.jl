using PrecompileTools

# Disable this for now, to avoid `__init__()` problems with IO locks
#=
@setup_workload begin
    git_envs = (
        "GIT_AUTHOR_NAME" => "BinaryBuilder2 Tester",
        "GIT_COMMITTER_NAME" => "BinaryBuilder2 Tester",
        "GIT_AUTHOR_EMAIL" => "bb2@julialang.org",
        "GIT_COMMITTER_EMAIL" => "bb2@julialang.org",
    )
    withenv(git_envs...) do
        @compile_workload begin
            meta = BuildMeta(;verbose=false)

            # Warm up the `build_tarballs()` loop.  Because we're, complete with deploying C toolchains and whatnot.
            # This could take a while the first time (due to actually needing to download some compiler
            # shards and whatnot) but should be not _too_ slow as long as you've got some artifacts locally.
            try
                build_tarballs(;
                    src_name = "blank",
                    src_version = v"1.0.0",
                    sources = [],
                    script = "touch LICENSE.md",
                    platforms = [BBHostPlatform()],
                    meta,
                )
            catch
            end

            # Warm up the `runshell` machinery
            try
                runshell(BBHostPlatform(); meta, shell=`/bin/true`)
            catch
            end

            # Clean up silently
            cleanup(meta.universe; silent=true)
        end
    end
end
=#
