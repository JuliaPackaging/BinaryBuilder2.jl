using Test, BB2, SHA

if !isdefined(Main, :TestingUtils)
    include("TestingUtils.jl")
end

using BB2: verify, prepare, deploy, download_cache_path, source_download_cache
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
        end

        url = "https://github.com/ralna/ARCHDefs.git"
        hash = "fc8c5960c3a6d26970ab245241cfc067fe4ecfdd"
        prev_hash = "dab23a5df2e33495c8d843920cc267c0c5051fe8"
        @testset "GitSource" begin
            # Construction works
            gs = GitSource(url, hash)
            @test gs.url == url
            @test gs.hash == hex2bytes(hash)
            @test gs.target == basename(url)

            # Nothing is on disk yet
            clone_path = download_cache_path(gs)
            @test !isfile(clone_path)
            @test !verify(gs)
            @test_throws InvalidStateException deploy(gs, @__DIR__)

            # Download succeeds
            prepare(gs)
            @test isdir(clone_path)
            @test verify(gs)

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
        end

        @testset "DirectorySource" begin
            mktempdir() do build_dir; cd(build_dir) do
                # Generate a directory to use as our source
                mkdir("src")
                open(joinpath("src", "foo"); write=true) do io
                    println(io, "I am foo!")
                end
                symlink("foo", joinpath("src", "link_to_foo"))

                ds = DirectorySource("src")
                @test ds.source == abspath("src")
                @test ds.target == ""
                @test ds.follow_symlinks == false

                # Test that this can be run, even though they don't do anything
                prepare(ds)

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
            end; end
        end
        @testset "JLLSource" begin
            bzip2_dep = JLLSource("Bzip2_jll", HostPlatform())
            zstd_dep = JLLSource("Zstd_jll", HostPlatform())
            @test bzip2_dep.package.name == "Bzip2_jll"
            @test zstd_dep.package.name == "Zstd_jll"
            @test bzip2_dep.subprefix == ""
            @test zstd_dep.subprefix == ""
            @test isempty(bzip2_dep.artifact_paths)
            @test isempty(zstd_dep.artifact_paths)

            # Download the files, check that they have artifact paths now:
            prepare([bzip2_dep, zstd_dep])
            @test !isempty(bzip2_dep.artifact_paths)
            @test !isempty(zstd_dep.artifact_paths)
            depot_artifacts_dir = joinpath(source_download_cache(), "jllsource_depot", "artifacts")
            @test all(startswith.(bzip2_dep.artifact_paths, Ref(depot_artifacts_dir)))
            @test all(startswith.(zstd_dep.artifact_paths, Ref(depot_artifacts_dir)))

            mktempdir() do prefix
                deploy([bzip2_dep, zstd_dep], prefix)
                @test isfile(joinpath(prefix, "bin", "zstd$(exext)"))
                @test isfile(joinpath(prefix, binlib, "libbz2$(soext)"))
            end

            # Test that subprefix works
            ccache_dep = JLLSource("Ccache_jll", HostPlatform(); subprefix="ext")
            @test ccache_dep.subprefix == "ext"
            prepare([ccache_dep])
            mktempdir() do prefix
                deploy([bzip2_dep, ccache_dep], prefix)
                # Ccache depends on zstd_jll, and that also gets installed in `ext`
                @test isfile(joinpath(prefix, "ext", "bin", "ccache$(exext)"))
                @test isfile(joinpath(prefix, "ext", "bin", "zstd$(exext)"))

                # bzip2 is still installed to the correct spot:
                @test isfile(joinpath(prefix, binlib, "libbz2$(soext)"))
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
        end
    end
end
