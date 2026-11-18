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
    for target in (Platform("x86_64", "linux"), Platform("aarch64", "macos"; os_version=v"20"))
        mktempdir() do prefix
            libfoo_path = make_libfoo(prefix, target)

            # Ensure that the library has no SONAME
            @test isfile(libfoo_path)
            curr_soname = readmeta(ohs -> get_soname(only(ohs)), libfoo_path)

            if Sys.isapple(target)
                @test curr_soname == abspath(libfoo_path)
            elseif Sys.islinux(target) || Sys.isbsd(target)
                @test curr_soname === nothing
            end

            # Run our audit pass on this prefix
            scan = scan_files(prefix, target)
            result = AuditResult(scan)
            ensure_sonames!(result)

            @test isfile(joinpath(libfoo_path))
            curr_soname = readmeta(ohs -> get_soname(only(ohs)), libfoo_path)
            if Sys.isapple(target)
                @test curr_soname == "@rpath/$(basename(libfoo_path))"
            elseif Sys.islinux(target) || Sys.isbsd(target)
                @test curr_soname == basename(libfoo_path)
            end
            @test success(result.pass_results)
        end

        mktempdir() do prefix
            # Do this a second time, but this time mangle the library so our manipulation fails
            libfoo_path = make_libfoo(prefix, target)
            scan = scan_files(prefix, target)
            result = AuditResult(scan)
            open(libfoo_path; write=true) do io
                println(io, "I am mangling the beginning of a library here")
            end
            ensure_sonames!(result)
            @test !success(result.pass_results)
            io = IOBuffer()
            show(io, result.pass_results)
            @test occursin("Failed to set SONAME:", String(take!(io)))
            @test any(r.identifier == relpath(libfoo_path, prefix) && r.status == :fail for r in result.pass_results["ensure_sonames!"])
        end
    end
end

@testset "ensure_sonames keeps the install name's basename on macOS" begin
    target = Platform("aarch64", "macos"; os_version=v"20")
    platform = CrossPlatform(BBHostPlatform() => target)
    toolchain = CToolchain(platform; use_ccache=false)
    libplus_c_path = joinpath(dirname(@__DIR__), "source", "libplus.c")
    mktempdir() do prefix
        # Like readline: the real file is `libfoo.1.2.dylib`, linked with the install
        # name `<libdir>/libfoo.1.dylib`, and that name is a symlink to the real file.
        mkpath(joinpath(prefix, "lib"))
        libfoo_path = joinpath(prefix, "lib", "libfoo.1.2.dylib")
        with_toolchains([toolchain]) do _, env
            run(setenv(`$(env["CC"]) -o $(libfoo_path) -shared $(libplus_c_path) -Wl,-install_name,$(prefix)/lib/libfoo.1.dylib`, env))
        end
        symlink("libfoo.1.2.dylib", joinpath(prefix, "lib", "libfoo.1.dylib"))
        symlink("libfoo.1.dylib", joinpath(prefix, "lib", "libfoo.dylib"))

        scan = scan_files(prefix, target)
        @test scan.soname_locator["libfoo.1.dylib"] == "lib/libfoo.1.2.dylib"
        result = AuditResult(scan)
        ensure_sonames!(result)
        @test success(result.pass_results)
        @test readmeta(ohs -> get_soname(only(ohs)), libfoo_path) == "@rpath/libfoo.1.dylib"
    end

    mktempdir() do prefix
        # Without a file of the install name's basename, fall back to the real file's name
        mkpath(joinpath(prefix, "lib"))
        libfoo_path = joinpath(prefix, "lib", "libfoo.1.2.dylib")
        with_toolchains([toolchain]) do _, env
            run(setenv(`$(env["CC"]) -o $(libfoo_path) -shared $(libplus_c_path) -Wl,-install_name,$(prefix)/lib/libfoo.1.dylib`, env))
        end
        scan = scan_files(prefix, target)
        result = AuditResult(scan)
        ensure_sonames!(result)
        @test success(result.pass_results)
        @test readmeta(ohs -> get_soname(only(ohs)), libfoo_path) == "@rpath/libfoo.1.2.dylib"
    end
end
