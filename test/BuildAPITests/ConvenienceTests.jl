
using Test, BinaryBuilder2, Random
using BinaryBuilder2: get_package_result

@testset "build_tarballs()" begin
    # Create a meta with a universe that we will then inspect as other
    # builds register things into it.
    universe_name = "BB2_tests-$(randstring(4))"
    meta = BuildMeta(;universe_name,target_list=[BBHostPlatform()])
    bootstrap_dir = joinpath(pkgdir(BinaryBuilder2), "bootstrap")

    @testset "Zlib" begin
        # Test a `--dry-run` first!
        run_build_tarballs(meta, joinpath(bootstrap_dir, "Zlib", "build_tarballs.jl"); dry_run=true)
        @test length(meta.packagings) > 0
        @test all(result.status == :skipped for result in values(meta.builds))
        @test all(result.status == :skipped for result in values(meta.extractions))
        @test all(result.status == :skipped for result in values(meta.packagings))
        @test all(config.src_name == "Zlib" for config in keys(meta.builds))

        # Test that we can take that dry run output and get everything we need for a `build_tarballs()` invocation
        build_args = extract_build_tarballs(get_package_result(meta, "Zlib"))
        empty!(meta.packagings)
        build_tarballs(;build_args...)
        package_result = get_package_result(meta, "Zlib")
        @test package_result.status == :success

        # Next, test some failing builds
        fail_build_args = copy(build_args)
        fail_build_args[:script] = "false"
        @test_throws BuildError build_tarballs(;fail_build_args...)
        fail_extract_args = copy(build_args)
        fail_extract_args[:extract_script] = "false"
        @test_throws BuildError build_tarballs(;fail_extract_args...)
    end
    @testset "Ncurses" begin
        run_build_tarballs(meta, joinpath(bootstrap_dir, "Ncurses", "build_tarballs.jl"))
        @test get_package_result(meta, "Ncurses").status == :success
    end
    @testset "Readline" begin
        run_build_tarballs(meta, joinpath(bootstrap_dir, "Readline", "build_tarballs.jl"))
        @test get_package_result(meta, "Readline").status == :success
    end

    # Test that we can see these builds in our universe:
    uni = Universe(universe_name; persistent=false)
    jll_names = ["Zlib_jll", "Ncurses_jll", "Readline_jll"]
    @test all(BinaryBuilder2.contains_jll.((uni,), jll_names))


    # All the tests above target a native linux; let's run a test on Windows and macOS, just so that
    # we're exercising those troublesome platforms in at least some way:
    @testset "Zlib on Windows and macOS" begin
        meta = BuildMeta(;universe_name,target_list=[Platform("x86_64", "windows"), Platform("aarch64", "macos")])
        run_build_tarballs(meta, joinpath(bootstrap_dir, "Zlib", "build_tarballs.jl"))
        package_result = get_package_result(meta, "Zlib")
        @test package_result.status == :success
    end
end
