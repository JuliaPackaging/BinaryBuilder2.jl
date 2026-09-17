using Base.BinaryPlatforms

const linux_system_libs = Dict{String,Union{Nothing,String}}(
    # dynamic loaders: not something one links against
    "ld-linux-x86-64.so.2" => nothing,
    "ld-linux.so.2" => nothing,
    "ld-linux-armhf.so.3" => nothing,
    "ld-linux-aarch64.so.1" => nothing,
    "ld-musl-x86_64.so.1" => nothing,
    "ld-musl-i386.so.1" => nothing,
    "ld-musl-aarch64.so.1" => nothing,
    "ld-musl-armhf.so.1" => nothing,
    "ld64.so.2" => nothing,

    # C runtime
    "libc.so" => "c",
    "libc.so.6" => "c",
    "libc.so.7" => "c",
    "libc.musl-x86_64.so.1" => "c",
    "libc.musl-i386.so.1" => "c",
    "libc.musl-aarch64.so.1" => "c",
    "libc.musl-armhf.so.1" => "c",

    # Glibc libraries
    "libdl.so.2" => "dl",
    "libdl.so.1" => "dl",
    "librt.so.1" => "rt",
    "libm.so.5" => "m",
    "libm.so.6" => "m",
    "libthr.so.3" => "thr",
    "libpthread.so.0" => "pthread",
    "libresolv.so.2" => "resolv",
    "libutil.so.1" => "util",
    "libatomic.so.1" => "atomic",

    # C++ runtime; it's arguable these should require `CompilerSupportLibraries_jll`
    "libstdc++.so.6" => "stdc++",
    "libc++.so.1" => "c++",
    "libcxxrt.so.1" => "cxxrt",

    # Compiler support libraries
    "libgcc_s.so.1" => "gcc_s",
    "libunwind.so.1" => "unwind",
)

# Keys are lowercased, as macOS filesystems are case-insensitive.
const macos_system_libs = Dict{String,Union{Nothing,String}}(
    "libbsm.0.dylib" => "bsm",
    "libcups.2.dylib" => "cups",
    "libobjc.a.dylib" => "objc",
    "libpmenergy.dylib" => "pmenergy",
    "libpmsample.dylib" => "pmsample",
    "libsandbox.1.dylib" => "sandbox",
    "libsystem.b.dylib" => "System",
    "libiconv.2.dylib" => "iconv",
    "libc++.1.dylib" => "c++",
    "libstdc++.6.dylib" => "stdc++",
    "libresolv.9.dylib" => "resolv",

    # Frameworks in the SDK
    "accelerate" => "framework:Accelerate",
    "appkit" => "framework:AppKit",
    "applicationservices" => "framework:ApplicationServices",
    "audiotoolbox" => "framework:AudioToolbox",
    "audiounit" => "framework:AudioUnit",
    "avfoundation" => "framework:AVFoundation",
    "carbon" => "framework:Carbon",
    "cfnetwork" => "framework:CFNetwork",
    "cocoa" => "framework:Cocoa",
    "coreaudio" => "framework:CoreAudio",
    "corebluetooth" => "framework:CoreBluetooth",
    "corefoundation" => "framework:CoreFoundation",
    "coregraphics" => "framework:CoreGraphics",
    "corelocation" => "framework:CoreLocation",
    "coremedia" => "framework:CoreMedia",
    "coremidi" => "framework:CoreMIDI",
    "coreservices" => "framework:CoreServices",
    "coretext" => "framework:CoreText",
    "corevideo" => "framework:CoreVideo",
    "corewlan" => "framework:CoreWLAN",
    "diskarbitration" => "framework:DiskArbitration",
    "forcefeedback" => "framework:ForceFeedback",
    "foundation" => "framework:Foundation",
    "gamecontroller" => "framework:GameController",
    "imageio" => "framework:ImageIO",
    "iobluetooth" => "framework:IOBluetooth",
    "iokit" => "framework:IOKit",
    "iosurface" => "framework:IOSurface",
    "localauthentication" => "framework:LocalAuthentication",
    "mediaaccessibility" => "framework:MediaAccessibility",
    "metal" => "framework:Metal",
    "metalkit" => "framework:MetalKit",
    "opencl" => "framework:OpenCL",
    "opengl" => "framework:OpenGL",
    "opendirectory" => "framework:OpenDirectory",
    "quartz" => "framework:Quartz",
    "quartzcore" => "framework:QuartzCore",
    "security" => "framework:Security",
    "securityinterface" => "framework:SecurityInterface",
    "systemconfiguration" => "framework:SystemConfiguration",
    "videotoolbox" => "framework:VideoToolbox",

    # Compiler support libraries
    "libgcc_s.1.dylib" => "gcc_s",
    "libgcc_s.1.1.dylib" => "gcc_s",
)

