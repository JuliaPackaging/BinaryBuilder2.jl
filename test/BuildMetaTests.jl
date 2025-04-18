using Test, BinaryBuilder2, Pkg
using BinaryBuilder2: parse_build_tarballs_args, universes_dir
using Base.BinaryPlatforms

# Ensure that, when testing, we do not attempt to authenticate to GitHub
BinaryBuilder2.allow_github_authentication[] = false
@testset "BuildMeta" begin
    @testset "parse_build_tarballs_args" begin
        # Ensure that we get very simple defaults for no args
        parsed_kwargs = parse_build_tarballs_args(String[])
        @test !parsed_kwargs[:verbose]
        @test !parsed_kwargs[:disable_cache]
        @test parsed_kwargs[:universe_name] === nothing
        @test parsed_kwargs[:deploy_org] === nothing
        @test !haskey(parsed_kwargs, :debug_modes)
        @test !haskey(parsed_kwargs, :register_depot)
        @test !haskey(parsed_kwargs, :target_list)

        # Next, turn on options that have defaults
        parsed_kwargs = parse_build_tarballs_args(String[
            "--verbose",
            "--debug",
            "--meta-json",
            "--deploy",
        ])
        @test parsed_kwargs[:verbose]
        @test parsed_kwargs[:debug_modes] == Set(["build-error","extract-error"])
        @test parsed_kwargs[:json_output] == Base.stdout
        @test parsed_kwargs[:deploy_org] === nothing
        @test !haskey(parsed_kwargs, :target_list)

        # Next, supply arguments to them all
        parsed_kwargs = parse_build_tarballs_args(String[
            "--debug=build-start",
            "--meta-json=meta.json",
            "--deploy=JuliaBinaryWrappers",
            "--universe=the_verse",
            "x86_64-apple-darwin14,aarch64-linux-musl,i686-linux-gnu-libgfortran3-cxx11",
        ])
        @test parsed_kwargs[:debug_modes] == Set(["build-start"])
        @test parsed_kwargs[:json_output] == "meta.json"
        @test parsed_kwargs[:deploy_org] == "JuliaBinaryWrappers"
        @test parsed_kwargs[:universe_name] == "the_verse"
        @test parsed_kwargs[:target_list] == [
            Platform("x86_64", "macos"; os_version=v"14"),
            Platform("aarch64", "linux"; libc="musl"),
            Platform("i686", "linux"; libgfortran_version=v"3", cxxstring_abi="cxx11"),
        ]
    end

    @testset "BuildMeta" begin
        # First, test default options
        meta = BuildMeta()
        @test isempty(meta.builds)
        @test isempty(meta.extractions)
        @test isempty(meta.packagings)
        @test isempty(meta.target_list)
        @test !meta.verbose
        @test isempty(meta.debug_modes)
        @test meta.universe.name === nothing
        @test !meta.universe.persistent
        @test !meta.build_cache_disabled
        @test isempty(meta.dry_run)
        @test meta.json_output === nothing
        @test !meta.register

        # Now, provide parameters for all sorts of stuff
        universe_name = "BB2_test_universe-$(time())"
        meta = BuildMeta(;
            target_list=[
                Platform("x86_64", "linux"),
                Platform("i686", "windows"),
            ],
            verbose=true,
            debug_modes=["build-stop"],
            dry_run=Symbol[],
            json_output=Base.stdout,
            deploy_org="JuliaBinaryWrappers",
            universe_name,
            register=true,
        )
        @test isempty(meta.builds)
        @test isempty(meta.extractions)
        @test isempty(meta.packagings)
        @test length(meta.target_list) == 2
        @test os(meta.target_list[1]) == "linux"
        @test os(meta.target_list[2]) == "windows"
        @test meta.verbose
        @test meta.debug_modes == Set(["build-stop"])
        @test isempty(meta.dry_run)
        @test meta.json_output == Base.stdout
        @test meta.register
        @test meta.universe.name == universe_name
        @test meta.universe.deploy_org == "JuliaBinaryWrappers"

        # Always try to clean up the universe, so we don't leak it.
        cleanup(meta.universe)

        # Next, test some errors
        @test_throws ArgumentError BuildMeta(;debug_modes=["foo"])
        @test_throws ArgumentError BuildMeta(;register=true)

        # Next, test end-to-end parsing of ARGS-style options
        json_path=mktemp()[1]
        meta = BuildMeta([
            "--verbose",
            "--debug=start",
            "--meta-json=$(json_path)",
            "--deploy=JuliaBinaryWrappers",
            "--register",
            "--universe=$(universe_name)",
            "x86_64-linux-gnu,x86_64-linux-musl,i686-linux-gnu"
        ])
        @test isempty(meta.builds)
        @test isempty(meta.extractions)
        @test isempty(meta.packagings)
        @test length(meta.target_list) == 3
        @test all(os.(meta.target_list) .== "linux")
        @test meta.verbose
        @test meta.debug_modes == Set(["build-start", "extract-start"])
        @test isempty(meta.dry_run)
        @test isa(meta.json_output, IOStream)
        @test meta.json_output.name == "<file $(json_path)>"
        @test meta.register
        @test meta.universe.name == universe_name
        @test meta.universe.deploy_org == "JuliaBinaryWrappers"
    end
end
