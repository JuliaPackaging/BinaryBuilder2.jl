using Test, BinaryBuilder2

if !isdefined(@__MODULE__, :TestingUtils)
    include("TestingUtils.jl")
end

native_arch = arch(HostPlatform())
native_linux = Platform(native_arch, "linux")

@warn("TODO: Write tests for DirectorySource patching")

@testset "BuildAPI" begin

using BinaryBuilder2: next_jll_version
@testset "next_jll_version" begin
    versions = [
        v"1.0.0",
        v"1.1.0",
        v"1.1.1",
        v"1.2.0",
    ]
    @test next_jll_version(versions, v"0.9.0") == v"0.9.0"
    @test next_jll_version(versions, v"1.1.0") == v"1.1.2"
    @test next_jll_version(versions, v"1.2.0") == v"1.2.1"
    @test next_jll_version(versions, v"1.3.0") == v"1.3.0"
    @test next_jll_version(nothing, v"1.2.0") == v"1.2.0"
end

@testset "Failing build" begin
    # This build explicitly fails because it runs `false`
    meta = BuildMeta(; verbose=false)
    bad_build_config = BuildConfig(
        meta,
        "foo",
        v"1.0.0",
        [],
        [],
        [],
        raw"""
        env_val=pre
        false
        env_val=post
        """,
        native_linux,
    );
    failing_build_result = build!(bad_build_config)
    @test failing_build_result.status == :failed
    @test failing_build_result.env["env_val"] == "pre"
    @test occursin("Previous command 'false' exited with code 1", failing_build_result.build_log)
end

@testset "Multi-stage build test" begin
    meta = BuildMeta(; verbose=false, disable_cache=true)
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
        [],
        [],
        raw"""
        cd 02_cxx_string_abi
        make libstring
        mkdir -p ${shlibdir}
        cp build/*.so ${shlibdir}/
        """,
        native_linux,
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
        [],
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
        native_linux,
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
        "Zlib",
        v"1.2.13",
        [
            ArchiveSource("https://github.com/madler/zlib/releases/download/v1.2.13/zlib-1.2.13.tar.xz",
                          "sha256:d14c38e313afc35a9a8760dadf26042f51ea0f5d154b0630a31da0540107fb98")
        ],
        [],
        [],
        """
        cd zlib*
        ./configure --prefix=\$prefix
        make -j30
        make install
        """,
        native_linux,
    )
    build_result = build!(build_config; disable_cache=true);
    @test build_result.status == :success

    extract_script = raw"""
    extract ${prefix}/lib/**.so*
    extract ${prefix}/include/**
    """
    products = [
        LibraryProduct("libz", :libz),
        FileProduct("include/zlib.h", :zlib_h),
    ]

    extract_config = ExtractConfig(
        build_result,
        extract_script,
        products,
    )
    extract_result = extract!(extract_config; disable_cache=true)
    @test extract_result.status == :success

    # Test that it built correctly
    in_universe(meta.universe) do env
        install_prefix = BinaryBuilder2.artifact_path(extract_result.artifact)
        @test isdir(install_prefix)
        @test isfile(joinpath(install_prefix, "include", "zlib.h"))
        @test isfile(joinpath(install_prefix, "lib", "libz.so.$(build_config.src_version)"))
    end

    # Test that if we try to build it again, we get a cached version
    cached_build_result = build!(build_config; extract_arg_hints=[(extract_script, products)])
    @test cached_build_result.status == :cached
    cached_extract_result = extract!(extract_config)
    @test cached_extract_result.status == :cached

    # PackageConfig() chooses a version number, let's check that it chooses the right one:
    package_config = PackageConfig(
        extract_result,
        version_series = v"99.99.99",
    )
    @test package_config.version == v"99.99.99"
    package_result = package!(package_config)
    @test package_result.status == :success

    # Ensure it was registered, and that it's the only `v99.99.x` version in there.
    of_the_ninetynine_versions_there_is_only_one = filter(BinaryBuilder2.get_package_versions(meta.universe, "Zlib_jll")) do v
        return v.major == 99 && v.minor == 99
    end
    @test length(of_the_ninetynine_versions_there_is_only_one) == 1

    # If we try to do this again, we get a newer version number
    package_config = PackageConfig(
        extract_result,
        version_series = v"99.99.99",
    )
    @test package_config.version == v"99.99.100"
    # Test that if we register it _again_, the patch number goes up by one:
    package_result2 = package!(package_config)
    ninetynine_versions = filter(BinaryBuilder2.get_package_versions(meta.universe, "Zlib_jll")) do v
        return v.major == 99 && v.minor == 99
    end
    @test length(ninetynine_versions) == 2
end

@testset "build_tarballs()" begin
    include("build_recipes/Zlib.jl")
    include("build_recipes/Readline.jl")
    include("build_recipes/Ncurses.jl")
    meta = BuildMeta(; verbose=false)
    @testset "Zlib" begin
        package_result = zlib_build_tarballs(meta, [native_linux])
        @test package_result.status == :success
    end
    @testset "Ncurses" begin
        package_result = ncurses_build_tarballs(meta, [native_linux])
        @test package_result.status == :success
    end
    @testset "Readline" begin
        package_result = readline_build_tarballs(meta, [native_linux])
        @test package_result.status == :success
    end

    @testset "Failing build" begin
        @test_throws BuildError readline_build_tarballs(meta, [native_linux]; fail_build=true)
        @test_throws BuildError readline_build_tarballs(meta, [native_linux]; fail_extract=true)
    end
end

end # testset "BuildAPI"
