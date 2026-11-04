using BinaryBuilder2, Test, Random
import BinaryBuilder2: import_archives, JLLSourceRecords
using BinaryBuilderSources: download_cache_path, verify
using TreeArchival: archive, treehash
using SHA, Downloads

if !isdefined(@__MODULE__, :TestingUtils)
    include(joinpath(pkgdir(BinaryBuilder2), "test", "TestingUtils.jl"))
end

@testset "Multi-stage build test (low-level)" begin
    meta = BuildMeta(; verbose=true, disabled_caches=["build"])
    # First, build `libstring` from the BBToolchains testsuite
    libstring_build_config = BuildConfig(
        meta,
        "libstring",
        v"1.0.0",
        [cxx_string_abi_source],
        apply_spec_plan(spec_plan, native_linux, native_linux),
        raw"""
        cd 02_cxx_string_abi
        make clean
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
        rm -rf build; mkdir build
        cp ${shlibdir}/libstring* build/
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
    archive_dir = mktempdir()
    meta = BuildMeta(; verbose=false, archive_dir)
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
    @test isempty(readdir(archive_dir))

    extract_script = raw"""
    extract ${prefix}/lib/**.so*
    extract ${prefix}/include/**
    """
    products = [
        LibraryProduct("libz", :libz),
        FileProduct("include/zlib.h", :zlib_h),
    ]

    # Test that a failed extraction with `archive_dir` set returns a failed
    # result (rather than throwing while trying to export an uncached
    # extraction) and does not export anything.
    failing_extract_config = ExtractConfig(
        build_result,
        raw"extract ${prefix}/lib/**.so*; rm -rf ${prefix}/lib",
        products,
    )
    failing_extract_result = extract!(failing_extract_config; disable_cache=true)
    @test failing_extract_result.status == :failed
    @test isempty(readdir(archive_dir))

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

    # Test that archive_dir has something in it
    @test !isempty(readdir(archive_dir))
    mktempdir() do cache_dir
        bc = BuildCache(;cache_dir, artifacts_dir=cache_dir)
        import_archives(bc, archive_dir)
        @test length(bc.build_entries) == 1
        @test length(bc.extract_entries) == 1
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

@testset "packaging a cached build fetches no sources" begin
    # A source tarball served from a port nothing listens on, so any attempt to
    # download it fails.  Random content keeps the build hash unique to this run.
    tarball_dir = mktempdir()
    mkpath(joinpath(tarball_dir, "src", "hello"))
    write(joinpath(tarball_dir, "src", "hello", "hello.txt"), randstring(32))
    write(joinpath(tarball_dir, "src", "hello", "LICENSE"), "MIT")
    tarball = joinpath(tarball_dir, "hello.tar.gz")
    archive(joinpath(tarball_dir, "src"), tarball, "gzip")
    source = ArchiveSource("http://127.0.0.1:1/hello.tar.gz", "sha256:" * bytes2hex(open(sha256, tarball)))
    seed_download_cache() = (mkpath(dirname(download_cache_path(source))); cp(tarball, download_cache_path(source); force=true))
    clear_download_cache() = rm(download_cache_path(source); force=true)

    script = raw"""
    mkdir -p ${prefix}/share
    cp hello/hello.txt ${prefix}/share/
    install_license hello/LICENSE
    """
    extract_script = raw"extract ${prefix}/share/**"
    products = [FileProduct("share/hello.txt", :hello_txt)]
    make_build_config(meta) = BuildConfig(meta, "Hello", v"1.0.0", [source], apply_spec_plan(spec_plan, native_linux, native_linux), script)

    # The build job: the source is "downloaded" by seeding the download cache.  Like
    # `build_tarballs()`, pass `extract_arg_hints` so the build hash is computed (and
    # the build cache consulted) before the build starts.
    archive_dir = mktempdir()
    seed_download_cache()
    build_meta = BuildMeta(; verbose=false, archive_dir)
    build_result = build!(make_build_config(build_meta); extract_arg_hints=[(extract_script, products)])
    @test build_result.status == :success
    expected_records = [JLLSourceRecord(first(source.urls), SHA1Hash(treehash(tarball)))]
    @test build_result.source_records == expected_records
    extract_result = extract!(ExtractConfig(build_result, extract_script, products))
    @test extract_result.status == :success
    build_hash = string(spec_hash(build_result.config))
    @test isfile(joinpath(archive_dir, "$(build_hash).sources.toml"))

    # Like the registration job: a machine that only has the archives, not the source.
    function cached_extract_result(archive_dir)
        meta = BuildMeta(; verbose=false)
        empty!(meta.build_cache.build_entries)
        empty!(meta.build_cache.extract_entries)
        import_archives(meta.build_cache, archive_dir)
        cached_build = build!(make_build_config(meta); extract_arg_hints=[(extract_script, products)])
        @test cached_build.status == :cached
        cached_extract = extract!(ExtractConfig(cached_build, extract_script, products))
        @test cached_extract.status == :cached
        return cached_extract
    end
    clear_download_cache()
    result = cached_extract_result(archive_dir)
    @test result.config.build.source_records == expected_records
    package_result = package!(PackageConfig(result))
    @test package_result.status == :success
    @test !verify(source)

    # Archives without the source records fall back to fetching the sources
    rm(joinpath(archive_dir, "$(build_hash).sources.toml"))
    result = cached_extract_result(archive_dir)
    @test result.config.build.source_records === nothing
    @test_throws Downloads.RequestError JLLSourceRecords(result)
    seed_download_cache()
    @test JLLSourceRecords(result) == expected_records
    clear_download_cache()
end

@testset "archives import into a cache that a fresh session hits" begin
    # An uncached build exports its archives keyed by `spec_hash(config)`, which it first
    # computes after `prepare()` has resolved the toolchain JLLs.  A later session
    # computes it before resolving anything, and must still find those archives.
    source_dir = mktempdir()
    write(joinpath(source_dir, "hello.txt"), "hello $(randstring(16))\n")
    build_script = raw"""
    mkdir -p ${prefix}/share
    cp hello.txt ${prefix}/share/
    mkdir -p ${prefix}/share/licenses/hello
    echo "public domain" > ${prefix}/share/licenses/hello/LICENSE.md
    """
    extract_script = raw"extract ${prefix}/share/**"
    products = [FileProduct("share/hello.txt", :hello_txt)]
    make_config(meta) = BuildConfig(
        meta,
        "hello",
        v"1.0.0",
        [DirectorySource(source_dir)],
        apply_spec_plan(spec_plan, native_linux, native_linux),
        build_script,
    )

    archive_dir = mktempdir()
    meta = BuildMeta(; verbose=false, archive_dir)
    build_result = build!(make_config(meta); disable_cache=true)
    @test build_result.status == :success
    extract_result = extract!(ExtractConfig(build_result, extract_script, products); disable_cache=true)
    @test extract_result.status == :success
    @test !isempty(readdir(archive_dir))

    fresh_meta = BuildMeta(; verbose=false)
    empty!(fresh_meta.build_cache.build_entries)
    empty!(fresh_meta.build_cache.extract_entries)
    import_archives(fresh_meta.build_cache, archive_dir)
    @test length(fresh_meta.build_cache.build_entries) == 1
    cached_build_result = build!(make_config(fresh_meta); extract_arg_hints=[(extract_script, products)])
    @test cached_build_result.status == :cached
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
        install_license /usr/share/licenses/MIT
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
