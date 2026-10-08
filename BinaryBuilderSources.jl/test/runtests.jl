using Test, BinaryBuilderSources, SHA, Base.BinaryPlatforms, Pkg, TreeArchival, TOML
using BinaryBuilderSources: verify, download_cache_path, source_download_cache, generated_source_cache
using BinaryBuilderSources: registry_slice_hash, full_registries_hash
using BinaryBuilderSources: strict_tags, check_strict_tags, exempt_from_strict_tags
using Pkg.Registry: RegistryInstance

include("common.jl")

const exext = Sys.iswindows() ? ".exe" : ""
const soext = Sys.iswindows() ? ".dll" :
              Sys.isapple() ? ".dylib" : ".so"
const binlib = Sys.iswindows() ? "bin" : "lib"

@testset "Sources" begin
    with_temp_storage_locations() do
        # A nice small download
        url = "https://github.com/JuliaBinaryWrappers/libcellml_jll.jl/releases/download/libcellml-v0.4.0%2B0/libcellml-logs.v0.4.0.x86_64-w64-mingw32-cxx03.tar.gz"
        hash = "237013b20851355c4c1d22ceac7e73207b44d989d38b6874187d333adfc79c77"

        @testset "ArchiveSource" begin
            as = ArchiveSource(url, hash)

            # Proper construction
            @test as.url == url
            @test as.hash == hex2bytes(hash)
            @test as.target == ""

            # Nothing is on disk yet
            download_path = download_cache_path(as)
            @test !isfile(download_path)
            @test !verify(as)
            @test_throws InvalidStateException deploy(as, @__DIR__)

            # Download succeeds
            prepare(as)
            @test isfile(download_path)
            @test verify(as)
            @test content_hash(as) == "25e8054cbaf45b17af3cc4f8b67cce3d3341b9d8"

            # Deployment succeeds
            mktempdir() do prefix
                deploy(as, prefix)
                @test isdir(joinpath(prefix, as.target))
                @test isfile(joinpath(prefix, "logs", "libcellml", "libcellml.log.gz"))
            end

            # Stale hash cache files still verify properly
            @test verify(as)
            setmtime(download_path, time() + 1.1)
            @test verify(as)

            open(download_path, write=true, append=true) do io
                write(io, UInt8(0))
            end
            setmtime(download_path, time() + 2.1)
            @test_throws ArgumentError verify(as)

            # Fix the file back
            open(download_path, write=true, append=true) do io
                truncate(io, filesize(io)-1)
            end
            setmtime(download_path, time() + 3.1)
            @test verify(as)


            # target works
            as = ArchiveSource(url, hash; target="foo/bar")
            @test as.target == "foo/bar"

            # We don't need to prepare() a second time, it's already good:
            @test verify(as)
            mktempdir() do prefix
                deploy(as, prefix)
                @test isdir(joinpath(prefix, as.target))
                @test isfile(joinpath(prefix, "foo", "bar", "logs", "libcellml", "libcellml.log.gz"))
            end

            @test_throws ArgumentError ArchiveSource(url, hash; target="/foo/bar")

            # retarget works
            as = retarget(as, "baz")
            @test as.target == "baz"
            @test_throws ArgumentError retarget(as, "/foo/bar")

            # source works
            @test source(as) == url
        end

        @testset "FileSource" begin
            fs = FileSource(url, hash)

            # Proper construction
            @test fs.url == url
            @test fs.hash == hex2bytes(hash)
            @test fs.target == basename(url)

            # The download from the ArchiveSource is shared by us!
            download_path = download_cache_path(fs)
            @test isfile(download_path)
            @test verify(fs)
            @test content_hash(fs) == "7a0f0237dc373d3d8f08ad7805607e0178b6ef3b"

            # But let's exercise our own downloading chops and ensure that it still works:
            rm(download_path)
            @test !verify(fs)
            @test_throws InvalidStateException deploy(fs, @__DIR__)
            prepare(fs)
            @test isfile(download_path)
            @test verify(fs)

            # Deployment succeeds
            mktempdir() do prefix
                deploy(fs, prefix)
                @test isfile(joinpath(prefix, fs.target))
            end

            # target works
            fs = FileSource(url, hash; target="foo/bar")
            @test fs.target == "foo/bar"

            mktempdir() do prefix
                deploy(fs, prefix)
                @test isfile(joinpath(prefix, fs.target))
            end

            # No absolute paths allowed
            @test_throws ArgumentError FileSource(url, hash; target="/foo/bar")

            # retarget works
            fs = retarget(fs, "baz")
            @test fs.target == "baz"
            @test_throws ArgumentError retarget(fs, "/foo/bar")

            # source works
            @test source(fs) == url
        end

        url = "https://github.com/ralna/ARCHDefs.git"
        hash = "fc8c5960c3a6d26970ab245241cfc067fe4ecfdd"
        prev_hash = "dab23a5df2e33495c8d843920cc267c0c5051fe8"
        @testset "GitSource" begin
            # Construction works
            gs = GitSource(url, hash)
            @test gs.url == url
            @test gs.hash == hex2bytes(hash)
            @test gs.target == basename(url)[1:end-4]

            # Nothing is on disk yet
            clone_path = download_cache_path(gs)
            @test !isfile(clone_path)
            @test !verify(gs)
            @test_throws InvalidStateException deploy(gs, @__DIR__)

            # Download succeeds
            prepare(gs)
            @test isdir(clone_path)
            @test verify(gs)
            @test content_hash(gs) == hash

            # Deployment succeeds
            mktempdir() do prefix
                deploy(gs, prefix)
                @test isdir(joinpath(prefix, gs.target))
                @test isfile(joinpath(prefix, gs.target, "version"))
            end

            # Invalid commit throws
            gs = GitSource(url, sha1("not a real commit sha"))
            @test !verify(gs)
            @test_throws ArgumentError prepare(gs)

            # Commits we know we already have verify immediately
            gs = GitSource(url, prev_hash)
            @test verify(gs)

            # target works
            gs = GitSource(url, hash, target="ARCHDefs")
            @test gs.target == "ARCHDefs"
            @test verify(gs)
            mktempdir() do prefix
                deploy(gs, prefix)
                @test isdir(joinpath(prefix, gs.target))
                @test isfile(joinpath(prefix, gs.target, "version"))
            end

            # Absolute paths not allowed
            @test_throws ArgumentError GitSource(url, hash; target="/foo/bar")

            # SHA256 hashes not allowed (yet)
            @test_throws ArgumentError GitSource(url, sha256("foo"))

            # retarget works
            gs = retarget(gs, "baz")
            @test gs.target == "baz"
            @test_throws ArgumentError retarget(gs, "/foo/bar")

            # source works
            @test source(gs) == url
        end

        @testset "DirectorySource" begin
            mktempdir() do build_dir; cd(build_dir) do
                # Generate a directory to use as our source
                mkdir("src")
                open(joinpath("src", "foo"); write=true) do io
                    println(io, "I am foo!")
                end
                chmod(joinpath("src", "foo"), 0o644);
                symlink("foo", joinpath("src", "link_to_foo"))

                ds = DirectorySource("src")
                @test ds.source == abspath("src")
                @test ds.target == ""
                @test ds.follow_symlinks == false

                # Test that this can be run, even though they don't do anything
                prepare(ds)
                @test content_hash(ds) == "74d740b14685c131d2b0caa431be3557d51eaa53"

                # Deploy works
                mktempdir() do prefix
                    deploy(ds, prefix)
                    @test isfile(joinpath(prefix, "foo"))
                    @test islink(joinpath(prefix, "link_to_foo"))
                end

                # target and follow_symlinks work:
                ds = DirectorySource("src"; target="bar/baz", follow_symlinks=true)
                @test ds.target == "bar/baz"
                @test ds.follow_symlinks == true

                mktempdir() do prefix
                    deploy(ds, prefix)
                    @test isfile(joinpath(prefix, ds.target, "foo"))
                    @test !islink(joinpath(prefix, ds.target, "link_to_foo"))
                    @test isfile(joinpath(prefix, ds.target, "link_to_foo"))
                end

                # Invalid source directories throw
                @test_throws ArgumentError DirectorySource("blah")

                # retarget works
                ds = retarget(ds, "baz")
                @test ds.target == "baz"
                @test_throws ArgumentError retarget(ds, "/foo/bar")

                # source works
                @test source(ds) == abspath("src")
            end; end
        end

        @testset "GeneratedSource" begin
            mktempdir() do build_dir; cd(build_dir) do
                num_times_generated = 0
                function generate_dir(dir)
                    open(joinpath(dir, "foo"); write=true) do io
                        println(io, "I am foo!")
                    end
                    symlink("foo", joinpath(dir, "link_to_foo"))
                    num_times_generated += 1
                end

                gs = GeneratedSource(generate_dir, "generate_test")
                @test gs.ds.target == ""
                @test gs.ds.follow_symlinks == false
                @test !isfile(joinpath(gs.ds.source, "foo"))
                @test !islink(joinpath(gs.ds.source, "link_to_foo"))
                @test num_times_generated == 0

                # Run the generation
                prepare(gs)

                @test isfile(joinpath(gs.ds.source, "foo"))
                @test islink(joinpath(gs.ds.source, "link_to_foo"))
                @test content_hash(gs) == "74d740b14685c131d2b0caa431be3557d51eaa53"
                @test num_times_generated == 1

                # Even if we delete one of the files, re-preparing doesn't do anything
                rm(joinpath(gs.ds.source, "foo"))
                prepare(gs)
                @test !isfile(joinpath(gs.ds.source, "foo"))
                @test islink(joinpath(gs.ds.source, "link_to_foo"))
                @test num_times_generated == 1

                # But if we delete the whole directory, it does something:
                rm(gs.ds.source; recursive=true, force=true)
                prepare(gs)
                @test isfile(joinpath(gs.ds.source, "foo"))
                @test islink(joinpath(gs.ds.source, "link_to_foo"))
                @test content_hash(gs) == "74d740b14685c131d2b0caa431be3557d51eaa53"
                @test num_times_generated == 2

                # Deploy works
                mktempdir() do prefix
                    deploy(gs, prefix)
                    @test isfile(joinpath(prefix, "foo"))
                    @test islink(joinpath(prefix, "link_to_foo"))
                end

                # target works:
                gs = GeneratedSource(generate_dir, "target_test"; target="bar/baz")
                prepare(gs)
                @test gs.ds.target == "bar/baz"
                @test gs.ds.follow_symlinks == false

                mktempdir() do prefix
                    deploy(gs, prefix)
                    @test isfile(joinpath(prefix, gs.ds.target, "foo"))
                    @test islink(joinpath(prefix, gs.ds.target, "link_to_foo"))
                end

                # retarget works
                gs = retarget(gs, "baz")
                @test gs.ds.target == "baz"
                @test_throws ArgumentError retarget(gs, "/foo/bar")

                # source works
                @test source(gs) == "<generated>"
            end; end
        end


        @testset "JLLSource" begin
            bzip2_dep = JLLSource("Bzip2_jll", HostPlatform())
            zstd_dep = JLLSource("Zstd_jll", HostPlatform())
            @test bzip2_dep.package.name == "Bzip2_jll"
            @test zstd_dep.package.name == "Zstd_jll"
            @test bzip2_dep.target == ""
            @test zstd_dep.target == ""
            @test isempty(bzip2_dep.artifact_paths)
            @test isempty(zstd_dep.artifact_paths)

            # Download the files, check that they have artifact paths now:
            prepare([bzip2_dep, zstd_dep])
            @test !isempty(bzip2_dep.artifact_paths)
            @test !isempty(zstd_dep.artifact_paths)
            depot_artifacts_dir = joinpath(source_download_cache("jllsource_depot"), "artifacts")
            @test all(startswith.(bzip2_dep.artifact_paths, Ref(depot_artifacts_dir)))
            @test all(startswith.(zstd_dep.artifact_paths, Ref(depot_artifacts_dir)))
            @test content_hash(bzip2_dep) != content_hash(zstd_dep)

            mktempdir() do prefix
                deploy([bzip2_dep, zstd_dep], prefix)
                @test isfile(joinpath(prefix, "bin", "zstd$(exext)"))
                @test isfile(joinpath(prefix, binlib, "libbz2$(soext)"))
            end

            # Test that subprefix works
            ccache_dep = JLLSource("Ccache_jll", HostPlatform(); target="ext")
            @test ccache_dep.target == "ext"
            prepare([ccache_dep])
            mktempdir() do prefix
                deploy([bzip2_dep, ccache_dep], prefix)
                # Ccache depends on zstd_jll, and that also gets installed in `ext`
                @test isfile(joinpath(prefix, "ext", "bin", "ccache$(exext)"))
                @test isfile(joinpath(prefix, "ext", "bin", "zstd$(exext)"))

                # bzip2 is still installed to the correct spot:
                @test isfile(joinpath(prefix, binlib, "libbz2$(soext)"))
            end

            @testset "resolution cache" begin
                old_jll_resolve_cache = BinaryBuilderSources._jll_resolve_cache[]
                mktempdir() do dir
                    BinaryBuilderSources._jll_resolve_cache[] = name -> joinpath(dir, "jll_resolve_cache", name)
                    try
                        # Resolve once to write the cache for this slice
                        prepare([JLLSource("Ccache_jll", HostPlatform())])
                        cache_path = only(filter(p -> isfile(joinpath(p, "cache.toml")),
                                                 readdir(joinpath(dir, "jll_resolve_cache"); join=true)))
                        cache_path = joinpath(cache_path, "cache.toml")
                        cache = TOML.parsefile(cache_path)
                        ccache_uuid = only(k for (k, v) in cache if v isa Dict && v["name"] == "Ccache_jll")
                        zstd_uuid = string(zstd_dep.package.uuid)
                        @test zstd_uuid in cache["dep_uuids"]

                        # Point the cache at a recognizable (existing) directory, to see where paths come from
                        fake_artifact = mkpath(joinpath(dir, "fake_artifact"))
                        cache[ccache_uuid]["artifact_paths"] = [fake_artifact]
                        open(io -> TOML.print(io, cache), cache_path; write=true)
                        ccache_dep = JLLSource("Ccache_jll", HostPlatform())
                        prepare([ccache_dep])
                        @test ccache_dep.artifact_paths == [fake_artifact]

                        # When a dependency of the slice is one we built ourselves, the cache must
                        # not be used, and the slice gets resolved instead.
                        project_dir = mkpath(joinpath(dir, "project"))
                        open(io -> TOML.print(io, Dict("deps" => Dict("Zstd_jll" => zstd_uuid))),
                             joinpath(project_dir, "Project.toml"); write=true)
                        ccache_dep = JLLSource("Ccache_jll", HostPlatform())
                        prepare([ccache_dep]; project_dir)
                        @test !isempty(ccache_dep.artifact_paths)
                        @test fake_artifact ∉ ccache_dep.artifact_paths

                        # A corrupt cache (here: lacking `dep_uuids`) is dropped, and the slice resolved
                        cache = TOML.parsefile(cache_path)
                        delete!(cache, "dep_uuids")
                        open(io -> TOML.print(io, cache), cache_path; write=true)
                        ccache_dep = JLLSource("Ccache_jll", HostPlatform())
                        prepare([ccache_dep])
                        @test !isempty(ccache_dep.artifact_paths)
                        @test all(isdir, ccache_dep.artifact_paths)
                        @test haskey(TOML.parsefile(cache_path), "dep_uuids")
                    finally
                        BinaryBuilderSources._jll_resolve_cache[] = old_jll_resolve_cache
                    end
                end
            end

            # Test that installing a specific platform works:
            local foreign_platform
            if Sys.isapple()
                foreign_platform = Platform("x86_64", "linux")
                foreign_soext = ".so"
            else
                foreign_platform = Platform("aarch64", "macos")
                foreign_soext = ".dylib"
            end
            bzip2_foreign_dep = JLLSource("Bzip2_jll", foreign_platform)
            mktempdir() do prefix
                prepare(bzip2_foreign_dep)
                deploy(bzip2_foreign_dep, prefix)
                @test isfile(joinpath(prefix, "lib", "libbz2$(foreign_soext)"))
            end

            @testset "strict tags" begin
                msan = Platform("x86_64", "linux"; sanitize="memory")
                plain = Platform("x86_64", "linux")
                meta(; kwargs...) = Dict{String,Any}("git-tree-sha1" => "0"^40, "arch" => "x86_64", "os" => "linux",
                                                     (string(k) => v for (k, v) in kwargs)...)
                metas(m) = Dict(PackageSpec(; name="Foo_jll") => m)

                @test "sanitize" in strict_tags
                # Same value, or absent on both sides: fine
                @test check_strict_tags(metas(meta(; sanitize="memory")), msan) === nothing
                @test check_strict_tags(metas(meta()), plain) === nothing
                # Any difference is an error, including a tag present on only one side
                @test_throws r"Foo_jll.*`sanitize=memory`.*no `sanitize` tag" check_strict_tags(metas(meta()), msan)
                @test_throws r"Foo_jll.*no `sanitize` tag.*`sanitize=memory`" check_strict_tags(metas(meta(; sanitize="memory")), plain)
                @test_throws ErrorException check_strict_tags(metas(meta(; sanitize="address")), msan)
                # Platform-independent artifacts, and JLLs without an artifact for this platform, are fine
                @test check_strict_tags(metas(delete!(meta(), "arch")), msan) === nothing
                @test check_strict_tags(metas(Dict{String,Any}("paths" => String[], "dep_uuids" => Base.UUID[])), msan) === nothing
                # Other tags are matched as usual
                @test check_strict_tags(metas(meta(; cxxstring_abi="cxx11")), plain) === nothing
                # The list can be extended
                push!(strict_tags, "mytag")
                try
                    @test_throws r"mytag" check_strict_tags(metas(meta(; mytag="1")), plain)
                    @test check_strict_tags(metas(meta(; mytag="1")), Platform("x86_64", "linux"; mytag="1")) === nothing
                finally
                    delete!(strict_tags, "mytag")
                end

                # Toolchain-internal JLLs (pinned to a repository, installed into a subdirectory) are exempt
                repo = Pkg.Types.GitRepo(; source="https://github.com/JuliaBinaryWrappers/Bzip2_jll.jl")
                @test exempt_from_strict_tags(JLLSource("Bzip2_jll", msan; repo, target="sysroot"))
                @test !exempt_from_strict_tags(JLLSource("Bzip2_jll", msan; repo))
                @test !exempt_from_strict_tags(JLLSource("Bzip2_jll", msan; target="sysroot"))

                # `prepare()` checks what it selects, including transitive dependencies
                @test_throws r"Bzip2_jll.*sanitize" prepare([JLLSource("Bzip2_jll", msan)])
                @test_throws r"Zstd_jll.*sanitize" prepare([JLLSource("LibCURL_jll", msan)])
                zlib_msan = JLLSource("Zlib_jll", msan)
                zlib_plain = JLLSource("Zlib_jll", plain)
                prepare([zlib_msan])
                prepare([zlib_plain])
                @test !isempty(zlib_msan.artifact_paths)
                @test !isempty(zlib_plain.artifact_paths)
                @test zlib_msan.artifact_paths != zlib_plain.artifact_paths
            end

            # retarget works
            bzip2_dep = retarget(bzip2_dep, "baz")
            @test bzip2_dep.target == "baz"
            @test_throws ArgumentError retarget(bzip2_dep, "/foo/bar")

            # source works
            @test startswith(source(bzip2_dep), "Bzip2_jll@v")

            # Test that multiple versions can be coalesced down to one:
            zstd_any_dep = JLLSource(
                PackageSpec(;name="Zstd_jll", version=Pkg.Types.VersionSpec("*")),
                HostPlatform(),
            )
            # Test that before we've done any version resolution, we get no version suffix
            @test source(zstd_any_dep) == "Zstd_jll"

            zstd_specific_dep = JLLSource(
                PackageSpec(;name="Zstd_jll", version=zstd_dep.package.version),
                HostPlatform(),
            )
            @test length(deduplicate_jlls([zstd_any_dep, zstd_specific_dep])) == 1
            @test startswith(source(zstd_specific_dep), "Zstd_jll@v")

            # Test that disjoint versions throw an error:
            zstd_impossible_dep = JLLSource(
                PackageSpec(;name="Zstd_jll", version=v"0.0.0"),
                HostPlatform(),
            )
            @test_throws ArgumentError deduplicate_jlls([zstd_impossible_dep, zstd_specific_dep])
            @test startswith(source(zstd_specific_dep), "Zstd_jll@v")
            @test startswith(source(zstd_any_dep), "Zstd_jll@v")

            # Test that disjoint versions in separate prefixes is okay:
            @test length(deduplicate_jlls([
                retarget(zstd_specific_dep, "foo"),
                retarget(zstd_impossible_dep, "bar"),
            ])) == 2

            function get_overlapping_jlls(should_warn = false)
                return [
                    # Get a zstd JLL, and another package that just so happens to contain the same files:
                    JLLSource("Zstd_jll", HostPlatform(),
                        uuid=Base.UUID("3161d3a3-bdf6-5164-811a-617609db77b4"),
                        version=v"1.5.6+3",
                        warn_on_overwrite=should_warn,
                    ),
                    JLLSource("OverlappingZstd_jll", HostPlatform(),
                        uuid=Base.UUID("3161d3a3-bdf6-5164-811a-000000000000"),
                        repo=Pkg.Types.GitRepo(
                            source="https://github.com/staticfloat/OverlappingZstd_jll.jl",
                            rev="cde53a86f0bf893872606759e28be06ebe1b8e89",
                        ),
                        warn_on_overwrite=false,
                    ),
                ]
            end

            # Test that two JLLs with overlapping contents warns about overwriting:
            mktempdir() do prefix
                jlls = get_overlapping_jlls(true)
                prepare(jlls)
                @test_logs (:warn, r"already exists in") match_mode=:any begin
                    deploy(jlls, prefix)
                end
            end

            # Test that we can squelch this by setting all JLLSource's to have
            # `warn_on_overwrite` set to `false`.
            mktempdir() do prefix
                jlls = get_overlapping_jlls(false)
                prepare(jlls)
                @test_logs begin
                    deploy(jlls, prefix)
                end
            end
        end
    end
