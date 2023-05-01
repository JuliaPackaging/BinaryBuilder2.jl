using Test, BinaryBuilderToolchains, BinaryBuilderSources, Base.BinaryPlatforms, Scratch

# Enable this for lots of JLLPrefixes output
const verbose = false

@testset "HostToolsToolchain" begin
    platform = CrossPlatform(HostPlatform() => HostPlatform())
    toolchain = HostToolsToolchain(platform)
    @test !isempty(filter(jll -> jll.package.name == "GNUMake_jll", toolchain.deps))
    @test !isempty(filter(jll -> jll.package.name == "Patchelf_jll", toolchain.deps))
    @test !isempty(filter(jll -> jll.package.name == "Ccache_jll", toolchain.deps))

    # Download the toolchain, make sure it runs
    srcs = toolchain_sources(toolchain)
    prepare(srcs; verbose)
    mktempdir(@get_scratch!("tempdirs")) do prefix
        deploy(srcs, prefix)
        env = toolchain_env(toolchain, prefix)
        # Do not allow external MAKEFLAGS to leak through:
        env = merge(env, Dict(
            "MAKEFLAGS" => nothing,
            "GNUMAKEFLAGS" => nothing
        ))

        # This list should more or less mirror the `default_tools` in 
        host_tools = [
            # Build tools
            "automake", "aclocal",
            "autoconf",
            "bison",
            "ccache",
            "file",
            "flex",
            "gawk",
            "make",
            "libtool",
            "m4",
            "patchelf",
            "perl",
            "patch",

            # Networking tools
            "curl",
            "git",

            # Compression tools
            "tar",
            "gzip",
            "zstd",
            "xz",
        ]
        for tool in host_tools
            # Ensure the tool comes from us
            @test startswith(readchomp(addenv(`sh -c "which $tool"`, env)), prefix)
            # Ensure it's runnable
            @test success(addenv(`$tool --version`, env))
        end

        # These tools require special treatment
        @test startswith(readchomp(addenv(`sh -c "which bzip2"`, env)), prefix)
        @test success(pipeline(addenv(`bzip2 --version`, env), stdout=devnull))

        # Run our more extensive test suites
        testsuite_path = joinpath(@__DIR__, "testsuite", "HostToolsToolchain")
        cd(testsuite_path) do
            p = run(addenv(`make cleancheck-all`, env))
            @test success(p)
        end
    end
end
