using Test, BinaryBuilderToolchains
import BinaryBuilderToolchains: PackageSpec, resolve_versions

@testset "resolve_versions" begin
    function is_resolved(p::PackageSpec; tree_hash_not_nothing::Bool = true)
        @test p.uuid !== nothing
        if tree_hash_not_nothing
            @test p.tree_hash !== nothing
        else
            @test p.tree_hash === nothing
        end
        @test isa(p.version, VersionNumber)
        return true
    end

    # Resolve a normal package, the simplest case:
    version_map = resolve_versions([PackageSpec(;name="Bzip2_jll")])
    @test length(version_map) == 1
    @test is_resolved(version_map["Bzip2_jll"])

    # Next, resolve a stdlib, which is slightly harder, and if we don't specify `julia_version=nothing`
    # then we don't get a `tree_hash` field.
    version_map = resolve_versions([(PackageSpec(;name="Zlib_jll"))])
    @test length(version_map) == 1
    @test is_resolved(version_map["Zlib_jll"]; tree_hash_not_nothing=false)

    version_map = resolve_versions([(PackageSpec(;name="Zlib_jll"))]; julia_version=nothing)
    @test length(version_map) == 1
    @test is_resolved(version_map["Zlib_jll"])
end


@testset "resolve() cache" begin
    import BinaryBuilderSources
    old_cache = BinaryBuilderSources._jll_resolve_cache[]
    mktempdir() do dir
        BinaryBuilderSources._jll_resolve_cache[] = name -> joinpath(dir, name)
        cache_files() = filter(isfile, [joinpath(dir, d, "resolve.toml") for d in readdir(dir)])
        same_spec(a, b) = all(getfield(a, f) == getfield(b, f) for f in fieldnames(PackageSpec))
        try
            first_map = resolve_versions([PackageSpec(;name="Bzip2_jll")]; julia_version=nothing)
            @test length(cache_files()) == 1

            # The same request is answered from the cache, with the same result
            cache_file = only(cache_files())
            mtime_before = mtime(cache_file)
            second_map = resolve_versions([PackageSpec(;name="Bzip2_jll")]; julia_version=nothing)
            @test cache_files() == [cache_file]
            @test mtime(cache_file) == mtime_before
            @test same_spec(second_map["Bzip2_jll"], first_map["Bzip2_jll"])

            # Everything `resolve()` returns, including dependencies, survives the round trip
            pkgs = [PackageSpec(;name="XML2_jll")]
            uncached = BinaryBuilderToolchains.resolve(pkgs; julia_version=nothing)
            cached = BinaryBuilderToolchains.resolve(pkgs; julia_version=nothing)
            @test length(cache_files()) == 2
            @test length(cached) == length(uncached) > 1
            @test all(same_spec(a, b) for (a, b) in zip(sort(cached; by=p->p.name), sort(uncached; by=p->p.name)))

            # Stdlibs resolved for a particular julia version have no tree hash
            stdlib_map = resolve_versions([PackageSpec(;name="Zlib_jll")])
            @test same_spec(resolve_versions([PackageSpec(;name="Zlib_jll")])["Zlib_jll"], stdlib_map["Zlib_jll"])
            @test stdlib_map["Zlib_jll"].tree_hash === nothing

            # A different julia version is a different request
            n = length(cache_files())
            resolve_versions([PackageSpec(;name="Bzip2_jll")]; julia_version=v"1.10.0")
            @test length(cache_files()) == n + 1

            # An unreadable cache file counts as a miss, and gets replaced
            write(cache_file, "not toml [")
            @test same_spec(resolve_versions([PackageSpec(;name="Bzip2_jll")]; julia_version=nothing)["Bzip2_jll"], first_map["Bzip2_jll"])
            @test BinaryBuilderToolchains.load_resolution(cache_file) !== nothing
        finally
            BinaryBuilderSources._jll_resolve_cache[] = old_cache
        end
    end
end
