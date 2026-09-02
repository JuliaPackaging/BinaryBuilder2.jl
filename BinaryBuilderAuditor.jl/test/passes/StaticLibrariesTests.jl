using Test, BinaryBuilderAuditor, BinaryBuilderProducts, JLLGenerator, BinaryBuilderToolchains, Base.BinaryPlatforms
using BinaryBuilderAuditor: resolve_static_libraries!
using JLLGenerator: generate_toml_dict

# The emitter describes each declared archive from its recipe and its dynamic
# sibling; nothing is read from the archive itself.
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

    function emit(prefix, library_products; static_library_products = StaticLibraryProduct[])
        scan = scan_files(prefix, target_platform, library_products; static_library_products)
        pass_results = Dict{String,Vector{PassResult}}()
        ensure_sonames!(scan, pass_results)
        products = resolve_dynamic_links!(scan, pass_results, Dict{Symbol,Vector{JLLLibraryProduct}}())
        products = resolve_static_libraries!(scan, pass_results, products)
        @test success(pass_results)
        return products
    end
    static_entries(products) = filter(p -> isa(p, JLLStaticLibraryProduct), products)
    entry(products, varname) = only(p for p in static_entries(products) if p.varname == varname)

    mktempdir() do prefix
        build_prefix(prefix)

        @testset "inherit from the dynamic sibling" begin
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
            # Nothing is read from the archive, so no initializer roots are known
            @test isempty(libplus.roots) && isempty(libmult.roots)
            # The sibling's record is untouched by the archive
            dynamic = only(p for p in products if isa(p, JLLLibraryProduct) && p.varname == :libmult)
            @test dynamic.deps == [JLLLibraryDep(nothing, :libplus)]
            @test dynamic.system_deps == ["c"]
            # Record shape
            d = generate_toml_dict(libmult)
            @test d["type"] == "library" && d["linkage"] == "static" && d["path"] == "lib/libmult.a"
            @test d["deps"] == ["libplus"] && d["system_deps"] == ["c"] && d["roots"] == String[]
        end

        @testset "augment and replace" begin
            products = emit(prefix, [
                LibraryProduct("libplus", :libplus; static = StaticLibraryProduct("libplus"; system_deps = [:inherit, "m"])),
                LibraryProduct("libmult", :libmult; static = StaticLibraryProduct("libmult"; deps = ["libplus"], system_deps = ["c", "pthread"])),
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
                LibraryProduct("libmult", :libmult; static = StaticLibraryProduct("libmult"; deps = String[])),
            ])
            @test isempty(entry(products, :libmult).deps)
        end

        @testset "standalone archives" begin
            products = emit(prefix, [LibraryProduct("libplus", :libplus)];
                            static_library_products = [StaticLibraryProduct("libmult"; varname = :libmult_a, deps = ["libplus"], system_deps = ["c"])])
            @test [(p.varname, isa(p, JLLStaticLibraryProduct)) for p in products] == [(:libmult_a, true), (:libplus, false)]
            libmult_a = entry(products, :libmult_a)
            @test libmult_a.path == "lib/libmult.a"
            @test libmult_a.deps == [JLLLibraryDep(nothing, :libplus)]
            @test libmult_a.system_deps == ["c"]
        end

        @testset "archives stay out of the dynamic passes" begin
            scan = scan_files(prefix, target_platform, [LibraryProduct("libplus", :libplus; static = StaticLibraryProduct("libplus"))])
            @test "lib/libplus.a" ∉ keys(scan.binary_objects)
            @test scan.static_archives == Dict(:libplus => "lib/libplus.a")
            @test collect(keys(scan.static_library_products)) == ["lib/libplus.a"]
        end

        @testset "a declared archive must exist" begin
            @test_throws ErrorException scan_files(prefix, target_platform, [LibraryProduct("libplus", :libplus; static = StaticLibraryProduct("libnope"))])
        end
    end
end
