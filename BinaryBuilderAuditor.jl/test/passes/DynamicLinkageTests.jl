using Test, BinaryBuilderAuditor, Base.BinaryPlatforms, ObjectFile, BinaryBuilderToolchains, BinaryBuilderProducts, JLLGenerator
using BinaryBuilderAuditor: resolve_dynamic_links!, ensure_sonames!, rpaths_consistent!

function versioned_shlib(name, major_version, platform)
    if Sys.iswindows(platform)
        return string(name, "-", major_version, ".dll")
    elseif Sys.isapple(platform)
        return string(name, ".", major_version, ".dylib")
    else
        return string(name, ".so.", major_version)
    end
end

function soname_flag(platform, soname)
    if Sys.isapple(platform)
        return "-Wl,-install_name,$(soname)"
    else
        return "-Wl,-soname,$(soname)"
    end
end

# We're gonna make use of a C toolchain for lots of these tests
for target_platform in (Platform("x86_64", "linux"), Platform("aarch64", "macos"; os_version=v"20"))
    platform = CrossPlatform(BBHostPlatform() => target_platform)
    toolchain = CToolchain(platform; use_ccache=false)

    # Use some bundled C source code from our test suite
    libplus_c_path = joinpath(dirname(@__DIR__), "source", "libplus.c")
    libmult_c_path = joinpath(dirname(@__DIR__), "source", "libmult.c")

    libplus_soname = versioned_shlib("libplus", 1, target_platform)
    libmult_soname = versioned_shlib("libmult", 2, target_platform)

    @testset "resolve_dynamic_links - $(triplet(target_platform))" begin
        # We will create a library without an SONAME by using the BB toolchain package
        mktempdir() do prefix
            # Compile the C source code into a shared library that has no SONAME.
            mkpath(joinpath(prefix, "lib"))
            libplus_path = joinpath(prefix, "lib", libplus_soname)
            libmult_path = joinpath(prefix, "lib", libmult_soname)
            with_toolchains([toolchain]) do _, env
                run(setenv(`$(env["CC"]) -o $(libplus_path) -shared $(libplus_c_path)`, env))
                symlink(libplus_soname, joinpath(prefix, "lib", "libplus$(dlext(platform))"))
                run(setenv(`$(env["CC"]) -o $(libmult_path) -shared $(libmult_c_path) -L $(prefix)/lib -lplus`, env))
            end

            @test isfile(joinpath(libplus_path))
            @test isfile(joinpath(libmult_path))

            # First, ensure we have SONAMEs, as those are important
            scan = scan_files(
                prefix,
                target_platform,
                [
                    LibraryProduct("libplus", :libplus),
                    LibraryProduct("libmult", :libmult),
                ],
            )
            result = AuditResult(scan)
            ensure_sonames!(result)
            @test success(result.pass_results)

            # First, resolve dynamic links when these are two librares in the same build:
            jll_lib_products = resolve_dynamic_links!(result, AuditInfo()).jll_lib_products
            @test success(result.pass_results)

            @test length(jll_lib_products) == 2
            @test jll_lib_products[2].varname == :libplus
            @test jll_lib_products[2].path == joinpath("lib", libplus_soname)
            @test isempty(jll_lib_products[2].deps)

            @test jll_lib_products[1].varname == :libmult
            @test jll_lib_products[1].path == joinpath("lib", libmult_soname)
            @test length(jll_lib_products[1].deps) == 1
            @test jll_lib_products[1].deps[1].mod === nothing
            @test jll_lib_products[1].deps[1].varname == :libplus

            # The C runtime edge is recorded as a system dependency, spelled the
            # way a link line names it, rather than dropped
            for product in jll_lib_products
                if Sys.islinux(target_platform)
                    @test "c" ∈ product.system_deps
                else
                    @test "System" ∈ product.system_deps
                end
                @test all(!contains(d, ".so") && !contains(d, ".dylib") for d in product.system_deps)
            end


            # Next, do a build where we pretend to be from two different JLLs:
            rm(joinpath(prefix, "lib"); recursive=true, force=true)
            mkpath(joinpath(prefix, "lib"))
            with_toolchains([toolchain]) do _, env
                run(setenv(`$(env["CC"]) -o $(libplus_path) -shared $(libplus_c_path) $(soname_flag(target_platform, libplus_soname))`, env))
                symlink(libplus_soname, joinpath(prefix, "lib", "libplus$(dlext(platform))"))
                run(setenv(`$(env["CC"]) -o $(libmult_path) -shared $(libmult_c_path) -L $(prefix)/lib -lplus`, env))
            end
            scan = scan_files(
                prefix,
                target_platform,
                [LibraryProduct("libmult", :libmult)],
            )
            result = AuditResult(scan)
            ensure_sonames!(result)

            jll_lib_products = resolve_dynamic_links!(result, AuditInfo(Dict(
                    :LibPlus_jll => AuditDependencyInfo([
                        JLLLibraryProduct(
                            :libplus,
                            joinpath("lib", libplus_soname),
                            [], [],
                        ),
                    ]),
                )),
            ).jll_lib_products
            @test success(result.pass_results)
            @test length(jll_lib_products) == 1
            @test jll_lib_products[1].varname == :libmult
            @test jll_lib_products[1].path == joinpath("lib", libmult_soname)
            @test length(jll_lib_products[1].deps) == 1
            @test jll_lib_products[1].deps[1].mod == :LibPlus_jll
            @test jll_lib_products[1].deps[1].varname == :libplus
        end
    end

    @testset "update_linkage - $(triplet(target_platform))" begin
        mktempdir() do prefix
            mkpath(joinpath(prefix, "lib"))
            libplus_path = joinpath(prefix, "lib", libplus_soname)
            libmult_path = joinpath(prefix, "lib", libmult_soname)

            # The unversioned name, the way `libplus` is first built and `libmult` links to it
            libplus_linkname = "libplus$(dlext(platform))"
            if Sys.isapple(target_platform)
                libplus_linkname_id = "@rpath/$(libplus_linkname)"
                libplus_soname_id = "@rpath/$(libplus_soname)"
            else
                libplus_linkname_id = libplus_linkname
                libplus_soname_id = libplus_soname
            end

            # Build `libplus` with an unversioned SONAME and link `libmult` against it,
            # then rebuild `libplus` with its real, versioned SONAME.  This leaves
            # `libmult` depending on `libplus` through the `libplus.so` symlink,
            # which is the linkage `update_linkage!()` must rewrite.
            with_toolchains([toolchain]) do _, env
                run(setenv(`$(env["CC"]) -o $(libplus_path) -shared $(libplus_c_path) $(soname_flag(target_platform, libplus_linkname_id))`, env))
                symlink(libplus_soname, joinpath(prefix, "lib", libplus_linkname))
                run(setenv(`$(env["CC"]) -o $(libmult_path) -shared $(libmult_c_path) -L $(prefix)/lib -lplus $(soname_flag(target_platform, libmult_soname))`, env))
                run(setenv(`$(env["CC"]) -o $(libplus_path) -shared $(libplus_c_path) $(soname_flag(target_platform, libplus_soname_id))`, env))
            end

            function libmult_deps()
                return readmeta(libmult_path) do ohs
                    return [path(dl) for dl in DynamicLinks(only(ohs))]
                end
            end
            @test libplus_linkname_id ∈ libmult_deps()

            # Make `libmult` read-only, to ensure that the rewrite can still happen
            chmod(libmult_path, 0o555)

            scan = scan_files(
                prefix,
                target_platform,
                [
                    LibraryProduct("libplus", :libplus),
                    LibraryProduct("libmult", :libmult),
                ],
            )
            @test scan.soname_forwards[libplus_linkname] == libplus_soname
            result = AuditResult(scan)
            ensure_sonames!(result)
            jll_lib_products = resolve_dynamic_links!(result, AuditInfo()).jll_lib_products
            @test success(result.pass_results)

            # The linkage was rewritten, and reported as such
            update_results = result.pass_results["update_linkage!"]
            @test only(update_results).status == :success
            @test only(update_results).identifier == joinpath("lib", libmult_soname)
            @test libplus_soname_id ∈ libmult_deps()
            @test libplus_linkname_id ∉ libmult_deps()

            # The scan's object handle was refreshed to see the rewritten linkage
            @test libplus_soname_id ∈ [path(dl) for dl in DynamicLinks(scan.binary_objects[joinpath("lib", libmult_soname)])]

            # The file permissions were restored
            @test !Sys.iswritable(libmult_path)

            # The dependency was resolved to `libplus` all the same
            libmult = only(p for p in jll_lib_products if p.varname == :libmult)
            @test libmult.deps == [JLLLibraryDep(nothing, :libplus)]

            # Running it again has nothing left to rewrite
            scan = scan_files(
                prefix,
                target_platform,
                [
                    LibraryProduct("libplus", :libplus),
                    LibraryProduct("libmult", :libmult),
                ],
            )
            result = AuditResult(scan)
            ensure_sonames!(result)
            resolve_dynamic_links!(result, AuditInfo())
            @test success(result.pass_results)
            @test !haskey(result.pass_results, "update_linkage!")
        end
    end

    @testset "rpaths_consistent - $(triplet(target_platform))" begin
        mktempdir() do prefix
            mkpath(joinpath(prefix, "lib", "plus"))

            # First, build `libplus` in `lib/plus/libplus.so`, then link `libmult` against it
            # with no RPATH set.  Let's ensure that `rpaths_consistent!()` adds the appropriate RPATH...
            libplus_path = joinpath(prefix, "lib", "plus", libplus_soname)
            libmult_path = joinpath(prefix, "lib", libmult_soname)
            with_toolchains([toolchain]) do _, env
                run(setenv(`$(env["CC"]) -o $(libplus_path) -shared $(libplus_c_path)`, env))
                symlink(libplus_soname, joinpath(prefix, "lib", "plus", "libplus$(dlext(platform))"))
                run(setenv(`$(env["CC"]) -o $(libmult_path) -shared $(libmult_c_path) -L $(prefix)/lib/plus -lplus`, env))
            end

            function run_scan_and_rpaths()
                scan = scan_files(prefix, target_platform, [LibraryProduct("lib/plus/libplus", :libplus)])
                result = AuditResult(scan)
                ensure_sonames!(result)
                jll_lib_products = resolve_dynamic_links!(result, AuditInfo()).jll_lib_products
                rpaths_consistent!(result, AuditInfo())
                @test success(result.pass_results)
            end
            run_scan_and_rpaths()

            readmeta(libmult_path) do ohs
                if Sys.isapple(target_platform)
                    true_rpath = "@loader_path/plus"
                else
                    true_rpath = "\$ORIGIN/plus"
                end
                @test only(rpaths(RPath(only(ohs)))) == true_rpath
            end

            # Next, tweak `libmult` to have an extra empty rpath entry, and ensure that it gets removed:
            # This doesn't work on macOS, `ldd` apparently doesn't know what to do with an empty rpath.
            if Sys.islinux(target_platform)
                with_toolchains([toolchain]) do _, env
                    run(setenv(`$(env["CC"]) -o $(libmult_path) -shared $(libmult_c_path) -L $(prefix)/lib/plus -lplus -Wl,-rpath,`, env))
                end

                readmeta(libmult_path) do ohs
                    @test any(isempty.(rpaths(RPath(only(ohs)))))
                end

                run_scan_and_rpaths()
                readmeta(libmult_path) do ohs
                    @test only(rpaths(RPath(only(ohs)))) == "\$ORIGIN/plus"
                end
            end
        end
    end

    @testset "rpaths_consistent with hard links - $(triplet(target_platform))" begin
        mktempdir() do prefix
            # Build an executable linked against `libplus`, then install it under two more
            # names, as hard links: one beside it and one in a deeper directory, the way
            # binutils installs `bin/ld`, `bin/ld.bfd` and `<target>/bin/ld`.
            mkpath(joinpath(prefix, "lib"))
            mkpath(joinpath(prefix, "bin"))
            mkpath(joinpath(prefix, "target", "bin"))
            libplus_path = joinpath(prefix, "lib", libplus_soname)
            main_c_path = joinpath(prefix, "main.c")
            write(main_c_path, "int plus(int, int);\nint main() { return plus(1, -1); }\n")
            tool_path = joinpath(prefix, "bin", "tool")
            with_toolchains([toolchain]) do _, env
                run(setenv(`$(env["CC"]) -o $(libplus_path) -shared $(libplus_c_path) $(soname_flag(target_platform, libplus_soname))`, env))
                symlink(libplus_soname, joinpath(prefix, "lib", "libplus$(dlext(platform))"))
                run(setenv(`$(env["CC"]) -o $(tool_path) $(main_c_path) -L $(prefix)/lib -lplus`, env))
            end
            rm(main_c_path)
            hardlink(tool_path, joinpath(prefix, "bin", "tool.alias"))
            hardlink(tool_path, joinpath(prefix, "target", "bin", "tool"))

            scan = scan_files(prefix, target_platform, [LibraryProduct("libplus", :libplus)])
            pass_results = Dict{String,Vector{PassResult}}()
            ensure_sonames!(scan, pass_results)
            resolve_dynamic_links!(scan, pass_results, Dict{Symbol,Vector{JLLLibraryProduct}}())
            rpaths_consistent!(scan, pass_results, Dict{Symbol,Vector{JLLLibraryProduct}}())
            @test success(pass_results)

            # Every name gets the RPATHs that every name needs
            origin = Sys.isapple(target_platform) ? "@loader_path" : "\$ORIGIN"
            for name in ("bin/tool", "bin/tool.alias", "target/bin/tool")
                readmeta(joinpath(prefix, name)) do ohs
                    @test Set(rpaths(RPath(only(ohs)))) == Set(["$(origin)/../lib", "$(origin)/../../lib"])
                end
                # ... and the scan's handles were refreshed
                @test Set(rpaths(RPath(scan.binary_objects[name]))) == Set(["$(origin)/../lib", "$(origin)/../../lib"])
            end
        end
    end
