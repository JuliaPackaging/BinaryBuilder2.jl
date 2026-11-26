using Test, BinaryBuilder2, Pkg, JLLGenerator, Accessors, TOML
using BinaryBuilder2: register_jll!, get_package_versions, reset_timeline!
using BinaryBuilder2: update_registries!, registries_to_download, registry_path, parse_registry_hashes
using BinaryBuilder2: exported_artifact_filename
using Base.BinaryPlatforms: Platform

function with_depot_path(f, depots)
    old = copy(DEPOT_PATH)
    empty!(DEPOT_PATH)
    append!(DEPOT_PATH, depots)
    try
        return f()
    finally
        empty!(DEPOT_PATH)
        append!(DEPOT_PATH, old)
    end
end

@testset "Exported artifact filenames" begin
    linux = Platform("x86_64", "linux")
    darwin = Platform("aarch64", "macos"; os_version="20")
    @test exported_artifact_filename("Zlib", nothing, v"1.4.1", linux) == "Zlib.v1.4.1.x86_64-linux-gnu.tar.gz"
    @test exported_artifact_filename("Zlib", nothing, v"1.4.1", darwin) == "Zlib.v1.4.1.aarch64-apple-darwin20.tar.gz"
    @test exported_artifact_filename("Zlib", "build_log", v"1.4.1", linux) == "Zlib-build_log.v1.4.1.x86_64-linux-gnu.tar.gz"
    @test exported_artifact_filename("Zlib", nothing, v"1.4.1", linux; compressor="zstd") == "Zlib.v1.4.1.x86_64-linux-gnu.tar.zst"
    @test_throws ArgumentError exported_artifact_filename("Zlib", nothing, v"1.4.1", linux; compressor="xz")
end

@testset "Universes" begin
    # Create a universe holding just `General`
    mktempdir() do dir
        uni = Universe("bb2_tests"; depot_path=dir)
        
        # Register a JLL into it; we'll use HelloWorldC_jll from JLLGenerator contrib directory,
        # but we'll name it `HelloWorldC2_jll` so that it is created as a new entry in the registry
        hwc_jll = include(joinpath(pkgdir(JLLGenerator), "contrib", "example_jllinfos", "HelloWorldC_jll.jl"))
        hwc_jll = @set hwc_jll.name = "HelloWorldC2"
        hwc_jll = @set hwc_jll.version = v"1.3.0"
        hwc_jll = @set hwc_jll.builds = map(hwc_jll.builds) do build
            build = @set build.src_version = v"1.3.0"
            build = @set build.name = "HelloWorldC2"
            return build
        end
        register_jll!(uni, hwc_jll; skip_artifact_export=true)
        @test get_package_versions(uni, "HelloWorldC2_jll") == [v"1.3.0"]

        # Launch a Julia sub-process and ensure that we can load HelloWorldC_jll from the universe
        in_universe(uni) do env
            @test success(run(addenv(`$(Base.julia_cmd()) --project=$(BinaryBuilder2.environment_path(uni)) -e "using Pkg; Pkg.instantiate(); using HelloWorldC2_jll, Test; @test success(hello_world())"`, env)))
        end

        # Re-create `uni`, ensure that our build of `hwc_jll` still exists:
        uni = Universe("bb2_tests"; depot_path=dir)
        @test get_package_versions(uni, "HelloWorldC2_jll") == [v"1.3.0"]

        # Register a second version of HelloWorldC2_jll, to ensure that we can stack multiple builds,
        # as long as the `src_version`'s in the builds are different:
        hwc_jll = @set hwc_jll.version = v"1.4.0"
        hwc_jll = @set hwc_jll.builds = map(hwc_jll.builds) do build
            build = @set build.src_version = v"1.4.0"
            return build
        end
        register_jll!(uni, hwc_jll; skip_artifact_export=true)

        hwc_versions = get_package_versions(uni, "HelloWorldC2_jll")
        @test sort(hwc_versions) == [v"1.3.0", v"1.4.0"]

        # Test that `reset_timeline!` eliminates our registrations:
        reset_timeline!(uni)
        @test isempty(get_package_versions(uni, "HelloWorldC2_jll"))
    end
end

