using PrecompileTools

# The `build_tarballs()` pipeline is extremely type-heavy, and paying for its inference
# on every fresh Julia process dominates the wall time of small builds.  Warm it up here
# by running a `--dry-run` build: this exercises `BuildMeta`, `Universe`, toolchain
# construction, `BuildConfig`, `ExtractConfig` and `PackageConfig` (the bulk of the
# compile latency) without launching a sandbox or building anything.
#
# Shape this call *exactly* the way a real `build_tarballs.jl` does, not the way that is
# most convenient here.  Julia specializes `Core.kwcall` on the names, the order and the
# argument types of the keywords it is given, so a call that differs in any of those --
# even just by threading `meta` through as a keyword rather than through
# `with_default_meta()` -- compiles a specialization no recipe will ever reuse, and
# every recipe then pays a fresh second of inferring `build_tarballs()` on startup.
# That is also why we pass real toolchains here: a build with no toolchains at all skips
# most of what a recipe actually asks for.
#
# Note this only covers the pipeline up to `should_skip()`; a dry run stops there, so
# everything downstream (`prepare()`, `deploy()`, the sandbox, extraction, auditing and
# packaging) is still inferred at runtime.  Reaching those would mean resolving and
# downloading JLLs during precompilation, which is not a trade we want to make.
#
# This is purely a latency optimization, so if anything goes wrong (e.g. we're
# precompiling on a machine with no network access, and so cannot set up the registries
# for a `Universe`) we silently give up rather than failing precompilation.
@setup_workload begin
    @compile_workload begin
        try
            meta = BuildMeta(; dry_run = Set(["build", "extract", "package"]))
            try
                # Recipes open by calling `supported_platforms()` at top level, so warm
                # that up too.  We still only *build* for one platform: the rest of the
                # pipeline learns nothing new from the 16th `BuildConfig`.
                supported_platforms()
                with_default_meta(meta) do
                    build_tarballs(;
                        src_name = "precompile",
                        src_version = v"1.0.0",
                        sources = [GitSource("https://example.com/precompile.git", "0"^40)],
                        script = "true",
                        products = [LibraryProduct("libprecompile", :libprecompile)],
                        host_toolchains = [CToolchain(;vendor=:gcc_bootstrap), HostToolsToolchain(), CMakeToolchain()],
                        target_toolchains = [CToolchain(;vendor=:gcc_bootstrap), CMakeToolchain()],
                        platforms = Platform[Platform("x86_64", "linux")],
                    )
                end
            finally
                cleanup(meta.universe; silent=true)
            end
        catch
        end
    end
end
