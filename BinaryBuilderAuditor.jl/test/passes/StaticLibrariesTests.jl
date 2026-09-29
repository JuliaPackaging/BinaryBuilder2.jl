using Test, BinaryBuilderAuditor, BinaryBuilderProducts, JLLGenerator, BinaryBuilderToolchains, Base.BinaryPlatforms
using BinaryBuilderAuditor: resolve_static_libraries!
using JLLGenerator: generate_toml_dict

# The emitter describes each declared archive from its recipe and its dynamic
# variant, then checks the archive's own contents against that description.
@testset "static library records" begin
    target_platform = Platform("x86_64", "linux")
    platform = CrossPlatform(BBHostPlatform() => target_platform)
    toolchain = CToolchain(platform; use_ccache=false)
    source_dir = joinpath(dirname(@__DIR__), "source")
    libplus_soname = versioned_shlib("libplus", 1, target_platform)
    libmult_soname = versioned_shlib("libmult", 2, target_platform)

    # Build each library both ways, from the same objects.  `libplus` also carries an
    # object calling into libc, so that its closure is checked against symbols the
    # shared library records with a version suffix; with `with_extra`, `libmult`'s
    # archive additionally carries an object referencing a symbol nothing provides.
    function build_prefix(prefix; with_extra::Bool = false)
        libdir = joinpath(prefix, "lib")
        mkpath(libdir)
        with_toolchains([toolchain]) do _, env
            ar = get(env, "AR", "ar")
            compile(name) = begin
                obj = joinpath(libdir, "$(name).o")
                run(setenv(`$(env["CC"]) -c -o $(obj) -fPIC $(joinpath(source_dir, "$(name).c"))`, env))
                return obj
            end
            plus_o, alloc_o, mult_o, extra_o = compile.(("libplus", "liballoc", "libmult", "libextra"))
            run(setenv(`$(env["CC"]) -o $(joinpath(libdir, libplus_soname)) -shared $(plus_o) $(alloc_o) $(soname_flag(target_platform, libplus_soname))`, env))
            run(setenv(`$(ar) rcs $(joinpath(libdir, "libplus.a")) $(plus_o) $(alloc_o)`, env))
            run(setenv(`$(env["CC"]) -o $(joinpath(libdir, libmult_soname)) -shared $(mult_o) -L $(libdir) -l:$(libplus_soname) $(soname_flag(target_platform, libmult_soname))`, env))
            mult_members = with_extra ? [mult_o, extra_o] : [mult_o]
            run(setenv(`$(ar) rcs $(joinpath(libdir, "libmult.a")) $(mult_members)`, env))
            foreach(rm, (plus_o, alloc_o, mult_o, extra_o))
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
            @test collect(keys(scan.static_library_products)) == ["lib/libplus.a"]
            # The archive carries its library's name, which is how the two are paired
            @test only(values(scan.static_library_products)).varname == :libplus
        end

        @testset "the closure of every archive is checked" begin
            result = run_passes(prefix, [
                LibraryProduct("libplus", :libplus; static = StaticLibraryProduct("libplus")),
                LibraryProduct("libmult", :libmult; static = StaticLibraryProduct("libmult")),
            ])
            @test success(result.pass_results)
            # `libplus.a` calls into libc, which its dynamic variant resolves at link time;
            # `libmult.a` needs `plus`, provided by its inherited dependency
            @test has_status(result, "lib/libplus.a", :success)
            @test has_status(result, "lib/libmult.a", :success)
            @test contains(messages(result, "lib/libmult.a"), "closure verified")
        end

        @testset "a dependency that ships no archive is normal, and noted" begin
            zlib = AuditInfo(Dict(:Zlib_jll => AuditDependencyInfo([JLLLibraryProduct(:libz, "lib/libz.so.1", [], [])])))
            result = run_passes(prefix, [
                LibraryProduct("libplus", :libplus),
                LibraryProduct("libmult", :libmult; static = StaticLibraryProduct("libmult"; deps = [LibraryDependency(:libplus), LibraryDependency(:Zlib_jll, :libz)])),
            ]; info = zlib)
            @test success(result.pass_results)
            @test contains(messages(result, "lib/libmult.a"), "no static library")
        end

        @testset "a dependency's real files are inspected when reachable" begin
            # Pretend `libplus` belongs to another JLL whose artifact is unpacked right here
            plus_libs = AbstractJLLProduct[
                JLLLibraryProduct(:libplus, joinpath("lib", libplus_soname), [], []),
                JLLStaticLibraryProduct(:libplus, "lib/libplus.a"),
            ]
            plus_here = AuditInfo(Dict(:Plus_jll => AuditDependencyInfo(plus_libs; artifact_dir = prefix)))
            plus_away = AuditInfo(Dict(:Plus_jll => AuditDependencyInfo(plus_libs)))
            archive = [StaticLibraryProduct("libmult"; varname = :libmult_a, deps = [LibraryDependency(:Plus_jll, :libplus)], system_deps = ["c"])]
            # With the files reachable, `libmult.a`'s reference to `plus` is verified outright
            result = run_passes(prefix, LibraryProduct[]; static_library_products = archive, info = plus_here)
            @test success(result.pass_results)
            @test has_status(result, "lib/libmult.a", :success) && !has_status(result, "lib/libmult.a", :warn)
            # With the same declaration but the artifact out of reach, the check is
            # inconclusive, and says so rather than failing
            result = run_passes(prefix, LibraryProduct[]; static_library_products = archive, info = plus_away)
            @test has_status(result, "lib/libmult.a", :warn)
            @test contains(messages(result, "lib/libmult.a"), "could not inspect Plus_jll.libplus")
        end

        @testset "a declared archive must exist" begin
            @test_throws ErrorException scan_files(prefix, target_platform, [LibraryProduct("libplus", :libplus; static = StaticLibraryProduct("libnope"))])
        end
    end

    @testset "an archive needing what nothing provides fails the audit" begin
        mktempdir() do prefix
            build_prefix(prefix; with_extra = true)
            result = run_passes(prefix, [
                LibraryProduct("libplus", :libplus; static = StaticLibraryProduct("libplus")),
                LibraryProduct("libmult", :libmult; static = StaticLibraryProduct("libmult")),
            ])
            @test !success(result.pass_results)
            @test has_status(result, "lib/libmult.a", :fail)
            @test contains(messages(result, "lib/libmult.a"), "undefined_extra_symbol")
            # `libplus.a` is still perfectly fine
            @test has_status(result, "lib/libplus.a", :success)
        end
    end
end
