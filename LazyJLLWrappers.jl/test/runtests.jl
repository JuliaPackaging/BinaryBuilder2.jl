using LazyJLLWrappers, Pkg, Test, JLLGenerator, Preferences, Libdl, Accessors, TOML

# The Julia that installs and loads the generated JLLs: the one running these tests,
# unless `LAZYJLLWRAPPERS_TEST_JULIA` names another Julia executable.  That lets the
# JLLs be tested on Julia versions too old to run JLLGenerator itself.
const target_julia = haskey(ENV, "LAZYJLLWRAPPERS_TEST_JULIA") ?
    `$(ENV["LAZYJLLWRAPPERS_TEST_JULIA"]) --startup-file=no` : Base.julia_cmd()
const target_version = VersionNumber(readchomp(`$(target_julia) -e "print(VERSION)"`))
const target_uses_lazy_libraries =
    parse(Bool, readchomp(`$(target_julia) -e "using Libdl; print(isdefined(Libdl, :LazyLibrary))"`))
@info("Loading generated JLLs with Julia $(target_version)")

# For more debugging info, set `io = stdout`
function generate_and_load_jll(jllinfo, test_code::String;
                               extra_envs::Dict{String,String} = Dict{String,String}(),
                               extra_preferences::Dict{String,String} = Dict{String,String}(),
                               expect_cache_mismatch::Bool = false,
                               io::IO = devnull)
    # LazyJLLWrappers supports preferences and platform augmentation from Julia v1.6 on.
    if target_version < v"1.6" &&
       (!isempty(extra_preferences) || !isempty(jllinfo.platform_augmentation_code))
        @info("Skipping $(jllinfo.name)_jll test: needs Julia v1.6 or later")
        return
    end

    # When the target Julia is older than the JLL's julia compat, drop the builds for
    # platforms it does not know, as a JLL made for that Julia would.  (`AnyPlatform`
    # builds load anywhere, though `guess_julia_compat()` asks v1.6 for them.)
    if target_version ∉ Pkg.Types.semver_spec(jllinfo.julia_compat)
        jllinfo = @set jllinfo.builds = filter(jllinfo.builds) do build
            return build.platform isa AnyPlatform ||
                   target_version ∈ Pkg.Types.semver_spec(JLLGenerator.guess_julia_compat([build]))
        end
        jllinfo = @set jllinfo.julia_compat = "$(target_version.major).$(target_version.minor)"
    end
    mktempdir() do dir
        JLLGenerator.generate_jll(dir, jllinfo)
        # The JLL may ask for a `LazyJLLWrappers` release newer than this checkout, when
        # it uses a feature this checkout adds; it is this checkout that is under test.
        project = TOML.parsefile(joinpath(dir, "Project.toml"))
        if pkgversion(LazyJLLWrappers) ∉ Pkg.Types.semver_spec(project["compat"]["LazyJLLWrappers"])
            project["compat"]["LazyJLLWrappers"] = string(pkgversion(LazyJLLWrappers))
            open(io -> TOML.print(io, project), joinpath(dir, "Project.toml"); write=true)
        end
        Pkg.activate(dir) do
            Preferences.set_preferences!("$(jllinfo.name)_jll", pairs(extra_preferences)...)
        end
        # Ensure we're using the current version of LazyJLLWrappers.jl
        install_code = """
        using Pkg
        Pkg.develop(PackageSpec(path = $(repr(dirname(@__DIR__)))))
        Pkg.instantiate()
        """
        run(pipeline(`$(target_julia) --project=$(dir) -e $(install_code)`; stdout = io, stderr = io))

        withenv(extra_envs...) do
            cmd = `$(target_julia) --project=$(dir) -e "using Test, $(jllinfo.name)_jll; $(test_code)"`
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

    # FlavoredHelloWorldC_jll has two builds for the host platform that differ only by a
    # `flavor` tag that the host platform lacks.  Without augmentation, the `flavor+zzz`
    # build (a foreign binary) would be chosen; the augmentation selects `flavor+native`,
    # both when Pkg installs the artifacts and when the JLL is loaded.
    let hwc = include(joinpath(example_jllinfos_path, "HelloWorldC_jll.jl"))
        host_build = only(filter(b -> platforms_match(b.platform, HostPlatform()), hwc.builds))
        foreign_build = first(filter(b -> !platforms_match(b.platform, HostPlatform()), hwc.builds))
        flavored(build, flavor) = JLLBuildInfo(;
            src_version = build.src_version,
            deps = build.deps,
            sources = build.sources,
            platform = Platform(arch(host_build.platform), os(host_build.platform);
                                (Symbol(k) => v for (k, v) in tags(host_build.platform) if k ∉ ("arch", "os"))...,
                                flavor),
            name = "FlavoredHelloWorldC",
            artifact = build.artifact,
            products = build.products,
            licenses = build.licenses,
        )
        jll = JLLInfo(;
            name = "FlavoredHelloWorldC",
            version = hwc.version,
            builds = [flavored(host_build, "native"), flavored(foreign_build, "zzz")],
            platform_augmentation_code = """
            function augment_platform!(p::Platform)
                if !haskey(p, "flavor")
                    p["flavor"] = "native"
                end
                return p
            end
            """,
        )
        host_treehash = string(host_build.artifact.treehash)[6:end]
        generate_and_load_jll(
            jll,
            """
            using Pkg
            @test FlavoredHelloWorldC_jll.platform["flavor"] == "native"
            @test occursin("$(host_treehash)", hello_world().exec[1])
            @test success(hello_world())
            # Pkg applies the augmentation when installing artifacts from Julia v1.7 on
            if VERSION >= v"1.7"
                installed = only(Pkg.Operations.collect_artifacts(dirname(dirname(pathof(FlavoredHelloWorldC_jll)))))[2]
                @test installed["FlavoredHelloWorldC"]["git-tree-sha1"] == "$(host_treehash)"
            end
            """,
        )
    end

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
if target_uses_lazy_libraries
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

