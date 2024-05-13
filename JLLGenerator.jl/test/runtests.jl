using JLLGenerator, Test, Base.BinaryPlatforms, Libdl, TOML

using JLLGenerator: rtld_symbols, rtld_flags, default_rtld_flags
@testset "RTLD flags" begin
    @test default_rtld_flags & RTLD_LAZY != 0
    @test rtld_symbols(RTLD_LAZY | RTLD_FIRST) == [:RTLD_FIRST, :RTLD_LAZY]
    @test rtld_flags([:RTLD_DEEPBIND, :RTLD_LOCAL, :RTLD_NOLOAD]) == RTLD_DEEPBIND | RTLD_LOCAL | RTLD_NOLOAD

    @test rtld_flags(Symbol[]) == 0x00000000
    @test rtld_symbols(0x00000000) == Symbol[]
    @test rtld_flags(rtld_symbols(default_rtld_flags)) == default_rtld_flags

    @test_throws ArgumentError rtld_flags([:RTLD_THIS_FLAG_DOES_NOT_EXIST])
    @test_throws ArgumentError rtld_symbols(0x80000000)
end

function roundtrip_jll_through_toml(jll)
    io = IOBuffer()
    TOML.print(io, generate_toml_dict(jll))
    toml_str = String(take!(io))
    d = TOML.parse(toml_str)
    return d, parse_toml_dict(d)
end