end

@testset "own libraries are never system dependencies" begin
    # `libgcc_s` is on the system-library list, but a JLL such as
    # CompilerSupportLibraries ships it itself.  A library we ship is a real
    # dependency edge, not a system dependency, however much it looks like one.
    target_platform = Platform("x86_64", "linux")
    platform = CrossPlatform(BBHostPlatform() => target_platform)
    toolchain = CToolchain(platform; use_ccache=false)
    libplus_c_path = joinpath(dirname(@__DIR__), "source", "libplus.c")
    libmult_c_path = joinpath(dirname(@__DIR__), "source", "libmult.c")
    libmult_soname = versioned_shlib("libmult", 2, target_platform)

    mktempdir() do prefix
        libdir = joinpath(prefix, "lib")
        mkpath(libdir)
        with_toolchains([toolchain]) do _, env
            # Ship a library that looks, by SONAME, exactly like a system library
            run(setenv(`$(env["CC"]) -o $(joinpath(libdir, "libgcc_s.so.1")) -shared $(libplus_c_path) -Wl,-soname,libgcc_s.so.1`, env))
            run(setenv(`$(env["CC"]) -o $(joinpath(libdir, libmult_soname)) -shared $(libmult_c_path) -L $(libdir) -l:libgcc_s.so.1 $(soname_flag(target_platform, libmult_soname))`, env))
        end

        scan = scan_files(prefix, target_platform, [
            LibraryProduct("lib/libgcc_s.so.1", :libgcc_s),
            LibraryProduct("libmult", :libmult),
        ])
        result = AuditResult(scan)
        ensure_sonames!(result)
        jll_lib_products = resolve_dynamic_links!(result, AuditInfo()).jll_lib_products
        @test success(result.pass_results)
        libmult = only(p for p in jll_lib_products if p.varname == :libmult)
        # The edge is recorded as a real dependency...
        @test JLLLibraryDep(nothing, :libgcc_s) ∈ libmult.deps
        # ... and is *not* reported as a system library
        @test "gcc_s" ∉ libmult.system_deps
        # The C runtime is still a system dependency
        @test "c" ∈ libmult.system_deps
    end
end
