using Test, BinaryBuilder2, Artifacts, TOML
using BinaryBuilder2: get_package_result, get_default_target_spec

if !isdefined(@__MODULE__, :TestingUtils)
    include(joinpath(pkgdir(BinaryBuilder2), "test", "TestingUtils.jl"))
end

zlib_multi_packaging_jl = joinpath(@__DIR__, "build_examples", "zlib_multi_packaging.jl")
@testset "MultiJLLOutput" begin
    meta = BuildMeta(; verbose=false)

    # First, build `Zlib` and extract into multiple extractions, but a single JLL:
    run_build_tarballs(meta, zlib_multi_packaging_jl, ["--multi-extractions"])
    package_result = get_package_result(meta, "Zlib")
    @test package_result.status == :success
    @test length(package_result.config.named_extractions) == 2

    zlib_full_path = artifact_path(only(package_result.config.named_extractions["ZlibFull"]))
    zlib_path = artifact_path(only(package_result.config.named_extractions["Zlib"]))

    @test ispath(joinpath(zlib_full_path, "lib", "libz.so.1"))
    @test ispath(joinpath(zlib_path, "lib", "libz.so.1"))

    @test isfile(joinpath(zlib_full_path, "include", "zlib.h"))
    @test !isfile(joinpath(zlib_path, "include", "zlib.h"))

    # Next, build `Zlib` and extract into multiple JLLs, one which depends on the other
    empty!(meta.packagings)
    run_build_tarballs(meta, zlib_multi_packaging_jl, ["--multi-jlls"])
    package_result = get_package_result(meta, "Zlib")
    @test package_result.config.name == "Zlib"
    @test package_result.status == :success
    @test length(package_result.config.named_extractions) == 1

    function get_deps(package_result::PackageResult)
        pkg_dir = BinaryBuilder2.jll_dir(package_result)
        return collect(keys(TOML.parsefile(joinpath(pkg_dir, "Project.toml"))["deps"]))
    end
    @test !any(endswith(dep, "_jll") for dep in get_deps(package_result))

    package_result = get_package_result(meta, "ZlibFull")
    @test package_result.status == :success
    @test length(package_result.config.named_extractions) == 2
    @test "Zlib_jll" ∈ get_deps(package_result)
end