@testset "Hand-crafted XZ_jll" begin
    # Hand-crafted XZ_jll impersonation
    xz_sources = [
        JLLSourceRecord("https://tukaani.org/xz/xz-5.4.3.tar.xz", "92177bef62c3824b4badc524f8abcce54a20b7dbcfb84cde0a2eb8b49159518c"),
    ]
    # These dependencies are not real, but I want to include them anyway for test coverage
    liblzma_deps = [
        JLLLibraryDep(:Glibc_jll, :libc),
    ]
    xz_deps = [
        JLLPackageDependency(:Glibc_jll),
    ]
    jll = JLLInfo(;
        name = "XZ",
        version = v"5.4.3+1",
        artifacts = [
            JLLArtifactInfo(;
                src_version = v"5.4.3",
                deps = xz_deps,
                sources = xz_sources,
                platform = Platform("x86_64", "linux"),
                name = "default",
                treehash = "214deacf44273474118c5fe83871fdfa8039b4ad",
                download_sources = [
                    JLLArtifactSource(
                        "https://github.com/JuliaBinaryWrappers/XZ_jll.jl/releases/download/XZ-v5.4.3%2B1/XZ.v5.4.3.x86_64-linux-gnu.tar.gz",
                        "70a053a45c76811bbb475aa43e0e0781c9e972d2fb57b67d35aa32a30de90336",
                    ),
                ],
                products = [
                    JLLExecutableProduct(:xz, "bin/xz"),
                    JLLFileProduct(:liblzma_a, "lib/liblzma.a"),
                    JLLLibraryProduct(:liblzma, "lib/liblzma.so.5", liblzma_deps),
                ]
            ),
            JLLArtifactInfo(;
                src_version = v"5.4.3",
                deps = xz_deps,
                sources = xz_sources,
                platform = Platform("x86_64", "windows"),
                name = "default",
                treehash = "4b8bb762c5118ee8ad81e67b981fe7d6a17fae77",
                download_sources = [
                    JLLArtifactSource(
                        "https://github.com/JuliaBinaryWrappers/XZ_jll.jl/releases/download/XZ-v5.4.3%2B1/XZ.v5.4.3.x86_64-w64-mingw32.tar.gz",
                        "3f05d8023b1776315c1761a67f87611859e9c8e9b2bd598592133d7d979f8e3e",
                    ),
                ],
                products = [
                    JLLExecutableProduct(:xz, "bin/xz.exe"),
                    JLLFileProduct(:liblzma_a, "lib/liblzma.a"),
                    JLLLibraryProduct(:liblzma, "bin/liblzma-5.dll", liblzma_deps),
                ],
            ),
            JLLArtifactInfo(;
                src_version = v"5.4.3",
                deps = xz_deps,
                sources = xz_sources,
                platform = Platform("aarch64", "macos"),
                name = "default",
                treehash = "abb153d4516c6a0ee718ea8f8cde9466de07553c",
                download_sources = [
                    JLLArtifactSource(
                        "https://github.com/JuliaBinaryWrappers/XZ_jll.jl/releases/download/XZ-v5.4.3%2B1/XZ.v5.4.3.aarch64-apple-darwin.tar.gz",
                        "93b6890109b5dc9e6e022888cef5e8d3180a4ea0eae3ceab1ce6f247b5fbc66c",
                    ),
                ],
                products = [
                    JLLExecutableProduct(:xz, "bin/xz"),
                    JLLFileProduct(:liblzma_a, "lib/liblzma.a"),
                    JLLLibraryProduct(:liblzma, "lib/liblzma.5.dylib", liblzma_deps),
                ]
            ),
        ],
        julia_compat = "1.7",
    )

    # Turn this into TOML, and back into a Dict:
    d, _ = roundtrip_jll_through_toml(jll)

    # Do some very basic assertions on the contents of this TOML file
    @test d["name"] == "XZ"
    @test d["version"] == "5.4.3+1"
    @test length(d["artifacts"]) == 3

    for aidx in 1:length(d["artifacts"])
        @test only(d["artifacts"][aidx]["deps"])["name"] == "Glibc_jll"
        @test only(d["artifacts"][aidx]["deps"])["compat"] == "*"
        @test length(d["artifacts"][aidx]["products"]) == 3
        @test length(d["artifacts"][aidx]["sources"]) == 1

        prods = d["artifacts"][aidx]["products"]
        for prod in prods
            if prod["type"] == "library"
                @test only(prod["deps"]) == "Glibc_jll.libc"
            end
        end
    end

    # Parse it back in and ensure it's identical
    @test jll == parse_toml_dict(d)

    # Test that `select_platform()` works on the `jll` object itself
    @test select_platform(jll, Platform("x86_64", "linux")).treehash == "214deacf44273474118c5fe83871fdfa8039b4ad"

    # Generate a JLL on-disk
    mktempdir() do dir
        generate_jll(dir, jll)

        @test isfile(joinpath(dir, "JLL.toml"))
        @test isfile(joinpath(dir, "README.md"))
        @test isfile(joinpath(dir, "Project.toml"))
        @test isfile(joinpath(dir, "src", "$(jll.name)_jll.jl"))

        # Parse the TOML back on disk, make sure it matches
        @test jll == parse_toml_dict(TOML.parsefile(joinpath(dir, "JLL.toml")))

        # Test that the Project.toml declares Glibc_jll as a dependency,
        # and that there is a compat bound on Julia itself.
        project = TOML.parsefile(joinpath(dir, "Project.toml"))
        @test project["name"] ==  "XZ_jll"
        @test haskey(project["deps"], "Glibc_jll")
        @test haskey(project["compat"], "julia")

        @test !haskey(project["deps"], "Pkg")
        @test haskey(project["deps"], "Artifacts")
    end
end

@testset "Duplicate dependencies" begin
    function make_dual_deps_constraint(compat1, compat2)
        return JLLInfo(;
            name = "default",
            version = v"1.2.13+1",
            artifacts = [
                JLLArtifactInfo(;
                    src_version = v"1.2.13+1",
                    deps = [
                        JLLPackageDependency(
                            "Glibc_jll",
                            nothing,
                            compat1,
                        ),
                    ],
                    platform = Platform("aarch64", "linux"; libc = "glibc"),
                    name = "default",
                    treehash = "0c6c284985577758b3a339c6215c9d4e3d71420e",
                    download_sources = [],
                    products = [],
                ),
                JLLArtifactInfo(;
                    src_version = v"1.2.13+1",
                    deps = [
                        JLLPackageDependency(
                            "Glibc_jll",
                            nothing,
                            compat2,
                        ),
                    ],
                    platform = Platform("aarch64", "linux"; libc = "musl"),
                    name = "default",
                    treehash = "377fed6108dca72651d7cb705a0aee7ce28d4a5b",
                    download_sources = [],
                    products = [],
                ),
            ]
        )
    end

    # This should throw an error because the compat bounds on `Glibc_jll` are messed up.
    jll = make_dual_deps_constraint("2.12.2 - 2.17", "2.19 - 2.24")
    mktempdir() do dir
        @test_throws ArgumentError generate_jll(dir, jll)
    end

    # This should be just fine, because it is an overlap in the compats.
    jll = make_dual_deps_constraint("2.12.2 - 2.17", "2.15 - 2.24")
    mktempdir() do dir
        generate_jll(dir, jll)

        @test isfile(joinpath(dir, "Project.toml"))
        project = TOML.parsefile(joinpath(dir, "Project.toml"))
        @test project["compat"]["Glibc_jll"] == "2.15 - 2.17"

        # Because this JLL doesn't have any exotic platforms, it defaults to Julia v1.0
        # and therefore depends on `Pkg`
        @test project["compat"]["julia"] == "1.0"
        @test haskey(project["deps"], "Pkg")
        @test !haskey(project["deps"], "Artifacts")
    end
