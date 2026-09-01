using BinaryBuilderProducts, Test, BinaryBuilderSources, JLLGenerator
using JLLGenerator: rtld_symbols, rtld_flags
using BinaryBuilderProducts: inherits_deps, declared_deps, resolve_deps, canonicalize_static_dep_spec

# Little helper to build a canonicalized declaration the way the constructor would
declared_of(spec) = canonicalize_static_dep_spec(spec, "deps", nothing)

@testset "BinaryBuilderProducts" begin
    function test_xz_products(dir, as, env; kwargs...)
        # Download and unpack that JLL build, then define a set of products on it:
        prepare(as)
        deploy(as, dir)

        # We're going to generate a whole bunch of products based on these three values
        true_products = [
            (ExecutableProduct, "\${bindir}/xzdec", :xzdec),
            (LibraryProduct, "\${shlibdir}/liblzma", :liblzma),
            # Also test that if someone puts a `dlext` at the end, it still works
            (LibraryProduct, "\${shlibdir}/liblzma.\${dlext}", :liblzma),
            (FileProduct, "\${libdir}/liblzma.a", :liblzma_a),
        ]

        test_products = Pair{AbstractProduct,Bool}[]
        for (ProductType, path, varname) in true_products
            # Test a single value, which should get expanded into a vector automatically
            push!(test_products, ProductType(path, varname) => true)

            # Test a vector with a bad first element
            bad_path = "$(path)_bad"
            push!(test_products, ProductType([bad_path, path], Symbol("$(varname)_bad")) => true)

            # Test default product directory guessing (This only works because the
            # Executable and Library products of our test JLL are in the standard dirs)
            if ProductType ∈ (ExecutableProduct, LibraryProduct)
                push!(test_products, ProductType(basename(path), varname) => true)
            end

            # Test a failing path
            push!(test_products, ProductType(bad_path, Symbol("$(varname)_bad")) => false)
        end

        # Ensure that for each product, we correctly locate or not
        for (product, pass) in test_products
            product_subpath = locate(product, dir; env, kwargs...)
            if (product_subpath !== nothing) != pass
                if pass
                    @error("Unable to locate $(product.varname)", dir, product.paths)
                else
                    @error("Located $(product.varname)", dir, product.paths)
                end
            end
            @test (product_subpath !== nothing) == pass
            if product_subpath !== nothing
                @test isfile(joinpath(dir, product_subpath))
            end

            # Ensure that we can create a JLLProduct from this:
            if pass
                @test JLLGenerator.AbstractJLLProduct(product, dir; env, kwargs...) !== nothing
            end
        end

        # Static archives live in `libdir` on every platform, and can be found with
        # or without their extension, or with an explicit directory.
        for path in ("\${libdir}/liblzma.a", "\${libdir}/liblzma", "liblzma", "liblzma.a")
            slp = StaticLibraryProduct(path)
            located = locate(slp, dir; env, kwargs...)
            @test located !== nothing
            @test isfile(joinpath(dir, located))
            @test basename(located) == "liblzma.a"
        end
        @test locate(StaticLibraryProduct("libnope"), dir; env, kwargs...) === nothing

    end

    # We'll test with the `XZ_jll` tarball, which contains three of our products
    artifacts_downloads = Dict(
        "x86_64-linux-gnu" => ArchiveSource(
            "https://github.com/JuliaBinaryWrappers/XZ_jll.jl/releases/download/XZ-v5.4.3%2B1/XZ.v5.4.3.x86_64-linux-gnu.tar.gz",
            "70a053a45c76811bbb475aa43e0e0781c9e972d2fb57b67d35aa32a30de90336",
        ),
        "x86_64-w64-mingw32" => ArchiveSource(
            "https://github.com/JuliaBinaryWrappers/XZ_jll.jl/releases/download/XZ-v5.4.3%2B1/XZ.v5.4.3.x86_64-w64-mingw32.tar.gz",
            "3f05d8023b1776315c1761a67f87611859e9c8e9b2bd598592133d7d979f8e3e",
        ),
        "aarch64-apple-darwin" => ArchiveSource(
            "https://github.com/JuliaBinaryWrappers/XZ_jll.jl/releases/download/XZ-v5.4.3%2B1/XZ.v5.4.3.aarch64-apple-darwin.tar.gz",
            "93b6890109b5dc9e6e022888cef5e8d3180a4ea0eae3ceab1ce6f247b5fbc66c",
        ),
    )
    function dlext(triplet::String)
        if endswith(triplet, "-gnu")
            return "so"
        elseif endswith(triplet, "-mingw32")
            return "dll"
        elseif endswith(triplet, "-darwin")
            return "dylib"
        else
            error("Unrecognized triplet '$(triplet)' for our little `dlext()` mockup")
        end
    end
    for (target, as) in artifacts_downloads
        @testset "$(target)" begin
            env = Dict(
                "prefix" => "/prefix",
                "bindir" => "/prefix/bin",
                "libdir" => "/prefix/lib",
                "shlibdir" => contains(target, "mingw32") ? "/prefix/bin" : "/prefix/lib",
                "dlext" => dlext(target),
                "bb_full_target" => target,
            )
            mktempdir() do dir
                test_xz_products(dir, as, env)

                # Do a test where `bb_full_target` is wrong, but we pass the right platform in to `locate()`:
                env["bb_full_target"] = "any"
                test_xz_products(dir, as, env; platform=parse(Platform, target))
            end
        end
    end

    @testset "StaticLibraryProduct construction" begin
        # Subordinate products carry no identity of their own, and inherit by default
        subordinate = StaticLibraryProduct("libfoo")
        @test subordinate.varname === nothing
        @test subordinate.deps === :inherit
        @test subordinate.system_deps === :inherit
        @test LibraryProduct("libfoo", :libfoo; static=subordinate).static === subordinate

        # ... and are refused if they try to name themselves
        @test_throws ArgumentError LibraryProduct("libfoo", :libfoo;
            static=StaticLibraryProduct("libfoo"; varname=:libfoo_a, deps=String[]))

        # Standalone products must declare their dependencies explicitly, as there is
        # no dynamic sibling for them to inherit from.
        @test_throws ArgumentError StaticLibraryProduct("libfoo"; varname=:libfoo_a)
        @test_throws ArgumentError StaticLibraryProduct("libfoo"; varname=:libfoo_a, deps=String[],
                                                        system_deps=:inherit)
        @test_throws ArgumentError StaticLibraryProduct("libfoo"; varname=:libfoo_a,
                                                        deps=[:inherit, "libbar"])
        standalone = StaticLibraryProduct("libfoo"; varname=:libfoo_a, deps=["Bar_jll.libbar"],
                                          system_deps=["m"])
        @test standalone.varname == :libfoo_a
        @test declared_deps(standalone.deps) == ["Bar_jll.libbar"]
        @test !inherits_deps(standalone.deps)

        # Only the `:inherit` sentinel is understood, and only once
        @test_throws ArgumentError StaticLibraryProduct("libfoo"; deps=:audit)
        @test_throws ArgumentError StaticLibraryProduct("libfoo"; deps=[:audit])
        @test_throws ArgumentError StaticLibraryProduct("libfoo"; deps=[:inherit, :inherit])
        @test_throws ArgumentError StaticLibraryProduct("libfoo"; deps=[1])
        @test_throws ArgumentError StaticLibraryProduct("libfoo"; system_deps=17)

        # The three spellings of a dependency declaration
        inherited = ["libgcc_s", "CSL_jll.libquadmath"]
        @test resolve_deps(:inherit, inherited) == (inherited, String[])
        @test resolve_deps(declared_of(["libgcc_s"]), inherited) ==
            (["libgcc_s"], ["CSL_jll.libquadmath"])
        @test resolve_deps(declared_of([:inherit, "Zlib_jll.libz"]), inherited) ==
            (vcat(inherited, "Zlib_jll.libz"), String[])
        # Augmenting with something already inherited is not a duplicate
        @test resolve_deps(declared_of([:inherit, "libgcc_s"]), inherited) == (inherited, String[])
    end
end
