using LazyJLLWrappers, Pkg, Test, JLLGenerator, Preferences, Libdl, Accessors

# For more debugging info, set `io = stdout`
function generate_and_load_jll(jllinfo, test_code::String;
                               extra_envs::Dict{String,String} = Dict{String,String}(),
                               extra_preferences::Dict{String,String} = Dict{String,String}(),
                               expect_cache_mismatch::Bool = false,
                               io::IO = devnull)
    mktempdir() do dir
        JLLGenerator.generate_jll(dir, jllinfo)
        Pkg.activate(dir) do
            Preferences.set_preferences!("$(jllinfo.name)_jll", pairs(extra_preferences)...)
            # Ensure we're using the current version of LazyJLLWrappers.jl
            Pkg.develop(;path=dirname(@__DIR__), io)
            Pkg.instantiate(;io)
        end

        withenv(extra_envs...) do
            cmd = `$(Base.julia_cmd()) --project=$(dir) -e "using Test, $(jllinfo.name)_jll; $(test_code)"`
            if expect_cache_mismatch
                stderr = IOBuffer()
                @test !success(run(pipeline(ignorestatus(cmd); stderr=stderr)))
                @test occursin("Cached host platform", String(take!(stderr)))
            else
                @test success(run(cmd))
            end
        end
    end
end

function only_foreign_platforms(jllinfo, host = HostPlatform())
    jllinfo = @set jllinfo.builds = filter(jllinfo.builds) do build
        return !platforms_match(build.platform, host)
    end
    return jllinfo
end

example_jllinfos_path = joinpath(@__DIR__, "..", "..", "JLLGenerator.jl", "contrib", "example_jllinfos")
@testset "JLL loading tests" begin
    # HelloWorldC_jll has `ExecutableProduct`s
    generate_and_load_jll(
        include(joinpath(example_jllinfos_path, "HelloWorldC_jll.jl")),
        """
        @test HelloWorldC_jll.is_available()
        @test success(hello_world())
        """,
    )

    # libxls_jll has `LibraryProduct`s, (with no library dependency structure)
    generate_and_load_jll(
        include(joinpath(example_jllinfos_path, "libxls_jll.jl")),
        """
        @test libxls_jll.is_available()
        @test unsafe_string(ccall((:xls_getVersion, libxlsreader), Cstring, ())) == "1.6.2"
        """,
    )

    # Vulkan_Headers_jll has `FileProduct`s and is not platform-specific
    generate_and_load_jll(
        include(joinpath(example_jllinfos_path, "Vulkan_Headers_jll.jl")),
        """
        @test Vulkan_Headers_jll.is_available()
        @test isfile(vulkan_hpp)
        """,
    )

    # Ncurses_jll has an `init_block` that must run on unixy systems.  Also test library products.
    generate_and_load_jll(
        include(joinpath(example_jllinfos_path, "Ncurses_jll.jl")),
        """
        @test Ncurses_jll.is_available()
        @test unsafe_string(ccall((:curses_version, libncurses), Cstring, ())) == "ncurses 6.4.20221231"
        if Sys.isunix()
            @test occursin(Ncurses_jll.terminfo, ENV["TERMINFO_DIRS"])
        end
        """,
    )

    # PlatformAugmentedHelloWorldC_jll just adds an extra tag to the platform it loads based on
    # an environment variable (which is a TERRIBLE idea but allows us to test things like mismatched
    # platforms and whatnot).
    generate_and_load_jll(
        include(joinpath(example_jllinfos_path, "PlatformAugmentedHelloWorldC_jll.jl")),
        """
        @test PlatformAugmentedHelloWorldC_jll.is_available()
        @test PlatformAugmentedHelloWorldC_jll.platform["augment"] == "true"
        """,
    )
    withenv("HELLO_WORLD_C_PLATFORM_AUGMENT" => "other") do
        generate_and_load_jll(
            include(joinpath(example_jllinfos_path, "PlatformAugmentedHelloWorldC_jll.jl")),
            """
            @test PlatformAugmentedHelloWorldC_jll.is_available()
            @test PlatformAugmentedHelloWorldC_jll.platform["augment"] == "other"
            """,
        )

        # This will cause a load failure, because the platform at runtime is different
        # from the platform at compile-time, which we do not allow.
        generate_and_load_jll(
            include(joinpath(example_jllinfos_path, "PlatformAugmentedHelloWorldC_jll.jl")),
            """
            @test PlatformAugmentedHelloWorldC_jll.is_available()
            @test PlatformAugmentedHelloWorldC_jll.platform["augment"] == "other"
            """;
            extra_envs = Dict("HELLO_WORLD_C_PLATFORM_AUGMENT" => "broken"),
            expect_cache_mismatch = true,
        )
    end

    # Test that we can override paths with preferences
    mktempdir() do dir
        generate_and_load_jll(
            include(joinpath(example_jllinfos_path, "HelloWorldC_jll.jl")),
            """
            @test HelloWorldC_jll.is_available()
            @test success(hello_world())
            @test startswith(HelloWorldC_jll.hello_world_doppelganger_path, "$(dir)")
            """,
            extra_preferences = Dict("hello_world_doppelganger_path" => dir)
        )
        generate_and_load_jll(
            include(joinpath(example_jllinfos_path, "Vulkan_Headers_jll.jl")),
            """
            @test Vulkan_Headers_jll.is_available()
            @test !isfile(vulkan_hpp)
            """,
            extra_preferences = Dict("vulkan_hpp_path" => dir)
        )
    end

    # Test that loading a JLL with no matching platforms doesn't error.
    generate_and_load_jll(
        only_foreign_platforms(include(joinpath(example_jllinfos_path, "HelloWorldC_jll.jl"))),
        """
        @test !HelloWorldC_jll.is_available()
        @test !isdefined(HelloWorldC_jll, :hello_world)
        @test isdefined(HelloWorldC_jll, :eager_mode)
        @test HelloWorldC_jll.eager_mode() === nothing
        """,
    )
