using Test, BinaryBuilder2, Artifacts

if !isdefined(@__MODULE__, :TestingUtils)
    include("TestingUtils.jl")
end

@testset "BuildAPI" begin

const native_arch = arch(HostPlatform())

@testset "Multi-stage build test" begin
    using Test, BinaryBuilder2, Artifacts
    const native_arch = arch(HostPlatform())

    meta = BuildMeta(; verbose=false)
    # First, build `libstring` from the BBToolchains testsuite
    cxx_string_abi_source =  DirectorySource(joinpath(
        pkgdir(BinaryBuilder2.BinaryBuilderToolchains),
        "test",
        "testsuite",
        "CToolchain"
    ));
    libstring_build_config = BuildConfig(
        "libstring",
        v"1.0.0",
        [cxx_string_abi_source],
        AbstractSource[],
        AbstractSource[],
        raw"""
        cd 02_cxx_string_abi
        make libstring
        mkdir -p ${shlibdir}
        cp build/*.so ${shlibdir}/
        """,
        Platform(native_arch, "linux"),
    );
    libstring_build_result = build!(meta, libstring_build_config);
    @test libstring_build_result.status == :success

    # Extract it:
    libstring_extract_config = ExtractConfig(
        libstring_build_result,
        raw"""
        extract ${prefix}/lib/**.so*
        """,
        [
            LibraryProduct("libstring", :libstring),
        ],
    );
    libstring_extract_result = extract!(meta, libstring_extract_config)
    @test libstring_extract_result.status == :success

    # Feed it in as a dependency to a further of `cxx_string_abi`
    cxx_string_abi_build_config = BuildConfig(
        "cxx_string_abi",
        v"1.0.0",
        [cxx_string_abi_source],
        [ExtractResultSource(libstring_extract_result)],
        AbstractSource[],
        raw"""
        cd 02_cxx_string_abi

        # Explicitly use the `libstring` we built previously,
        # remove `libstring.cpp` to assert that we're not trying to rebuild
        cp ${shlibdir}/libstring* .
        rm libstring.cpp

        make cxx_string_abi
        mkdir -p ${bindir}
        cp build/cxx_string_abi* ${bindir}/
        """,
        Platform(native_arch, "linux"),
    );
    cxx_string_abi_build_result = build!(meta, cxx_string_abi_build_config);
    @test cxx_string_abi_build_result.status == :success

    libstring_extract_config = ExtractConfig(
        libstring_build_result,
        raw"""
        extract ${prefix}/lib/**.so*
        """,
        [
            LibraryProduct("libstring", :libstring),
        ],
    );
    libstring_extract_result = extract!(meta, libstring_extract_config)
    @test libstring_extract_result.status == :success
end

@testset "native zlib build test" begin
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
        [
            LibraryProduct("libz", :libz),
            FileProduct("include/libz.h", :libh_z),
        ],
    )
    extract_result = extract!(meta, extract_config)
    @test extract_result.status == :success

    # Test that it built correctly
    install_prefix = Artifacts.artifact_path(extract_result.artifact)
    @test isdir(install_prefix)
    @test isfile(joinpath(install_prefix, "include", "zlib.h"))
    @test isfile(joinpath(install_prefix, "lib", "libz.so.$(build_config.src_version)"))
end

end # testset "BuildAPI"