end

@testset "Missing Dependency" begin
    # This throws an error because we declare our library as depending on `Glibc_jll.libc`,
    # but we don't declare a dependency on `Glibc_jll`.
    @test_throws ArgumentError JLLInfo(;
        name = "Zlib",
        version = v"1.2.13+1",
        artifacts = [
            JLLArtifactInfo(;
                src_version = v"1.2.13+1",
                platform = Platform("aarch64", "linux"; libc = "glibc"),
                name = "default",
                treehash = "0c6c284985577758b3a339c6215c9d4e3d71420e",
                download_sources = [],
                products = [
                    JLLLibraryProduct(
                        :libz,
                        "bin\\libz.dll",
                        [JLLLibraryDep("Glibc_jll", "libc")],
                        flags = [:RTLD_LAZY, :RTLD_DEEPBIND],
                    ),
                ],
            ),
        ]
    )
end

@testset "Intra-JLL library dependency" begin
    function make_intra_jll_dependency(incoherent)
        return JLLInfo(;
            name = "default",
            version = v"1.0.5+1",
            artifacts = [
                JLLArtifactInfo(;
                    src_version = v"1.0.5+1",
                    platform = Platform("aarch64", "macos"; libgfortran_version = "5.0.0"),
                    name = "default",
                    treehash = "f9547d56705c03a6e887a01aeb0f0b6b030b7060",
                    download_sources = [
                        JLLArtifactSource(
                            "https://github.com/JuliaBinaryWrappers/CompilerSupportLibraries_jll.jl/releases/download/CompilerSupportLibraries-v1.0.5+1/CompilerSupportLibraries.v1.0.5.aarch64-apple-darwin-libgfortran5.tar.gz",
                            "c7d0330a55d3b32fbe1b6f73c43e9b9d6649f23b6d9034efd5e107b1d537ab53",
                        ),
                    ],
                    products = [
                        JLLLibraryProduct(
                            :libgcc_s,
                            "lib/libgcc_s.1.1.dylib",
                            [],
                            flags = [:RTLD_LAZY, :RTLD_DEEPBIND],
                        ),
                        JLLLibraryProduct(
                            :libquadmath,
                            "lib/libquadmath.1.dylib",
                            incoherent ? [JLLLibraryDep(nothing, :does_not_exist)] : [],
                            flags = [:RTLD_LAZY, :RTLD_DEEPBIND],
                        ),
                        JLLLibraryProduct(
                            :libgfortran,
                            "lib/libgfortran.5.dylib",
                            [JLLLibraryDep(nothing, :libgcc_s), JLLLibraryDep(nothing, :libquadmath)],
                            flags = [:RTLD_LAZY, :RTLD_DEEPBIND],
                        ),
                        JLLLibraryProduct(
                            :libstdcxx,
                            "lib/libstdc++.6.dylib",
                            [JLLLibraryDep(nothing, :libgcc_s)],
                            flags = [:RTLD_LAZY, :RTLD_DEEPBIND],
                        ),
                    ]
                ),
            ],
        )
    end

    # Test that a properly-generated JLL can refer to its own products in its library dependencies:
    jll = make_intra_jll_dependency(false)
    d, new_jll = roundtrip_jll_through_toml(jll)

    products = only(d["artifacts"])["products"]
    @test length([p for p in products if p["type"] == "library" && length(p["deps"]) > 0]) == 2

    # Also test that this roundtripped properly
    @test jll == new_jll

    # Test that an improperly-generated JLL throws an error if it can't resolve one of its own products
    @test_throws ArgumentError make_intra_jll_dependency(true)
