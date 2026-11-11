using Test, BinaryBuilderSources, SHA, Base.BinaryPlatforms, Pkg, TreeArchival, TOML, Sockets, Downloads
using BinaryBuilderSources: verify, download_cache_path, source_download_cache, generated_source_cache
using BinaryBuilderSources: registry_slice_hash, full_registries_hash, tracks_branch
using BinaryBuilderSources: strict_tags, drop_strict_tags, resolution_platform
using Pkg.Registry: RegistryInstance
using BinaryBuilderGitUtils: init!, commit!, remote_url
using BinaryBuilderSources: remote_name
using Git: git

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
            @test as.urls == [url]
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
            @test fs.urls == [url]
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
            @test gs.urls == [url]
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

            # `spec_hash()` hashes the inputs of resolution, so `prepare()` writing the
            # resolved version, tree hash, etc... into `package` must not change it.
            jll_registries = Pkg.Registry.reachable_registries(; depots=[BinaryBuilderSources.default_jll_source_depot()])
            pre_prepare_hashes = spec_hash.([bzip2_dep, zstd_dep]; registries=jll_registries)
            pre_prepare_cache_name = BinaryBuilderSources.jll_cache_name([bzip2_dep, zstd_dep], jll_registries)

            # Download the files, check that they have artifact paths now:
            prepare([bzip2_dep, zstd_dep])
            @test bzip2_dep.package.tree_hash !== nothing
            @test spec_hash.([bzip2_dep, zstd_dep]; registries=jll_registries) == pre_prepare_hashes
            @test BinaryBuilderSources.jll_cache_name([bzip2_dep, zstd_dep], jll_registries) == pre_prepare_cache_name
            # Retargeting carries the requested spec along with the resolved package, and
            # the target is part of what is requested.
            @test spec_hash(retarget(bzip2_dep, ""); registries=jll_registries) == pre_prepare_hashes[1]
            @test spec_hash(retarget(bzip2_dep, "ext"); registries=jll_registries) != pre_prepare_hashes[1]
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

                        # A JLL that tracks a branch is resolved from scratch every time, and
                        # never written into the cache; it keeps tracking that branch afterwards.
                        rm(joinpath(dir, "jll_resolve_cache"); recursive=true)
                        branch_dep = JLLSource("Ccache_jll", HostPlatform();
                            repo=Pkg.Types.GitRepo(; source="https://github.com/JuliaBinaryWrappers/Ccache_jll.jl", rev="main"))
                        prepare([branch_dep])
                        @test !isempty(branch_dep.artifact_paths)
                        @test all(isdir, branch_dep.artifact_paths)
                        @test branch_dep.package.repo.rev == "main"
                        @test !isdir(joinpath(dir, "jll_resolve_cache")) ||
                              isempty(filter(p -> isfile(joinpath(p, "cache.toml")), readdir(joinpath(dir, "jll_resolve_cache"); join=true)))
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

                # The opt-out flag is carried along
                @test !JLLSource("Bzip2_jll", msan).exempt_from_strict_tags
                bzip2_exempt = JLLSource("Bzip2_jll", msan; exempt_from_strict_tags=true, target="sysroot")
                @test bzip2_exempt.exempt_from_strict_tags
                @test retarget(bzip2_exempt, "other").exempt_from_strict_tags

                if !isdefined(Base.BinaryPlatforms, :strict_presence_tags)
                    # This Julia's platform matching would pick uninstrumented artifacts
                    @test strict_tags() == ()
                    @test_throws r"needs a Julia whose platform matching implements strict tags" prepare([JLLSource("Zlib_jll", msan)])
                else
                    @test strict_tags() === Base.BinaryPlatforms.strict_presence_tags
                    @test "sanitize" in strict_tags()
                    @test drop_strict_tags(msan) == plain
                    @test drop_strict_tags(plain) === plain
                    @test haskey(tags(msan), "sanitize")
                    # Exempt and non-exempt requests for the same JLL are kept apart
                    @test length(deduplicate_jlls([JLLSource("Zlib_jll", msan), JLLSource("Zlib_jll", msan; exempt_from_strict_tags=true)])) == 2

                    # `prepare()` refuses a JLL (including transitive dependencies) that only
                    # has an artifact for the platform without its strict tags...
                    @test_throws r"Bzip2_jll has no artifact for x86_64-linux-gnu-sanitize\+memory" prepare([JLLSource("Bzip2_jll", msan)])
                    # (which of LibCURL's dependencies gets reported first varies)
                    @test_throws r"_jll has no artifact for x86_64-linux-gnu-sanitize\+memory" prepare([JLLSource("LibCURL_jll", msan)])
                    # ... but picks the matching artifact where there is one
                    zlib_msan = JLLSource("Zlib_jll", msan)
                    zlib_plain = JLLSource("Zlib_jll", plain)
                    prepare([zlib_msan])
                    prepare([zlib_plain])
                    @test !isempty(zlib_msan.artifact_paths)
                    @test !isempty(zlib_plain.artifact_paths)
                    @test basename.(zlib_msan.artifact_paths) != basename.(zlib_plain.artifact_paths)

                    # Exempt JLLs resolve as if for the platform without strict tags
                    @test resolution_platform(bzip2_exempt) == plain
                    @test resolution_platform(JLLSource("Bzip2_jll", msan)) == msan
                    bzip2_plain = JLLSource("Bzip2_jll", plain)
                    prepare([bzip2_exempt, bzip2_plain])
                    @test !isempty(bzip2_exempt.artifact_paths)
                    @test basename.(bzip2_exempt.artifact_paths) == basename.(bzip2_plain.artifact_paths)
                    # The exemption covers that JLL's own dependencies, but no other JLL
                    curl_exempt = JLLSource("LibCURL_jll", msan; exempt_from_strict_tags=true)
                    prepare([curl_exempt])
                    @test !isempty(curl_exempt.artifact_paths)
                    @test_throws r"Bzip2_jll.*sanitize=memory" prepare([JLLSource("Bzip2_jll", msan; target="other")])
                end
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
            any_hash = spec_hash(zstd_any_dep; registries=jll_registries)
            deduped = deduplicate_jlls([zstd_any_dep, zstd_specific_dep])
            @test length(deduped) == 1
            @test startswith(source(only(deduped)), "Zstd_jll@v")
            # Intersecting the version constraints changes what is requested, and so the
            # hash, of the JLL that replaces `zstd_any_dep`; `zstd_any_dep` itself is untouched.
            @test spec_hash(only(deduped); registries=jll_registries) != any_hash
            @test spec_hash(zstd_any_dep; registries=jll_registries) == any_hash
            @test source(zstd_any_dep) == "Zstd_jll"
            @test startswith(source(zstd_specific_dep), "Zstd_jll@v")

            # Test that disjoint versions throw an error:
            zstd_impossible_dep = JLLSource(
                PackageSpec(;name="Zstd_jll", version=v"0.0.0"),
                HostPlatform(),
            )
            @test_throws ArgumentError deduplicate_jlls([zstd_impossible_dep, zstd_specific_dep])
            @test startswith(source(zstd_specific_dep), "Zstd_jll@v")

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
    function write_registry(dir; versions = Dict{String,Vector{String}}(), mid_deps = ["Leaf_jll"], mid_weak_deps = String[])
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
            weak_deps = name == "Mid_jll" ? mid_weak_deps : String[]
            for (fname, fdeps) in (("Deps.toml", deps), ("WeakDeps.toml", weak_deps))
                isempty(fdeps) && continue
                open(joinpath(pkg_dir, fname); write=true) do io
                    println(io, "[\"1\"]")
                    for dep in fdeps
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

        # Weak dependencies can't pull a package into a resolution, so we don't walk
        # into them: their new versions must not change the slice.  Their compat bounds
        # are part of the entry of the package that declares them, however.
        weak = [make_registry(joinpath(dir, "weak"); mid_weak_deps=["Other_jll"])]
        weak_hash = registry_slice_hash(root, weak)
        @test weak_hash != base_hash
        weak_bumped = [make_registry(joinpath(dir, "weak_bumped");
                                     mid_weak_deps=["Other_jll"],
                                     versions=Dict("Other_jll" => ["1.0.0", "2.0.0"]))]
        @test registry_slice_hash(root, weak_bumped) == weak_hash

        # A package developed by path resolves against the dependencies in its
        # `Project.toml` rather than its own registry entry, so that is what we slice;
        # even when it isn't registered at all.
        project_toml(name, deps) = string(
            "name = \"$(name)\"\nuuid = \"$("0"^8)-0000-0000-0000-$("0"^11)5\"\n[deps]\n",
            join(("$(dep) = \"$(uuids[dep])\"\n" for dep in deps)),
        )
        unreg_dir = mkpath(joinpath(dir, "Unregistered_jll"))
        write(joinpath(unreg_dir, "Project.toml"), project_toml("Unregistered_jll", ["Mid_jll"]))
        unreg = PackageSpec(; name="Unregistered_jll", path=unreg_dir)
        mid = PackageSpec(; name="Mid_jll")
        @test registry_slice_hash(unreg, base) == registry_slice_hash(mid, base)
        @test registry_slice_hash(unreg, unrelated) == registry_slice_hash(unreg, base)
        @test registry_slice_hash(unreg, relevant) != registry_slice_hash(unreg, base)

        # A package added from a git repository slices by name if it is registered, and
        # otherwise leaves the registries out of its hash, rather than hash them wholesale.
        repo_spec(name; rev="main") = PackageSpec(; name, repo=Pkg.Types.GitRepo(; source="https://example.com/$(name).jl", rev))
        @test registry_slice_hash(repo_spec("Root_jll"), base) == base_hash
        @test registry_slice_hash(repo_spec("Unregistered_jll"), base) != full_registries_hash(base)
        @test registry_slice_hash(repo_spec("Unregistered_jll"), unrelated) == registry_slice_hash(repo_spec("Unregistered_jll"), base)

        # A package added from a git repository at a commit resolves against the
        # dependencies of its registered versions rather than its own registry entry: a
        # new registered version of it must not change the slice, but a new version of
        # anything it can depend on must.  One that tracks a branch must still see both.
        pinned = repo_spec("Root_jll"; rev="0"^40)
        @test registry_slice_hash(pinned, base) == registry_slice_hash(mid, base)
        root_bumped = [make_registry(joinpath(dir, "root_bumped"); versions=Dict("Root_jll" => ["1.0.0", "1.1.0"]))]
        @test registry_slice_hash(pinned, root_bumped) == registry_slice_hash(pinned, base)
        @test registry_slice_hash(pinned, unrelated) == registry_slice_hash(pinned, base)
        @test registry_slice_hash(pinned, relevant) != registry_slice_hash(pinned, base)
        @test registry_slice_hash(repo_spec("Root_jll"), root_bumped) != base_hash
        @test registry_slice_hash(root, root_bumped) != base_hash
        pinned_jll = JLLSource(pinned, HostPlatform())
        @test spec_hash(pinned_jll; registries=root_bumped) == spec_hash(pinned_jll; registries=base)
        @test spec_hash(pinned_jll; registries=relevant) != spec_hash(pinned_jll; registries=base)
        branch_jll = JLLSource(repo_spec("Root_jll"), HostPlatform())
        @test spec_hash(branch_jll; registries=root_bumped) != spec_hash(branch_jll; registries=base)
        # An unregistered package pinned to a commit leaves the registries out entirely.
        unreg_pinned = repo_spec("Unregistered_jll"; rev="0"^40)
        @test registry_slice_hash(unreg_pinned, base) == registry_slice_hash(repo_spec("Unregistered_jll"), base)
        @test registry_slice_hash(unreg_pinned, relevant) == registry_slice_hash(unreg_pinned, base)

        # Anything other than a full commit hash counts as tracking a branch.
        @test tracks_branch(repo_spec("Root_jll"))
        @test tracks_branch(repo_spec("Root_jll"; rev=nothing))
        @test tracks_branch(repo_spec("Root_jll"; rev="v1.0.0"))
        @test !tracks_branch(repo_spec("Root_jll"; rev="0"^40))
        @test !tracks_branch(root)
    end
