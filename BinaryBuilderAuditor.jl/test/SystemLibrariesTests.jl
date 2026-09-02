using Test, BinaryBuilderAuditor, Base.BinaryPlatforms
using BinaryBuilderAuditor: is_system_library, system_library_linker_name,
                            known_system_libraries

@testset "system library linker names" begin
    linux = Platform("x86_64", "linux")
    @test system_library_linker_name("libm.so.6", linux) == "m"
    @test system_library_linker_name("libpthread.so.0", linux) == "pthread"
    @test system_library_linker_name("/usr/lib/libc.so.6", linux) == "c"
    @test system_library_linker_name("libc.musl-x86_64.so.1", linux) == "c"
    @test system_library_linker_name("libgcc_s.so.1", linux) == "gcc_s"
    # The comparison is case-insensitive on every platform
    @test system_library_linker_name("LIBM.SO.6", linux) == "m"
    # The dynamic loader is not a library one links against
    @test is_system_library("ld-linux-x86-64.so.2", linux)
    @test system_library_linker_name("ld-linux-x86-64.so.2", linux) === nothing
    @test system_library_linker_name("ld-musl-aarch64.so.1", linux) === nothing

    macos = Platform("aarch64", "macos")
    @test system_library_linker_name("libSystem.B.dylib", macos) == "System"
    @test system_library_linker_name("libc++.1.dylib", macos) == "c++"
    # `libobjc.a.dylib` is linked as `-lobjc`; no version-suffix stripping gets
    # there from the SONAME, which is why the SONAME to library-name mapping is
    # written down, never derived
    @test system_library_linker_name("libobjc.a.dylib", macos) == "objc"
    # Frameworks are not `-l`-linkable; their linker name is marked as such
    @test system_library_linker_name("CoreFoundation", macos) == "framework:CoreFoundation"
    @test is_system_library("/System/Library/Frameworks/CoreFoundation.framework/Versions/A/CoreFoundation", macos)

    windows = Platform("x86_64", "windows")
    @test system_library_linker_name("kernel32.dll", windows) == "kernel32"
    @test system_library_linker_name("libwinpthread-1.dll", windows) == "winpthread"
    @test system_library_linker_name("libgfortran-5.dll", windows) == "gfortran"
    # mingw links either unwinder flavour of libgcc through `libgcc_s.a`
    @test system_library_linker_name("libgcc_s_seh-1.dll", windows) == "gcc_s"
    @test system_library_linker_name("libgcc_s_sjlj-1.dll", windows) == "gcc_s"
    @test system_library_linker_name("dbghelp.dll", windows) == "dbghelp"
    @test system_library_linker_name("libz.so.6", Platform("x86_64", "freebsd")) == "z"
    # ucrt symbol-forwarding DLLs are system libraries, but nothing one links
    @test is_system_library("api-ms-win-crt-math-l1-1-0.dll", windows)
    @test system_library_linker_name("api-ms-win-crt-math-l1-1-0.dll", windows) === nothing

    # A SONAME outside the map is not a system library, and has no linker name:
    # unknown entries fail the audit loudly rather than being guessed at
    for platform in (linux, macos, windows, Platform("x86_64", "freebsd"))
        @test !is_system_library("libnope.so.99", platform)
        @test system_library_linker_name("libnope.so.99", platform) === nothing
    end

    # Every entry of every map carries a reviewed linker library name: a bare
    # `-l` name, a well-formed framework reference, or an explicit `nothing`
    for platform in (linux, macos, windows, Platform("x86_64", "freebsd"))
        for (soname, linker_name) in known_system_libraries(platform)
            @test linker_name === nothing || !isempty(linker_name)
            if linker_name !== nothing && startswith(linker_name, "framework:")
                @test Sys.isapple(platform)
                @test length(linker_name) > length("framework:")
            end
            # The gate and the linker names are one table by construction
            @test is_system_library(soname, platform)
        end
    end
end