end

@testset "Registry slicing" begin
    # A tiny synthetic registry: `Root_jll` -> `Mid_jll` -> `Leaf_jll`, plus an
    # `Other_jll` that nothing depends on.
    uuids = Dict(
        "Root_jll"  => "00000000-0000-0000-0000-000000000001",
        "Mid_jll"   => "00000000-0000-0000-0000-000000000002",
        "Leaf_jll"  => "00000000-0000-0000-0000-000000000003",
        "Other_jll" => "00000000-0000-0000-0000-000000000004",
    )
    reg_uuid = "00000000-0000-0000-0000-0000000000aa"
    function write_registry(dir; versions = Dict{String,Vector{String}}(), mid_deps = ["Leaf_jll"])
        mkpath(dir)
        open(joinpath(dir, "Registry.toml"); write=true) do io
            println(io, "name = \"TestReg\"")
            println(io, "uuid = \"$(reg_uuid)\"")
            println(io, "[packages]")
            for (name, uuid) in uuids
                println(io, "\"$(uuid)\" = { name = \"$(name)\", path = \"$(name[1])/$(name)\" }")
            end
        end
        for (name, uuid) in uuids
            pkg_dir = joinpath(dir, string(name[1]), name)
            mkpath(pkg_dir)
            write(joinpath(pkg_dir, "Package.toml"),
                  "name = \"$(name)\"\nuuid = \"$(uuid)\"\nrepo = \"https://example.com/$(name).git\"\n")
            open(joinpath(pkg_dir, "Versions.toml"); write=true) do io
                for (idx, v) in enumerate(get(versions, name, ["1.0.0"]))
                    println(io, "[\"$(v)\"]\ngit-tree-sha1 = \"$(string(idx; pad=40, base=16))\"\n")
                end
            end
            deps = name == "Root_jll" ? ["Mid_jll"] : (name == "Mid_jll" ? mid_deps : String[])
            if !isempty(deps)
                open(joinpath(pkg_dir, "Deps.toml"); write=true) do io
                    println(io, "[\"1\"]")
                    for dep in deps
                        println(io, "$(dep) = \"$(uuids[dep])\"")
                    end
                end
            end
        end
    end
    # Package the registry up the way `Pkg` downloads them: a `.tar.gz` next to a
    # `.toml` that records its tree hash.  This is the only kind of registry we slice.
    function make_registry(dir; kwargs...)
        src_dir = joinpath(dir, "src")
        write_registry(src_dir; kwargs...)
        TreeArchival.archive(src_dir, joinpath(dir, "TestReg.tar.gz"), "gzip")
        toml_path = joinpath(dir, "TestReg.toml")
        open(toml_path; write=true) do io
            println(io, "git-tree-sha1 = \"$(bytes2hex(TreeArchival.treehash(SHA.SHA1_CTX, src_dir)))\"")
            println(io, "uuid = \"$(reg_uuid)\"")
            println(io, "path = \"TestReg.tar.gz\"")
        end
        return RegistryInstance(toml_path)
    end
    # A registry that lives as a plain directory, as a git checkout would.
    function make_directory_registry(dir; kwargs...)
        write_registry(dir; kwargs...)
        return RegistryInstance(dir)
    end

    mktempdir() do dir
        root = PackageSpec(;name="Root_jll")
        base = [make_registry(joinpath(dir, "base"))]
        base_hash = registry_slice_hash(root, base)

        # An unrelated package gaining a version must not change the slice, even though
        # it changes the registry as a whole.  This is the entire point of slicing.
        unrelated = [make_registry(joinpath(dir, "unrelated"); versions=Dict("Other_jll" => ["1.0.0", "2.0.0"]))]
        @test registry_slice_hash(root, unrelated) == base_hash
        @test full_registries_hash(unrelated) != full_registries_hash(base)

        # A transitive dependency gaining a version must change the slice.
        relevant = [make_registry(joinpath(dir, "relevant"); versions=Dict("Leaf_jll" => ["1.0.0", "1.1.0"]))]
        @test registry_slice_hash(root, relevant) != base_hash

        # So must a change in the shape of the dependency graph, and thereafter changes
        # to the package that graph newly reaches.
        regraphed = [make_registry(joinpath(dir, "regraphed"); mid_deps=["Leaf_jll", "Other_jll"])]
        @test registry_slice_hash(root, regraphed) != base_hash
        regraphed_bumped = [make_registry(joinpath(dir, "regraphed_bumped");
                                          mid_deps=["Leaf_jll", "Other_jll"],
                                          versions=Dict("Other_jll" => ["1.0.0", "2.0.0"]))]
        @test registry_slice_hash(root, regraphed_bumped) != registry_slice_hash(root, regraphed)

        # Identical content in a different location hashes identically...
        @test registry_slice_hash(root, [make_registry(joinpath(dir, "copy"))]) == base_hash
        # ...and a package we can't slice falls back to hashing the registries wholesale.
        @test registry_slice_hash(PackageSpec(;name="Unregistered_jll"), base) == full_registries_hash(base)

        # A registry that is not a tarball (such as a `Universe`'s local registry) is
        # ignored entirely, even when it would have changed the slice.
        directory = make_directory_registry(joinpath(dir, "directory"); versions=Dict("Leaf_jll" => ["1.0.0", "1.1.0"]))
        @test registry_slice_hash(root, [directory; base]) == base_hash
        @test full_registries_hash([directory; base]) == full_registries_hash(base)

        # A `JLLSource`'s `spec_hash()` must not depend on whether `prepare()` has
        # filled out its UUID for us.
        jll = JLLSource("Root_jll", HostPlatform())
        unresolved_hash = spec_hash(jll; registries=base)
        jll.package.uuid = Base.UUID(uuids["Root_jll"])
        @test spec_hash(jll; registries=base) == unresolved_hash

        # A JLL developed by path changes in place when it is rebuilt: its `spec_hash()`
        # must follow the content of its `Project.toml` and `Artifacts.toml`.
        dev_dir = mkpath(joinpath(dir, "Root_jll"))
        write(joinpath(dev_dir, "Project.toml"), "name = \"Root_jll\"\nuuid = \"$(uuids["Root_jll"])\"\nversion = \"1.0.0\"\n")
        write(joinpath(dev_dir, "Artifacts.toml"), "[Root]\ngit-tree-sha1 = \"$("0"^40)\"\n")
        dev_jll = JLLSource(PackageSpec(; name="Root_jll", uuid=Base.UUID(uuids["Root_jll"]), path=dev_dir), HostPlatform())
        dev_hash = spec_hash(dev_jll; registries=base)
        @test spec_hash(dev_jll; registries=base) == dev_hash
        write(joinpath(dev_dir, "Artifacts.toml"), "[Root]\ngit-tree-sha1 = \"$("1"^40)\"\n")
        artifacts_hash = spec_hash(dev_jll; registries=base)
        @test artifacts_hash != dev_hash
        write(joinpath(dev_dir, "Project.toml"), "name = \"Root_jll\"\nuuid = \"$(uuids["Root_jll"])\"\nversion = \"1.0.1\"\n")
        @test spec_hash(dev_jll; registries=base) != artifacts_hash
    end
