using Test, BinaryBuilderAuditor, Base.BinaryPlatforms, ObjectFile, BinaryBuilderToolchains
using BinaryBuilderAuditor: ensure_sonames!, get_soname

function make_libfoo(prefix)
    # We will create a library without an SONAME by using the BB toolchain package
    platform = CrossPlatform(BBHostPlatform() => HostPlatform())
    toolchain = CToolchain(platform; default_ctoolchain = true, host_ctoolchain = true)

    # Use some bundled C source code from our test suite
    libplus_c_path = joinpath(dirname(@__DIR__), "source", "libplus.c")
    libfoo_path = joinpath(prefix, "lib", "libfoo$(dlext(platform)).1")

    # Compile the `libplus` C source code into a shared library that has no SONAME.
    mkpath(joinpath(prefix, "lib"))
    with_toolchains([toolchain]) do _, env
        run(setenv(`$(env["CC"]) -o $(libfoo_path) -shared $(libplus_c_path)`, env))
    end
    return libfoo_path
end

@testset "ensure_sonames" begin
    mktempdir() do prefix
        libfoo_path = make_libfoo(prefix)

        # Ensure that the library has no SONAME
        @test isfile(joinpath(libfoo_path))
        @test readmeta(ohs -> get_soname(only(ohs)), libfoo_path) === nothing

        # Run our audit pass on this prefix
        scan = scan_files(prefix, HostPlatform())
        pass_results = Dict{String,Vector{PassResult}}()
        ensure_sonames!(scan, pass_results)

        @test isfile(joinpath(libfoo_path))
        @test readmeta(ohs -> get_soname(only(ohs)), libfoo_path) == basename(libfoo_path)
        @test success(pass_results)
    end

    mktempdir() do prefix
        # Do this a second time, but this time set it to read-only, so we are unable to set the SONAME properly
        libfoo_path = make_libfoo(prefix)
        scan = scan_files(prefix, HostPlatform())
        pass_results = Dict{String,Vector{PassResult}}()
        open(libfoo_path; write=true) do io
            println(io, "I am mangling the beginning of a library here")
        end
        ensure_sonames!(scan, pass_results)
        @test !success(pass_results)
        print_results(pass_results)
        @test any(r.identifier == relpath(libfoo_path, prefix) && r.status == :fail for r in pass_results["ensure_sonames!"])
    end
end
