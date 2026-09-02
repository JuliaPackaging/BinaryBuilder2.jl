using Test, Pkg, BinaryBuilder2, SHA, MultiHashParsing, Patchelf_jll
using BinaryBuilder2: load_cache, save_cache, prune!, export_archive, import_archives
using BinaryBuilder2: load_build_entries!, load_extract_entries!
using BinaryBuilder2: BuildCacheBuildEntry, BuildCacheExtractEntry, Universe
using JLLGenerator

@testset "BuildCache" begin
    archive_dir = mktempdir()
    mktempdir() do cache_dir
        # It's not normal to store the artifacts alongside the cache database,
        # but for testing it's fine so we don't have to make more tempdirs.
        bc = BuildCache(; cache_dir, artifacts_dir=cache_dir)

        function make_hashdir(name)
            hash = Pkg.Artifacts.with_artifacts_directory(cache_dir) do
                Pkg.Artifacts.create_artifact() do artifact_dir
                    open(joinpath(artifact_dir, name); write=true) do io
                        println(io, name)
                    end
                end
            end
            return SHA1Hash(hash)
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
        extract1_jlp = [JLLLibraryProduct(:libfoo, "lib/libfoo.1.dylib", [], [], flags = [:RTLD_LAZY, :RTLD_DEEPBIND])]
        extract2_jlp = AbstractJLLProduct[
            JLLLibraryProduct(:libfoo, "lib/libfoo.2.dylib", [], [], flags = [:RTLD_LAZY, :RTLD_DEEPBIND]),
            JLLStaticLibraryProduct(:libfoo_a, "lib/libfoo.a"; system_deps = ["m"], roots = ["init"]),
        ]

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
            # Include a static archive entry so that `load_cache()` exercises the
            # linkage-dispatched deserialization of `jll_lib_products`.
            AbstractJLLProduct[JLLStaticLibraryProduct(:libpatchelf_a, "lib/libpatchelf.a"; system_deps = ["c"])],
        )
        put!(bc, patchelf_build_hash, patchelf_extract_hash, patchelf_build_entry, patchelf_extract_entry)
        save_cache(bc)
        @test isfile(joinpath(cache_dir, "build_entries.db"))
        @test isfile(joinpath(cache_dir, "extract_entries.db"))

        # Also export buildcache entries:
        export_archive(bc, build1_hash, extract1_hash, archive_dir)
        export_archive(bc, build2_hash, extract2_hash, archive_dir)

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

        # Wipe out our cache_dir, create an empty bc3, then import from the archive directory
        for file in readdir(cache_dir; join=true)
            rm(file; force=true, recursive=true)
        end
        bc3 = BuildCache(; cache_dir, artifacts_dir=cache_dir)

        import_archives(bc3, archive_dir)
        probe_buildcache(bc3)
    end
end

@testset "load_build_entries!" begin
    using BinaryBuilder2: serialize_env_block

    mktempdir() do cache_dir
        mkpath(joinpath(cache_dir, "envs"))

        h1 = SHA1Hash(sha1("build1"))
        h2 = SHA1Hash(sha1("build2"))
        log1 = SHA1Hash(sha1("log1"))
        log2 = SHA1Hash(sha1("log2"))
        env1 = Dict("A" => "1", "B" => "2")
        env2 = Dict("X" => "y")

        # Write env files
        write(joinpath(cache_dir, "envs", "$(bytes2hex(h1)).env"), serialize_env_block(env1))
        write(joinpath(cache_dir, "envs", "$(bytes2hex(h2)).env"), serialize_env_block(env2))

        # Write a valid build_entries.db
        db = joinpath(cache_dir, "build_entries.db")
        write(db, "$(bytes2hex(h1)) $(bytes2hex(log1))\n$(bytes2hex(h2)) $(bytes2hex(log2))\n")

        entries = Dict{SHA1Hash,BuildCacheBuildEntry}()
        load_build_entries!(entries, cache_dir)
        @test length(entries) == 2
        @test entries[h1] == BuildCacheBuildEntry(log1, env1)
        @test entries[h2] == BuildCacheBuildEntry(log2, env2)

        # Missing .env file → entry skipped
        rm(joinpath(cache_dir, "envs", "$(bytes2hex(h2)).env"))
        entries2 = Dict{SHA1Hash,BuildCacheBuildEntry}()
        load_build_entries!(entries2, cache_dir)
        @test haskey(entries2, h1)
        @test !haskey(entries2, h2)

        # Malformed hash line → entry skipped
        write(db, "$(bytes2hex(h1)) $(bytes2hex(log1))\nnotahash notahash\n")
        write(joinpath(cache_dir, "envs", "$(bytes2hex(h2)).env"), serialize_env_block(env2))
        entries3 = Dict{SHA1Hash,BuildCacheBuildEntry}()
        load_build_entries!(entries3, cache_dir)
        @test length(entries3) == 1
        @test haskey(entries3, h1)

        # Missing db file → empty result, no error
        rm(db)
        entries4 = Dict{SHA1Hash,BuildCacheBuildEntry}()
        load_build_entries!(entries4, cache_dir)
        @test isempty(entries4)

        # Pre-existing entries in the dict are preserved (merge semantics)
        write(db, "$(bytes2hex(h1)) $(bytes2hex(log1))\n")
        existing_entry = BuildCacheBuildEntry(SHA1Hash(sha1("other")), Dict("Z" => "z"))
        entries5 = Dict{SHA1Hash,BuildCacheBuildEntry}(h2 => existing_entry)
        load_build_entries!(entries5, cache_dir)
        @test haskey(entries5, h1)
        @test entries5[h2] === existing_entry
    end
