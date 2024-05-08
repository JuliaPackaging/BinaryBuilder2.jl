using Test, BinaryBuilderAuditor, JLLGenerator, BinaryBuilderToolchains

include("ScanningTests.jl")
include("passes/RelativeSymlinkTests.jl")
include("passes/LibrarySONAMETests.jl")
include("passes/DynamicLinkageTests.jl")


@testset "audit!" begin
    platform = CrossPlatform(BBHostPlatform() => HostPlatform())
    toolchain = CToolchain(platform; default_ctoolchain = true, host_ctoolchain = true)

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
        end

        library_products = [
            LibraryProduct("libplus", :libplus),
            LibraryProduct("libmult", :libmult),
        ]
        result = audit!(prefix, library_products, JLLInfo[]; verbose=true)
        @test readlink(joinpath(prefix, "lib", "libplus$(dlext(platform))")) == libplus_soname
        @test length(result.jll_lib_products) == 2
    end
end
