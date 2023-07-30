using Test, BB2, Artifacts

if !isdefined(@__MODULE__, :TestingUtils)
    include("TestingUtils.jl")
end

const native_arch = arch(HostPlatform())
@testset "Build API" begin
    # Test building `zlib`
    meta = BuildMeta(; verbose=false)
    build_config = BuildConfig(
        "zlib",
        v"1.2.13",
        [
            ArchiveSource("https://github.com/madler/zlib/releases/download/v1.2.13/zlib-1.2.13.tar.xz",
                            "sha256:d14c38e313afc35a9a8760dadf26042f51ea0f5d154b0630a31da0540107fb98")
        ],
        AbstractSource[],
        AbstractSource[],
        """
        cd zlib*
        ./configure --prefix=\$prefix
        make -j30
        make install
        export FOO=foo
        """,
        Platform(native_arch, "linux"),
    )
    build_result = build!(meta, build_config);
    @test build_result.status == :success

    extract_config = ExtractConfig(
        build_result,
        raw"""
        extract ${prefix}/lib/**.so*
        extract ${prefix}/include/**
        """,
        BB2.AbstractProduct[],
    )
    extract_result = extract!(meta, extract_config)
    @test extract_result.status == :success

    # Test that it built correctly
    install_prefix = Artifacts.artifact_path(extract_result.artifact)
    @test isdir(install_prefix)
    @test isfile(joinpath(install_prefix, "include", "zlib.h"))
    @test isfile(joinpath(install_prefix, "lib", "libz.so.$(build_config.src_version)"))
end
