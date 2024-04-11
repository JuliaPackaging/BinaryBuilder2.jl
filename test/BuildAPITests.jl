using Test, BinaryBuilder2, Artifacts

if !isdefined(@__MODULE__, :TestingUtils)
    include("TestingUtils.jl")
end

native_arch = arch(HostPlatform())

@testset "BuildAPI" begin

@testset "Failing build" begin
    # This build explicitly fails because it runs `false`
    meta = BuildMeta(; verbose=false)
    bad_build_config = BuildConfig(
        meta,
        "foo",
        v"1.0.0",
        AbstractSource[],
        AbstractSource[],
        AbstractSource[],
        raw"""
        env_val=pre
        false
        env_val=post
        """,
        Platform(native_arch, "linux"),
    );
    failing_stderr = IOBuffer()
    failing_build_result = build!(bad_build_config; stderr=failing_stderr)
    @test failing_build_result.status == :failed
    @test failing_build_result.env["env_val"] == "pre"
    @test occursin("Previous command 'false' exited with code 1", String(take!(failing_stderr)))
end

@testset "Multi-stage build test" begin
    meta = BuildMeta(; verbose=false)
    # First, build `libstring` from the BBToolchains testsuite
    cxx_string_abi_source =  DirectorySource(joinpath(
        pkgdir(BinaryBuilder2.BinaryBuilderToolchains),
        "test",
        "testsuite",
        "CToolchain"
    ));
    libstring_build_config = BuildConfig(
        meta,
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
    libstring_build_result = build!(libstring_build_config);
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
    libstring_extract_result = extract!(libstring_extract_config)
    @test libstring_extract_result.status == :success

    # Feed it in as a dependency to a build of `cxx_string_abi`
    cxx_string_abi_build_config = BuildConfig(
        meta,
        "cxx_string_abi",
        v"1.0.0",
        [cxx_string_abi_source],
        [ExtractResultSource(libstring_extract_result)],
        AbstractSource[],
        raw"""
        cd 02_cxx_string_abi

        # Explicitly use the `libstring` we built previously,
        # ensure this file does not get rebuilt by checking timestamps
        cp ${shlibdir}/libstring* .
        orig_mtime=$(stat -c %Y libstring*)

        make cxx_string_abi
        [[ "${orig_mtime}" == "$(stat -c %Y libstring*)" ]]
        mkdir -p ${bindir}
        cp build/cxx_string_abi* ${bindir}/
        """,
        Platform(native_arch, "linux"),
    );
    cxx_string_abi_build_result = build!(cxx_string_abi_build_config);
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
    libstring_extract_result = extract!(libstring_extract_config)
    @test libstring_extract_result.status == :success
end

@testset "native zlib build test" begin
    # Test building `zlib`
    meta = BuildMeta(; verbose=false)
    build_config = BuildConfig(
        meta,
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
    build_result = build!(build_config);
    @test build_result.status == :success

    extract_config = ExtractConfig(
        build_result,
        raw"""
        extract ${prefix}/lib/**.so*
        extract ${prefix}/include/**
        """,
        [
            LibraryProduct("libz", :libz),
            FileProduct("include/zlib.h", :zlib_h),
        ],
    )
    extract_result = extract!(extract_config)
    @test extract_result.status == :success

    # Test that it built correctly
    install_prefix = Artifacts.artifact_path(extract_result.artifact)
    @test isdir(install_prefix)
    @test isfile(joinpath(install_prefix, "include", "zlib.h"))
    @test isfile(joinpath(install_prefix, "lib", "libz.so.$(build_config.src_version)"))
end

end # testset "BuildAPI"