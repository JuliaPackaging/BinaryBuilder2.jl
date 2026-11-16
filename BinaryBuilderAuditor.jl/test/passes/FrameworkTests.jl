using Test, BinaryBuilderAuditor, Base.BinaryPlatforms, ObjectFile, BinaryBuilderToolchains, BinaryBuilderProducts, JLLGenerator, TreeArchival
using BinaryBuilderAuditor: framework_relpath, relpath_search, rpath_dir, get_soname, is_for_platform

@testset "framework helpers" begin
    @test framework_relpath("lib/Foo.framework/Versions/A/Foo") == "Foo.framework/Versions/A/Foo"
    @test framework_relpath("Foo.framework/Foo") == "Foo.framework/Foo"
    @test framework_relpath("lib/Foo.framework/Versions/A/Bar") === nothing
    @test framework_relpath("lib/libfoo.dylib") === nothing

    macos = Platform("aarch64", "macos")
    linux = Platform("x86_64", "linux")
    @test rpath_dir("@rpath/Foo.framework/Versions/A/Foo", "lib/Foo.framework/Versions/A/Foo", macos) == "lib"
    @test rpath_dir("@rpath/Foo.framework/Versions/A/Foo", "Foo.framework/Versions/A/Foo", macos) == ""
    @test rpath_dir("@rpath/libfoo.1.dylib", "lib/libfoo.1.dylib", macos) == "lib"
    @test rpath_dir("@rpath/libfoo.dylib", "lib/libfoo.1.dylib", macos) == "lib"
    @test rpath_dir("libfoo.so.1", "lib/libfoo.so.1", linux) == "lib"

    symlinks = Dict(
        "lib/Foo.framework/Versions/Current" => "lib/Foo.framework/Versions/A",
        "lib/Foo.framework/Foo" => "lib/Foo.framework/Versions/Current/Foo",
        "lib/libfoo.dylib" => "lib/libfoo.1.dylib",
        "lib/loop" => "lib/loop",
        "lib/escape" => "../outside",
    )
    @test relpath_search(symlinks, "lib/Foo.framework/Foo") == "lib/Foo.framework/Versions/A/Foo"
    @test relpath_search(symlinks, "lib/Foo.framework/Versions/Current/Foo") == "lib/Foo.framework/Versions/A/Foo"
    @test relpath_search(symlinks, "lib/libfoo.dylib") == "lib/libfoo.1.dylib"
    @test relpath_search(symlinks, "lib/libfoo.1.dylib") == "lib/libfoo.1.dylib"
    @test relpath_search(symlinks, "lib/loop") == "lib/loop"
    @test relpath_search(symlinks, "lib/escape") == "lib/escape"
end

# Lay out `prefix/lib/<name>.framework` the way macOS frameworks usually are,
# with `Versions/Current` pointing at `current_target`.
function framework_skeleton(prefix, name; current_target = "A")
    fw = joinpath(prefix, "lib", "$(name).framework")
    mkpath(joinpath(fw, "Versions", "A", "Resources"))
    symlink(current_target, joinpath(fw, "Versions", "Current"))
    symlink("Versions/Current/$(name)", joinpath(fw, name))
    symlink("Versions/Current/Resources", joinpath(fw, "Resources"))
    return joinpath(fw, "Versions", "A", name)
end

