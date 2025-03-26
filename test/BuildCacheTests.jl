using Test, BinaryBuilder2, SHA, MultiHashParsing, Patchelf_jll
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
        build_log1_hash = SHA1Hash(sha1("build_log1"))
        build_log2_hash = SHA1Hash(sha1("build_log2"))
        extract_log1_hash = SHA1Hash(sha1("extract_log1"))
        extract_log2_hash = SHA1Hash(sha1("extract_log2"))
        put!(bc, build1_hash, extract1_hash, artifact1_hash, build_log1_hash, extract_log1_hash, Dict("1" => "1"))
        put!(bc, build2_hash, extract2_hash, artifact2_hash, build_log2_hash, extract_log2_hash, Dict("2" => "2"))

        function probe_buildcache(bc)
            @test haskey(bc, build1_hash, extract1_hash)
            @test get(bc, build1_hash, extract1_hash) == (artifact1_hash, build_log1_hash, extract_log1_hash, Dict("1" => "1"))
            @test haskey(bc, build2_hash, extract2_hash)
            @test get(bc, build2_hash, extract2_hash) == (artifact2_hash, build_log2_hash, extract_log2_hash, Dict("2" => "2"))
            @test !haskey(bc, build1_hash, extract2_hash)
            @test !haskey(bc, build2_hash, extract1_hash)
        end
        probe_buildcache(bc)

        # Test load/save
        patchelf_artifact_hash = SHA1Hash(basename(dirname(dirname(Patchelf_jll.patchelf_path))))
        patchelf_build_hash = SHA1Hash(sha1("patchelf_build"))
        patchelf_extract_hash = SHA1Hash(sha1("patchelf_extract"))
        patchelf_build_log_hash = SHA1Hash(sha1("patchelf_build_log"))
        patchelf_extract_log_hash = SHA1Hash(sha1("patchelf_extract_log"))
        put!(bc, patchelf_build_hash, patchelf_extract_hash, patchelf_artifact_hash, patchelf_build_log_hash, patchelf_extract_log_hash, Dict("3" => "3"))
        save_cache(bc)
        @test isfile(joinpath(cache_dir, "extractions_cache.db"))
        @test isfile(joinpath(cache_dir, "extract_log_cache.db"))
        @test isfile(joinpath(cache_dir, "build_log_cache.db"))
        bc2 = load_cache(cache_dir)
        probe_buildcache(bc2)

        # Test prune!() gets rid of any mappings that do not have an actual artifact on-disk
        mktempdir() do extra_depot
            # These artifacts don't actually exist, so we create a fake depot that contains only those
            # artifacts so that the "patchelf" cache entry doesn't get pruned.
            mkpath(joinpath(extra_depot, "artifacts", bytes2hex(patchelf_build_log_hash)))
            mkpath(joinpath(extra_depot, "artifacts", bytes2hex(patchelf_extract_log_hash)))

            prune!(bc2, vcat(Base.DEPOT_PATH, [extra_depot]))
            @test !haskey(bc2, build1_hash, extract1_hash)
            @test !haskey(bc2, build2_hash, extract2_hash)
            @test !haskey(bc2, build1_hash, extract2_hash)
            @test !haskey(bc2, build2_hash, extract1_hash)
            @test get(bc2, patchelf_build_hash, patchelf_extract_hash) == (patchelf_artifact_hash, patchelf_build_log_hash, patchelf_extract_log_hash, Dict("3" => "3"))
        end
    end
end
