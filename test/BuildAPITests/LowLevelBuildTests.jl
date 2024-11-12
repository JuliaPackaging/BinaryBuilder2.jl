using BinaryBuilder2, Test

if !isdefined(@__MODULE__, :TestingUtils)
    include(joinpath(pkgdir(BinaryBuilder2), "test", "TestingUtils.jl"))
end

@testset "Multi-stage build test" begin
    meta = BuildMeta(; verbose=false, disable_cache=true)
    # First, build `libstring` from the BBToolchains testsuite
    libstring_build_config = BuildConfig(
        meta,
        "libstring",
        v"1.0.0",
        [cxx_string_abi_source],
        apply_spec_plan(spec_plan, native_linux, native_linux),
        raw"""
        cd 02_cxx_string_abi
        make libstring
        mkdir -p ${shlibdir}
        cp build/*.so ${shlibdir}/
        mkdir -p ${includedir}
        cp libstring.h ${includedir}/

        mkdir -p ${prefix}/share/licenses/libstring
        echo "public domain" > ${prefix}/share/licenses/libstring/LICENSE.md
        """,
    )
    libstring_build_result = build!(libstring_build_config)
    @test libstring_build_result.status == :success

    # Extract it:
    libstring_extract_script =  raw"extract ${shlibdir}/**.so*"
    libstring_products = [LibraryProduct("libstring", :libstring)]

    libstring_extract_config = ExtractConfig(
        libstring_build_result,
        libstring_extract_script,
        libstring_products,
    )
    libstring_extract_result = extract!(libstring_extract_config; verbose=false)
    @test libstring_extract_result.status == :success

    # Try extracting the same thing twice, it should still work
    libstring_extract_result = extract!(libstring_extract_config)
    @test libstring_extract_result.status == :success

    # Also extract an `AnyPlatform` header artifact.
    libstring_h_extract_script = raw"extract ${includedir}"
    libstring_h_products = [FileProduct(raw"${includedir}/libstring.h", :libstring_h)]
    libstring_h_extract_config = ExtractConfig(
        libstring_build_result,
        libstring_h_extract_script,
        libstring_h_products;
        # Override the platform since this is just a header file
        platform = AnyPlatform()
    )
    libstring_h_extract_result = extract!(libstring_h_extract_config)
    @test libstring_h_extract_result.status == :success

    cxx_string_spec_plan = make_target_spec_plan(;
        host_toolchains=[CToolchain(;use_ccache=false), HostToolsToolchain()],
        target_toolchains=[CToolchain(;use_ccache=false)],
        target_dependencies=[ExtractResultSource(libstring_extract_result)],
    )
    # Feed it in as a dependency to a build of `cxx_string_abi`
    cxx_string_abi_build_config = BuildConfig(
        meta,
        "cxx_string_abi",
        v"1.0.0",
        [cxx_string_abi_source],
        apply_spec_plan(cxx_string_spec_plan, native_linux, native_linux),
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
        touch build/
        """,
    )
    cxx_string_abi_build_result = build!(cxx_string_abi_build_config);
    @test cxx_string_abi_build_result.status == :success

    # Test that running the extraction a second time still works
    # and does not cause a cache hit, because we disabled that.
    libstring_extract_config = ExtractConfig(
        libstring_build_result,
        libstring_extract_script,
        libstring_products,
    )
    libstring_extract_result = extract!(libstring_extract_config)
    @test libstring_extract_result.status == :success

    # Test that running an extraction that fails to find one of its products
    # attempts to show us the nice debugging messages:
    libstring_bad_products = [LibraryProduct("libstring2", :libstring)]
    libstring_bad_extract_config = ExtractConfig(
        libstring_build_result,
        libstring_extract_script,
        libstring_bad_products,
    )
    @test_logs((:error, r"Running again with debugging enabled, then erroring out!"),
               (:debug, r"Locating LibraryProduct"), match_mode=:any, begin
        extract!(libstring_bad_extract_config)
    end)

    # Test that if we run an extraction that deletes a bunch of files from `${prefix}`,
    # it fails because that is read-only at the point of extraction.
    deleting_extract_script =  raw"extract ${shlibdir}/**.so*; rm -rf ${shlibdir}"
    deleting_extract_config = ExtractConfig(
        libstring_build_result,
        deleting_extract_script,
        libstring_products,
    )
    deleting_extract_result = extract!(deleting_extract_config)
    @test deleting_extract_result.status == :failed
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
        apply_spec_plan(spec_plan, native_linux, native_linux),
        """
        cd zlib*
        ./configure --prefix=\$prefix
        make -j30
        make install
        """,
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

@testset "atomic_patch" begin
    meta = BuildMeta(; verbose=false)
    # First, apply the patch and all is good
    patch_test_build_config = BuildConfig(
        meta,
        "patch_test",
        v"1.0.0",
        [DirectorySource(joinpath(@__DIR__, "bundled"))],
        apply_spec_plan(spec_plan, native_linux, native_linux),
        raw"""
        atomic_patch -p1 test.c.patch
        mkdir -p ${bindir}
        $CC -o ${bindir}/test test.c
        install_license test.c
        """,
    )
    patch_test_result = build!(patch_test_build_config)
    @test patch_test_result.status == :success

    # Next, alter the source so that the patch only partially applies
    patch_test_build_config = BuildConfig(
        meta,
        "patch_test",
        v"1.0.0",
        [DirectorySource(joinpath(@__DIR__, "bundled"))],
        apply_spec_plan(spec_plan, native_linux, native_linux),
        raw"""
        sed -i'' -e 's/cool/awesome/g' test.c
        atomic_patch -p1 test.c.patch
        """,
    )
    patch_test_result = build!(patch_test_build_config)
    @test patch_test_result.status == :failed
end
