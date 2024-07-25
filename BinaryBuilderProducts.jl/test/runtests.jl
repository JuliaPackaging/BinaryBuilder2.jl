using BinaryBuilderProducts, Test, BinaryBuilderSources, JLLGenerator
using JLLGenerator: rtld_symbols, rtld_flags

@testset "BinaryBuilderProducts" begin
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
                    product_subpath = locate(product, dir; env)
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
                        @test JLLGenerator.AbstractJLLProduct(product, dir; env) !== nothing
                    end
                end
            end
        end
    end
end
