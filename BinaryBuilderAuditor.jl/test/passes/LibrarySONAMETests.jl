using Test, BinaryBuilderAuditor, Base.BinaryPlatforms, ObjectFile, BinaryBuilderToolchains
using BinaryBuilderAuditor: ensure_sonames!, get_soname

@testset "ensure_sonames" begin
    # We will create a library without an SONAME by using the BB toolchain package
    platform = CrossPlatform(BBHostPlatform() => HostPlatform())
    toolchain = CToolchain(platform; default_ctoolchain = true, host_ctoolchain = true)

    mktempdir() do prefix
        # Use some bundled C source code from our test suite
        libplus_c_path = joinpath(dirname(@__DIR__), "source", "libplus.c")

        # Compile the `libplus` C source code into a shared library that has no SONAME.
        mkpath(joinpath(prefix, "lib"))
        libplus_path = joinpath(prefix, "lib", "libfoo$(dlext(platform)).1")
        with_toolchains([toolchain]) do _, env
            run(setenv(`$(env["CC"]) -o $(libplus_path) -shared $(libplus_c_path)`, env))
        end

        # Ensure that the library has no SONAME
        @test isfile(joinpath(libplus_path))
        @test readmeta(ohs -> get_soname(only(ohs)), libplus_path) === nothing

        # Run our audit pass on this prefix
        scan = scan_files(prefix, HostPlatform())
        ensure_sonames!(scan; verbose=true)

        @test isfile(joinpath(libplus_path))
        @test readmeta(ohs -> get_soname(only(ohs)), libplus_path) == basename(libplus_path)
    end
end
