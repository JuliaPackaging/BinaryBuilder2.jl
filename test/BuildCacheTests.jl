using Test, BinaryBuilder2, SHA, MultiHashParsing, BinaryBuilderAuditor.Patchelf_jll
using BinaryBuilder2: load_cache, save_cache, prune!

@testset "BuildCache" begin
    mktempdir() do cache_dir
        bc = BuildCache(; cache_dir)

        build1_hash = SHA1Hash(sha1("build1"))
        build2_hash = SHA1Hash(sha1("build2"))
        extract1_hash = SHA1Hash(sha1("extract1"))
        extract2_hash = SHA1Hash(sha1("extract2"))
        artifact1_hash = SHA1Hash(sha1("artifact1"))
        artifact2_hash = SHA1Hash(sha1("artifact2"))
        put!(bc, build1_hash, extract1_hash, artifact1_hash, "1", Dict("1" => "1"))
        put!(bc, build2_hash, extract2_hash, artifact2_hash, "2", Dict("2" => "2"))

        function probe_buildcache(bc)
            @test haskey(bc, build1_hash, extract1_hash)
            @test get(bc, build1_hash, extract1_hash) == (artifact1_hash, "1", Dict("1" => "1"))
            @test haskey(bc, build2_hash, extract2_hash)
            @test get(bc, build2_hash, extract2_hash) == (artifact2_hash, "2", Dict("2" => "2"))
            @test !haskey(bc, build1_hash, extract2_hash)
            @test !haskey(bc, build2_hash, extract1_hash)
        end
        probe_buildcache(bc)

        # Test load/save
        patchelf_artifact_hash = SHA1Hash(basename(dirname(dirname(Patchelf_jll.patchelf_path))))
        patchelf_build_hash = SHA1Hash(sha1("patchelf_build"))
        patchelf_extract_hash = SHA1Hash(sha1("patchelf_extract"))
        put!(bc, patchelf_build_hash, patchelf_extract_hash, patchelf_artifact_hash, "3", Dict("3" => "3"))
        save_cache(bc)
        @test isfile(joinpath(cache_dir, "build_cache.db"))
        bc2 = load_cache(cache_dir)
        probe_buildcache(bc2)

        # Test prune!() gets rid of any mappings that do not have an actual artifact on-disk
        prune!(bc2)
        @test !haskey(bc2, build1_hash, extract1_hash)
        @test !haskey(bc2, build2_hash, extract2_hash)
        @test !haskey(bc2, build1_hash, extract2_hash)
        @test !haskey(bc2, build2_hash, extract1_hash)
        @test get(bc2, patchelf_build_hash, patchelf_extract_hash) == (patchelf_artifact_hash, "3", Dict("3" => "3"))
    end
end