# Keys are lowercased, as Windows filesystems are case-insensitive.
const windows_system_libs = Dict{String,Union{Nothing,String}}(
    # Core runtime libs
    "ntdll.dll" => "ntdll",
    "msvcrt.dll" => "msvcrt",
    "kernel32.dll" => "kernel32",
    "user32.dll" => "user32",
    "shell32.dll" => "shell32",
    "shlwapi.dll" => "shlwapi",
    "advapi32.dll" => "advapi32",
    "crypt32.dll" => "crypt32",
    "ws2_32.dll" => "ws2_32",
    "rpcrt4.dll" => "rpcrt4",
    "usp10.dll" => "usp10",
    "dwrite.dll" => "dwrite",
    "gdi32.dll" => "gdi32",
    "gdiplus.dll" => "gdiplus",
    "comdlg32.dll" => "comdlg32",
    "secur32.dll" => "secur32",
    "ole32.dll" => "ole32",
    "dbeng.dll" => "dbeng",
    "wldap32.dll" => "wldap32",
    "opengl32.dll" => "opengl32",
    "winmm.dll" => "winmm",
    "iphlpapi.dll" => "iphlpapi",
    "imm32.dll" => "imm32",
    "comctl32.dll" => "comctl32",
    "oleaut32.dll" => "oleaut32",
    "userenv.dll" => "userenv",
    "netapi32.dll" => "netapi32",
    "winhttp.dll" => "winhttp",
    "msimg32.dll" => "msimg32",
    "dnsapi.dll" => "dnsapi",
    "wsock32.dll" => "wsock32",
    "psapi.dll" => "psapi",
    "bcrypt.dll" => "bcrypt",
    "version.dll" => "version",
    "dbghelp.dll" => "dbghelp",

    # Compiler support libraries
    # Both unwinder flavours are linked through the `libgcc_s.a` import library
    "libgcc_s_seh-1.dll" => "gcc_s",
    "libgcc_s_sjlj-1.dll" => "gcc_s",
    "libgfortran-3.dll" => "gfortran",
    "libgfortran-4.dll" => "gfortran",
    "libgfortran-5.dll" => "gfortran",
    "libstdc++-6.dll" => "stdc++",
    "libwinpthread-1.dll" => "winpthread",

    # This one needs some special attention, eventually
    "libgomp-1.dll" => "gomp",
)

# From the FreeBSD SDK.
const freebsd_system_libs = Dict{String,Union{Nothing,String}}(
    "libdevstat.so.7" => "devstat",
    "libdl.so.1" => "dl",
    "libexecinfo.so.1" => "execinfo",
    "libkvm.so.7" => "kvm",
    "libutil.so.9" => "util",
    "librt.so.1" => "rt",
    "libc.so.7" => "c",
    "libc.so.6" => "c",
    "libthr.so.3" => "thr",
    "libm.so.5" => "m",
    "libm.so.6" => "m",
    # zlib ships in the FreeBSD base system
    "libz.so.6" => "z",

    # compiler support libraries
    "libc++.so.1" => "c++",
    "libcxxrt.so.1" => "cxxrt",
    "libgcc_s.so.1" => "gcc_s",
    "libstdc++.so.6" => "stdc++",
)

const NO_SYSTEM_LIBS = Dict{String,Union{Nothing,String}}()

function known_system_libraries(platform::AbstractPlatform)
    if os(platform) == "linux"
        return linux_system_libs
    elseif os(platform) == "macos"
        return macos_system_libs
    elseif os(platform) == "windows"
        return windows_system_libs
    elseif os(platform) == "freebsd"
        return freebsd_system_libs
    else
        return NO_SYSTEM_LIBS
    end
end

# Windows stores symbol versions in DLL symbol-forwarding libraries that forward on
# to ucrt as a backend [0].  These are system libraries, but nothing one links.
# [0]: https://mingwpy.github.io/ucrt.html
is_ucrt_forwarder(name::AbstractString, platform::AbstractPlatform) =
    os(platform) == "windows" && startswith(lowercase(name), "api-ms-win-crt-")

function is_system_library(soname::AbstractString, platform::AbstractPlatform)
    soname = lowercase(basename(soname))
    return is_ucrt_forwarder(soname, platform) || haskey(known_system_libraries(platform), soname)
end

function system_library_linker_name(soname::AbstractString, platform::AbstractPlatform)
    soname = lowercase(basename(soname))
    if is_ucrt_forwarder(soname, platform)
        return nothing
    end
    return get(known_system_libraries(platform), soname, nothing)
end