for target_platform in (Platform("aarch64", "macos"; os_version=v"20"), Platform("x86_64", "macos"; os_version=v"20"))
    platform = CrossPlatform(BBHostPlatform() => target_platform)
    toolchain = CToolchain(platform; use_ccache=false)
    libplus_c_path = joinpath(dirname(@__DIR__), "source", "libplus.c")
    libmult_c_path = joinpath(dirname(@__DIR__), "source", "libmult.c")

    @testset "framework audit - $(triplet(target_platform))" begin
        mktempdir() do prefix
            # `Plus.framework` carries a proper `@rpath` install name.  `Mult.framework`
            # links against it, has no usable install name (the linker records the
            # absolute output path) and an absolute `Versions/Current` link.
            # `libsquare.dylib` is an ordinary library that links against `Plus`, and
            # `libcube.dylib` links against `Mult` by its absolute path.
            plus_path = framework_skeleton(prefix, "Plus")
            mult_path = framework_skeleton(prefix, "Mult"; current_target = joinpath(prefix, "lib", "Mult.framework", "Versions", "A"))
            square_path = joinpath(prefix, "lib", "libsquare.dylib")
            cube_path = joinpath(prefix, "lib", "libcube.dylib")
            with_toolchains([toolchain]) do _, env
                run(setenv(`$(env["CC"]) -o $(plus_path) -shared $(libplus_c_path) -Wl,-install_name,@rpath/Plus.framework/Versions/A/Plus`, env))
                run(setenv(`$(env["CC"]) -o $(mult_path) -shared $(libmult_c_path) -F $(prefix)/lib -framework Plus`, env))
                run(setenv(`$(env["CC"]) -o $(square_path) -shared $(libmult_c_path) -F $(prefix)/lib -framework Plus -Wl,-install_name,@rpath/libsquare.dylib`, env))
                run(setenv(`$(env["CC"]) -o $(cube_path) -shared $(libplus_c_path) -F $(prefix)/lib -framework Mult -Wl,-install_name,@rpath/libcube.dylib`, env))
            end
            mkpath(joinpath(prefix, "share", "licenses", "Plus"))
            touch(joinpath(prefix, "share", "licenses", "Plus", "LICENSE"))

            products = [
                FrameworkProduct("Plus", :libplus),
                FrameworkProduct("Mult", :libmult),
                LibraryProduct("libsquare", :libsquare),
                LibraryProduct("libcube", :libcube),
            ]
            result = audit!(prefix, products, AuditInfo(); platform=target_platform, verbose=true)
            @test success(result)

            # The absolute directory symlink was made relative
            @test readlink(joinpath(prefix, "lib", "Mult.framework", "Versions", "Current")) == "A"

            jlps = Dict(p.varname => p for p in result.jll_lib_products)
            @test jlps[:libplus].path == "lib/Plus.framework/Versions/A/Plus"
            @test jlps[:libplus].soname == "@rpath/Plus.framework/Versions/A/Plus"
            @test isempty(jlps[:libplus].deps)
            @test jlps[:libmult].path == "lib/Mult.framework/Versions/A/Mult"
            @test jlps[:libmult].soname == "@rpath/Mult.framework/Versions/A/Mult"
            @test jlps[:libmult].deps == [JLLLibraryDep(nothing, :libplus)]
            @test jlps[:libsquare].deps == [JLLLibraryDep(nothing, :libplus)]
            @test jlps[:libcube].deps == [JLLLibraryDep(nothing, :libmult)]

            # The install name and RPATHs let each binary find the frameworks
            # through `@rpath/<Name>.framework/...`
            function read_oh(path)
                return only(filter(oh -> is_for_platform(oh, target_platform), readmeta(open(path))))
            end
            mult_oh = read_oh(mult_path)
            @test get_soname(mult_oh) == "@rpath/Mult.framework/Versions/A/Mult"
            @test rpaths(RPath(mult_oh)) == ["@loader_path/../../.."]
            square_oh = read_oh(square_path)
            @test rpaths(RPath(square_oh)) == ["@loader_path"]
            # The absolute dependency on `Mult` was relinked through `@rpath`
            cube_oh = read_oh(cube_path)
            @test "@rpath/Mult.framework/Versions/A/Mult" in [path(dl) for dl in DynamicLinks(cube_oh)]
            @test rpaths(RPath(cube_oh)) == ["@loader_path"]

            # Running the audit again changes nothing
            pre_treehash = treehash(prefix)
            result = audit!(prefix, products, AuditInfo(); platform=target_platform, readonly=true)
            @test success(result)
            @test treehash(prefix) == pre_treehash

            # `Plus` may also come from a dependency JLL
            info = AuditInfo(Dict(
                :Plus_jll => AuditDependencyInfo([
                    JLLLibraryProduct(:libplus, jlps[:libplus].path, [], [];
                                      soname = jlps[:libplus].soname),
                ]),
            ))
            result = audit!(prefix, [FrameworkProduct("Mult", :libmult)], info; platform=target_platform, readonly=true)
            @test success(result)
            @test only(result.jll_lib_products).deps == [JLLLibraryDep(:Plus_jll, :libplus)]
        end
    end
end

@testset "framework paths audit - non-macOS" begin
    platform = CrossPlatform(BBHostPlatform() => HostPlatform())
    toolchain = CToolchain(platform; use_ccache=false)
    libplus_c_path = joinpath(dirname(@__DIR__), "source", "libplus.c")
    mktempdir() do prefix
        mkpath(joinpath(prefix, "lib"))
        with_toolchains([toolchain]) do _, env
            run(setenv(`$(env["CC"]) -o $(joinpath(prefix, "lib", "libPlus.so")) -shared $(libplus_c_path)`, env))
        end
        mkpath(joinpath(prefix, "share", "licenses", "Plus"))
        touch(joinpath(prefix, "share", "licenses", "Plus", "LICENSE"))
        result = audit!(prefix, [LibraryProduct(["Plus.framework", "libPlus"], :libplus)], AuditInfo())
        @test success(result)
        @test only(result.jll_lib_products).path == "lib/libPlus.so"
    end
end
