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

@testset "License names" begin
    if !Sys.isapple()
        for (name, text) in JLLGenerator.license_texts
            poss_names = JLLGenerator.licensecheck(text).licenses_found
            @test length(poss_names) == 1
            @test name == only(poss_names)
        end
    end
end

function roundtrip_jll_through_toml(jll)
    io = IOBuffer()
    TOML.print(io, generate_toml_dict(jll))
    toml_str = String(take!(io))
    d = TOML.parse(toml_str)
    return d, parse_toml_dict(d)
end

mit_license = JLLBuildLicense("LICENSE.md", JLLGenerator.get_license_text("MIT"))

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
        builds = [
            JLLBuildInfo(;
                src_version = v"5.4.3",
                deps = xz_deps,
                sources = xz_sources,
                platform = Platform("x86_64", "linux"),
                name = "XZ",
                artifact = JLLArtifactBinding(;
                    treehash = "214deacf44273474118c5fe83871fdfa8039b4ad",
                    download_sources = [
                        JLLArtifactSource(
                            "https://github.com/JuliaBinaryWrappers/XZ_jll.jl/releases/download/XZ-v5.4.3%2B1/XZ.v5.4.3.x86_64-linux-gnu.tar.gz",
                            "70a053a45c76811bbb475aa43e0e0781c9e972d2fb57b67d35aa32a30de90336",
                        ),
                    ],
                ),
                products = [
                    JLLExecutableProduct(:xz, "bin/xz"),
                    JLLFileProduct(:liblzma_a, "lib/liblzma.a"),
                    JLLLibraryProduct(:liblzma, "lib/liblzma.so.5", liblzma_deps),
                ],
                licenses = [mit_license],
            ),
            JLLBuildInfo(;
                src_version = v"5.4.3",
                deps = xz_deps,
                sources = xz_sources,
                platform = Platform("x86_64", "windows"),
                name = "XZ",
                artifact = JLLArtifactBinding(;
                    treehash = "4b8bb762c5118ee8ad81e67b981fe7d6a17fae77",
                    download_sources = [
                        JLLArtifactSource(
                            "https://github.com/JuliaBinaryWrappers/XZ_jll.jl/releases/download/XZ-v5.4.3%2B1/XZ.v5.4.3.x86_64-w64-mingw32.tar.gz",
                            "3f05d8023b1776315c1761a67f87611859e9c8e9b2bd598592133d7d979f8e3e",
                        ),
                    ],
                ),
                products = [
                    JLLExecutableProduct(:xz, "bin/xz.exe"),
                    JLLFileProduct(:liblzma_a, "lib/liblzma.a"),
                    JLLLibraryProduct(:liblzma, "bin/liblzma-5.dll", liblzma_deps),
                ],
                licenses = [mit_license],
            ),
            JLLBuildInfo(;
                src_version = v"5.4.3",
                deps = xz_deps,
                sources = xz_sources,
                platform = Platform("aarch64", "macos"),
                name = "XZ",
                artifact = JLLArtifactBinding(;
                    treehash = "abb153d4516c6a0ee718ea8f8cde9466de07553c",
                    download_sources = [
                        JLLArtifactSource(
                            "https://github.com/JuliaBinaryWrappers/XZ_jll.jl/releases/download/XZ-v5.4.3%2B1/XZ.v5.4.3.aarch64-apple-darwin.tar.gz",
                            "93b6890109b5dc9e6e022888cef5e8d3180a4ea0eae3ceab1ce6f247b5fbc66c",
                        ),
                    ],
                ),
                products = [
                    JLLExecutableProduct(:xz, "bin/xz"),
                    JLLFileProduct(:liblzma_a, "lib/liblzma.a"),
                    JLLLibraryProduct(:liblzma, "lib/liblzma.5.dylib", liblzma_deps),
                ],
                licenses = [mit_license],
            ),
        ],
        julia_compat = "1.7",
    )

    # Turn this into TOML, and back into a Dict:
    d, _ = roundtrip_jll_through_toml(jll)

    # Do some very basic assertions on the contents of this TOML file
    @test d["name"] == "XZ"
    @test d["version"] == "5.4.3+1"
    @test length(d["builds"]) == 3

    for aidx in 1:length(d["builds"])
        @test only(d["builds"][aidx]["deps"])["name"] == "Glibc_jll"
        @test only(d["builds"][aidx]["deps"])["compat"] == "*"
        @test length(d["builds"][aidx]["products"]) == 3
        @test length(d["builds"][aidx]["sources"]) == 1

        prods = d["builds"][aidx]["products"]
        for prod in prods
            if prod["type"] == "library"
                @test only(prod["deps"]) == "Glibc_jll.libc"
            end
        end
    end

    # Parse it back in and ensure it's identical
    @test jll == parse_toml_dict(d)

    # Test that `select_platform()` works on the `jll` object itself
    @test select_platform(jll, Platform("x86_64", "linux")).artifact.treehash == "214deacf44273474118c5fe83871fdfa8039b4ad"

    # Generate a JLL on-disk
    mktempdir() do dir
        generate_jll(dir, jll)

        @test isfile(joinpath(dir, "JLL.toml"))
        @test isfile(joinpath(dir, "README.md"))
        @test isfile(joinpath(dir, "LICENSE.md"))
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
            name = "Zlib",
            version = v"1.2.13+1",
            builds = [
                JLLBuildInfo(;
                    src_version = v"1.2.13+1",
                    deps = [
                        JLLPackageDependency(
                            "Glibc_jll",
                            nothing,
                            compat1,
                        ),
                    ],
                    platform = Platform("aarch64", "linux"; libc = "glibc"),
                    name = "Zlib",
                    artifact = JLLArtifactBinding(
                        treehash = "0c6c284985577758b3a339c6215c9d4e3d71420e",
                        download_sources = [],
                    ),
                    products = [],
                    licenses = [mit_license],
                ),
                JLLBuildInfo(;
                    src_version = v"1.2.13+1",
                    deps = [
                        JLLPackageDependency(
                            "Glibc_jll",
                            nothing,
                            compat2,
                        ),
                    ],
                    platform = Platform("aarch64", "linux"; libc = "musl"),
                    name = "Zlib",
                    artifact = JLLArtifactBinding(
                        treehash = "377fed6108dca72651d7cb705a0aee7ce28d4a5b",
                        download_sources = [],
                    ),
                    products = [],
                    licenses = [mit_license],
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
        builds = [
            JLLBuildInfo(;
                src_version = v"1.2.13+1",
                platform = Platform("aarch64", "linux"; libc = "glibc"),
                name = "Zlib",
                artifact = JLLArtifactBinding(
                    treehash = "0c6c284985577758b3a339c6215c9d4e3d71420e",
                    download_sources = [],
                ),
                products = [
                    JLLLibraryProduct(
                        :libz,
                        "bin\\libz.dll",
                        [JLLLibraryDep("Glibc_jll", "libc")],
                        flags = [:RTLD_LAZY, :RTLD_DEEPBIND],
                    ),
                ],
                licenses = [mit_license],
            ),
        ]
    )
end

@testset "Missing Licenses" begin
    @test_throws ArgumentError JLLInfo(;
        name = "Zlib",
        version = v"1.2.13+1",
        builds = [
            JLLBuildInfo(;
                src_version = v"1.2.13+1",
                platform = Platform("aarch64", "linux"; libc = "glibc"),
                name = "Zlib",
                artifact = JLLArtifactBinding(
                    treehash = "0c6c284985577758b3a339c6215c9d4e3d71420e",
                    download_sources = [],
                ),
                products = [],
                licenses = [],
            ),
        ]
    )
end

@testset "Intra-JLL library dependency" begin
    function make_intra_jll_dependency(incoherent)
        return JLLInfo(;
            name = "CompilerSupportLibraries",
            version = v"1.0.5+1",
            builds = [
                JLLBuildInfo(;
                    src_version = v"1.0.5+1",
                    platform = Platform("aarch64", "macos"; libgfortran_version = "5.0.0"),
                    name = "CompilerSupportLibraries",
                    artifact = JLLArtifactBinding(;
                        treehash = "f9547d56705c03a6e887a01aeb0f0b6b030b7060",
                        download_sources = [
                            JLLArtifactSource(
                                "https://github.com/JuliaBinaryWrappers/CompilerSupportLibraries_jll.jl/releases/download/CompilerSupportLibraries-v1.0.5+1/CompilerSupportLibraries.v1.0.5.aarch64-apple-darwin-libgfortran5.tar.gz",
                                "c7d0330a55d3b32fbe1b6f73c43e9b9d6649f23b6d9034efd5e107b1d537ab53",
                            ),
                        ],
                    ),
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
                    ],
                    licenses = [mit_license],
                ),
            ],
        )
    end

    # Test that a properly-generated JLL can refer to its own products in its library dependencies:
    jll = make_intra_jll_dependency(false)
    d, new_jll = roundtrip_jll_through_toml(jll)

    products = only(d["builds"])["products"]
    @test length([p for p in products if p["type"] == "library" && length(p["deps"]) > 0]) == 2

    # Also test that this roundtripped properly
    @test jll == new_jll

    # Test that an improperly-generated JLL throws an error if it can't resolve one of its own products
    @test_throws ArgumentError make_intra_jll_dependency(true)
