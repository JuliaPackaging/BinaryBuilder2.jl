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

# Test that `LazyLirary` support works on Julias new enough to use it
if isdefined(Libdl, :LazyLibrary)
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
end
