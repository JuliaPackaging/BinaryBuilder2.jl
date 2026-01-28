using Test, BinaryBuilder2, SHA, MultiHashParsing, Patchelf_jll
using BinaryBuilder2: load_cache, save_cache, prune!
using BinaryBuilder2: BuildCacheBuildEntry, BuildCacheExtractEntry
using JLLGenerator

@testset "BuildCache" begin
    mktempdir() do cache_dir
        # It's not normal to store the artifacts alongside the cache database,
        # but for testing it's fine so we don't have to make more tempdirs.
        bc = BuildCache(; cache_dir, artifacts_dir=cache_dir)

        function make_hashdir(name)
            hash = SHA1Hash(sha1(name))
            mkpath(joinpath(cache_dir, bytes2hex(hash)))
            return hash
        end

        build1_hash = SHA1Hash(sha1("build1"))
        build2_hash = SHA1Hash(sha1("build2"))
        extract1_hash = SHA1Hash(sha1("extract1"))
        extract2_hash = SHA1Hash(sha1("extract2"))
        artifact1_hash = make_hashdir("artifact1")
        artifact2_hash = make_hashdir("artifact2")
        build_log1_hash = make_hashdir("build_log1")
        build_log2_hash = make_hashdir("build_log2")
        extract_log1_hash = make_hashdir("extract_log1")
        extract_log2_hash = make_hashdir("extract_log2")
        build_env1 = Dict("1" => "1")
        build_env2 = Dict("2" => "2")
        extract1_jlp = [JLLLibraryProduct(:libfoo, "lib/libfoo.1.dylib", [], flags = [:RTLD_LAZY, :RTLD_DEEPBIND])]
        extract2_jlp = [JLLLibraryProduct(:libfoo, "lib/libfoo.2.dylib", [], flags = [:RTLD_LAZY, :RTLD_DEEPBIND])]

        put!(bc, build1_hash, extract1_hash, build_log1_hash, build_env1, artifact1_hash, extract_log1_hash, extract1_jlp )
        put!(bc, build2_hash, extract2_hash, build_log2_hash, build_env2, artifact2_hash, extract_log2_hash, extract2_jlp)

        function probe_buildcache(bc)
            @test haskey(bc, build1_hash, extract1_hash)
            b1, e1 = get(bc, build1_hash, extract1_hash)
            @test b1.log_artifact == build_log1_hash
            @test b1.env == build_env1
            @test e1.artifact == artifact1_hash
            @test e1.log_artifact == extract_log1_hash
            @test e1.jll_lib_products == extract1_jlp

            @test haskey(bc, build2_hash, extract2_hash)
            b2, e2 = get(bc, build2_hash, extract2_hash)
            @test b2.log_artifact == build_log2_hash
            @test b2.env == build_env2
            @test e2.artifact == artifact2_hash
            @test e2.log_artifact == extract_log2_hash
            @test e2.jll_lib_products == extract2_jlp
        end
        probe_buildcache(bc)

        # Test load/save
        patchelf_artifact_hash = SHA1Hash(basename(dirname(dirname(Patchelf_jll.patchelf_path))))
        patchelf_build_hash = SHA1Hash(sha1("patchelf_build"))
        patchelf_extract_hash = SHA1Hash(sha1("patchelf_extract"))
        patchelf_build_entry = BuildCacheBuildEntry(
            SHA1Hash(sha1("patchelf_build_log")),
            Dict("foo" => "bar"),
        )
        patchelf_extract_entry = BuildCacheExtractEntry(
            patchelf_artifact_hash,
            SHA1Hash(sha1("patchelf_extract_log")),
            JLLLibraryProduct[],
        )
        put!(bc, patchelf_build_hash, patchelf_extract_hash, patchelf_build_entry, patchelf_extract_entry)
        save_cache(bc)
        @test isfile(joinpath(cache_dir, "build_entries.db"))
        @test isfile(joinpath(cache_dir, "extract_entries.db"))

        bc2 = load_cache(cache_dir)
        probe_buildcache(bc2)

        # Test prune!() gets rid of any mappings that do not have an actual artifact on-disk
        # These artifacts don't actually exist, so we create a fake depot that contains only those
        # artifacts so that the "patchelf" cache entry doesn't get pruned.
        mkpath(joinpath(cache_dir, bytes2hex(patchelf_build_entry.log_artifact)))
        mkpath(joinpath(cache_dir, bytes2hex(patchelf_extract_entry.log_artifact)))
        mkpath(joinpath(cache_dir, bytes2hex(patchelf_extract_entry.artifact)))
        rm(joinpath(cache_dir, bytes2hex(artifact1_hash)); recursive=true)
        rm(joinpath(cache_dir, bytes2hex(artifact2_hash)); recursive=true)

        prune!(bc2)
        @test !haskey(bc2, build1_hash, extract1_hash)
        @test !haskey(bc2, build2_hash, extract2_hash)
        @test !haskey(bc2, build1_hash, extract2_hash)
        @test !haskey(bc2, build2_hash, extract1_hash)
        @test get(bc2, patchelf_build_hash, patchelf_extract_hash) == (patchelf_build_entry, patchelf_extract_entry)
    end
end
