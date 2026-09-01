using PrecompileTools

# The `build_tarballs()` pipeline is extremely type-heavy, and paying for its inference
# on every fresh Julia process dominates the wall time of small builds.  Warm it up here
# by running a `--dry-run` build for the host platform: this exercises `BuildMeta`,
# `Universe`, `BuildConfig`, `ExtractConfig` and `PackageConfig` construction (the bulk
# of the compile latency) without launching a sandbox or building anything.
#
# This is purely a latency optimization, so if anything goes wrong (e.g. we're
# precompiling on a machine with no network access, and so cannot set up the registries
# for a `Universe`) we silently give up rather than failing precompilation.
@setup_workload begin
    @compile_workload begin
        try
            meta = BuildMeta(; dry_run = Set(["build", "extract", "package"]))
            try
                build_tarballs(
                    "precompile",
                    v"1.0.0",
                    AbstractSource[],
                    "true";
                    products = [LibraryProduct("libprecompile", :libprecompile)],
                    platforms = [BBHostPlatform()],
                    meta,
                )
            finally
                cleanup(meta.universe; silent=true)
            end
        catch
        end
    end
end
