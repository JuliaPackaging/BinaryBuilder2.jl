using BinaryBuilder2, Test
import BinaryBuilder2: get_target_spec, spec_hash, BuildCacheExtractEntry

@testset "Build Selection" begin
    meta = BuildMeta(; verbose=false)
    # First, pretend that these build recipes have been changed:
    build_examples_dir = joinpath(dirname(dirname(Base.pathof(BinaryBuilder2))), "test", "BuildAPITests", "build_examples")
    run_build_tarballs(meta, joinpath(build_examples_dir, "multi_stage_build.jl"); dry_run=true)

    # Invoke a build that builds only libstring for x86_64-linux-gnu and i686-linux-gnu, identified by hashes:
    should_build_target(p) = os(p) == "linux" && arch(p) ∈ ("x86_64", "i686") && libc(p) == "glibc"
    build_results = collect_builds(meta["libstring"])
    build_hash_list = []
    for br in build_results
        p = get_target_spec(br.config, "target").platform.target
        if should_build_target(p)
            push!(build_hash_list, spec_hash(br.config))
        end
    end

    # Run a build with that build hash list applied
    filtered_meta = BuildMeta(; verbose=false, build_hash_list)
    run_build_tarballs(filtered_meta, joinpath(build_examples_dir, "multi_stage_build.jl"))

    # Ensure that the extraction results show that only the builds with our
    # selected targets actually built
    extract_results = collect_extractions(filtered_meta["libstring"])
    for er in extract_results
        if should_build_target(er.config.platform)
            @test er.status == :success
        else
            @test er.status == :skipped
        end
    end

    # Next, ensure that `libstring` was not packaged, since it has skipped elements
    @test filtered_meta["libstring"].status == :skipped

    # Now, let's pretend that we're Yggdrasil; two separate workers have built and sent
    # us each an `BuildCacheExtractEntry` (and extract config hash), which is precisely
    # what is needed for BB2 to consider a build as previously successfully built.
    # The hash will allow us to pair this result with the ExtractConfig from a dry run,
    # enabling us to then synthesize a `PackageConfig` we can `package!()`.
    struct YggdrasilBuildResult
        config_hash::SHA1Hash
        entry::BuildCacheExtractEntry
    end
    build_results = [
        YggdrasilBuildResult(
            spec_hash(er.config),
            BuildCacheExtractEntry(er.artifact, er.log_artifact, er.jll_lib_products),
        )
        for er in filter(er -> er.status == :success, extract_results)
    ]

    function BinaryBuilder2.ExtractResult(ybg::YggdrasilBuildResult)
        for er in extract_results
            if spec_hash(er.config) == ybg.config_hash
                return BinaryBuilder2.ExtractResult_cached(er.config, ybg.entry)
            end
        end
        return nothing
    end

    extract_results = ExtractResult.(build_results)
    package_config = PackageConfig(meta["libstring"].config, Dict("libstring" => extract_results))
    package_result = package!(package_config)
    @test package_result.status == :success
end
