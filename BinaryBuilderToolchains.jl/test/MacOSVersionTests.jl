using Test, BinaryBuilderToolchains, BinaryBuilderPlatformExtensions, Base.BinaryPlatforms
using BinaryBuilderToolchains: macos_target_kernel_version, default_macos_kernel_version,
                               macos_sdk_platform, toolchain_jll_triplet,
                               add_macos_flags, gcc_wrappers, clang_wrappers, binutils_wrappers,
                               generate_cmake_toolchain_file
using BinaryBuilderSources: JLLSource

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

    @testset "macos_sdk_platform" begin
        @test_throws ArgumentError macos_sdk_platform(Platform("x86_64", "linux"))
        @test toolchain_jll_triplet(Platform("x86_64", "linux")) == "x86_64-linux-gnu"
        for (target, _, _) in cases
            sdk_target = macos_sdk_platform(target)
            @test os_version(sdk_target) == v"20"
            @test toolchain_jll_triplet(target) == "$(arch(target))-apple-darwin20"
            @test macos_sdk_platform(CrossPlatform(host => target)).target == sdk_target
        end
    end

    for (target, kver, mver) in cases
        cp = CrossPlatform(host => target)
        @testset "$(triplet(target))" begin
            # Toolchains keep the user-visible platform as given
            @test triplet(CToolchain(cp).platform.target) == triplet(target)

            # The darwin20-only toolchain JLLs are installed for the SDK's `os_version`
            jll_triplet = "$(arch(target))-apple-darwin20"
            for vendor in (:gcc, :clang)
                srcs = toolchain_sources(CToolchain(cp; vendor, use_ccache=false))
                for name in ("macOSSDK_jll", "CCTools_jll", "GCC_jll")
                    for src in filter(s -> s isa JLLSource && s.package.name == name, srcs)
                        src_target = src.platform isa CrossPlatform ? src.platform.target : src.platform
                        @test os_version(src_target) == v"20"
                    end
                end
            end

            # Binutils wrappers keep the target's names, but run the binaries the JLLs ship
            mktempdir() do dir
                binutils_wrappers(BinutilsToolchain(cp, :clang), dir)
                as_wrapper = read(joinpath(dir, "$(triplet(target))-as"), String)
                @test occursin("/bin/$(jll_triplet)-as", as_wrapper)
                @test occursin("CCTOOLS_CLANG_AS_EXECUTABLE='$(triplet(target))-clang-as'", as_wrapper)
                @test isfile(joinpath(dir, "$(triplet(target))-clang-as"))
                @test occursin("--target=$(triplet(target))", read(joinpath(dir, "$(triplet(target))-clang-as"), String))
                @test occursin("/bin/$(jll_triplet)-ld", read(joinpath(dir, "$(triplet(target))-ld"), String))
            end

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
                    wrapper_src = read(wrapper, String)
                    @test occursin("-mmacosx-version-min=$(mver)", wrapper_src)
                    if vendor == :gcc
                        @test occursin("/bin/$(jll_triplet)-gcc", wrapper_src)
                    else
                        @test occursin("--target=$(triplet(target))", wrapper_src)
                        @test occursin("--sysroot=\$(dirname \"\${WRAPPER_DIR}\")/clang/$(jll_triplet)", wrapper_src)
                    end
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
