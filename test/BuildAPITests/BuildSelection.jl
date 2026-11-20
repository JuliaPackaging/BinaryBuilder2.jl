using BinaryBuilder2, Test, SHA
import BinaryBuilder2: get_target_spec, spec_hash, BuildCacheExtractEntry, build_hash_debug_logger

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
            BuildCacheExtractEntry(er.artifact, er.log_artifact, er.jll_lib_products, er.runtime_requirements),
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

    # A build hash that never gets selected causes every build hash to be recomputed
    # with debug logging enabled, then an `UnconsumedBuildHashesError`.
    bogus_hash = SHA1Hash(sha1(""))
    native_linux = Platform(arch(HostPlatform()), "linux")
    failing_meta() = BuildMeta(; verbose=false, build_hash_list=[bogus_hash], target_list=[native_linux])
    meta1 = failing_meta()
    run_build_tarballs(meta1, multi_stage_build; check_build_hashes=false)
    @test isempty(meta1.build_hash_list_used)
    scheduled = Dict(config => spec_hash(config) for config in keys(meta1.builds))
    @test length(scheduled) == 2
    debug_io = IOBuffer()
    err = try
        check_build_hashes_consumed(meta1; debug_logger=build_hash_debug_logger(debug_io))
        nothing
    catch e
        e
    end
    @test isa(err, UnconsumedBuildHashesError)
    debug_output = String(take!(debug_io))
    @test occursin("Build hash selection", debug_output)
    @test occursin("BuildConfig hash buffer", debug_output)
    @test occursin("[source_trees]", debug_output)
    @test count("Recomputed build hash", debug_output) == 2
    err_msg = sprint(showerror, err)
    @test occursin("Not all build hashes provided were used", err_msg)
    @test occursin("Unconsumed: $(MultiHash(bogus_hash))", err_msg)
    for (config, build_hash) in scheduled
        @test occursin("$(build_hash) $(config)", err_msg)
        # The recomputation leaves the scheduled hash in place
        @test config.spec_hash[] == build_hash
    end
    # `meta1` has been reported, so the exit hooks no longer check it
    @test meta1 ∉ BinaryBuilder2.get_exit_hooks().build_metas

    # `run_build_tarballs()` performs this check once the script has finished
    @test_throws UnconsumedBuildHashesError run_build_tarballs(failing_meta(), multi_stage_build)

    # If nobody checked, the `atexit()` hook does
    meta3 = failing_meta()
    run_build_tarballs(meta3, multi_stage_build; check_build_hashes=false)
    @test meta3 ∈ BinaryBuilder2.get_exit_hooks().build_metas
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
    @test occursin("BuildConfig hash buffer", output)
    @test occursin("Recomputed build hash", output)
    if success(proc) || !occursin("Not all build hashes provided were used", output)
        @error("Unexpected output from bogus build hash invocation", output)
    end
end
