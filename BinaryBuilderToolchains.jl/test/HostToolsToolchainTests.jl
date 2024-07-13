using Test, BinaryBuilderToolchains, BinaryBuilderSources, Base.BinaryPlatforms, Scratch

# Enable this for lots of JLLPrefixes output
const verbose = false

@testset "HostToolsToolchain" begin
    platform = CrossPlatform(BBHostPlatform() => HostPlatform())
    toolchain = HostToolsToolchain(platform)
    @test !isempty(filter(jll -> jll.package.name == "GNUMake_jll", toolchain.deps))
    @test !isempty(filter(jll -> jll.package.name == "Patchelf_jll", toolchain.deps))
    @test !isempty(filter(jll -> jll.package.name == "Ccache_jll", toolchain.deps))

    # Download the toolchain, make sure it runs.
    # We include a host-targeted C toolchain here, because our `autotools` test requires one.
    c_toolchain = CToolchain(platform)
    with_toolchains([toolchain, c_toolchain]) do prefix, env
        # This list should more or less mirror the `default_tools` in 
        host_tools = [
            # Build tools
            "automake", "aclocal", "autoconf",
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
            @testset "$tool" begin
                # Ensure the tool comes from us
                @test startswith(readchomp(addenv(`sh -c "which $tool"`, env)), prefix)
                # Ensure it's runnable
                @test success(addenv(`$tool --version`, env))
            end
        end

        # These tools require special treatment
        @test startswith(readchomp(addenv(`sh -c "which bzip2"`, env)), prefix)
        @test success(pipeline(addenv(`bzip2 --version`, env), stdout=devnull))

        # Run our more extensive test suites.
        testsuite_path = joinpath(@__DIR__, "testsuite", "HostToolsToolchain")
        cd(testsuite_path) do
            p = run(setenv(`make -s cleancheck-all`, env))
            @test success(p)
        end
    end

    # Because the platform we define as a host can have things like `julia_version`
    # embedded within it if we use `HostPlatform()` rather than `BBHostPlatform()`,
    # let's just make sure that it does something reasonable:
    julia_v1_10_host_platform = BBHostPlatform()
    julia_v1_10_host_platform["julia_version"] = "1.10.2"
    julia_v1_10_host_toolchain = HostToolsToolchain(CrossPlatform(julia_v1_10_host_platform => BBHostPlatform()))
    
    # Test that we get `CURL_jll` `v7``, not `v8`
    julia_v1_10_curl = only(filter(d -> d.package.name == "CURL_jll", julia_v1_10_host_toolchain.deps))
    free_curl = only(filter(d -> d.package.name == "CURL_jll", toolchain.deps))
    @test julia_v1_10_curl.package.version.major == 7
    @test free_curl.package.version.major == 8
end
