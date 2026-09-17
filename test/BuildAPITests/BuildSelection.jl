using BinaryBuilder2, Test, SHA
import BinaryBuilder2: get_target_spec, spec_hash, BuildCacheExtractEntry

if !isdefined(@__MODULE__, :TestingUtils)
    include(joinpath(pkgdir(BinaryBuilder2), "test", "TestingUtils.jl"))
end

build_examples_dir = joinpath(pkgdir(BinaryBuilder2), "test", "BuildAPITests", "build_examples")
multi_stage_build = joinpath(build_examples_dir, "multi_stage_build.jl")

@testset "Build Selection" begin
    meta = BuildMeta(; verbose=false)
    # First, pretend that these build recipes have been changed:
    run_build_tarballs(meta, multi_stage_build; dry_run=true)

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
    @test length(build_hash_list) == 2

    # Run a build with that build hash list applied
    filtered_meta = BuildMeta(; verbose=true, build_hash_list)
    run_build_tarballs(filtered_meta, multi_stage_build)

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

    # Ensure that running with a hash that never gets selected fails when we trigger `atexit()`
    failing_meta = BuildMeta(; verbose=false, build_hash_list=[SHA1Hash(sha1(""))])
    run_build_tarballs(failing_meta, multi_stage_build)
    @test_logs (:error, r"Not all build hashes provided were used") match_mode=:any Base.atexit(BinaryBuilder2.get_exit_hooks(); exit_process=false)

    # Do the same thing, but out-of-process, to ensure that the `atexit()` hook actually
    # causes the process to exit with a nonzero exit code, rather than just logging an error.
    bogus_hash = string("sha1:", "0"^40)
    native_triplet = triplet(Platform(arch(HostPlatform()), "linux"))
    cmd = `$(Base.julia_cmd()) --project=$(Base.active_project()) $(multi_stage_build) --build-hashes=$(bogus_hash) $(native_triplet)`
    out_io = IOBuffer()
    proc = run(pipeline(ignorestatus(cmd); stdout=out_io, stderr=out_io))
    output = String(take!(out_io))
    @test !success(proc)
    @test occursin("Not all build hashes provided were used", output)
    if success(proc) || !occursin("Not all build hashes provided were used", output)
        @error("Unexpected output from bogus build hash invocation", output)
    end
end