end

# Test that `LazyLibrary` support works on Julias new enough to use it
if LazyJLLWrappers.use_lazy_libraries()
    @testset "Laziness" begin
        generate_and_load_jll(
            include(joinpath(example_jllinfos_path, "Ncurses_jll.jl")),
            """
            using Libdl
            @test Ncurses_jll.is_available()
            @test isempty(filter(l -> occursin("libncurses", l), Libdl.dllist()))
            @test isempty(filter(l -> occursin("libpanel", l), Libdl.dllist()))
            @test unsafe_string(ccall((:curses_version, libncurses), Cstring, ())) == "ncurses 6.4.20221231"
            @test !isempty(filter(l -> occursin("libncurses", l), Libdl.dllist()))
            @test isempty(filter(l -> occursin("libpanel", l), Libdl.dllist()))
            """,
        )
    end

    @testset "LazyLibrary path contract" begin
        generate_and_load_jll(
            include(joinpath(example_jllinfos_path, "libxls_jll.jl")),
            """
            import Libdl, LazyJLLWrappers
            @test libxlsreader.path isa Union{String, Libdl.LazyLibraryPath}
            @test libxlsreader.path.pieces[1] isa LazyJLLWrappers.LazyArtifactDir
            @test unsafe_string(ccall((:xls_getVersion, libxlsreader), Cstring, ())) == "1.6.2"
            """,
        )
    end
end

using Base.BinaryPlatforms: Platform
@testset "system_deps are ignored, toolchain-runtime edges are dependencies" begin
    # A record may name the system libraries a product links against
    # (`system_deps`), and may depend on a `CompilerSupportLibraries_jll` product
    # for its toolchain runtime.  The former is of no concern to the wrapper; the
    # latter is an ordinary cross-JLL dependency edge.
    platform = Platform("x86_64", "linux")
    csl_uuid = Base.UUID("e66e0078-7015-5450-92f7-15fbd957f2ae")
    jllinfo = JLLInfo(;
        name = "Foo",
        version = v"1.0.0",
        builds = [
            JLLBuildInfo(;
                src_version = v"1.0.0",
                deps = [JLLPackageDependency("CompilerSupportLibraries_jll", csl_uuid, "*")],
                sources = [],
                platform,
                name = "Foo",
                artifact = JLLArtifactBinding(;
                    treehash = "0000000000000000000000000000000000000000",
                    download_sources = [],
                ),
                products = [
                    JLLLibraryProduct(
                        :libfoo,
                        "lib/libfoo.so.1",
                        [JLLLibraryDep(:CompilerSupportLibraries_jll, :libgcc_s)],
                        [JLLLibraryDep(:Glibc_jll, :libc), JLLLibraryDep(:CompilerSupportLibraries_jll, :libstdcxx)];
                        soname = "libfoo.so.1",
                    ),
                ],
                licenses = [JLLBuildLicense("LICENSE.md", JLLGenerator.get_license_text("MIT"))],
            ),
        ],
    )
    toml = JLLGenerator.generate_toml_dict(jllinfo)
    build = only(toml["builds"])
    @test only(build["products"])["system_deps"] == ["Glibc_jll.libc", "CompilerSupportLibraries_jll.libstdcxx"]

    # Generate the wrapper for this build directly, as `@generate_jll_from_toml`
    # would.  The generator consults the JLL module only for its preferences, so
    # any loaded package module stands in for it here.
    jb = LazyJLLWrappers.JLLBlocks(LazyJLLWrappers)
    LazyJLLWrappers.top_level_statements(jb, build, platform)
    LazyJLLWrappers.library_product_definition(jb, build, only(build["products"]))
    code = string(LazyJLLWrappers.synthesize(jb))

    # The dependency package is loaded and the edge is expressed against its product
    @test contains(code, "using CompilerSupportLibraries_jll")
    @test contains(code, "CompilerSupportLibraries_jll.libgcc_s")
    # The system libraries do not appear anywhere in the wrapper, whoever owns them
    @test !contains(code, "system_deps")
    @test !contains(code, "Glibc_jll")
    @test !contains(code, "libstdcxx")
end
