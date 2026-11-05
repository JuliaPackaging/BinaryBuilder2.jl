using Test, BinaryBuilder2, Pkg, JLLGenerator, Accessors
using BinaryBuilder2: register_jll!, get_package_versions, reset_timeline!
using BinaryBuilder2: update_registries!, registries_to_download, registry_path, parse_registry_hashes
using BinaryBuilder2: registry_pr_text, new_registered_versions, jll_commit_for_tree
using BinaryBuilderGitUtils: git

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

        # Both versions are new to `General`, and the latest one's registered tree maps back
        # to its JLL commit
        hwc_path = joinpath(dir, "dev", "HelloWorldC2_jll")
        new_versions = new_registered_versions(uni, registry_path(uni, first(uni.registries)), "HelloWorldC2_jll")
        @test first.(new_versions) == [v"1.3.0", v"1.4.0"]
        @test jll_commit_for_tree(hwc_path, last(new_versions)[2]) == readchomp(git(["-C", hwc_path, "rev-parse", "HEAD"]))
        @test jll_commit_for_tree(hwc_path, "0"^40) === nothing

        # Test that `reset_timeline!` eliminates our registrations:
        reset_timeline!(uni)
        @test isempty(get_package_versions(uni, "HelloWorldC2_jll"))
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
            pinned = only(update_registries!(registries, pinned_depot; registry_hashes=Dict("General" => general_hash)))
            @test pinned.tree_info == general.tree_info
            @test isfile(joinpath(pinned_depot, "registries", "General.tar.gz"))

            # Asking for it again doesn't need to download anything
            mtime_before = mtime(joinpath(pinned_depot, "registries", "General.tar.gz"))
            update_registries!(registries, pinned_depot; registry_hashes=Dict("General" => general_hash))
            @test mtime(joinpath(pinned_depot, "registries", "General.tar.gz")) == mtime_before
        end
        @test_throws ArgumentError update_registries!(registries, depot; registry_hashes=Dict("Nonexistent" => general_hash))
    end

    @test parse_registry_hashes("General=$("a"^40),Other=$("b"^40)") == Dict("General" => "a"^40, "Other" => "b"^40)
    @test_throws ArgumentError parse_registry_hashes("General=main")
end

@testset "Registry pull request text" begin
    repo_url = "https://github.com/JuliaBinaryWrappers/Foo_jll.jl.git"
    title, body = registry_pr_text("Foo_jll", repo_url, [(v"1.2.3", "a"^40)], false)
    @test title == "New version: Foo_jll v1.2.3"
    @test body == """
    Autogenerated JLL package registration

    * Registering JLL package Foo_jll.jl
    * Repository: $(repo_url)
    * Version: v1.2.3
    * Commit: $("a"^40)
    """
    @test first(registry_pr_text("Foo_jll", repo_url, [(v"1.2.3", "a"^40)], true)) == "New package: Foo_jll v1.2.3"

    versions = [(v"2.17.1", "a"^40), (v"2.19.1", nothing), (v"2.34.1", "c"^40)]
    title, body = registry_pr_text("Glibc_jll", repo_url, versions, false)
    @test title == "New versions: Glibc_jll v2.17.1, v2.19.1, v2.34.1"
    @test body == """
    Autogenerated JLL package registration

    * Registering JLL package Glibc_jll.jl
    * Repository: $(repo_url)
    * Versions:
      * v2.17.1 (commit: $("a"^40))
      * v2.19.1
      * v2.34.1 (commit: $("c"^40))
    """
    @test first(registry_pr_text("Glibc_jll", repo_url, versions[1:2], true)) == "New package: Glibc_jll v2.17.1, v2.19.1"
end
