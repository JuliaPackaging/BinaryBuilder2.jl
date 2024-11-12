using Test, BinaryBuilder2, Artifacts, TOML
using BinaryBuilder2: get_package_result, get_default_target_spec

if !isdefined(@__MODULE__, :TestingUtils)
    include(joinpath(pkgdir(BinaryBuilder2), "test", "TestingUtils.jl"))
end

@testset "MultiJLLOutput" begin
    meta = BuildMeta(; verbose=false)
    zlib_args = (;
        meta,
        src_name = "Zlib",
        src_version = v"1.2.13",
        sources = [
            ArchiveSource("https://github.com/madler/zlib/releases/download/v1.2.13/zlib-1.2.13.tar.xz",
                            "sha256:d14c38e313afc35a9a8760dadf26042f51ea0f5d154b0630a31da0540107fb98")
        ],
        script = """
        cd zlib*
        ./configure --prefix=\$prefix
        make -j30
        make install
        """,
        platforms = [native_linux],
    )

    # First, build `Zlib` and extract into multiple extractions, but a single JLL:
    empty!(meta.packagings)
    build_tarballs(;
        zlib_args...,
        extract_spec_generator = (build_config, platform) -> begin
            return Dict(
                # The default extraction (denoted by matching the JLL name) contains only the shared library
                "Zlib" => ExtractSpec(
                    raw"extract ${shlibdir}/**",
                    [
                        LibraryProduct("libz", :libz),
                    ],
                    get_default_target_spec(build_config),
                ),
                # The "full" extraction contains everything
                "ZlibFull" => ExtractSpec(
                    raw"extract ${prefix}/**",
                    [
                        FileProduct("include/zlib.h", :zlib_h),
                        LibraryProduct("libz", :libz),
                    ],
                    get_default_target_spec(build_config),
                ),
            )
        end,
        jll_extraction_map = Dict(
            "Zlib" => ["Zlib", "ZlibFull"],
        ),
    )
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
    build_tarballs(;
        zlib_args...,
        extract_spec_generator = (build_config, platform) -> begin
            return Dict(
                # The default extraction (denoted by matching the JLL name) contains only the shared library
                "Zlib" => ExtractSpec(
                    raw"extract ${shlibdir}/**",
                    [
                        LibraryProduct("libz", :libz),
                    ],
                    get_default_target_spec(build_config),
                ),
                # The "full" extraction contains headers and whatnot, and is what BB2 would install
                "ZlibFull" => ExtractSpec(
                    raw"extract ${includedir}/**",
                    [
                        FileProduct("include/zlib.h", :zlib_h),
                    ],
                    get_default_target_spec(build_config);
                    inter_deps = ["Zlib"],
                ),
            )
        end,
        jll_extraction_map = Dict(
            "Zlib" => ["Zlib"],
            "ZlibFull" => ["ZlibFull", "Zlib"],
        )
    )
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
