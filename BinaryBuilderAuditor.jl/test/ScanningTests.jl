using Test, BinaryBuilderAuditor, ObjectFile, JLLPrefixes, Base.BinaryPlatforms, BinaryBuilderProducts

@testset "Scanning" begin
    # Download XZ_jll and scan its prefix
    paths = collect_artifact_paths(["XZ_jll"])
    xz_path = only(only(values(paths)))

    # Ensure we find at least these files
    scan = scan_files(
        xz_path,
        HostPlatform(),
        [LibraryProduct("liblzma", :liblzma)],
    )
    @test "bin/xz" ∈ keys(scan.files)
    @test isfile(scan.files["bin/xz"])
    @test "include/lzma.h" ∈ keys(scan.files)
    @test isfile(scan.files["include/lzma.h"])
    liblzma_relpath = "lib/liblzma$(dlext(HostPlatform()))"
    @test liblzma_relpath ∈ keys(scan.files)
    @test islink(scan.files[liblzma_relpath])

    # Ensure we have `bin/xz` as a binary object.
    # We skip symlinks here to avoid processing the same
    # binary object multiple times, so e.g. `bin/lzma`
    # does not show up as its own binary object.
    @test "bin/xz" ∈ keys(scan.binary_objects)
    @test isexecutable(scan.binary_objects["bin/xz"])

    # Ensure that we only have a single `liblzma.*` file
    # listed as a binary object.
    liblzma_objects = filter(keys(scan.binary_objects)) do name
        return startswith(name, "lib/liblzma.")
    end
    @test length(liblzma_objects) == 1
    @test islibrary(scan.binary_objects[only(liblzma_objects)])

    # Test that our symlink resolver knows about `lib/liblzma.so -> lib/liblzma.so.X`
    @test haskey(scan.binary_objects, relpath(scan, liblzma_relpath))

    # Test soname_forwards knows about the symlink as well
    liblzma_soname = scan.soname_forwards[basename(liblzma_relpath)]
    @test haskey(scan.binary_objects, scan.soname_locator[liblzma_soname])

    # A product path containing `..` must be keyed by the same normalized path
    # as the scanned binary object it refers to
    real_xz_path = realpath(xz_path)
    env = Dict(
        "prefix" => real_xz_path,
        "bindir" => joinpath(real_xz_path, "bin"),
        "bb_full_target" => triplet(HostPlatform()),
    )
    dotdot_scan = scan_files(
        xz_path,
        HostPlatform(),
        [LibraryProduct("\${bindir}/../lib/liblzma", :liblzma)],
        env,
    )
    dotdot_key = only(keys(dotdot_scan.library_products))
    @test dotdot_key == only(keys(scan.library_products))
    @test haskey(dotdot_scan.binary_objects, dotdot_key)
end

@testset "is_static_archive" begin
    using BinaryBuilderAuditor: is_static_archive
    mktempdir() do dir
        for (name, contents, expected) in (
                # An archive without any members is still an archive
                ("empty_archive.a", b"!<arch>\n", true),
                # Thin archives only refer to their members, so cannot be shipped
                ("thin.a", b"!<thin>\n", false),
                ("text.a", b"!<arch> but not really", false),
                ("short.a", b"!<a", false),
                ("empty.a", UInt8[], false),
                # A malformed member header
                ("malformed.a", vcat(b"!<arch>\n", fill(UInt8(' '), 60)), false),
            )
            path = joinpath(dir, name)
            write(path, contents)
            @test is_static_archive(path) == expected
        end
    end
end

@testset "resolve_prefix_path" begin
    using BinaryBuilderAuditor: resolve_prefix_path
    mktempdir() do prefix
        alias = "/workspace/destdir"
        mkpath(joinpath(prefix, "bin"))
        mkpath(joinpath(prefix, "include", "ncursesw"))
        touch(joinpath(prefix, "bin", "xz"))
        touch(joinpath(prefix, "include", "ncursesw", "curses.h"))
        symlink("xz", joinpath(prefix, "bin", "lzma"))
        symlink("../bin/lzma", joinpath(prefix, "bin", "unlzma"))
        symlink("$(alias)/bin/xz", joinpath(prefix, "bin", "unxz"))
        symlink("ncursesw", joinpath(prefix, "include", "ncurses"))
        symlink("/elsewhere/xz", joinpath(prefix, "bin", "outside"))
        symlink("loop", joinpath(prefix, "bin", "loop"))

        resolve(p) = resolve_prefix_path(prefix, alias, p)
        @test resolve("bin/xz") == joinpath("bin", "xz")
        @test resolve("bin/lzma") == joinpath("bin", "xz")
        @test resolve("bin/unlzma") == joinpath("bin", "xz")
        @test resolve("bin/unxz") == joinpath("bin", "xz")
        @test resolve("include/ncurses") == joinpath("include", "ncursesw")
        @test resolve("include/ncurses/curses.h") == joinpath("include", "ncursesw", "curses.h")
        @test resolve("include/ncurses/../ncurses/curses.h") == joinpath("include", "ncursesw", "curses.h")
        @test resolve("bin/outside") === nothing
        @test resolve("../bin/xz") === nothing
        @test resolve("bin/loop") === nothing
    end
end

@testset "products naming the same path" begin
    platform = HostPlatform()
    mktempdir() do prefix
        mkpath(joinpath(prefix, "bin"))
        mkpath(joinpath(prefix, "include", "ncursesw"))
        write(joinpath(prefix, "bin", "xz"), "#!/bin/sh\n")
        chmod(joinpath(prefix, "bin", "xz"), 0o755)
        symlink("xz", joinpath(prefix, "bin", "lzma"))
        touch(joinpath(prefix, "include", "ncursesw", "curses.h"))
        symlink("ncursesw", joinpath(prefix, "include", "ncurses"))
        env = Dict(
            "prefix" => prefix,
            "bindir" => joinpath(prefix, "bin"),
            "includedir" => joinpath(prefix, "include"),
            "bb_full_target" => triplet(platform),
        )
        scan(products) = scan_files(prefix, platform, AbstractProduct[products...], env)
        function scan_error(products)
            try
                scan(products)
            catch e
                return e
            end
            return nothing
        end

        # Two file products for one path is an error, whichever way round, through a
        # symlinked file or a symlinked directory
        for products in ([FileProduct("include/ncursesw/curses.h", :curses_h), FileProduct("include/ncurses/curses.h", :ncurses_curses_h)],
                         [FileProduct("include/ncurses/curses.h", :ncurses_curses_h), FileProduct("include/ncursesw/curses.h", :curses_h)],
                         [FileProduct("include/ncursesw", :ncursesw_include), FileProduct("include/ncurses", :ncurses_include)])
            err = scan_error(products)
            @test isa(err, ErrorException)
            @test contains(err.msg, "FileProducts '$(products[1].varname)' and '$(products[2].varname)' both resolve to")
        end

        # Executables may share a file, as they can behave differently by the name they
        # are run by (`lzma` here, like `clang++` for `clang`)
        scan([ExecutableProduct("xz", :xz), ExecutableProduct("lzma", :lzma)])

        # ... and aliases are the way to give it several names
        scan([ExecutableProduct("xz", :xz; aliases = [:lzma]),
              FileProduct("include/ncursesw/curses.h", :curses_h; aliases = [:ncurses_curses_h])])
        # A file product may name an executable's file, as they are different kinds
        scan([ExecutableProduct("xz", :xz), FileProduct("bin/lzma", :lzma_path)])
        @test true
    end
end
