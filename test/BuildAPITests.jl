using Test, BinaryBuilder2, Random

if !isdefined(@__MODULE__, :TestingUtils)
    include("TestingUtils.jl")
end

native_arch = arch(HostPlatform())
native_linux = Platform(native_arch, "linux")

@warn("TODO: Write tests for DirectorySource patching")

# Would be cool to do something like nvtpx output or something
@warn("TODO: Write a test case that uses more than 3 platforms")

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

# By default, don't allow ccache usage in these tests
spec_plan = make_target_spec_plan(;
    host_toolchains=[CToolchain(;use_ccache=false), HostToolsToolchain()],
    target_toolchains=[CToolchain(;use_ccache=false)],
)

@testset "Failing build" begin
    # This build explicitly fails because it runs `false`
    meta = BuildMeta(; verbose=false)
    bad_build_config = BuildConfig(
        meta,
        "foo",
        v"1.0.0",
        [],
        apply_spec_plan(spec_plan, native_linux, native_linux),
        raw"""
        env_val=pre
        false
        env_val=post
        """,
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
    ))
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

using BinaryBuilder2: get_package_result
@testset "build_tarballs()" begin
    # Create a meta with a universe that we will then inspect as other
    # builds register things into it.
    universe_name = "BB2_tests-$(randstring(4))"
    meta = BuildMeta(;universe_name,target_list=[BBHostPlatform()])
    bootstrap_dir = joinpath(pkgdir(BinaryBuilder2), "bootstrap")

    @testset "Zlib" begin
        # Test a `--dry-run` first!
        package_result = run_build_tarballs(meta, joinpath(bootstrap_dir, "Zlib", "build_tarballs.jl"); dry_run=true)
        @test package_result.status == :skipped
        @test all(result.status == :skipped for result in values(meta.builds))
        @test all(result.status == :skipped for result in values(meta.extractions))
        @test all(result.status == :skipped for result in values(meta.packagings))
        @test all(config.src_name == "Zlib" for config in keys(meta.builds))

        # Test that we can take that dry run output and get everything we need for a `build_tarballs()` invocation
        build_args = extract_build_tarballs(get_package_result(meta, "Zlib"))
        package_result = build_tarballs(;build_args...)
        @test package_result.status == :success

        # Next, test some failing builds
        fail_build_args = copy(build_args)
        fail_build_args[:script] = "false"
        @test_throws BuildError build_tarballs(;fail_build_args...)
        fail_extract_args = copy(build_args)
        fail_extract_args[:extract_scripts] = Dict("Zlib" => "false")
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
end

end # testset "BuildAPI"