end

@testset "Download headers" begin
    using BinaryBuilderSources: download_headers
    using BinaryBuilderGitUtils: access_tokens, set_access_tokens!
    asset_url = "https://api.github.com/repos/JuliaPackaging/Yggdrasil/releases/assets/12345"
    old_tokens = access_tokens[]
    try
        set_access_tokens!(Dict{String,Any}())
        # Ordinary URLs get no special headers
        @test isempty(download_headers("https://github.com/JuliaPackaging/Yggdrasil/releases/download/v1/foo.tar.gz"))
        @test isempty(download_headers("https://api.github.com/repos/JuliaPackaging/Yggdrasil/releases/12345"))
        @test isempty(download_headers(asset_url * "/foo"))
        # A release asset by its API URL asks for the asset's content, even without a token
        @test download_headers(asset_url) == ["Accept" => "application/octet-stream"]
        # Tokens from the environment are not used
        withenv("GITHUB_TOKEN" => "github_token", "GH_TOKEN" => "gh_token") do
            @test download_headers(asset_url) == ["Accept" => "application/octet-stream"]
        end

        set_access_tokens!(Dict("github.com" => Dict("JuliaPackaging" => Dict("Yggdrasil" => "ygg_token"))))
        auth = "Authorization" => "Bearer ygg_token"
        @test download_headers(asset_url) == ["Accept" => "application/octet-stream", auth]
        @test download_headers("https://github.com/JuliaPackaging/Yggdrasil/releases/download/v1/foo.tar.gz") == [auth]
        # The token is never sent anywhere else
        @test download_headers("https://api.github.com/repos/JuliaPackaging/BinaryBuilder.jl/releases/assets/1") == ["Accept" => "application/octet-stream"]
        @test isempty(download_headers("https://example.com/repos/JuliaPackaging/Yggdrasil/releases/assets/1"))
    finally
        access_tokens[] = old_tokens
    end
