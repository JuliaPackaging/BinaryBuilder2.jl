using Base.BinaryPlatforms

function is_system_library(soname::AbstractString, platform::AbstractPlatform)
    if os(platform) == "linux"
        loaders = [
            # dynamic loaders
            "ld-linux-x86-64.so.2",
            "ld-linux.so.2",
            "ld-linux-armhf.so.3",
            "ld-linux-aarch64.so.1",
            "ld-musl-x86_64.so.1",
            "ld-musl-i386.so.1",
            "ld-musl-aarch64.so.1",
            "ld-musl-armhf.so.1",
            "ld64.so.2",
        ]

        c_runtimes = [
            # C runtime
            "libc.so",
            "libc.so.6",
            "libc.so.7",
            "libc.musl-x86_64.so.1",
            "libc.musl-i386.so.1",
            "libc.musl-aarch64.so.1",
            "libc.musl-armhf.so.1",

            # Glibc libraries
            "libdl.so.2",
            "librt.so.1",
            "libm.so.5",
            "libm.so.6",
            "libthr.so.3",
            "libpthread.so.0",
            "libresolv.so.2",
            "libutil.so.1",
        ]

        # It's arguable these should require `CompilerSupportLibraries_jll`
        cxx_runtimes = [
            # C++ runtime
            "libstdc++.so.6",
            "libc++.so.1",
            "libcxxrt.so.1",
        ]

        csl_libs = [
            "libgcc_s.so.1",
        ]
        llvmunwind_libs = [
            "libunwind.so.1",
        ]
        return soname ∈ vcat(loaders, c_runtimes, cxx_runtimes, csl_libs, llvmunwind_libs)
    elseif os(platform) == "macos"
        ignore_libs = [
            "libbsm.0.dylib",
            "libcups.2.dylib",
            "libobjc.a.dylib",
            "libpmenergy.dylib",
            "libpmsample.dylib",
            "libsandbox.1.dylib",
            "libsystem.b.dylib",
            # This is not built by clang or GCC, so we leave it as a system library
            "libc++.1.dylib",
            "libresolv.9.dylib",
            # Frameworks in the SDK
            "accelerate",
            "appkit",
            "applicationservices",
            "audiotoolbox",
            "audiounit",
            "avfoundation",
            "carbon",
            "cfnetwork",
            "cocoa",
            "coreaudio",
            "corebluetooth",
            "corefoundation",
            "coregraphics",
            "corelocation",
            "coremedia",
            "coremidi",
            "coreservices",
            "coretext",
            "corevideo",
            "corewlan",
            "diskarbitration",
            "forcefeedback",
            "foundation",
            "gamecontroller",
            "imageio",
            "iobluetooth",
            "iokit",
            "iosurface",
            "localauthentication",
            "mediaaccessibility",
            "metal",
            "metalkit",
            "opencl",
            "opengl",
            "opendirectory",
            "quartz",
            "quartzcore",
            "security",
            "securityinterface",
            "systemconfiguration",
            "videotoolbox",
        ]
        return lowercase(soname) ∈ ignore_libs
    elseif os(platform) == "windows"
        runtime_libs = [
            # Core runtime libs
            "ntdll.dll",
            "msvcrt.dll",
            "kernel32.dll",
            "user32.dll",
            "shell32.dll",
            "shlwapi.dll",
            "advapi32.dll",
            "crypt32.dll",
            "ws2_32.dll",
            "rpcrt4.dll",
            "usp10.dll",
            "dwrite.dll",
            "gdi32.dll",
            "gdiplus.dll",
            "comdlg32.dll",
            "secur32.dll",
            "ole32.dll",
            "dbeng.dll",
            "wldap32.dll",
            "opengl32.dll",
            "winmm.dll",
            "iphlpapi.dll",
            "imm32.dll",
            "comctl32.dll",
            "oleaut32.dll",
            "userenv.dll",
            "netapi32.dll",
            "winhttp.dll",
            "msimg32.dll",
            "dnsapi.dll",
            "wsock32.dll",
            "psapi.dll",
            "bcrypt.dll",
        ]

        csl_libs = [
            # Compiler support libraries
            "libgcc_s_seh-1.dll",
            "libgcc_s_sjlj-1.dll",
            "libgfortran-3.dll",
            "libgfortran-4.dll",
            "libgfortran-5.dll",
            "libstdc++-6.dll",
            "libwinpthread-1.dll",

            # This one needs some special attention, eventually
            "libgomp-1.dll",
        ]
        return lowercase(soname) ∈ vcat(runtime_libs, csl_libs)
    elseif os(platform) == "freebsd"
        # From FreeBSD SDK
        sdk_libs = [
            "libdevstat.so.7",
            "libdl.so.1",
            "libexecinfo.so.1",
            "libkvm.so.7",
            "libutil.so.9",
        ]
        return soname ∈ sdk_libs
    else
        return false
    end
end
