using Test, BinaryBuilderAuditor, BinaryBuilderProducts, JLLGenerator, BinaryBuilderToolchains, Base.BinaryPlatforms
using BinaryBuilderAuditor: resolve_static_libraries!
using JLLGenerator: generate_toml_dict

# The emitter describes each declared archive from its recipe and its dynamic
# variant; nothing is read from the archive itself.
@testset "static library records" begin
    target_platform = Platform("x86_64", "linux")
    platform = CrossPlatform(BBHostPlatform() => target_platform)
    toolchain = CToolchain(platform; use_ccache=false)
    libplus_c_path = joinpath(dirname(@__DIR__), "source", "libplus.c")
    libmult_c_path = joinpath(dirname(@__DIR__), "source", "libmult.c")
    libplus_soname = versioned_shlib("libplus", 1, target_platform)
    libmult_soname = versioned_shlib("libmult", 2, target_platform)

    # Build each library both ways, from the same objects
    function build_prefix(prefix)
        libdir = joinpath(prefix, "lib")
        mkpath(libdir)
        with_toolchains([toolchain]) do _, env
            ar = get(env, "AR", "ar")
            for (name, src, soname, extra) in (("libplus", libplus_c_path, libplus_soname, ``),
                                                ("libmult", libmult_c_path, libmult_soname, `-L $(libdir) -l:$(libplus_soname)`))
                run(setenv(`$(env["CC"]) -o $(joinpath(libdir, soname)) -shared $(src) $(extra) $(soname_flag(target_platform, soname))`, env))
                run(setenv(`$(env["CC"]) -c -o $(joinpath(libdir, "$(name).o")) $(src)`, env))
                run(setenv(`$(ar) rcs $(joinpath(libdir, "$(name).a")) $(joinpath(libdir, "$(name).o"))`, env))
                rm(joinpath(libdir, "$(name).o"))
            end
            symlink(joinpath(libdir, libplus_soname), joinpath(libdir, "libplus$(dlext(target_platform))"))
        end
    end

    # Run the dynamic and static passes, returning the filled-in result
    function run_passes(prefix, library_products; static_library_products = StaticLibraryProduct[],
                        info = AuditInfo())
        scan = scan_files(prefix, target_platform, AbstractProduct[library_products..., static_library_products...])
        result = AuditResult(scan)
        ensure_sonames!(result)
        resolve_dynamic_links!(result, info)
        resolve_static_libraries!(result, info)
        return result
    end
    function emit(prefix, library_products; kwargs...)
        result = run_passes(prefix, library_products; kwargs...)
        @test success(result.pass_results)
        return result.jll_lib_products
    end
    results_for(result, rel_path) = [r for r in get(result.pass_results, "resolve_static_libraries!", PassResult[]) if r.identifier == rel_path]
    has_status(result, rel_path, status) = any(r.status == status for r in results_for(result, rel_path))
    messages(result, rel_path) = join([something(r.message, "") for r in results_for(result, rel_path)], "\n")
    static_entries(products) = filter(p -> isa(p, JLLStaticLibraryProduct), products)
    entry(products, varname) = only(p for p in static_entries(products) if p.varname == varname)

    mktempdir() do prefix
        build_prefix(prefix)

        @testset "inherit from the dynamic variant" begin
            products = emit(prefix, [
                LibraryProduct("libplus", :libplus; static = StaticLibraryProduct("libplus")),
                LibraryProduct("libmult", :libmult; static = StaticLibraryProduct("libmult")),
            ])
            # One library, once per linkage, loadable entry first
            @test [(p.varname, isa(p, JLLStaticLibraryProduct)) for p in products] ==
                  [(:libmult, false), (:libmult, true), (:libplus, false), (:libplus, true)]
            libplus = entry(products, :libplus)
            @test libplus.path == "lib/libplus.a"
            @test isempty(libplus.deps)
            @test libplus.system_deps == ["c"]
            libmult = entry(products, :libmult)
            @test libmult.deps == [JLLLibraryDep(nothing, :libplus)]
            @test libmult.system_deps == ["c"]
            # The dynamic variant's record is untouched by the archive
            dynamic = only(p for p in products if isa(p, JLLLibraryProduct) && p.varname == :libmult)
            @test dynamic.deps == [JLLLibraryDep(nothing, :libplus)]
            @test dynamic.system_deps == ["c"]
            # Record shape
            d = generate_toml_dict(libmult)
            @test d["type"] == "library" && d["linkage"] == "static" && d["path"] == "lib/libmult.a"
            @test d["deps"] == ["libplus"] && d["system_deps"] == ["c"]
        end

        @testset "explicit lists replace" begin
            products = emit(prefix, [
                LibraryProduct("libplus", :libplus; static = StaticLibraryProduct("libplus"; system_deps = ["c", "m"])),
                LibraryProduct("libmult", :libmult; static = StaticLibraryProduct("libmult"; deps = [LibraryDependency(:libplus)], system_deps = ["c", "pthread"])),
            ])
            @test entry(products, :libplus).system_deps == ["c", "m"]
            libmult = entry(products, :libmult)
            @test libmult.deps == [JLLLibraryDep(nothing, :libplus)]
            @test libmult.system_deps == ["c", "pthread"]
        end

        @testset "replacement that drops an inherited entry is pointed out" begin
            products = @test_logs (:warn, r"system dependencies of 'lib/libmult\.a'.*: c") match_mode=:any emit(prefix, [
                LibraryProduct("libplus", :libplus),
                LibraryProduct("libmult", :libmult; static = StaticLibraryProduct("libmult"; system_deps = ["m"])),
            ])
            # The declaration wins, and the audit still passes
            @test entry(products, :libmult).system_deps == ["m"]
            @test entry(products, :libmult).deps == [JLLLibraryDep(nothing, :libplus)]
            # A dropped dependency edge is pointed out just the same
            products = @test_logs (:warn, r"^Declared dependencies of 'lib/libmult\.a'.*: libplus") match_mode=:any emit(prefix, [
                LibraryProduct("libplus", :libplus),
                LibraryProduct("libmult", :libmult; static = StaticLibraryProduct("libmult"; deps = LibraryDependency[])),
            ])
            @test isempty(entry(products, :libmult).deps)
        end

        @testset "standalone archives" begin
            # A declared edge is recorded as declared: naming a package, or none for
            # a library of this JLL
            products = emit(prefix, [LibraryProduct("libplus", :libplus)];
                            static_library_products = [StaticLibraryProduct("libmult"; varname = :libmult_a,
                                deps = [LibraryDependency(:libplus), LibraryDependency(:Foo_jll, :libfoo)], system_deps = ["c"])],
                            info = AuditInfo(Dict(:Foo_jll => AuditDependencyInfo([JLLLibraryProduct(:libfoo, "lib/libfoo.so.1", [], [])]))))
            @test [(p.varname, isa(p, JLLStaticLibraryProduct)) for p in products] == [(:libmult_a, true), (:libplus, false)]
            libmult_a = entry(products, :libmult_a)
            @test libmult_a.path == "lib/libmult.a"
            @test libmult_a.deps == [JLLLibraryDep(nothing, :libplus), JLLLibraryDep(:Foo_jll, :libfoo)]
            @test libmult_a.system_deps == ["c"]
        end

        @testset "standalone archives cannot inherit" begin
            scan = scan_files(prefix, target_platform, AbstractProduct[LibraryProduct("libplus", :libplus),
                              StaticLibraryProduct("libmult"; varname = :libmult_a, deps = [LibraryDependency(:libplus)])])
            result = AuditResult(scan)
            ensure_sonames!(result)
            resolve_dynamic_links!(result, AuditInfo())
            resolve_static_libraries!(result, AuditInfo())
            @test !success(result.pass_results)
            failure = only(result.pass_results["resolve_static_libraries!"])
            @test failure.status == :fail && failure.identifier == "lib/libmult.a"
            # ... and no record is written for it
            @test isempty(static_entries(result.jll_lib_products))
        end

        @testset "declared edges must name a library that exists" begin
            # A library of this build may be a standalone archive
            result = run_passes(prefix, [LibraryProduct("libplus", :libplus)];
                                static_library_products = [
                                    StaticLibraryProduct("libplus"; varname = :libplus_a, deps = LibraryDependency[], system_deps = ["c"]),
                                    StaticLibraryProduct("libmult"; varname = :libmult_a, deps = [LibraryDependency(:libplus_a)], system_deps = ["c"]),
                                ])
            @test !has_status(result, "lib/libmult.a", :fail)
            @test entry(result.jll_lib_products, :libmult_a).deps == [JLLLibraryDep(nothing, :libplus_a)]
            # A library this build does not provide
            result = run_passes(prefix, [
                LibraryProduct("libplus", :libplus),
                LibraryProduct("libmult", :libmult; static = StaticLibraryProduct("libmult"; deps = [LibraryDependency(:libnope)])),
            ])
            @test has_status(result, "lib/libmult.a", :fail)
            @test contains(messages(result, "lib/libmult.a"), "does not name any library product of this build")
            # The edge is still recorded as declared
            @test entry(result.jll_lib_products, :libmult).deps == [JLLLibraryDep(nothing, :libnope)]
            # A JLL this build does not depend on, including the JLL being built, whose
            # libraries are named without a package
            for pkg in (:Nope_jll, :Foo_jll)
                result = run_passes(prefix, [
                    LibraryProduct("libplus", :libplus),
                    LibraryProduct("libmult", :libmult; static = StaticLibraryProduct("libmult"; deps = [LibraryDependency(pkg, :libplus)])),
                ])
                @test has_status(result, "lib/libmult.a", :fail)
                @test contains(messages(result, "lib/libmult.a"), "'$(pkg)', which is not a dependency of this build")
            end
            # A library that dependency does not provide
            zlib = AuditInfo(Dict(:Zlib_jll => AuditDependencyInfo([JLLLibraryProduct(:libz, "lib/libz.so.1", [], [])])))
            result = run_passes(prefix, [
                LibraryProduct("libplus", :libplus),
                LibraryProduct("libmult", :libmult; static = StaticLibraryProduct("libmult"; deps = [LibraryDependency(:Zlib_jll, :libwrong)])),
            ]; info = zlib)
            @test has_status(result, "lib/libmult.a", :fail)
            @test contains(messages(result, "lib/libmult.a"), "does not name a library product of 'Zlib_jll' (it provides: libz)")
            # ... and one it does
            products = emit(prefix, [
                LibraryProduct("libplus", :libplus),
                LibraryProduct("libmult", :libmult; static = StaticLibraryProduct("libmult"; deps = [LibraryDependency(:libplus), LibraryDependency(:Zlib_jll, :libz)])),
            ]; info = zlib)
            @test entry(products, :libmult).deps == [JLLLibraryDep(nothing, :libplus), JLLLibraryDep(:Zlib_jll, :libz)]
        end

        @testset "archives stay out of the dynamic passes" begin
            scan = scan_files(prefix, target_platform, [LibraryProduct("libplus", :libplus; static = StaticLibraryProduct("libplus"))])
            @test "lib/libplus.a" ∉ keys(scan.binary_objects)
            # Archives are found by their contents, declared or not
            @test scan.static_libraries == Set(["lib/libplus.a", "lib/libmult.a"])
            @test collect(keys(scan.static_library_products)) == ["lib/libplus.a"]
            # The archive carries its library's name, which is how the two are paired
            @test only(values(scan.static_library_products)).varname == :libplus
        end

        @testset "a declared archive must exist" begin
            @test_throws ErrorException scan_files(prefix, target_platform, [LibraryProduct("libplus", :libplus; static = StaticLibraryProduct("libnope"))])
        end

        @testset "a declared archive must be an archive" begin
            write(joinpath(prefix, "lib", "libfake.a"), "not an archive\n")
            @test_throws ErrorException scan_files(prefix, target_platform, [StaticLibraryProduct("libfake"; varname = :libfake)])
            rm(joinpath(prefix, "lib", "libfake.a"))
        end
    end
end