@testset "Registering a JLL in two universes" begin
    function example_jll(name, version)
        jll = include(joinpath(pkgdir(JLLGenerator), "contrib", "example_jllinfos", "HelloWorldC_jll.jl"))
        jll = @set jll.name = name
        jll = @set jll.version = version
        jll = @set jll.builds = map(jll.builds) do build
            build = @set build.src_version = version
            build = @set build.name = name
            return build
        end
        return jll
    end

    # `HelloWorldC_jll` has a repository listed in `General`, `HelloWorldC3_jll` does not.
    for jll in (example_jll("HelloWorldC", v"1.99.0"), example_jll("HelloWorldC3", v"1.0.0"))
        mktempdir() do dir_a
            mktempdir() do dir_b
                uni_a = Universe("jllcheckout-a"; depot_path=dir_a)
                uni_b = Universe("jllcheckout-b"; depot_path=dir_b)
                register_jll!(uni_a, jll; skip_artifact_export=true)

                # Registering the same JLL elsewhere must not disturb the repository
                # that `uni_a`'s checkout was made from.
                register_jll!(uni_b, jll; skip_artifact_export=true)
                for uni in (uni_a, uni_b)
                    jll_path = joinpath(uni.depot_path, "dev", "$(jll.name)_jll")
                    @test success(BinaryBuilder2.Git.git(["-C", jll_path, "fsck", "--full"]))
                    @test !isempty(readchomp(BinaryBuilder2.Git.git(["-C", jll_path, "rev-list", "--max-count=1", "HEAD"])))
                    @test get_package_versions(uni, "$(jll.name)_jll") ⊇ [jll.version]
                end

                # A JLL without a remote repository gets a repository of its own in each universe.
                if jll.name == "HelloWorldC3"
                    for uni in (uni_a, uni_b)
                        @test isdir(BinaryBuilder2.jll_local_repo_path(uni, jll.name))
                    end
                end
            end
        end
    end
end

@testset "Registry downloads" begin
    # We want every session to start from an up-to-date registry, but we only want to
    # pay for that once, no matter how many `Universe`s get built on top of it.
    mktempdir() do depot
        registries = copy(Pkg.Registry.DEFAULT_REGISTRIES)
        @test !isempty(registries_to_download(registries, depot))

        update_registries!(registries, depot)
        @test isempty(registries_to_download(registries, depot))

        # A registry that goes missing gets fetched again regardless.
        rm(registry_path(depot, "General"); recursive=true, force=true)
        @test !isempty(registries_to_download(registries, depot))

        # ...and a depot we've never filled out obviously needs its own download.
        mktempdir() do other_depot
            @test !isempty(registries_to_download(registries, other_depot))
        end

        # A registry pinned to a snapshot gets exactly that snapshot, regardless of
        # whether we've already downloaded it during this session.
        general = only(update_registries!(registries, depot))
        general_hash = bytes2hex(general.tree_info.bytes)
        mktempdir() do pinned_depot
            # No depot on `DEPOT_PATH` holds the snapshot, so it gets downloaded
            pinned = with_depot_path(String[]) do
                only(update_registries!(registries, pinned_depot; registry_hashes=Dict("General" => general_hash)))
            end
            @test pinned.tree_info == general.tree_info
            @test isfile(joinpath(pinned_depot, "registries", "General.tar.gz"))
            @test !islink(joinpath(pinned_depot, "registries", "General.tar.gz"))

            # Asking for it again doesn't need to download anything
            mtime_before = mtime(joinpath(pinned_depot, "registries", "General.tar.gz"))
            update_registries!(registries, pinned_depot; registry_hashes=Dict("General" => general_hash))
            @test mtime(joinpath(pinned_depot, "registries", "General.tar.gz")) == mtime_before
        end

        # A depot on `DEPOT_PATH` that holds the snapshot gets linked rather than downloaded
        mktempdir() do pinned_depot
            pinned = with_depot_path([depot]) do
                only(update_registries!(registries, pinned_depot; registry_hashes=Dict("General" => general_hash)))
            end
            @test pinned.tree_info == general.tree_info
            @test islink(joinpath(pinned_depot, "registries", "General.toml"))
            @test BinaryBuilder2.installed_registry_tree_hash(general) == general_hash
        end
        @test_throws ArgumentError update_registries!(registries, depot; registry_hashes=Dict("Nonexistent" => general_hash))
    end

    # A registry that a depot already holds from an earlier session gets refreshed by the
    # first `update_registries!()` of the next session, unless it is pinned.
    mktempdir() do depot
        registries = copy(Pkg.Registry.DEFAULT_REGISTRIES)
        general_toml = joinpath(depot, "registries", "General.toml")
        stale_hash = "0"^40
        function make_stale!(depot)
            toml = TOML.parsefile(general_toml)
            toml["git-tree-sha1"] = stale_hash
            open(io -> TOML.print(io, toml), general_toml; write=true)
            delete!(BinaryBuilder2.downloaded_registries, (depot, "General"))
        end

        update_registries!(registries, depot)
        make_stale!(depot)
        general = only(update_registries!(registries, depot))
        @test bytes2hex(general.tree_info.bytes) != stale_hash
        @test TOML.parsefile(general_toml)["git-tree-sha1"] != stale_hash

        make_stale!(depot)
        pinned = only(update_registries!(registries, depot; registry_hashes=Dict("General" => stale_hash)))
        @test bytes2hex(pinned.tree_info.bytes) == stale_hash
        @test TOML.parsefile(general_toml)["git-tree-sha1"] == stale_hash
    end

    @test parse_registry_hashes("General=$("a"^40),Other=$("b"^40)") == Dict("General" => "a"^40, "Other" => "b"^40)
    @test_throws ArgumentError parse_registry_hashes("General=main")
end