@testset "PATH and LIBPATH hold directories" begin
    generate_and_load_jll(
        include(joinpath(example_jllinfos_path, "HelloWorldC_jll.jl")),
        """
        @test HelloWorldC_jll.is_available()
        @test dirname(HelloWorldC_jll.hello_world_path) in HelloWorldC_jll.PATH_list
        @test all(isdir, HelloWorldC_jll.PATH_list)
        @test dirname(HelloWorldC_jll.hello_world_path) in split(HelloWorldC_jll.PATH[], $(repr(LazyJLLWrappers.pathsep)))
        """,
    )

    generate_and_load_jll(
        include(joinpath(example_jllinfos_path, "libxls_jll.jl")),
        """
        @test libxls_jll.is_available()
        @test dirname(libxls_jll.libxlsreader_path) in libxls_jll.LIBPATH_list
        @test all(isdir, libxls_jll.LIBPATH_list)
        @test dirname(libxls_jll.libxlsreader_path) in split(libxls_jll.LIBPATH[], $(repr(LazyJLLWrappers.pathsep)))
        """,
    )
end

using Base.BinaryPlatforms: Platform
@testset "system_deps are ignored by the wrapper" begin
    # A record may name the system libraries a product links against; the
    # wrapper has no use for them and must not mention them.
    platform = Platform("x86_64", "linux")
    jllinfo = JLLInfo(;
        name = "Foo",
        version = v"1.0.0",
        builds = [
            JLLBuildInfo(;
                src_version = v"1.0.0",
                deps = [],
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
                        [],
                        ["c", "m", "stdc++"];
                        soname = "libfoo.so.1",
                    ),
                ],
                licenses = [JLLBuildLicense("LICENSE.md", JLLGenerator.get_license_text("MIT"))],
            ),
        ],
    )
    toml = JLLGenerator.generate_toml_dict(jllinfo)
    build = only(toml["builds"])
    @test only(build["products"])["system_deps"] == ["c", "m", "stdc++"]

    # Generate the wrapper for this build directly, as `@generate_jll_from_toml`
    # would.  The generator consults the JLL module only for its preferences, so
    # any loaded package module stands in for it here.
    jb = LazyJLLWrappers.JLLBlocks(LazyJLLWrappers)
    LazyJLLWrappers.top_level_statements(jb, build, platform)
    LazyJLLWrappers.library_product_definition(jb, build, only(build["products"]))
    code = string(LazyJLLWrappers.synthesize(jb))
    @test contains(code, "libfoo")
    @test !contains(code, "system_deps")
    @test !contains(code, "stdc++")
end