end

@testset "load_extract_entries!" begin
    using BinaryBuilder2: export_jll_lib_products

    mktempdir() do cache_dir
        mkpath(joinpath(cache_dir, "jll_lib_products"))

        h1 = SHA1Hash(sha1("extract1"))
        h2 = SHA1Hash(sha1("extract2"))
        art1 = SHA1Hash(sha1("artifact1"))
        art2 = SHA1Hash(sha1("artifact2"))
        log1 = SHA1Hash(sha1("extlog1"))
        log2 = SHA1Hash(sha1("extlog2"))
        jlp1 = [JLLLibraryProduct(:libfoo, "lib/libfoo.so", [], [], flags=[:RTLD_LAZY])]
        jlp2 = JLLLibraryProduct[]

        # Write .jlp files
        export_jll_lib_products(jlp1, joinpath(cache_dir, "jll_lib_products", "$(bytes2hex(h1)).jlp"))
        export_jll_lib_products(jlp2, joinpath(cache_dir, "jll_lib_products", "$(bytes2hex(h2)).jlp"))

        # Write a valid extract_entries.db
        db = joinpath(cache_dir, "extract_entries.db")
        write(db, "$(bytes2hex(h1)) $(bytes2hex(art1)) $(bytes2hex(log1))\n$(bytes2hex(h2)) $(bytes2hex(art2)) $(bytes2hex(log2))\n")

        entries = Dict{SHA1Hash,BuildCacheExtractEntry}()
        load_extract_entries!(entries, cache_dir)
        @test length(entries) == 2
        @test entries[h1] == BuildCacheExtractEntry(art1, log1, jlp1)
        @test entries[h2] == BuildCacheExtractEntry(art2, log2, jlp2)

        # Missing .jlp file → entry skipped
        rm(joinpath(cache_dir, "jll_lib_products", "$(bytes2hex(h2)).jlp"))
        entries2 = Dict{SHA1Hash,BuildCacheExtractEntry}()
        load_extract_entries!(entries2, cache_dir)
        @test haskey(entries2, h1)
        @test !haskey(entries2, h2)

        # Malformed TOML in .jlp → entry skipped
        write(joinpath(cache_dir, "jll_lib_products", "$(bytes2hex(h2)).jlp"), "not valid toml [[[")
        entries3 = Dict{SHA1Hash,BuildCacheExtractEntry}()
        load_extract_entries!(entries3, cache_dir)
        @test haskey(entries3, h1)
        @test !haskey(entries3, h2)

        # Malformed hash line → entry skipped
        write(db, "$(bytes2hex(h1)) $(bytes2hex(art1)) $(bytes2hex(log1))\nnotahash notahash notahash\n")
        export_jll_lib_products(jlp2, joinpath(cache_dir, "jll_lib_products", "$(bytes2hex(h2)).jlp"))
        entries4 = Dict{SHA1Hash,BuildCacheExtractEntry}()
        load_extract_entries!(entries4, cache_dir)
        @test length(entries4) == 1
        @test haskey(entries4, h1)

        # Missing db file → empty result, no error
        rm(db)
        entries5 = Dict{SHA1Hash,BuildCacheExtractEntry}()
        load_extract_entries!(entries5, cache_dir)
        @test isempty(entries5)

        # Pre-existing entries in the dict are preserved (merge semantics)
        write(db, "$(bytes2hex(h1)) $(bytes2hex(art1)) $(bytes2hex(log1))\n")
        existing_entry = BuildCacheExtractEntry(SHA1Hash(sha1("other")), SHA1Hash(sha1("otherlog")), jlp2)
        entries6 = Dict{SHA1Hash,BuildCacheExtractEntry}(h2 => existing_entry)
        load_extract_entries!(entries6, cache_dir)
        @test haskey(entries6, h1)
        @test entries6[h2] === existing_entry
    end
end
