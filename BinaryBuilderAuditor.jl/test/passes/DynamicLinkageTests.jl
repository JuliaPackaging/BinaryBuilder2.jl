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
            pass_results = Dict{String,Vector{PassResult}}()
            ensure_sonames!(scan, pass_results)
            @test success(pass_results)

            # First, resolve dynamic links when these are two librares in the same build:
            jll_lib_products = resolve_dynamic_links!(
                scan,
                pass_results,
                Dict{Symbol,Vector{JLLLibraryProduct}}(),
            )
            @test success(pass_results)

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
            pass_results = Dict{String,Vector{PassResult}}()
            ensure_sonames!(scan, pass_results)

            jll_lib_products = resolve_dynamic_links!(
                scan,
                pass_results,
                Dict{Symbol,Vector{JLLLibraryProduct}}(
                    :LibPlus => [
                        JLLLibraryProduct(
                            :libplus,
                            joinpath("lib", libplus_soname),
                            [], [],
                        ),
                    ]
                ),
            )
            @test success(pass_results)
            @test length(jll_lib_products) == 1
            @test jll_lib_products[1].varname == :libmult
            @test jll_lib_products[1].path == joinpath("lib", libmult_soname)
            @test length(jll_lib_products[1].deps) == 1
            @test jll_lib_products[1].deps[1].mod == :LibPlus_jll
            @test jll_lib_products[1].deps[1].varname == :libplus
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
                pass_results = Dict{String,Vector{PassResult}}()
                ensure_sonames!(scan, pass_results)
                jll_lib_products = resolve_dynamic_links!(
                    scan,
                    pass_results,
                    Dict{Symbol,Vector{JLLLibraryProduct}}(),
                )
                rpaths_consistent!(scan, pass_results, Dict{Symbol,Vector{JLLLibraryProduct}}())
                @test success(pass_results)
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
        pass_results = Dict{String,Vector{PassResult}}()
        ensure_sonames!(scan, pass_results)
        jll_lib_products = resolve_dynamic_links!(scan, pass_results,
                                                  Dict{Symbol,Vector{JLLLibraryProduct}}())
        @test success(pass_results)
        libmult = only(p for p in jll_lib_products if p.varname == :libmult)
        # The edge is recorded as a real dependency...
        @test JLLLibraryDep(nothing, :libgcc_s) ∈ libmult.deps
        # ... and is *not* reported as a system library
        @test "gcc_s" ∉ libmult.system_deps
        # The C runtime is still a system dependency
        @test "c" ∈ libmult.system_deps
    end
end