end

@testset "on-load callbacks" begin
    function make_on_load_callback(incoherent)
        return jll = JLLInfo(;
            name = "libblastrampoline",
            version = v"5.8.0+1",
            builds = [
                JLLBuildInfo(;
                    src_version = v"5.8.0+1",
                    deps = [],
                    sources = [],
                    platform = Platform("aarch64", "macos"; ),
                    name = "libblastrampoline",
                    artifact = JLLArtifactBinding(;
                        treehash = "214e75bb92aa2acc9de8ff89f8d1aaeeba8fd26d",
                        download_sources = [
                            JLLArtifactSource(
                                "https://github.com/JuliaBinaryWrappers/libblastrampoline_jll.jl/releases/download/libblastrampoline-v5.8.0+1/libblastrampoline.v5.8.0.aarch64-apple-darwin.tar.gz",
                                "2b241d3105f62bfae7ce56b4d7957a4a17272e743e2e23a57ccec1ee36140aac",
                            ),
                        ],
                    ),
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
                    ),
                    licenses = [mit_license],
                ),
            ],
        )
    end

    jll = make_on_load_callback(false)
    d, new_jll = roundtrip_jll_through_toml(jll)
    @test contains(only(d["builds"])["callback_defs"]["libblastrampoline_on_load_callback"], "this is our callback")
    @test jll == new_jll

    # Trying to declare a library product with a non-existant on-load callback fails
    @test_throws ArgumentError make_on_load_callback(true)
