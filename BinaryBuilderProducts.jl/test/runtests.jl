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
    for (target, as) in artifacts_downloads
        @testset "$(target)" begin
            env = Dict(
                "prefix" => "/prefix",
                "bindir" => "/prefix/bin",
                "libdir" => "/prefix/lib",
                "shlibdir" => contains(target, "mingw32") ? "/prefix/bin" : "/prefix/lib",
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

                    if isa(product, LibraryProduct) && pass
                        resolve_dependency_links!([product], dir, env)
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

@testset "resolve_dependency_links!" begin
    artifacts_downloads = Dict(
        "x86_64-linux-gnu" => [
            ArchiveSource(
                "https://github.com/JuliaBinaryWrappers/FreeType2_jll.jl/releases/download/FreeType2-v2.13.1%2B0/FreeType2.v2.13.1.x86_64-linux-gnu.tar.gz",
                "b4ff8f733e4d4fc61f2d32147a5691c5b394b899398ebb0dd375ae8caeb0d0b7",
            ),
            ArchiveSource(
                "https://github.com/JuliaBinaryWrappers/Bzip2_jll.jl/releases/download/Bzip2-v1.0.8%2B0/Bzip2.v1.0.8.x86_64-linux-gnu.tar.gz",
                "7cac890c49ed760223194100c84c701ecba65fcc2b0a8916950c19143c3bbddb",
            ),
            ArchiveSource(
                "https://github.com/JuliaBinaryWrappers/Zlib_jll.jl/releases/download/Zlib-v1.2.13%2B1/Zlib.v1.2.13.x86_64-linux-gnu.tar.gz",
                "46678eabc97358858872a85192903f427288f9ea814bddc6b3e81a8681b63da4",
            ),
        ],
        "x86_64-w64-mingw32" => [
            ArchiveSource(
                "https://github.com/JuliaBinaryWrappers/FreeType2_jll.jl/releases/download/FreeType2-v2.13.1%2B0/FreeType2.v2.13.1.x86_64-w64-mingw32.tar.gz",
                "94cb57cf1b32456c22e75958a953344a87a15e068a698996b15d7819374a9357",
            ),
            ArchiveSource(
                "https://github.com/JuliaBinaryWrappers/Bzip2_jll.jl/releases/download/Bzip2-v1.0.8%2B0/Bzip2.v1.0.8.x86_64-w64-mingw32.tar.gz",
                "9a68eae2cf05414dafebceb116ac9b2e9cd5f274ad6a6836512d7db8f133dc72",
            ),
            ArchiveSource(
                "https://github.com/JuliaBinaryWrappers/Zlib_jll.jl/releases/download/Zlib-v1.2.13%2B1/Zlib.v1.2.13.x86_64-w64-mingw32.tar.gz",
                "94e6f53f78af66a9d9f25e47a6038640f803980cfc6d5a0dcbb6521a0748283a",
            ),
        ],
        "aarch64-apple-darwin" => [
            ArchiveSource(
                "https://github.com/JuliaBinaryWrappers/FreeType2_jll.jl/releases/download/FreeType2-v2.13.1%2B0/FreeType2.v2.13.1.aarch64-apple-darwin.tar.gz",
                "537cee2c03ba6d3d7047f6021cf0830f863c2916097e203574246463cf3a3118",
            ),
            ArchiveSource(
                "https://github.com/JuliaBinaryWrappers/Bzip2_jll.jl/releases/download/Bzip2-v1.0.8%2B0/Bzip2.v1.0.8.aarch64-apple-darwin.tar.gz",
                "02bb57e59658a0c8cff431b69217383d42d99c8729822348600d1dee7eeec6db",
            ),
            ArchiveSource(
                "https://github.com/JuliaBinaryWrappers/Zlib_jll.jl/releases/download/Zlib-v1.2.13%2B1/Zlib.v1.2.13.aarch64-apple-darwin.tar.gz",
                "c3cd33a20f082b947fa4175c60545d5d4a6bc360f0175597bca87be9028b15b1",
            ),
        ],
    )

    for (target, as) in artifacts_downloads
        @testset "$(target)" begin
            env = Dict(
                "prefix" => "/prefix",
                "bb_full_target" => target,
            )
            mktempdir() do dir
                # Download and unpack the JLLs into the same prefix:
                for a in as
                    prepare(a)
                    unpack_dir = joinpath(dir, basename(a.url))
                    deploy(a, unpack_dir)
                    for subdir in ("bin", "lib")
                        if isdir(joinpath(dir, unpack_dir, subdir))
                            for f in readdir(joinpath(dir, unpack_dir, subdir))
                                mkpath(joinpath(dir, subdir))
                                cp(joinpath(dir, unpack_dir, subdir, f), joinpath(dir, subdir, f); force=true)
                            end
                        end
                    end
                    rm(joinpath(dir, unpack_dir); force=true, recursive=true)
                end

                # Test providing a `dlopen_flags` argument as well.
                libft = LibraryProduct("libfreetype", :libfreetype, dlopen_flags=[:RTLD_NOLOAD])
                libz = LibraryProduct("libz", :libz)
                libbz2 = LibraryProduct("libbz2", :libbz2)

                libft_subpath = locate(libft, dir; env)
                @test libft_subpath !== nothing
                @test isfile(joinpath(dir, libft_subpath))

                resolve_dependency_links!([libft, libz, libbz2], dir, env)
                # The Windows build of libfreetype.dll doesn't seem to link against `libbz2.dll` :(
                if target == "x86_64-w64-mingw32"
                    @test length(libft.deps) == 1
                    @test libz ∈ libft.deps
                else
                    @test length(libft.deps) == 2
                    @test libz ∈ libft.deps
                    @test libbz2 ∈ libft.deps
                end

                # These two remain untouched
                @test isempty(libz.deps)
                @test isempty(libbz2.deps)

                # Test that turning this into a AbstractJLLProduct works
                jll_lib = JLLGenerator.AbstractJLLProduct(
                    libft,
                    dir;
                    jll_maps = Dict(
                        libz => :Zlib_jll,
                        libbz2 => :Bzip2_jll,
                    ),
                    env,
                )
                @test jll_lib.varname == libft.varname
                @test jll_lib.flags == rtld_symbols(libft.dlopen_flags)
                @test jll_lib.path == libft_subpath
                @test length(jll_lib.deps) == length(libft.deps)
                @test any(d.mod == :Zlib_jll && d.varname == :libz for d in jll_lib.deps)
                if length(libft.deps) > 1
                    @test any(d.mod == :Bzip2_jll && d.varname == :libbz2 for d in jll_lib.deps)
                end
            end
        end
    end
end
