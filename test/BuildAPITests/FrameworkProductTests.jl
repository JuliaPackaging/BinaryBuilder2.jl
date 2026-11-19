using Test, BinaryBuilder2, Random, TOML, Artifacts
using BinaryBuilder2: get_package_result, collect_extractions, jll_dir, in_universe
using JLLGenerator: JLLLibraryDep
import BinaryBuilderAuditor

if !isdefined(@__MODULE__, :TestingUtils)
    include(joinpath(pkgdir(BinaryBuilder2), "test", "TestingUtils.jl"))
end
include(joinpath(pkgdir(BinaryBuilderAuditor), "test", "CodeSignatureUtils.jl"))

@testset "Framework bundles" begin
    universe_name = "framework-tests-$(randstring(4))"
    meta = BuildMeta(; universe_name)
    run_build_tarballs(meta, joinpath(@__DIR__, "build_examples", "framework_product.jl"))
    package_result = get_package_result(meta, "FrameworkExample")
    @test package_result.status == :success

    extractions = Dict(triplet(er.config.platform) => er for er in collect_extractions(package_result))
    @test length(extractions) == 3
    for (target, er) in extractions
        @test er.status ∈ (:success, :cached)
        jlps = Dict(p.varname => p for p in er.jll_lib_products)
        if occursin("apple", target)
            # On macOS the products are the binaries inside the framework bundles
            @test jlps[:libplus].path == "lib/Plus.framework/Versions/A/Plus"
            @test jlps[:libplus].soname == "@rpath/Plus.framework/Versions/A/Plus"
            @test jlps[:libmult].path == "lib/Mult.framework/Versions/A/Mult"
            @test jlps[:libmult].soname == "@rpath/Mult.framework/Versions/A/Mult"

            # The bundle layout survives packaging
            fw = joinpath(artifact_path(er), "lib", "Mult.framework")
            @test readlink(joinpath(fw, "Versions", "Current")) == "A"
            @test readlink(joinpath(fw, "Mult")) == "Versions/Current/Mult"
            @test isfile(joinpath(fw, "Mult"))

            # The auditor rewrote the install names, then re-signed the binaries
            for name in ("Plus", "Mult")
                @test codesignature_status(joinpath(artifact_path(er), "lib", "$(name).framework", "Versions", "A", name)) == :adhoc
            end
        else
            # Elsewhere they are plain shared libraries
            @test jlps[:libplus].path == "lib/libPlus.so"
            @test jlps[:libmult].path == "lib/libMult.so"
        end
        @test jlps[:libmult].deps == [JLLLibraryDep(nothing, :libplus)]
    end

    # Each platform's JLL.toml entry records the framework binary as a library
    jll_toml = TOML.parsefile(joinpath(jll_dir(package_result), "JLL.toml"))
    for build in jll_toml["builds"]
        products = Dict(p["name"] => p for p in build["products"])
        @test all(p["type"] == "library" for p in values(products))
        if occursin("apple", build["platform"])
            @test products["libmult"]["path"] == "lib/Mult.framework/Versions/A/Mult"
        end
    end

    # The JLL loads on this (Linux) host, through the plain library paths
    in_universe(meta.universe) do env
        mktempdir() do project
            code = """
            using Pkg, Test
            Pkg.develop(; path=$(repr(jll_dir(package_result))), io=devnull)
            using FrameworkExample_jll
            @test FrameworkExample_jll.is_available()
            @test endswith(FrameworkExample_jll.libmult_path, "libMult.so")
            @test ccall((:mult, libmult), Cint, (Cint, Cint), 3, 4) == 12
            """
            @test success(run(addenv(`$(Base.julia_cmd()) --project=$(project) -e $(code)`, env)))
        end
    end
end