end

@testset "on-load callbacks" begin
    function make_on_load_callback(incoherent)
        return jll = JLLInfo(;
            name = "default",
            version = v"5.8.0+1",
            artifacts = [
                JLLArtifactInfo(;
                    src_version = v"5.8.0+1",
                    deps = [],
                    sources = [],
                    platform = Platform("aarch64", "macos"; ),
                    name = "default",
                    treehash = "214e75bb92aa2acc9de8ff89f8d1aaeeba8fd26d",
                    download_sources = [
                        JLLArtifactSource(
                            "https://github.com/JuliaBinaryWrappers/libblastrampoline_jll.jl/releases/download/libblastrampoline-v5.8.0+1/libblastrampoline.v5.8.0.aarch64-apple-darwin.tar.gz",
                            "2b241d3105f62bfae7ce56b4d7957a4a17272e743e2e23a57ccec1ee36140aac",
                        ),
                    ],
                    products = [
                        JLLLibraryProduct(
                            :libblastrampoline,
                            "lib/libblastrampoline.5.4.0.dylib",
                            [];
                            flags = [:RTLD_LAZY, :RTLD_DEEPBIND],
                            on_load_callback = incoherent ? :callback_does_not_exist : :libblastrampoline_on_load_callback,
                        ),
                    ],
                    callback_defs = Dict(
                        :libblastrampoline_on_load_callback => """
                        function libblastrampoline_on_load_callback()
                            println("this is our callback!")
                        end
                        """
                    )
                ),
            ],
        )
    end

    jll = make_on_load_callback(false)
    d, new_jll = roundtrip_jll_through_toml(jll)
    @test contains(only(d["artifacts"])["callback_defs"]["libblastrampoline_on_load_callback"], "this is our callback")
    @test jll == new_jll

    # Trying to declare a library product with a non-existant on-load callback fails
    @test_throws ArgumentError make_on_load_callback(true)
end

# Test that we can generate all of the stdlib JLLs in `contrib/`
@testset "stdlib JLL generation" begin
    include(joinpath(dirname(@__DIR__), "contrib", "gen_julia_jlls.jl"))
end

@testset "jll_auto_upgrade_helper" begin
    # Just make sure this tool doesn't bitrot too bad:
    mktempdir() do dir
        contrib_dir = joinpath(dirname(@__DIR__), "contrib")
        run(`$(Base.julia_cmd()) --project=$(contrib_dir) -e 'import Pkg; Pkg.instantiate()'`)

        test_repos = [
            ("https://github.com/JuliaBinaryWrappers/Zlib_jll.jl", "2c0602d8ec8557ee3f0beb7fd60b324bfc5def82"),
            ("https://github.com/JuliaBinaryWrappers/GMP_jll.jl", "76b821798c26f25ce230cbfd2237da63255b3931"),
            ("https://github.com/JuliaBinaryWrappers/p7zip_jll.jl", "10fd1c830f63c9095104d4bce34afac8171b31c2"),
            ("https://github.com/JuliaBinaryWrappers/CompilerSupportLibraries_jll.jl", "7aeb8eeda1cb109833b8f81d23045fd0e9e31eed"),
        ]
        for (url, commit) in test_repos
            jllinfo_def = readchomp(`$(Base.julia_cmd()) --project=$(contrib_dir) $(contrib_dir)/jll_auto_upgrade_helper.jl $(url) $(commit)`)

            # Just assume no library dependencies for this simple test
            jllinfo_def = replace(jllinfo_def, "<deps>" => "")
            
            # Try constructing the JLLInfo object:
            m = Module()
            Core.eval(m, :(using JLLGenerator))
            Core.eval(m, Meta.parse(jllinfo_def))

            # Round-trip the JLLInfo object to TOML and ensure it comes back clean:
            @test m.jll == roundtrip_jll_through_toml(m.jll)[2]
        end
    end
