using Test, Pkg, BinaryBuilder2, SHA, MultiHashParsing, Patchelf_jll
using BinaryBuilder2: load_cache, save_cache, prune!, export_archive, import_archives
using BinaryBuilder2: load_build_entries!, load_extract_entries!
using BinaryBuilder2: BuildCacheBuildEntry, BuildCacheExtractEntry, Universe, export_source_records
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
            JLLStaticLibraryProduct(:libfoo_a, "lib/libfoo.a"; system_deps = ["m"]),
        ]

        # build1 records its sources, build2 is an entry stored without them
        build1_sources = [
            JLLSourceRecord("https://example.com/foo-1.0.tar.gz", SHA1Hash(sha1("foo_tree"))),
            JLLSourceRecord("https://example.com/foo.git", SHA1Hash(sha1("foo_commit"))),
        ]
        put!(bc, build1_hash, extract1_hash, build_log1_hash, build_env1, artifact1_hash, extract_log1_hash, extract1_jlp; source_records=build1_sources)
        put!(bc, build2_hash, extract2_hash, build_log2_hash, build_env2, artifact2_hash, extract_log2_hash, extract2_jlp)

        function probe_buildcache(bc)
            @test haskey(bc, build1_hash, extract1_hash)
            b1, e1 = get(bc, build1_hash, extract1_hash)
            @test b1.log_artifact == build_log1_hash
            @test b1.env == build_env1
            @test b1.source_records == build1_sources
            @test e1.artifact == artifact1_hash
            @test e1.log_artifact == extract_log1_hash
            @test e1.jll_lib_products == extract1_jlp

            @test haskey(bc, build2_hash, extract2_hash)
            b2, e2 = get(bc, build2_hash, extract2_hash)
            @test b2.log_artifact == build_log2_hash
            @test b2.env == build_env2
            @test b2.source_records === nothing
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
        @test isfile(joinpath(archive_dir, "$(build1_hash).sources.toml"))
        @test !isfile(joinpath(archive_dir, "$(build2_hash).sources.toml"))

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
        # Also drop build1's log so that its build entry is pruned, while build2's survives.
        rm(joinpath(cache_dir, bytes2hex(build_log1_hash)); recursive=true)

        # prune!() also removes the aux files of pruned entries (and anything that
        # isn't named after a cache hash) from `cache_dir`, but nothing else.
        env_path(h) = joinpath(cache_dir, "envs", "$(bytes2hex(h)).env")
        jlp_path(h) = joinpath(cache_dir, "jll_lib_products", "$(bytes2hex(h)).jlp")
        @test all(isfile, env_path.([build1_hash, build2_hash, patchelf_build_hash]))
        @test all(isfile, jlp_path.([extract1_hash, extract2_hash, patchelf_extract_hash]))
        src_path(h) = joinpath(cache_dir, "sources", "$(bytes2hex(h)).toml")
        @test isfile(src_path(build1_hash))
        # build2 was stored without source records; give it a sources file so we can
        # check that the sources of a surviving entry are kept.
        export_source_records(build1_sources, src_path(build2_hash))
        touch(joinpath(cache_dir, "envs", "not_a_hash.env"))
        touch(joinpath(cache_dir, "sources", "not_a_hash.toml"))
        touch(joinpath(cache_dir, "jll_lib_products", "$(bytes2hex(patchelf_extract_hash)).txt"))

        # Populate the working directory with lookalike files that must survive.
        cwd_dir = mktempdir()
        cwd_files = [
            joinpath(cwd_dir, "envs", "$(bytes2hex(build1_hash)).env"),
            joinpath(cwd_dir, "envs", "not_a_hash.env"),
            joinpath(cwd_dir, "jll_lib_products", "$(bytes2hex(extract1_hash)).jlp"),
            joinpath(cwd_dir, "sources", "$(bytes2hex(build1_hash)).toml"),
        ]
        for f in cwd_files
            mkpath(dirname(f))
            touch(f)
        end

        cd(cwd_dir) do
            prune!(bc2)
        end
        @test all(isfile, cwd_files)
        rm(cwd_dir; recursive=true)

        @test !isfile(env_path(build1_hash))
        @test isfile(env_path(build2_hash))
        @test isfile(env_path(patchelf_build_hash))
        @test !isfile(jlp_path(extract1_hash))
        @test !isfile(jlp_path(extract2_hash))
        @test isfile(jlp_path(patchelf_extract_hash))
        @test sort(readdir(joinpath(cache_dir, "envs"))) == sort(["$(bytes2hex(h)).env" for h in (build2_hash, patchelf_build_hash)])
        @test readdir(joinpath(cache_dir, "jll_lib_products")) == ["$(bytes2hex(patchelf_extract_hash)).jlp"]
        @test readdir(joinpath(cache_dir, "sources")) == ["$(bytes2hex(build2_hash)).toml"]

        @test !haskey(bc2, build1_hash, extract1_hash)
        @test !haskey(bc2, build2_hash, extract2_hash)
        @test !haskey(bc2, build1_hash, extract2_hash)
        @test !haskey(bc2, build2_hash, extract1_hash)
        @test !haskey(bc2.build_entries, build1_hash)
        @test haskey(bc2.build_entries, build2_hash)
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

        # Source records are picked up when present
        records = [JLLSourceRecord("https://example.com/foo.tar.gz", SHA1Hash(sha1("tree")))]
        mkpath(joinpath(cache_dir, "sources"))
        export_source_records(records, joinpath(cache_dir, "sources", "$(bytes2hex(h1)).toml"))
        entries_with_sources = Dict{SHA1Hash,BuildCacheBuildEntry}()
        load_build_entries!(entries_with_sources, cache_dir)
        @test entries_with_sources[h1] == BuildCacheBuildEntry(log1, env1, records)
        @test entries_with_sources[h2].source_records === nothing
        rm(joinpath(cache_dir, "sources"); recursive=true)

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