@testset "static libraries are ignored by the wrapper" begin
    # The wrapper defines nothing for a static library, so it must export nothing for
    # one either.  `libxlsreader` also ships as an archive (a same-named second entry)
    # and `libxls_static` ships only as one.
    jllinfo = include(joinpath(example_jllinfos_path, "libxls_jll.jl"))
    jllinfo = @set jllinfo.builds = map(jllinfo.builds) do build
        static_products = [
            JLLStaticLibraryProduct(:libxlsreader, "lib/libxlsreader.a"),
            JLLStaticLibraryProduct(:libxls_static, "lib/libxls_static.a"),
        ]
        return @set build.products = vcat(build.products, static_products)
    end
    generate_and_load_jll(
        jllinfo,
        """
        exported = names(libxls_jll)
        @test count(==(:libxlsreader), exported) == 1
        @test :libxls_static ∉ exported
        @test !isdefined(libxls_jll, :libxls_static)
        @test unsafe_string(ccall((:xls_getVersion, libxlsreader), Cstring, ())) == "1.6.2"
        """,
    )
end

@testset "dont_dlopen libraries are not eagerly loaded" begin
    jllinfo = include(joinpath(example_jllinfos_path, "libxls_jll.jl"))
    jllinfo = @set jllinfo.builds = map(jllinfo.builds) do build
        return @set build.products = map(build.products) do p
            return JLLLibraryProduct(p.varname, p.path, p.deps, p.system_deps;
                                     soname = p.soname, flags = p.flags,
                                     on_load_callback = p.on_load_callback,
                                     dont_dlopen = true)
        end
    end
    generate_and_load_jll(
        jllinfo,
        """
        import Libdl, LazyJLLWrappers
        @test libxls_jll.is_available()
        @test isabspath(libxls_jll.libxlsreader_path)
        @test isfile(libxls_jll.libxlsreader_path)
        @test isempty(filter(l -> occursin("libxlsreader", l), Libdl.dllist()))
        if VERSION < v"1.6"
            # The exported variable is the constant SONAME, which `ccall()` finds only
            # once the library has been loaded
            @test !isabspath(libxlsreader)
            Libdl.dlopen(libxls_jll.libxlsreader_path)
        elseif !LazyJLLWrappers.use_lazy_libraries()
            # The exported variable still names the library's absolute path
            @test libxlsreader == libxls_jll.libxlsreader_path
        end
        @test unsafe_string(ccall((:xls_getVersion, libxlsreader), Cstring, ())) == "1.6.2"
        @test !isempty(filter(l -> occursin("libxlsreader", l), Libdl.dllist()))
        """,
    )

    # Without the flag, the eager regime loads the library in `__init__()`
    if !target_uses_lazy_libraries
        generate_and_load_jll(
            include(joinpath(example_jllinfos_path, "libxls_jll.jl")),
            """
            import Libdl
            @test !isempty(filter(l -> occursin("libxlsreader", l), Libdl.dllist()))
            """,
        )
    end
end

@testset "on_load_callback runs when the library is loaded" begin
    jllinfo = include(joinpath(example_jllinfos_path, "libxls_jll.jl"))
    jllinfo = @set jllinfo.builds = map(jllinfo.builds) do build
        build = @set build.callback_defs = Dict{Symbol,String}(
            :xls_loaded => "xls_loaded() = (global XLS_CALLBACK_RAN = true; nothing)",
        )
        return @set build.products = map(build.products) do p
            return JLLLibraryProduct(p.varname, p.path, p.deps, p.system_deps;
                                     soname = p.soname, flags = p.flags,
                                     on_load_callback = :xls_loaded,
                                     dont_dlopen = p.dont_dlopen)
        end
    end

    # A `LazyLibrary` runs the callback on its first `dlopen()`, the eager regime
    # runs it in `__init__()`.
    generate_and_load_jll(
        jllinfo,
        """
        import LazyJLLWrappers
        @test isdefined(libxls_jll, :XLS_CALLBACK_RAN) == !LazyJLLWrappers.use_lazy_libraries()
        @test unsafe_string(ccall((:xls_getVersion, libxlsreader), Cstring, ())) == "1.6.2"
        @test libxls_jll.XLS_CALLBACK_RAN
        """,
    )

    # `eager_mode()` loads every library, so it must run the callback as well.
    generate_and_load_jll(
        jllinfo,
        """
        libxls_jll.eager_mode()
        @test libxls_jll.XLS_CALLBACK_RAN
        """,
    )
end

