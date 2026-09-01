using Test, BinaryBuilderAuditor, JLLGenerator, Base.BinaryPlatforms
using BinaryBuilderAuditor: is_system_library, system_library_identity, known_system_libraries,
                            system_library_uuids

@testset "system library table" begin
    linux = Platform("x86_64", "linux")
    macos = Platform("aarch64", "macos")
    windows = Platform("x86_64", "windows")
    freebsd = Platform("x86_64", "freebsd")
    all_platforms = (linux, macos, windows, freebsd)

    @testset "identities" begin
        # The C library and its companions belong to the libc JLLs
        @test system_library_identity("libc.so.6", linux) == JLLLibraryDep(:Glibc_jll, :libc)
        @test system_library_identity("/usr/lib/libm.so.6", linux) == JLLLibraryDep(:Glibc_jll, :libm)
        @test system_library_identity("libpthread.so.0", linux) == JLLLibraryDep(:Glibc_jll, :libpthread)
        @test system_library_identity("libresolv.so.2", linux) == JLLLibraryDep(:Glibc_jll, :libresolv)
        @test system_library_identity("libc.musl-x86_64.so.1", linux) == JLLLibraryDep(:Musl_jll, :libc)
        @test system_library_identity("libc.so", linux) == JLLLibraryDep(:Musl_jll, :libc)
        # The toolchain runtime belongs to CompilerSupportLibraries_jll, on every platform
        @test system_library_identity("libgcc_s.so.1", linux) == JLLLibraryDep(:CompilerSupportLibraries_jll, :libgcc_s)
        @test system_library_identity("libstdc++.so.6", linux) == JLLLibraryDep(:CompilerSupportLibraries_jll, :libstdcxx)
        @test system_library_identity("libgcc_s.1.1.dylib", macos) == JLLLibraryDep(:CompilerSupportLibraries_jll, :libgcc_s)
        @test system_library_identity("libgcc_s_seh-1.dll", windows) == JLLLibraryDep(:CompilerSupportLibraries_jll, :libgcc_s)
        @test system_library_identity("libgcc_s_sjlj-1.dll", windows) == JLLLibraryDep(:CompilerSupportLibraries_jll, :libgcc_s)
        @test system_library_identity("libgfortran-5.dll", windows) == JLLLibraryDep(:CompilerSupportLibraries_jll, :libgfortran)
        @test system_library_identity("libquadmath.so.0", linux) == JLLLibraryDep(:CompilerSupportLibraries_jll, :libquadmath)
        @test system_library_identity("libgcc_s.so.1", freebsd) == JLLLibraryDep(:CompilerSupportLibraries_jll, :libgcc_s)
        # Everything no package provides is SystemLibraries_jll
        @test system_library_identity("libSystem.B.dylib", macos) == JLLLibraryDep(:SystemLibraries_jll, :libSystem)
        @test system_library_identity("CoreFoundation", macos) == JLLLibraryDep(:SystemLibraries_jll, :CoreFoundation)
        @test system_library_identity("/System/Library/Frameworks/CoreFoundation.framework/Versions/A/CoreFoundation", macos) == JLLLibraryDep(:SystemLibraries_jll, :CoreFoundation)
        @test system_library_identity("kernel32.dll", windows) == JLLLibraryDep(:SystemLibraries_jll, :kernel32)
        @test system_library_identity("libc.so.7", freebsd) == JLLLibraryDep(:SystemLibraries_jll, :libc)
        @test system_library_identity("libz.so.6", freebsd) == JLLLibraryDep(:SystemLibraries_jll, :libz)
        # The comparison is case-insensitive on every platform
        @test system_library_identity("LIBM.SO.6", linux) == system_library_identity("libm.so.6", linux)
        @test system_library_identity("KERNEL32.DLL", windows) == system_library_identity("kernel32.dll", windows)
    end

    @testset "system libraries no library depends on" begin
        # The dynamic loader is a system library, but has no identity to record
        @test is_system_library("ld-linux-x86-64.so.2", linux)
        @test system_library_identity("ld-linux-x86-64.so.2", linux) === nothing
        @test system_library_identity("ld-musl-aarch64.so.1", linux) === nothing
        # ucrt symbol-forwarding DLLs likewise
        @test is_system_library("api-ms-win-crt-math-l1-1-0.dll", windows)
        @test system_library_identity("api-ms-win-crt-math-l1-1-0.dll", windows) === nothing
    end

    @testset "unknown SONAMEs" begin
        # A SONAME outside the map is not a system library: unknown entries fail
        # the audit loudly rather than being guessed at
        for platform in all_platforms
            @test !is_system_library("libnope.so.99", platform)
            @test system_library_identity("libnope.so.99", platform) === nothing
        end
    end

    @testset "table invariants" begin
        for platform in all_platforms
            for (soname, identity) in known_system_libraries(platform)
                # Keys are stored lowercased, matching the case-insensitive lookup
                @test soname == lowercase(soname)
                # The gate and the table are one and the same by construction
                @test is_system_library(soname, platform)
                identity === nothing && continue
                # Every identity's module has a UUID
                @test haskey(system_library_uuids, identity.mod)
            end
        end
        # The modules are named like JLL packages
        for mod in keys(system_library_uuids)
            @test endswith(string(mod), "_jll")
        end
        @test allunique(values(system_library_uuids))
    end
end
