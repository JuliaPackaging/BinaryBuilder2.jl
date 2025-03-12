using Test, BinaryBuilderAuditor, Base.BinaryPlatforms, ObjectFile, BinaryBuilderToolchains
using BinaryBuilderAuditor: ensure_sonames!, get_soname

function make_libfoo(prefix, target)
    # We will create a library without an SONAME by using the BB toolchain package
    platform = CrossPlatform(BBHostPlatform() => target)
    toolchain = CToolchain(platform; use_ccache=false)

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
    for target in (Platform("x86_64", "linux"), Platform("aarch64", "macos"))
        mktempdir() do prefix
            libfoo_path = make_libfoo(prefix, target)

            # Ensure that the library has no SONAME
            @test isfile(libfoo_path)
            curr_soname = readmeta(ohs -> get_soname(only(ohs)), libfoo_path)
            if Sys.islinux(target)
                @test curr_soname === nothing
            elseif Sys.isapple(target)
                @test curr_soname == abspath(libfoo_path)
            end

            # Run our audit pass on this prefix
            scan = scan_files(prefix, target)
            pass_results = Dict{String,Vector{PassResult}}()
            ensure_sonames!(scan, pass_results)

            @test isfile(joinpath(libfoo_path))
            curr_soname = readmeta(ohs -> get_soname(only(ohs)), libfoo_path)
            if Sys.islinux(target)
                @test curr_soname == basename(libfoo_path)
            elseif Sys.isapple(target)
                @test curr_soname == "@rpath/$(basename(libfoo_path))"
            end
            @test success(pass_results)
        end

        mktempdir() do prefix
            # Do this a second time, but this time mangle the library so our manipulation fails
            libfoo_path = make_libfoo(prefix, target)
            scan = scan_files(prefix, target)
            pass_results = Dict{String,Vector{PassResult}}()
            open(libfoo_path; write=true) do io
                println(io, "I am mangling the beginning of a library here")
            end
            ensure_sonames!(scan, pass_results)
            @test !success(pass_results)
            io = IOBuffer()
            print_results(pass_results; io)
            @test occursin("Failed to set SONAME:", String(take!(io)))
            @test any(r.identifier == relpath(libfoo_path, prefix) && r.status == :fail for r in pass_results["ensure_sonames!"])
        end
    end
end
