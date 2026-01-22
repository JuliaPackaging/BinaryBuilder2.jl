using BinaryBuilder2, Test
import BinaryBuilder2: get_target_spec, spec_hash

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
end
