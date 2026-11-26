
using Test, BinaryBuilder2, Random, TOML
using BinaryBuilder2: get_package_result, JLLPackageDependencies, PackageSpec

if !isdefined(@__MODULE__, :TestingUtils)
    include(joinpath(pkgdir(BinaryBuilder2), "test", "TestingUtils.jl"))
end

@testset "build_tarballs()" begin
    # Create a meta with a universe that we will then inspect as other
    # builds register things into it.
    universe_name = "BB2_tests-$(randstring(4))"
    meta = BuildMeta(;universe_name,target_list=[BBHostPlatform()])
    bootstrap_dir = joinpath(pkgdir(BinaryBuilder2), "bootstrap")

    @testset "Zlib" begin
        # Test a `--dry-run` first!
        zlib_build_script_path = joinpath(bootstrap_dir, "Zlib", "build_tarballs.jl")
        run_build_tarballs(meta, zlib_build_script_path; dry_run=true)
        @test length(meta.packagings) > 0
        @test all(result.status == :skipped for result in values(meta.builds))
        @test all(result.status == :skipped for result in values(meta.extractions))
        @test all(result.status == :skipped for result in values(meta.packagings))
        @test all(config.src_name == "Zlib" for config in keys(meta.builds))

        # Test that we can take that dry run output and get everything we need for a `build_tarballs()` invocation
        build_args = extract_build_tarballs(get_package_result(meta, "Zlib"))
        empty!(meta.packagings)
        build_tarballs(;build_args..., build_script_path = zlib_build_script_path)
        package_result = get_package_result(meta, "Zlib")
        @test package_result.status == :success

        # `augment_platform_block` reaches the generated JLL and survives `extract_build_tarballs()`
        @test build_args[:augment_platform_block] == ""
        augment_platform_block = """
        function augment_platform!(p::Platform)
            return p
        end
        """
        empty!(meta.packagings)
        @test_throws r"`augment_platform_block` requires a `julia_compat`" build_tarballs(;build_args..., augment_platform_block, build_script_path = zlib_build_script_path)
        empty!(meta.packagings)
        augment_args = merge(build_args, Dict(:julia_compat => "1.7", :augment_platform_block => augment_platform_block))
        build_tarballs(;augment_args..., build_script_path = zlib_build_script_path)
        package_result = get_package_result(meta, "Zlib")
        @test package_result.status == :success
        @test extract_build_tarballs(package_result)[:augment_platform_block] == augment_platform_block
        jll_path = joinpath(meta.universe.depot_path, "dev", "Zlib_jll")
        @test occursin(augment_platform_block, read(joinpath(jll_path, ".pkg", "platform_augmentation.jl"), String))
        @test isfile(joinpath(jll_path, ".pkg", "select_artifacts.jl"))

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

    @testset "init_block" begin
        init_block = """
        greeting_dir = joinpath(artifact_dir, "share", "hello")
        ENV["BB2_INIT_BLOCK_GREETING_DIR"] = greeting_dir
        """
        build_tarballs(;
            meta,
            src_name = "InitBlockTest",
            src_version = v"1.0.0",
            sources = [],
            script = raw"""
            mkdir -p ${prefix}/share/hello
            echo "hello" > ${prefix}/share/hello/greeting.txt
            echo "MIT" > LICENSE
            install_license LICENSE
            """,
            products = [FileProduct("share/hello/greeting.txt", :greeting)],
            platforms = [BBHostPlatform()],
            init_block,
        )
        @test get_package_result(meta, "InitBlockTest").status == :success

        jll_dir = joinpath(meta.universe.depot_path, "dev", "InitBlockTest_jll")
        jll_toml = TOML.parsefile(joinpath(jll_dir, "JLL.toml"))
        @test !isempty(jll_toml["builds"])
        @test all(b["init_def"] == init_block for b in jll_toml["builds"])

        # The init code runs when the JLL is loaded, with `artifact_dir` set
        in_universe(meta.universe) do env
            test_code = """
            using InitBlockTest_jll, Test
            @test ENV["BB2_INIT_BLOCK_GREETING_DIR"] == dirname(InitBlockTest_jll.greeting)
            @test ENV["BB2_INIT_BLOCK_GREETING_DIR"] == joinpath(InitBlockTest_jll.artifact_dir, "share", "hello")
            @test readchomp(InitBlockTest_jll.greeting) == "hello"
            """
            @test success(run(addenv(`$(Base.julia_cmd()) --project=$(BinaryBuilder2.environment_path(meta.universe)) -e $(test_code)`, env)))
        end

        # Code that does not parse is rejected before anything is built
        dry_meta = BuildMeta(;dry_run=["build"])
        @test_throws ArgumentError build_tarballs(;
            meta = dry_meta,
            src_name = "InitBlockBroken",
            src_version = v"1.0.0",
            sources = [],
            script = "true",
            platforms = [BBHostPlatform()],
            init_block = "if true",
        )

        # An empty `init_block` (`BinaryBuilder`'s default) means no init code
        dry_meta = BuildMeta(;dry_run=["build"])
        build_tarballs(;
            meta = dry_meta,
            src_name = "InitBlockEmpty",
            src_version = v"1.0.0",
            sources = [],
            script = "true",
            platforms = [BBHostPlatform()],
            init_block = "",
        )
        config = only(keys(dry_meta.packagings))
        @test config.init_block === nothing
        @test extract_build_tarballs(config)[:init_block] === nothing
    end

    # Test that we can see these builds in our universe:
    uni = Universe(universe_name; persistent=false)
    jll_names = ["Zlib_jll", "Ncurses_jll", "Readline_jll"]
    @test all(BinaryBuilder2.contains_jll.((uni,), jll_names))

    # Test that these builds got the correct build_script_path
    function check_build_script_path(name)
        true_path = abspath(joinpath(bootstrap_dir, name, "build_tarballs.jl"))
        for build_result in collect_builds(meta[name])
            @test abspath(build_result.config.build_script_path) == true_path
        end
    end
    check_build_script_path("Zlib")
    check_build_script_path("Readline")
    check_build_script_path("Ncurses")

    # All the tests above target a native linux; let's run a test on Windows and macOS, just so that
    # we're exercising those troublesome platforms in at least some way:
    @testset "Zlib on Windows and macOS" begin
        meta = BuildMeta(;universe_name,target_list=[Platform("x86_64", "windows"), Platform("aarch64", "macos"; os_version=v"20")])
        run_build_tarballs(meta, joinpath(bootstrap_dir, "Zlib", "build_tarballs.jl"))
        package_result = get_package_result(meta, "Zlib")
        @test package_result.status == :success
    end

    @testset "Multi-stage build test (high-level)" begin
        meta = BuildMeta(;universe_name)
        run_build_tarballs(meta, joinpath(@__DIR__, "build_examples", "multi_stage_build.jl"))

        for package_name in ("libstring", "libstring_headers", "cxx_string_abi")
            package_result = get_package_result(meta, package_name)
            @test package_result.status == :success
        end
    end

    @testset "platformless JLLSource" begin
        # Resolving one `JLLSource` made from a wrapper must not change what the
        # wrapper requests for the next one.
        wrapper = JLLSource("Zstd_jll")
        first_jll = apply_platform(wrapper, Platform("x86_64", "linux"))
        first_jll.package.version = v"1.5.7"
        first_jll.package.tree_hash = Base.SHA1("446b23e73536f84e8037f5dce465e92275f6a308")
        second_jll = apply_platform(wrapper, Platform("aarch64", "linux"))
        @test !isa(second_jll.package.version, VersionNumber)
        @test second_jll.package.tree_hash === nothing
        @test second_jll.spec.tree_hash === nothing
    end

    @testset "BinaryBuilder2.Compat" begin
        meta = BuildMeta(;dry_run=["build"])
        run_build_tarballs(meta, joinpath(@__DIR__, "build_examples", "binary_builder_one.jl"))
        @test meta["SSW"].status == :skipped
        ssw_config = only(c for c in keys(meta.packagings) if c.name == "SSW")
        @test ssw_config.init_block == "ENV[\"SSW_ARTIFACT_DIR\"] = artifact_dir\n"

        # Ensure that `compilers` gets mapped to the appropriate toolchains
        target_toolchains, host_toolchains = BinaryBuilder2.Compat.compilers_to_toolchains([:c])
        @test any(isa.(target_toolchains, PlatformlessWrapper{CToolchain}))
        @test any(isa.(target_toolchains, PlatformlessWrapper{CMakeToolchain}))
        @test any(isa.(host_toolchains, PlatformlessWrapper{CToolchain}))
        @test any(isa.(host_toolchains, PlatformlessWrapper{HostToolsToolchain}))
        @test_throws ArgumentError BinaryBuilder2.Compat.compilers_to_toolchains([:c, :rust])

        # `Dependency` passes an explicit compat on to its `JLLSource`
        native = Platform("x86_64", "linux")
        @test apply_platform(BinaryBuilder2.Compat.Dependency("libLLVM_jll"; compat="18.1").jll, native).compat == "18.1"
        @test apply_platform(BinaryBuilder2.Compat.Dependency("Zlib_jll").jll, native).compat === nothing
    end

    @testset "host and build deps" begin
        meta = BuildMeta(;dry_run=["build"])
        build_tarballs(;
            meta,
            src_name = "libcxxstring",
            src_version = v"1.2.3",
            sources = [cxx_string_abi_source],
            script = "true",
            target_dependencies = [JLLSource("Zlib_jll")],
            target_build_time_dependencies = [JLLSource("LinuxKernelHeaders_jll")],
            host_dependencies = [JLLSource("GNUMake_jll")],
        )

        # Ensure that each spec has the correct dependencies recorded
        for build in collect_builds(meta["libcxxstring"])
            for spec in build.config.target_specs
                if spec.name == "host"
                    @test only(spec.dependencies).package.name == "GNUMake_jll"
                elseif spec.name == "target"
                    @test only(spec.dependencies).package.name == "Zlib_jll"
                    @test only(spec.build_time_dependencies).package.name == "LinuxKernelHeaders_jll"
                end
            end
        end

        # Test that only Zlib_jll is recorded as a dependency
        for extraction in collect_extractions(meta["libcxxstring"])
            @test only(JLLPackageDependencies(extraction, PackageSpec[]; julia_compat="1.6")).name == :Zlib_jll
        end
    end

    @testset "CMake search prefixes" begin
        # `/usr/local` is the host prefix; CMake searches it by default for every
        # Unix-like target, so non-host `CMakeToolchain`s must be told to ignore it,
        # whether they're cross-compiling or not.
        plan = make_target_spec_plan(;
            host_toolchains = [CToolchain(), CMakeToolchain(), HostToolsToolchain()],
            target_toolchains = [CToolchain(), CMakeToolchain()],
        )
        host = Platform(arch(HostPlatform()), "linux")
        for target in (host, Platform(arch(HostPlatform()) == "aarch64" ? "x86_64" : "aarch64", "linux"))
            for spec in apply_spec_plan(plan, host, target)
                cmake = only(t for t in spec.toolchains if isa(t, CMakeToolchain))
                @test cmake.prefix_paths == [BinaryBuilder2.target_prefix(spec)]
                if spec.name == "host"
                    @test BinaryBuilder2.target_prefix(spec) == BinaryBuilder2.host_prefix()
                    @test isempty(cmake.ignore_prefix_paths)
                else
                    @test cmake.ignore_prefix_paths == [BinaryBuilder2.host_prefix()]
                end
            end
        end
    end

    @testset "dependency compat" begin
        # The platformless `JLLSource` constructor splits its keyword arguments between
        # `PkgSpec` and `JLLSource`.
        jll = apply_platform(JLLSource("Zlib_jll"; version=v"1.2.13", target="foo", compat="~1.2",
                                       warn_on_overwrite=false, exempt_from_strict_tags=true),
                             Platform("x86_64", "linux"))
        @test jll.package.version == v"1.2.13"
        @test jll.target == "foo"
        @test jll.compat == "~1.2"
        @test !jll.warn_on_overwrite
        @test jll.exempt_from_strict_tags
        @test_throws MethodError apply_platform(JLLSource("Zlib_jll"; not_a_kwarg=1), Platform("x86_64", "linux"))

        meta = BuildMeta(;dry_run=["build"])
        build_tarballs(;
            meta,
            src_name = "libcompat",
            src_version = v"1.2.3",
            sources = [cxx_string_abi_source],
            script = "true",
            target_dependencies = [
                # Exact version: the bound comes from it even without a build
                JLLSource("Bzip2_jll"; version=v"1.0.8"),
                # Explicit compat, written verbatim, also for a stdlib
                JLLSource("Zstd_jll"; compat="~1.5"),
                # A stdlib without explicit compat admits every version that the Julia
                # versions the JLL supports ship, whatever version it was requested at
                JLLSource("Zlib_jll"; version=v"1.4.1"),
                # Neither: only a build records the version this resolves to, and this
                # one is a dry run, so there is no bound for it.
                JLLSource("XZ_jll"),
            ],
        )
        for extraction in collect_extractions(meta["libcompat"])
            @test extraction.config.build.dependency_versions === nothing
            for (julia_compat, zlib_compat) in (("1.6", "1.2"), ("1.12", "1.3"))
                deps = @test_logs (:warn, r"No resolved version recorded for XZ_jll") begin
                    Dict(d.name => d for d in JLLPackageDependencies(extraction, PackageSpec[]; julia_compat))
                end
                @test deps[:Bzip2_jll].compat == "1.0"
                @test deps[:Zstd_jll].compat == "~1.5"
                @test deps[:Zlib_jll].compat == zlib_compat
                @test deps[:XZ_jll].compat == "*"
            end
        end

        # A dependency on an LLVM JLL needs an explicit compat, and its absence is caught
        # before anything gets built.
        meta = BuildMeta(;dry_run=["build"])
        @test_throws r"libLLVM_jll .* explicit `compat`" build_tarballs(;
            meta,
            src_name = "libllvmuser",
            src_version = v"1.2.3",
            sources = [cxx_string_abi_source],
            script = "true",
            target_dependencies = [JLLSource("libLLVM_jll")],
        )
        @test isempty(meta.builds)
    end
end
