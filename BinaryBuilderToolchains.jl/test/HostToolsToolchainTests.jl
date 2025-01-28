using Test, BinaryBuilderToolchains, BinaryBuilderSources, Base.BinaryPlatforms, Scratch
using HistoricalStdlibVersions

# Enable this for lots of JLLPrefixes output
const verbose = false

@testset "HostToolsToolchain" begin
    platform = CrossPlatform(BBHostPlatform() => HostPlatform())
    toolchain = HostToolsToolchain(platform)
    @test !isempty(filter(jll -> jll.package.name == "GNUMake_jll", toolchain.deps))
    @test !isempty(filter(jll -> jll.package.name == "Patchelf_jll", toolchain.deps))

    # Download the toolchain, make sure it runs.
    # We include a host-targeted C toolchain here, because our `autotools` test requires one.
    c_toolchain = CToolchain(platform; use_ccache=false)
    with_toolchains([toolchain, c_toolchain]) do prefix, env
        host_tools = [
            # Build tools
            "automake", "aclocal", "autoconf",
            "bison",
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
            "bzip2",
            "gzip",
            "zstd",
            "xz",
        ]
        for tool in host_tools
            @testset "$tool" begin
                # Ensure the tool comes from us
                @test startswith(readchomp(setenv(`sh -c "which $tool"`, env)), prefix)
                # Ensure it's runnable
                @test success(setenv(`$tool --version`, env))
            end
        end

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
    function stdlibs_for_version(version::VersionNumber)
        idx = findlast(((v, d),) -> v <= version, HistoricalStdlibVersions.STDLIBS_BY_VERSION)
        return HistoricalStdlibVersions.STDLIBS_BY_VERSION[idx][2]
    end
    function stdlibinfo_for_version(name::String, version::VersionNumber)
        stdlibs = stdlibs_for_version(version)
        return only(filter(info -> info.name == name, collect(values(stdlibs))))
    end

    julia_v1_11_host_platform = BBHostPlatform()
    julia_v1_11_host_platform["julia_version"] = "1.11.0"
    julia_v1_11_libcurl_stdlib_info = stdlibinfo_for_version(
        "LibCURL_jll",
        VersionNumber(julia_v1_11_host_platform["julia_version"]),
    )
    julia_v1_11_libcurl_version = julia_v1_11_libcurl_stdlib_info.version
    julia_v1_11_host_toolchain = HostToolsToolchain(CrossPlatform(julia_v1_11_host_platform => BBHostPlatform()))
    
    # Test that we get `CURL_jll` `v7``, not `v8`
    julia_v1_11_curl = only(filter(d -> d.package.name == "CURL_jll", julia_v1_11_host_toolchain.deps))
    free_curl = only(filter(d -> d.package.name == "CURL_jll", toolchain.deps))
    @test julia_v1_11_curl.package.version.major == julia_v1_11_libcurl_version.major
    @test julia_v1_11_curl.package.version.minor == julia_v1_11_libcurl_version.minor
    @test free_curl.package.version.major >= julia_v1_11_libcurl_version.major
    @test free_curl.package.version.major > julia_v1_11_libcurl_version.minor
end