@testset "library aliases name the same library" begin
    jllinfo = include(joinpath(example_jllinfos_path, "libxls_jll.jl"))
    jllinfo = @set jllinfo.builds = map(jllinfo.builds) do build
        build = @set build.callback_defs = Dict{Symbol,String}(
            :xls_loaded => "xls_loaded() = (global XLS_CALLBACK_RUNS = (isdefined(@__MODULE__, :XLS_CALLBACK_RUNS) ? XLS_CALLBACK_RUNS : 0) + 1; nothing)",
        )
        return @set build.products = map(build.products) do p
            isa(p, JLLLibraryProduct) || return p
            return JLLLibraryProduct(p.varname, p.path, p.deps, p.system_deps;
                                     soname = p.soname, flags = p.flags,
                                     on_load_callback = :xls_loaded,
                                     dont_dlopen = p.dont_dlopen,
                                     aliases = [:libxlsalias])
        end
    end
    generate_and_load_jll(
        jllinfo,
        """
        import LazyJLLWrappers
        @test :libxlsalias ∈ names(libxls_jll)
        @test libxlsalias === libxlsreader
        @test libxls_jll.libxlsalias_path == libxls_jll.libxlsreader_path
        @test isfile(libxls_jll.libxlsalias_path)
        @test unsafe_string(ccall((:xls_getVersion, libxlsalias), Cstring, ())) == "1.6.2"
        @test unsafe_string(ccall((:xls_getVersion, libxlsreader), Cstring, ())) == "1.6.2"
        # One library, so its callback runs once
        @test libxls_jll.XLS_CALLBACK_RUNS == 1
        """,
    )

    # A preference overriding the library's path applies to the alias as well.  (The
    # override names no real library, so this needs a regime that does not load it.)
    target_uses_lazy_libraries && mktempdir() do dir
        override = joinpath(dir, "libxlsreader_override")
        generate_and_load_jll(
            jllinfo,
            """
            @test libxls_jll.libxlsreader_path == $(repr(override))
            @test libxls_jll.libxlsalias_path == $(repr(override))
            """;
            extra_preferences = Dict("libxlsreader_path" => override),
        )
    end
end

@testset "executable and file aliases name the same product" begin
    with_aliases(jllinfo, varname, aliases) = @set jllinfo.builds = map(jllinfo.builds) do build
        return @set build.products = map(build.products) do p
            p.varname == varname || return p
            return typeof(p)(p.varname, p.path; aliases)
        end
    end

    jllinfo = with_aliases(include(joinpath(example_jllinfos_path, "HelloWorldC_jll.jl")), :hello_world, [:hello_alias])
    generate_and_load_jll(
        jllinfo,
        """
        @test :hello_alias ∈ names(HelloWorldC_jll)
        @test hello_alias === hello_world
        @test HelloWorldC_jll.hello_alias_path == HelloWorldC_jll.hello_world_path
        @test isfile(HelloWorldC_jll.hello_alias_path)
        @test success(hello_alias())
        """,
    )

    jllinfo = with_aliases(include(joinpath(example_jllinfos_path, "Vulkan_Headers_jll.jl")), :vulkan_hpp, [:vulkan_hpp_alias])
    generate_and_load_jll(
        jllinfo,
        """
        @test :vulkan_hpp_alias ∈ names(Vulkan_Headers_jll)
        @test vulkan_hpp_alias == vulkan_hpp
        @test isfile(vulkan_hpp_alias)
        @test Vulkan_Headers_jll.vulkan_hpp_alias_path == Vulkan_Headers_jll.vulkan_hpp_path
        """,
    )

    # A preference overriding the product's path applies to the alias as well
    mktempdir() do dir
        generate_and_load_jll(
            jllinfo,
            """
            @test vulkan_hpp_alias == vulkan_hpp == $(repr(dir))
            @test Vulkan_Headers_jll.vulkan_hpp_alias_path == $(repr(dir))
            """;
            extra_preferences = Dict("vulkan_hpp_path" => dir),
        )
    end
end

@testset "builds for unparseable platforms are skipped" begin
    # Older Julias cannot parse some triplets (e.g. `riscv64` before v1.10); such
    # builds must not prevent selecting among the ones that do parse.
    host = HostPlatform()
    builds = [
        Dict{String,Any}("name" => "Foo", "platform" => triplet(host)),
        Dict{String,Any}("name" => "Foo", "platform" => "notanarch-linux-gnu"),
    ]
    @test LazyJLLWrappers.select_artifact(builds, "Foo", host) === builds[1]
    @test LazyJLLWrappers.select_artifact(builds[2:2], "Foo", host) === nothing
end
