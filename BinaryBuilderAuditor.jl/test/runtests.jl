using Test, BinaryBuilderProducts, BinaryBuilderAuditor, JLLGenerator, BinaryBuilderToolchains, TreeArchival, UUIDs

include("ScanningTests.jl")
include("passes/RelativeSymlinkTests.jl")
include("passes/LicenseTests.jl")
include("passes/LibrarySONAMETests.jl")
include("passes/DynamicLinkageTests.jl")

@testset "audit!" begin
    platform = CrossPlatform(BBHostPlatform() => HostPlatform())
    toolchain = CToolchain(platform; use_ccache=false)

    # Use some bundled C source code from our test suite
    libplus_c_path = joinpath(@__DIR__, "source", "libplus.c")
    libmult_c_path = joinpath(@__DIR__, "source", "libmult.c")

    libplus_soname = versioned_shlib("libplus", 1, platform)
    libmult_soname = versioned_shlib("libmult", 2, platform)

    # We will create a library without an SONAME by using the BB toolchain package
    mktempdir() do prefix
        # Compile the C source code into a shared library that has no SONAME.
        mkpath(joinpath(prefix, "lib"))
        libplus_path = joinpath(prefix, "lib", libplus_soname)
        libmult_path = joinpath(prefix, "lib", libmult_soname)
        with_toolchains([toolchain]) do _, env
            run(setenv(`$(env["CC"]) -o $(libplus_path) -shared $(libplus_c_path)`, env))
            symlink(joinpath(prefix, "lib", libplus_soname), joinpath(prefix, "lib", "libplus$(dlext(platform))"))
            run(setenv(`$(env["CC"]) -o $(libmult_path) -shared $(libmult_c_path) -L $(prefix)/lib -lplus`, env))
            mkpath(joinpath(prefix, "share", "licenses", "libplus"))
            touch(joinpath(prefix, "share", "licenses", "libplus", "LICENSE.md"))
        end

        library_products = [
            LibraryProduct("libplus", :libplus),
            LibraryProduct("libmult", :libmult),
        ]
        empty_dep_libs = Dict{Symbol,Vector{JLLLibraryProduct}}()
        result = audit!(prefix, library_products, empty_dep_libs; verbose=true)
        @test readlink(joinpath(prefix, "lib", "libplus$(dlext(platform))")) == libplus_soname
        @test length(result.jll_lib_products) == 2
        @test success(result)

        # Run audit a second time with `readonly=true`, ensure that the treehash does not change
        pre_treehash = treehash(prefix)
        result = audit!(prefix, library_products, empty_dep_libs; readonly=true)
        post_treehash = treehash(prefix)
        @test pre_treehash == post_treehash
        @test length(result.jll_lib_products) == 2
        @test success(result)

        # Without a `pkg_uuid`, the products carry no library identity...
        @test all(p.dlid === nothing for p in result.jll_lib_products)
        # ... and with one, each is born with an identity namespaced under it
        pkg_uuid = Base.UUID("bfe6b9e6-b96c-4ffe-b444-b032dd7326b0")
        result = audit!(prefix, library_products, empty_dep_libs; readonly=true, pkg_uuid)
        @test success(result)
        for p in result.jll_lib_products
            @test p.dlid == UUIDs.uuid5(pkg_uuid, string(p.varname))
        end

        # A declared identity survives auditing untouched, while its siblings
        # still receive the derived default
        override = Base.UUID("2fa9b87e-ecfa-4b46-8b6a-27ac02c17e18")
        overridden_products = [
            LibraryProduct("libplus", :libplus; dlid=override),
            LibraryProduct("libmult", :libmult),
        ]
        result = audit!(prefix, overridden_products, empty_dep_libs; readonly=true, pkg_uuid)
        @test success(result)
        by_name = Dict(p.varname => p for p in result.jll_lib_products)
        @test by_name[:libplus].dlid == override
        @test by_name[:libmult].dlid == UUIDs.uuid5(pkg_uuid, "libmult")

        # Also check to see that this works if we say that `libplus` belongs
        # to another JLL/extraction:
        dep_libs = Dict{Symbol,Vector{JLLLibraryProduct}}(
            :LibPlus => [
                JLLLibraryProduct(
                    :libplus,
                    joinpath("lib", libplus_soname),
                    [],
                ),
            ]
        )
        result = audit!(prefix, [LibraryProduct("libmult", :libmult)], dep_libs; readonly=true)
        post_treehash = treehash(prefix)
        @test pre_treehash == post_treehash
        @test length(result.jll_lib_products) == 1
        @test success(result)
    end
end
