using PrecompileTools

@setup_workload begin
    @compile_workload begin
        meta = BuildMeta(;verbose=false)

        # Warm up the `build_tarballs()` loop.  Because we're, complete with deploying C toolchains and whatnot.
        # This could take a while the first time (due to actually needing to download some compiler
        # shards and whatnot) but should be not _too_ slow as long as you've got some artifacts locally.
        build_tarballs(;
            src_name = "blank",
            src_version = v"1.0.0",
            sources = [],
            script = "touch LICENSE.md",
            platforms = [BBHostPlatform()],
            meta,
        )

        # Warm up the `runshell` machinery
        runshell(BBHostPlatform(); meta, shell=`/bin/true`)

        # Clean up silently
        cleanup(meta.universe; silent=true)
    end
end
