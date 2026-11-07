using Test, BinaryBuilderToolchains, BinaryBuilderPlatformExtensions, Base.BinaryPlatforms
using BinaryBuilderToolchains: macos_target_kernel_version, default_macos_kernel_version,
                               add_macos_flags, gcc_wrappers, clang_wrappers,
                               generate_cmake_toolchain_file

@testset "macOS deployment target" begin
    host = Platform("x86_64", "linux")
    # (target, expected darwin kernel version, expected macOS version)
    cases = [
        (Platform("x86_64", "macos"), v"14", "10.10"),
        (Platform("aarch64", "macos"), v"20", "11.0"),
        (Platform("x86_64", "macos"; os_version="16"), v"16", "10.12"),
        (Platform("aarch64", "macos"; os_version="20"), v"20", "11.0"),
    ]

    @testset "macos_target_kernel_version" begin
        @test default_macos_kernel_version("x86_64") == v"14"
        @test default_macos_kernel_version("aarch64") == v"20"
        @test_throws ArgumentError default_macos_kernel_version("armv7l")
        @test_throws ArgumentError macos_target_kernel_version(Platform("x86_64", "linux"))
        for (target, kver, _) in cases
            @test macos_target_kernel_version(target) == kver
        end
        # The platform passed in is left untouched
        p = Platform("x86_64", "macos")
        macos_target_kernel_version(p)
        @test os_version(p) === nothing
    end

    for (target, kver, mver) in cases
        cp = CrossPlatform(host => target)
        @testset "$(triplet(target))" begin
            # Toolchains keep the user-visible platform as given
            @test triplet(CToolchain(cp).platform.target) == triplet(target)

            # Binutils exports the deployment target
            env = toolchain_env(BinutilsToolchain(cp, :clang), "/prefix")
            @test env["MACOSX_DEPLOYMENT_TARGET"] == mver

            for vendor in (:gcc, :clang)
                toolchain = CToolchain(cp; vendor, use_ccache=false)
                io = IOBuffer()
                add_macos_flags(io, toolchain)
                flags = String(take!(io))
                @test occursin("-mmacosx-version-min=$(mver)", flags)
                @test occursin("-Wl,-sdk_version,$(mver)", flags)
                @test occursin("-D_DARWIN_FEATURE_CLOCK_GETTIME=0", flags) == (vendor == :gcc && kver < v"16")

                # Generated compiler wrappers carry the deployment target
                mktempdir() do dir
                    gen = vendor == :gcc ? gcc_wrappers : clang_wrappers
                    gen(toolchain, dir)
                    wrapper = joinpath(dir, "$(triplet(target))-$(vendor == :gcc ? "gcc" : "clang")")
                    @test isfile(wrapper)
                    @test occursin("-mmacosx-version-min=$(mver)", read(wrapper, String))
                end
            end

            # CMake toolchain file reports the matching Darwin version
            io = IOBuffer()
            generate_cmake_toolchain_file(CMakeToolchain(cp), io)
            cmake = String(take!(io))
            @test occursin("set(CMAKE_SYSTEM_VERSION $(kver.major).$(kver.minor))", cmake)
            @test occursin("set(DARWIN_MAJOR_VERSION $(kver.major))", cmake)
        end
    end
end
