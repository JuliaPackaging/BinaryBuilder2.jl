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

