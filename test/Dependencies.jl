using Test, BB2, Base.BinaryPlatforms

if !isdefined(Main, :TestingUtils)
    include("TestingUtils.jl")
end

import BB2: download, deploy, dependency_depot
@testset "JLLDependency" begin
    with_temp_storage_locations() do
        bzip2_dep = JLLDependency("Bzip2_jll", HostPlatform())
        zstd_dep = JLLDependency("Zstd_jll", HostPlatform())
        @test bzip2_dep.package.name == "Bzip2_jll"
        @test zstd_dep.package.name == "Zstd_jll"
        @test bzip2_dep.subprefix == ""
        @test zstd_dep.subprefix == ""
        @test isempty(bzip2_dep.artifact_paths)
        @test isempty(zstd_dep.artifact_paths)

        # Download the files, check that they have artifact paths now:
        download([bzip2_dep, zstd_dep])
        @test !isempty(bzip2_dep.artifact_paths)
        @test !isempty(zstd_dep.artifact_paths)
        depot_artifacts_dir = joinpath(dependency_depot(), "artifacts")
        @test all(startswith.(bzip2_dep.artifact_paths, Ref(depot_artifacts_dir)))
        @test all(startswith.(zstd_dep.artifact_paths, Ref(depot_artifacts_dir)))

        mktempdir() do prefix
            deploy(prefix, [bzip2_dep, zstd_dep])
            @test isfile(joinpath(prefix, "bin", "zstd$(exext)"))
            @test isfile(joinpath(prefix, binlib, "libbz2$(soext)"))
        end

        # Test that subprefix works
        ccache_dep = JLLDependency("Ccache_jll", HostPlatform(); subprefix="ext")
        @test ccache_dep.subprefix == "ext"
        download([ccache_dep])
        mktempdir() do prefix
            deploy(prefix, [ccache_dep])
            # Ccache depends on zstd_jll, and that also gets installed
            @test isfile(joinpath(prefix, "ext", "bin", "ccache$(exext)"))
            @test isfile(joinpath(prefix, "ext", "bin", "zstd$(exext)"))

            # TODO: Figure out why we download a whole bunch of other stdlibs here?
            # We don't link them in, which is good...
            run(`find $(prefix)`)
        end
    end
end