end

@testset "make_thin_depot!" begin
    using BinaryBuilderSources: make_thin_depot!
    mktempdir() do dir
        # A parent depot that has none of the shared stores yet
        parent = joinpath(dir, "parent")
        thin = joinpath(dir, "thin")
        make_thin_depot!(thin, parent)
        for store_name in ("artifacts", "packages", "compiled", "logs")
            store_path = joinpath(thin, store_name)
            @test islink(store_path)
            @test readlink(store_path) == joinpath(parent, store_name)
            # The link must not dangle, so things can be created through it
            @test isdir(store_path)
            mkpath(joinpath(store_path, "Foo", "abcd"))
            @test isdir(joinpath(parent, store_name, "Foo", "abcd"))
        end

        # Calling it again (with the links already in place) is a no-op
        make_thin_depot!(thin, parent)
        @test isdir(joinpath(thin, "packages", "Foo", "abcd"))
    end
end

@testset "Network retries" begin
    using BinaryBuilderSources: network_retry_delays, with_network_retries, is_transient_network_error

    # Serve `body` over HTTP on localhost, misbehaving on the first requests as dictated
    # by `failures` (one entry per request; `:drop` closes the connection without an answer,
    # `:truncate` sends only half of the promised body, and an integer answers with that
    # HTTP status).  Once `failures` runs out, every request is served properly, unless
    # `fallback` gives a failure to repeat forever.  `f(url, num_requests)` is called with
    # the URL to fetch and a `Ref` counting the requests made so far.
    function with_flaky_server(f, body::Vector{UInt8}, failures::Vector; fallback = nothing)
        port, server = listenany(ip"127.0.0.1", 0)
        num_requests = Ref(0)
        server_task = @async while true
            sock = try
                accept(server)
            catch
                break
            end
            try
                while !isempty(strip(readline(sock)))
                end
                num_requests[] += 1
                behavior = num_requests[] <= length(failures) ? failures[num_requests[]] : fallback
                if behavior === :drop
                elseif behavior === :truncate
                    write(sock, "HTTP/1.1 200 OK\r\nContent-Length: $(length(body))\r\nConnection: close\r\n\r\n")
                    write(sock, body[1:div(length(body), 2)])
                elseif behavior isa Integer
                    write(sock, "HTTP/1.1 $(behavior) Nope\r\nContent-Length: 0\r\nConnection: close\r\n\r\n")
                else
                    write(sock, "HTTP/1.1 200 OK\r\nContent-Length: $(length(body))\r\nConnection: close\r\n\r\n")
                    write(sock, body)
                end
            catch e
                e isa Base.IOError || rethrow()
            finally
                close(sock)
            end
        end
        try
            f("http://127.0.0.1:$(port)/payload.bin", num_requests)
        finally
            close(server)
            wait(server_task)
        end
    end

    # Files in the download cache directory other than the final download, its
    # hash cache file and its lock, i.e. leftovers from failed attempts.
    function stray_files(download_path)
        dir = dirname(download_path)
        isdir(dir) || return String[]
        return filter(readdir(dir)) do name
            !startswith(name, basename(download_path))
        end
    end

    body = rand(UInt8, 64*1024)
    body_hash = bytes2hex(sha256(body))
    old_delays = network_retry_delays[]
    try
        network_retry_delays[] = [0.0, 0.0, 0.0]
        with_temp_storage_locations() do
            @testset "transient failures are retried" begin
                with_flaky_server(body, [:drop, 503, :truncate]) do url, num_requests
                    fs = FileSource(url, body_hash)
                    download_path = download_cache_path(fs)
                    @test_logs (:warn, r"attempt 1/4") (:warn, r"attempt 2/4") (:warn, r"attempt 3/4") prepare(fs)
                    @test num_requests[] == 4
                    @test verify(fs)
                    @test read(download_path) == body
                    @test isempty(stray_files(download_path))
                end
            end

            @testset "exhausted retries" begin
                with_flaky_server(body, []; fallback=503) do url, num_requests
                    fs = FileSource(url, body_hash)
                    download_path = download_cache_path(fs)
                    @test_throws Downloads.RequestError prepare(fs)
                    @test num_requests[] == 4
                    @test !ispath(download_path)
                    @test isempty(stray_files(download_path))
                end
                with_flaky_server(body, []; fallback=:truncate) do url, num_requests
                    fs = FileSource(url, body_hash)
                    download_path = download_cache_path(fs)
                    @test_throws Downloads.RequestError prepare(fs)
                    @test num_requests[] == 4
                    @test !ispath(download_path)
                    @test isempty(stray_files(download_path))
                end
            end

            @testset "permanent failures are not retried" begin
                with_flaky_server(body, []; fallback=404) do url, num_requests
                    fs = FileSource(url, body_hash)
                    download_path = download_cache_path(fs)
                    @test_throws Downloads.RequestError prepare(fs)
                    @test num_requests[] == 1
                    @test !ispath(download_path)
                end

                # A hash mismatch is not a network problem, so it is not retried either
                with_flaky_server(body, []) do url, num_requests
                    fs = FileSource(url, bytes2hex(sha256(UInt8[])))
                    @test_throws ArgumentError prepare(fs)
                    @test num_requests[] == 1
                end
            end

            @testset "mirrors" begin
                # A mirror that doesn't have the file is skipped for the next one
                with_flaky_server(body, []; fallback=404) do bad_url, bad_requests
                    with_flaky_server(body, []) do good_url, good_requests
                        fs = FileSource([bad_url, good_url], body_hash)
                        @test_logs (:warn, r"trying the next URL") prepare(fs)
                        @test bad_requests[] == 1
                        @test good_requests[] == 1
                        @test read(download_cache_path(fs)) == body
                    end
                end

                # So is a mirror serving the wrong file, which never reaches the cache
                with_flaky_server(reverse(body), []) do bad_url, bad_requests
                    with_flaky_server(body, []) do good_url, good_requests
                        fs = FileSource([bad_url, good_url], body_hash)
                        @test_logs (:warn, r"trying the next URL") prepare(fs)
                        @test bad_requests[] == 1
                        @test good_requests[] == 1
                        @test read(download_cache_path(fs)) == body
                        @test isempty(stray_files(download_cache_path(fs)))
                    end
                end

                # Each URL gets its own retries before the next one is tried
                with_flaky_server(body, [503, 503]) do flaky_url, flaky_requests
                    with_flaky_server(body, []) do other_url, other_requests
                        fs = FileSource([flaky_url, other_url], body_hash)
                        prepare(fs)
                        @test flaky_requests[] == 3
                        @test other_requests[] == 0
                        @test read(download_cache_path(fs)) == body
                    end
                end

                # A URL that runs out of retries falls through to the next one, which gets
                # a full set of retries of its own
                with_flaky_server(body, []; fallback=503) do down_url, down_requests
                    with_flaky_server(body, [:drop, :drop, :drop]) do flaky_url, flaky_requests
                        fs = FileSource([down_url, flaky_url], body_hash)
                        @test_logs (:warn, r"trying the next URL") match_mode=:any prepare(fs)
                        @test down_requests[] == 4
                        @test flaky_requests[] == 4
                        @test read(download_cache_path(fs)) == body
                    end
                end

                # Once every URL has failed, the error lists each URL's failure
                with_flaky_server(body, []; fallback=503) do flaky_url, flaky_requests
                    with_flaky_server(body, []; fallback=404) do missing_url, missing_requests
                        fs = FileSource([flaky_url, missing_url], body_hash)
                        err = try
                            prepare(fs)
                            nothing
                        catch e
                            e
                        end
                        @test err isa BinaryBuilderSources.MirrorsFailedError
                        @test first.(err.errors) == [flaky_url, missing_url]
                        @test flaky_requests[] == 4
                        @test missing_requests[] == 1
                        @test !ispath(download_cache_path(fs))
                        @test occursin("all 2 URLs failed", sprint(showerror, err))
                    end
                end

                # Mirrors don't change where a source is cached, what it is called, or its hash
                as = ArchiveSource("https://example.com/a.tar.gz", body_hash)
                as_mirrored = ArchiveSource(["https://example.com/a.tar.gz", "https://mirror.example.com/a.tar.gz"], body_hash)
                @test as_mirrored.urls == ["https://example.com/a.tar.gz", "https://mirror.example.com/a.tar.gz"]
                @test download_cache_path(as_mirrored) == download_cache_path(as)
                @test source(as_mirrored) == source(as)
                @test spec_hash(as_mirrored) == spec_hash(as)
                @test retarget(as_mirrored, "foo").urls == as_mirrored.urls
                @test FileSource(["https://example.com/a.tar.gz", "https://mirror.example.com/b.tar.gz"], body_hash).target == "a.tar.gz"
                @test_throws ArgumentError FileSource(String[], body_hash)
            end

            @testset "GitSource mirrors" begin
                # A bare repository holding the commits of `base_repo` (if any) plus one
                # more, which writes `content` to a file.  Returns the repository and the
                # new commit.
                function make_repo(path, content; base_repo = nothing)
                    if base_repo === nothing
                        init!(path)
                    else
                        run(git(["clone", "--quiet", "--bare", base_repo, path]))
                    end
                    mktempdir() do checkout
                        run(git(["clone", "--quiet", path, checkout]))
                        write(joinpath(checkout, "file"), content)
                        commit!(checkout, content)
                        push!(checkout)
                    end
                    return path, readchomp(git(["-C", path, "rev-parse", "HEAD"]))
                end

                mktempdir() do dir
                    upstream, old_commit = make_repo(joinpath(dir, "upstream.git"), "old")
                    mirror, new_commit = make_repo(joinpath(dir, "mirror.git"), "new"; base_repo=upstream)
                    missing_repo = joinpath(dir, "missing.git")

                    # The primary URL doesn't have the commit yet, but the mirror does
                    gs = GitSource([upstream, mirror], new_commit)
                    @test gs.urls == [upstream, mirror]
                    @test gs.target == "upstream"
                    @test source(gs) == upstream
                    @test download_cache_path(gs) == download_cache_path(GitSource(upstream, new_commit))
                    @test_logs (:warn, r"trying the next URL") match_mode=:any prepare(gs)
                    @test verify(gs)
                    repo_path = download_cache_path(gs)
                    @test remote_url(repo_path, remote_name(upstream)) == upstream
                    @test remote_url(repo_path, remote_name(mirror)) == mirror
                    @test readchomp(git(["-C", repo_path, "symbolic-ref", "HEAD"])) == "refs/heads/main"
                    mktempdir() do prefix
                        deploy(gs, prefix)
                        @test read(joinpath(prefix, "upstream", "file"), String) == "new"
                    end

                    # Fetching the other URL again does not lose what came from the mirror
                    gs_old = GitSource([upstream, mirror], old_commit)
                    @test verify(gs_old)
                    run(git(["-C", repo_path, "fetch", "--quiet", remote_name(upstream)]))
                    @test verify(gs)

                    # A first URL that doesn't exist at all: the clone is created from the mirror
                    gs = GitSource([missing_repo, mirror], new_commit)
                    @test_logs (:warn, r"trying the next URL") match_mode=:any prepare(gs)
                    @test verify(gs)
                    @test remote_url(download_cache_path(gs), remote_name(mirror)) == mirror
                    # Its `HEAD` is the mirror's default branch, so clones of it check that out
                    @test readchomp(git(["-C", download_cache_path(gs), "symbolic-ref", "HEAD"])) == "refs/heads/main"
                    @test readchomp(git(["-C", download_cache_path(gs), "rev-parse", "HEAD"])) == new_commit
                    mktempdir() do prefix
                        deploy(gs, prefix)
                        @test read(joinpath(prefix, "missing", "file"), String) == "new"
                    end

                    # No URL has the commit: the error lists each URL's failure
                    gs = GitSource([upstream, mirror], "0"^40)
                    err = try
                        prepare(gs)
                        nothing
                    catch e
                        e
                    end
                    @test err isa BinaryBuilderSources.MirrorsFailedError
                    @test first.(err.errors) == [upstream, mirror]
                    @test all(e isa ArgumentError for (_, e) in err.errors)

                    # A single URL without the commit throws as before
                    other = joinpath(dir, "other.git")
                    run(git(["clone", "--quiet", "--bare", upstream, other]))
                    @test_throws ArgumentError prepare(GitSource(other, new_commit))

                    @test retarget(GitSource([upstream, mirror], new_commit), "foo").urls == [upstream, mirror]
                    @test_throws ArgumentError GitSource(String[], new_commit)
                end
            end

            @testset "GitSource" begin
                mktempdir() do dir
                    url = joinpath(dir, "nonexistent.git")
                    gs = GitSource(url, "0"^40)
                    @test_logs (:warn, r"attempt 1/4") (:warn, r"attempt 2/4") (:warn, r"attempt 3/4") match_mode=:any begin
                        @test_throws ProcessFailedException prepare(gs)
                    end
                    @test !ispath(download_cache_path(gs))
                end
            end
        end

        @testset "with_network_retries" begin
            # Explicit delays override the default
            attempts = Ref(0)
            @test_throws Base.IOError with_network_retries("thing"; delays=[0.0]) do
                attempts[] += 1
                throw(Base.IOError("nope", -1))
            end
            @test attempts[] == 2

            attempts[] = 0
            @test with_network_retries("thing") do
                attempts[] += 1
                attempts[] < 3 && throw(Base.IOError("nope", -1))
                return :done
            end == :done
            @test attempts[] == 3

            attempts[] = 0
            @test_throws ErrorException with_network_retries("thing") do
                attempts[] += 1
                error("not a network problem")
            end
            @test attempts[] == 1

            response(status) = Downloads.Response("http", "http://x", status, "", Pair{String,String}[])
            @test is_transient_network_error(Downloads.RequestError("http://x", 28, "Operation too slow", response(0)))
            @test is_transient_network_error(Downloads.RequestError("http://x", 0, "", response(503)))
            @test is_transient_network_error(Downloads.RequestError("http://x", 0, "", response(429)))
            @test !is_transient_network_error(Downloads.RequestError("http://x", 0, "", response(404)))
            @test !is_transient_network_error(Downloads.RequestError("http://x", 3, "URL using bad/illegal format", response(0)))
            @test !is_transient_network_error(ArgumentError("Hash Mismatch"))
        end
    finally
        network_retry_delays[] = old_delays
    end
end