end

@testset "Build binding shape" begin
    binding = JLLArtifactBinding(treehash = "0c6c284985577758b3a339c6215c9d4e3d71420e",
                                 download_sources = [])
    mkbuild(; kwargs...) = JLLBuildInfo(; src_version = v"1.0.0",
                                        platform = Platform("x86_64", "linux"),
                                        name = "Demo",
                                        products = [JLLLibraryProduct(:libz, "lib/libz.so.1", [])],
                                        licenses = [mit_license], kwargs...)
    roundtrip_build(b) = parse_toml_dict(JLLBuildInfo, generate_toml_dict(b))

    # Anything we generate lives in an artifact, and its products' paths are
    # relative to the artifact root
    build = mkbuild(; artifact = binding)
    @test build.artifact === binding
    d = generate_toml_dict(build)
    @test d["artifact"]["treehash"] == "sha1:0c6c284985577758b3a339c6215c9d4e3d71420e"
    @test !haskey(d["artifact"], "bundled_path")
    @test roundtrip_build(build) == build

    # A hand-written record whose libraries ship inside Julia names the directory
    # they ship in instead, in the same table
    shlibdir_build = mkbuild()
    @test shlibdir_build.artifact == JuliaBundledPath("private_shlibdir")
    d = generate_toml_dict(shlibdir_build)
    @test d["artifact"] == Dict("bundled_path" => "private_shlibdir")
    @test roundtrip_build(shlibdir_build) == shlibdir_build

    # Any Julia directory can be named, not just the shared library one
    bindir_build = mkbuild(; artifact = JuliaBundledPath("private_bindir"))
    @test generate_toml_dict(bindir_build)["artifact"]["bundled_path"] == "private_bindir"
    @test roundtrip_build(bindir_build) == bindir_build

    # `location` is gone: the table's own fields say which kind of binding it is,
    # and a table that says both or neither says nothing we can act on
    @test !any(haskey(generate_toml_dict(b), "location") for b in (build, shlibdir_build))
    @test_throws ArgumentError JLLGenerator.parse_artifact_dict(
        Dict("treehash" => "sha1:0c6c284985577758b3a339c6215c9d4e3d71420e",
             "download_sources" => [], "bundled_path" => "private_shlibdir"))
    @test_throws ArgumentError JLLGenerator.parse_artifact_dict(Dict("somewhere" => "else"))
    @test_throws ArgumentError JLLGenerator.parse_artifact_dict(Dict{String,Any}())

    # ... and a bundled build cannot be generated into a package, since
    # there is nothing to bind into `Artifacts.toml`
    jll = JLLInfo(; name = "Demo", version = v"1.0.0", builds = [shlibdir_build])
    mktempdir() do dir
        @test_throws ArgumentError generate_jll(dir, jll)
    end

    # A library entry must always state its path
    @test_throws KeyError parse_toml_dict(JLLLibraryProduct,
                        Dict("type" => "library", "name" => "libz", "soname" => "libz.so.1",
                             "deps" => [], "flags" => String[]))
