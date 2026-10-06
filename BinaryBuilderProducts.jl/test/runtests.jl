using BinaryBuilderProducts, Test, BinaryBuilderSources, JLLGenerator
using JLLGenerator: rtld_symbols, rtld_flags
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
    @testset "exactly-declared paths are authoritative" begin
        # Exact path matches take priority over other sorting / ordering, even
        # for names that would appear to be versioned copies of the same library.
        platform = Platform("x86_64", "macos")
        mktempdir() do dir
            env = Dict(
                "prefix" => dir,
                "libdir" => joinpath(dir, "lib"),
                "bb_full_target" => triplet(platform),
            )
            mkpath(joinpath(dir, "lib"))

            # These libraries have distinct ABI and are shipped together on macOS
            touch(joinpath(dir, "lib", "libgcc_s.1.dylib"))
            touch(joinpath(dir, "lib", "libgcc_s.1.1.dylib"))

            # Both exact declarations bind their exact file
            @test locate(LibraryProduct("lib/libgcc_s.1.dylib", :libgcc_s), dir; env, platform) ==
                joinpath("lib", "libgcc_s.1.dylib")
            @test locate(LibraryProduct("lib/libgcc_s.1.1.dylib", :libgcc_s), dir; env, platform) ==
                joinpath("lib", "libgcc_s.1.1.dylib")

            # A stem declaration still matches by name, version-agnostically
            @test locate(LibraryProduct("lib/libgcc_s", :libgcc_s), dir; env, platform) !== nothing

            # A declared version that does not exist still falls back to matching
            @test locate(LibraryProduct("lib/libgcc_s.2.dylib", :libgcc_s), dir; env, platform) !== nothing
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

    @testset "LibraryDependency" begin
        @test LibraryDependency(:libz).pkg === nothing
        @test LibraryDependency(:libz).varname == :libz
        @test LibraryDependency(:Zlib_jll, :libz) == LibraryDependency("Zlib_jll", "libz")
        @test LibraryDependency(:Zlib_jll, :libz).pkg == :Zlib_jll
    end

    @testset "StaticLibraryProduct construction" begin
        # An archive declared for a `LibraryProduct` has no name of its own until it is
        # attached, inherits by default, and takes the library's name when attached
        subordinate = StaticLibraryProduct("libfoo")
        @test subordinate.varname === nothing
        @test subordinate.deps === nothing
        @test subordinate.system_deps === nothing
        attached = LibraryProduct("libfoo", :libfoo; static=subordinate).static
        @test attached.varname == :libfoo
        @test attached.paths == subordinate.paths && attached.deps === nothing
        # Naming it the same is harmless; naming it differently is a contradiction
        @test LibraryProduct("libfoo", :libfoo; static=StaticLibraryProduct("libfoo"; varname=:libfoo)).static.varname == :libfoo
        @test_throws ArgumentError LibraryProduct("libfoo", :libfoo;
            static=StaticLibraryProduct("libfoo"; varname=:libfoo_a))

        # A standalone product that inherits is only a declaration here; that there is
        # no dynamic variant to inherit from is found out by the auditor, which resolves it.
        @test StaticLibraryProduct("libfoo"; varname=:libfoo_a).deps === nothing
        standalone = StaticLibraryProduct("libfoo"; varname=:libfoo_a,
                                          deps=[LibraryDependency(:Bar_jll, :libbar), LibraryDependency(:libbaz)],
                                          system_deps=["m"])
        @test standalone.varname == :libfoo_a
        @test standalone.deps == [LibraryDependency(:Bar_jll, :libbar), LibraryDependency(:libbaz)]

        # A declaration is `:inherit` or a vector of the right kind, and nothing else; in
        # particular, `:inherit` does not mix with explicit entries
        @test_throws ArgumentError StaticLibraryProduct("libfoo"; deps=:audit)
        # `nothing` is how inheritance is stored, not how it is spelled
        @test_throws ArgumentError StaticLibraryProduct("libfoo"; deps=nothing)
        @test_throws ArgumentError StaticLibraryProduct("libfoo"; deps=[:inherit, LibraryDependency(:libbar)])
        # Edges are declared as `LibraryDependency`, never as spelled-out strings
        @test_throws ArgumentError StaticLibraryProduct("libfoo"; deps=["Bar_jll.libbar"])
        @test_throws ArgumentError StaticLibraryProduct("libfoo"; deps=[1])
        @test_throws ArgumentError StaticLibraryProduct("libfoo"; system_deps=17)
        @test_throws ArgumentError StaticLibraryProduct("libfoo"; system_deps=[LibraryDependency(:libm)])
        @test StaticLibraryProduct("libfoo"; deps=[]).deps == LibraryDependency[]
        @test StaticLibraryProduct("libfoo"; system_deps=["m"]).system_deps == ["m"]
    end

    @testset "LibraryProduct(...; static=:auto)" begin
        using BinaryBuilderProducts: generate_default_static_lib_paths
        # The archive is looked for wherever the dynamic library is, minus any
        # versioned extension, and inherits the library's name and dependencies
        auto = LibraryProduct(["libfoo", "lib/sub/libfoo.so.6"], :libfoo; static=:auto).static
        @test auto.paths == ["libfoo", "lib/sub/libfoo"]
        @test auto.varname == :libfoo
        @test auto.deps === nothing && auto.system_deps === nothing
        @test LibraryProduct("libfoo", :libfoo).static === nothing
        @test_throws ArgumentError LibraryProduct("libfoo", :libfoo; static=:inherit)

        # Every platform's spelling of a dynamic library reduces to the same archive name,
        # and `\${libdir}` (which is `bin` on Windows) gives way to the archive's own `lib`
        @test generate_default_static_lib_paths([
            "libfoo.so.6", "libfoo.6.dylib", "libfoo-6.dll", "libfoo.dll", "\${libdir}/libfoo",
        ]) == ["libfoo"]
        @test generate_default_static_lib_paths(["\${prefix}/lib64/libfoo.so"]) == ["\${prefix}/lib64/libfoo"]

        mktempdir() do prefix
            mkpath(joinpath(prefix, "lib"))
            touch(joinpath(prefix, "lib", "libfoo.a"))
            env = Dict("prefix" => prefix, "libdir" => joinpath(prefix, "bin"))
            lp = LibraryProduct("\${libdir}/libfoo", :libfoo; static=:auto)
            @test locate(lp.static, prefix; env, platform=Platform("x86_64", "windows")) == joinpath("lib", "libfoo.a")
        end
    end

    @testset "StaticLibraryProduct archive extensions" begin
        mktempdir() do prefix
            mkpath(joinpath(prefix, "lib"))
            env = Dict("prefix" => prefix)
            windows = Platform("x86_64", "windows")
            linux = Platform("x86_64", "linux")

            # MSVC-style archives are found on Windows, and only there
            touch(joinpath(prefix, "lib", "foo.lib"))
            @test locate(StaticLibraryProduct("foo"), prefix; env, platform=windows) == joinpath("lib", "foo.lib")
            @test locate(StaticLibraryProduct("foo.lib"), prefix; env, platform=windows) == joinpath("lib", "foo.lib")
            @test locate(StaticLibraryProduct("foo"), prefix; env, platform=linux) === nothing

            # A MinGW import library is never taken for the archive
            touch(joinpath(prefix, "lib", "libbar.dll.a"))
            @test locate(StaticLibraryProduct("libbar"), prefix; env, platform=windows) === nothing
            touch(joinpath(prefix, "lib", "libbar.a"))
            @test locate(StaticLibraryProduct("libbar"), prefix; env, platform=windows) == joinpath("lib", "libbar.a")
        end
    end
end