end

@testset "Upgrade" begin
    zlib_products = [
        JLLLibraryProduct(:libz, "lib/libz.so.1", []),
    ]
    old_zlib_jll = JLLInfo(;
        name = "Zlib",
        version = v"1.2.13+1",
        artifacts = [
            JLLArtifactInfo(;
                src_version = v"1.2.13+1",
                deps = [],
                platform = Platform("aarch64", "linux"; libc = "glibc"),
                name = "default",
                treehash = "0c6c284985577758b3a339c6215c9d4e3d71420e",
                download_sources = [],
                products = zlib_products,
            ),
            JLLArtifactInfo(;
                src_version = v"1.2.13+1",
                deps = [],
                platform = Platform("aarch64", "linux"; libc = "musl"),
                name = "default",
                treehash = "377fed6108dca72651d7cb705a0aee7ce28d4a5b",
                download_sources = [],
                products = zlib_products,
            ),
        ]
    )

    new_zlib_jll = JLLInfo(;
        name = "Zlib",
        version = v"1.2.13+1",
        artifacts = [
            JLLArtifactInfo(;
                src_version = v"1.2.13+1",
                deps = [],
                platform = Platform("aarch64", "linux"; libc = "glibc"),
                name = "default",
                treehash = "0c6c284985577758b3a339c6215c9d4e3d71420e",
                download_sources = [],
                products = zlib_products,
            ),
        ]
    )

    mktempdir() do dir
        mkpath(joinpath(dir, ".git"))
        touch(joinpath(dir, ".git", "bar"))
        generate_jll(dir, old_zlib_jll)
        touch(joinpath(dir, "foo.txt"))

        @test isfile(joinpath(dir, "foo.txt"))
        @test isfile(joinpath(dir, ".git", "bar"))
        jll_dict = parse_toml_dict(TOML.parsefile(joinpath(dir, "JLL.toml")))
        @test length(jll_dict.artifacts) == 2

        # Ensure that if we generate_jll() into the same location
        # we clear out extraneous files (but not `.git/*`) and
        # lose all previous content.
        generate_jll(dir, new_zlib_jll)
        jll_dict = parse_toml_dict(TOML.parsefile(joinpath(dir, "JLL.toml")))
        @test !isfile(joinpath(dir, "foo.txt"))
        @test isfile(joinpath(dir, ".git", "bar"))
        @test length(jll_dict.artifacts) == 1
    end
end

# Ensure that all of our example JLLInfos are valid and roundtrip properly.
@testset "Example JLLInfos" begin
    for example_file in readdir(joinpath(dirname(@__DIR__), "contrib", "example_jllinfos"); join=true)
        jll = include(example_file)
        @test roundtrip_jll_through_toml(jll)[2] == jll
    end
end

using BinaryBuilderSources, Base.BinaryPlatforms, Pkg
using BinaryBuilderSources: PkgSpec
@testset "JLLSource TOML loading" begin
    # Use special Readline_jll.jl because we do not yet have any JLLs built in the wild that have a `JLL.toml`.
    jll = JLLSource(PkgSpec(;
        name = "Readline_jll",
        uuid = "05236dd9-4125-5232-aa7c-9ec0c9b2c25a",
        tree_hash = Base.SHA1("a1083574ec4b58dbde579b72760001a1741cdae7"),
        repo=Pkg.Types.GitRepo(
            rev="5a3fde0fda4dadcaf444c54aad9651a3ef373027",
            source="https://github.com/staticfloat/Readline_jll.jl",
        ),
    ), Platform("aarch64", "linux"))

    mktempdir() do prefix
        prepare(jll; depot=prefix)
        data = parse_toml_dict(jll; depot=prefix)

        @test data.name == "Readline"
        @test length(data.artifacts) == 1
        jart = only(data.artifacts)
        @test jart.name == "default"
        @test length(jart.products) == 2
        @test jart.treehash == "sha1:b18bc5bdcff9c62785e46d19dcdce3717ce10335"
    end
end