end

@testset "JLL.toml format marker" begin
    jll = JLLInfo(; name = "Demo", version = v"1.0.0", builds = [
        JLLBuildInfo(; src_version = v"1.0.0", platform = Platform("x86_64", "linux"),
                     name = "Demo",
                     artifact = JLLArtifactBinding(
                        treehash = "0c6c284985577758b3a339c6215c9d4e3d71420e",
                        download_sources = []),
                     products = [JLLLibraryProduct(:libz, "lib/libz.so.1", [])],
                     licenses = [mit_license])])
    d = generate_toml_dict(jll)
    # We are versioning the format published JLLs already speak, not declaring a new one
    @test d["format_version"] == "1.0"
    @test d["format_version"] isa String
    @test parse_toml_dict(d) == jll

    # A published record predates the marker, and must still read
    legacy = copy(d); delete!(legacy, "format_version")
    @test parse_toml_dict(legacy) == jll
    # ... but a future major version has moved somewhere we cannot follow
    future = copy(d); future["format_version"] = "2.0"
    @test_throws ArgumentError parse_toml_dict(future)
    nonsense = copy(d); nonsense["format_version"] = "not-a-version"
    @test_throws ArgumentError parse_toml_dict(nonsense)

    # A JLL with no static library asks for nothing newer than any released wrapper
    mktempdir() do dir
        generate_jll(dir, jll)
        @test TOML.parsefile(joinpath(dir, "JLL.toml"))["format_version"] == "1.0"
        @test TOML.parsefile(joinpath(dir, "Project.toml"))["compat"]["LazyJLLWrappers"] == "1.0.0"
    end
end

