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
    @test "lib/liblzma.so" ∈ keys(scan.files)
    @test islink(scan.files["lib/liblzma.so"])

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
    @test haskey(scan.binary_objects, relpath(scan, "lib/liblzma.so"))

    # Test soname_forwards knows about the symlink as well
    liblzma_soname = scan.soname_forwards["liblzma.so"]
    @test haskey(scan.binary_objects, scan.soname_locator[liblzma_soname])
end
