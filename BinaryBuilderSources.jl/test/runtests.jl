using Test, BinaryBuilderSources, SHA, Base.BinaryPlatforms
using BinaryBuilderSources: verify, download_cache_path, source_download_cache

function with_temp_storage_locations(f::Function)
    old_source_download_cache = source_download_cache()
    try
        source_download_cache(mktempdir())
        f()
    finally
        source_download_cache(old_source_download_cache)
    end
end

# Set a file to have a particular timestamp
# X-ref: https://discourse.julialang.org/t/how-to-adjust-file-modification-times/52337/3?u=staticfloat
function setmtime(path::AbstractString, mtime::Real, atime::Real=mtime)
    req = Libc.malloc(Base._sizeof_uv_fs)
    try
        ret = ccall(:uv_fs_utime, Cint,
            (Ptr{Cvoid}, Ptr{Cvoid}, Cstring, Cdouble, Cdouble, Ptr{Cvoid}),
            C_NULL, req, path, atime, mtime, C_NULL)
        ccall(:uv_fs_req_cleanup, Cvoid, (Ptr{Cvoid},), req)
        ret < 0 && Base.uv_error("utime($(repr(path)))", ret)
    finally
        Libc.free(req)
    end
end

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
            end; end
        end

        @testset "GeneratedSource" begin
            mktempdir() do build_dir; cd(build_dir) do
                function generate_dir(dir)
                    open(joinpath(dir, "foo"); write=true) do io
                        println(io, "I am foo!")
                    end
                    symlink("foo", joinpath(dir, "link_to_foo"))
                end
                gs = GeneratedSource(generate_dir)
                @test gs.ds.target == ""
                @test gs.ds.follow_symlinks == false

                # Run the generation
                prepare(gs)

                @test isfile(joinpath(gs.ds.source, "foo"))
                @test islink(joinpath(gs.ds.source, "link_to_foo"))
                @test content_hash(gs) == "74d740b14685c131d2b0caa431be3557d51eaa53"

                # Deploy works
                mktempdir() do prefix
                    deploy(gs, prefix)
                    @test isfile(joinpath(prefix, "foo"))
                    @test islink(joinpath(prefix, "link_to_foo"))
                end

                # target works:
                gs = GeneratedSource(generate_dir; target="bar/baz")
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
            depot_artifacts_dir = joinpath(source_download_cache(), "jllsource_depot", "artifacts")
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

            # retarget works
            bzip2_dep = retarget(bzip2_dep, "baz")
            @test bzip2_dep.target == "baz"
            @test_throws ArgumentError retarget(bzip2_dep, "/foo/bar")
        end
    end
end