@testset "Legacy v1 records" begin
    # A record exactly as published JLLs write one today: no `format_version` and no
    # `linkage`.  It must read, with sane defaults.
    legacy = Dict{String,Any}(
        "name" => "Legacy", "version" => "1.0.0", "julia_compat" => "1.6",
        "platform_augmentation_code" => "",
        "builds" => [Dict{String,Any}(
            "name" => "Legacy", "platform" => "x86_64-linux-gnu", "deps" => [],
            "lazy" => "false", "src_version" => "1.0.0", "sources" => [],
            "callback_defs" => Dict(), "auxilliary_artifacts" => Dict(),
            "licenses" => [Dict("filename" => "LICENSE.md", "license_text" => "x")],
            "artifact" => Dict("treehash" => "sha1:0c6c284985577758b3a339c6215c9d4e3d71420e",
                               "download_sources" => []),
            "products" => [
                Dict{String,Any}("type" => "library", "name" => "libz",
                                 "path" => "lib/libz.so.1", "soname" => "libz.so.1",
                                 "flags" => ["RTLD_LAZY"], "deps" => []),
                Dict{String,Any}("type" => "executable", "name" => "tool", "path" => "bin/tool"),
            ])])
    info = parse_toml_dict(legacy)
    build = only(info.builds)
    # A build whose `artifact` table carries a treehash binds an artifact, whether or
    # not the record ever said so in a `location`
    @test build.artifact isa JLLArtifactBinding
    @test string(build.artifact.treehash) == "sha1:0c6c284985577758b3a339c6215c9d4e3d71420e"
    libz = only([p for p in build.products if isa(p, JLLLibraryProduct)])
    # A library with no stated linkage is a shared library
    @test libz.path == "lib/libz.so.1"
    @test libz.soname == "libz.so.1"
    # The executable comes back untouched
    @test only([p for p in build.products if isa(p, JLLExecutableProduct)]).path == "bin/tool"

    # No released generator ever wrote a record without an `artifact` table (the v1
    # parser required the key), so absence is refused rather than defaulted
    bundled = deepcopy(legacy)
    delete!(only(bundled["builds"]), "artifact")
    @test_throws KeyError parse_toml_dict(bundled)

    # A stale `location` key is no longer read, and no longer stops a record parsing
    stale = deepcopy(legacy)
    only(stale["builds"])["location"] = "artifact"
    @test only(parse_toml_dict(stale).builds).artifact isa JLLArtifactBinding
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
            jll = Core.eval(m, :jll)
            @test jll == roundtrip_jll_through_toml(jll)[2]
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
        builds = [
            JLLBuildInfo(;
                src_version = v"1.2.13+1",
                deps = [],
                platform = Platform("aarch64", "linux"; libc = "glibc"),
                name = "Zlib",
                artifact = JLLArtifactBinding(
                    treehash = "0c6c284985577758b3a339c6215c9d4e3d71420e",
                    download_sources = [],
                ),
                products = zlib_products,
                licenses = [mit_license],
            ),
            JLLBuildInfo(;
                src_version = v"1.2.13+1",
                deps = [],
                platform = Platform("aarch64", "linux"; libc = "musl"),
                name = "Zlib",
                artifact = JLLArtifactBinding(
                    treehash = "377fed6108dca72651d7cb705a0aee7ce28d4a5b",
                    download_sources = [],
                ),
                products = zlib_products,
                licenses = [mit_license],
            ),
        ]
    )

    new_zlib_jll = JLLInfo(;
        name = "Zlib",
        version = v"1.2.13+1",
        builds = [
            JLLBuildInfo(;
                src_version = v"1.2.13+1",
                deps = [],
                platform = Platform("aarch64", "linux"; libc = "glibc"),
                name = "Zlib",
                artifact = JLLArtifactBinding(
                    treehash = "0c6c284985577758b3a339c6215c9d4e3d71420e",
                    download_sources = [],
                ),
                products = zlib_products,
                licenses = [mit_license],
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
        @test length(jll_dict.builds) == 2

        # Ensure that if we generate_jll() into the same location
        # we clear out extraneous files (but not `.git/*`) and
        # lose all previous content.
        generate_jll(dir, new_zlib_jll)
        jll_dict = parse_toml_dict(TOML.parsefile(joinpath(dir, "JLL.toml")))
        @test !isfile(joinpath(dir, "foo.txt"))
        @test isfile(joinpath(dir, ".git", "bar"))
        @test length(jll_dict.builds) == 1
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
    # Use special Ncurses_jll.jl because we do not yet have any JLLs built in the wild that have a `JLL.toml`.
    jll = JLLSource(PkgSpec(;
        name = "Ncurses_jll",
        uuid = "68e3532b-a499-55ff-9963-d1c0c0748b3a",
        tree_hash = Base.SHA1("f801fa135e0e3aa5b7ff026ff8b5fdcfefefdb3c"),
        repo=Pkg.Types.GitRepo(
            rev="3574bb57a8e29d239be1228fadbc1951ff7d50c6",
            source="https://github.com/staticfloat/Ncurses_jll.jl",
        ),
    ), Platform("aarch64", "linux"))

    mktempdir() do prefix
        prepare(jll; depot=prefix, ignore_empty_registries=true)
        data = parse_toml_dict(jll; depot=prefix)

        @test data.name == "Ncurses"
        for build in data.builds
            @test build.name == "Ncurses"
            @test length(build.products) == 4
        end
    end
end