end

@testset "Download headers" begin
    using BinaryBuilderSources: download_headers
    asset_url = "https://api.github.com/repos/JuliaPackaging/Yggdrasil/releases/assets/12345"
    withenv("GITHUB_TOKEN" => nothing, "GH_TOKEN" => nothing) do
        # Ordinary URLs get no special headers
        @test isempty(download_headers("https://github.com/JuliaPackaging/Yggdrasil/releases/download/v1/foo.tar.gz"))
        @test isempty(download_headers("https://api.github.com/repos/JuliaPackaging/Yggdrasil/releases/12345"))
        @test isempty(download_headers(asset_url * "/foo"))
        # A release asset by its API URL asks for the asset's content, even without a token
        @test download_headers(asset_url) == ["Accept" => "application/octet-stream"]
    end
    withenv("GITHUB_TOKEN" => nothing, "GH_TOKEN" => "gh_token") do
        @test download_headers(asset_url) == ["Accept" => "application/octet-stream", "Authorization" => "Bearer gh_token"]
    end
    withenv("GITHUB_TOKEN" => "github_token", "GH_TOKEN" => "gh_token") do
        @test download_headers(asset_url) == ["Accept" => "application/octet-stream", "Authorization" => "Bearer github_token"]
        # The token is never sent anywhere else
        @test isempty(download_headers("https://example.com/repos/a/b/releases/assets/1"))
    end
end
