using Base.BinaryPlatforms
using JLLGenerator: JLLLibraryDep

"""
    system_library_uuids

The UUIDs of the JLLs that stand for system libraries.  A system library is one
the target system provides, which therefore never ships in an artifact; records
refer to it by a canonical identity, the JLL that stands for it and the variable
name of the library within that JLL, e.g. `Glibc_jll.libc`:

- `CompilerSupportLibraries_jll` for the toolchain runtime (`libgcc_s`, `libstdc++`,
  the `libgfortran` family, `libquadmath`, ...).  This is a real package a build can
  depend on; when it does, its libraries resolve as dependency edges and never reach
  this table.
- `Glibc_jll` and `Musl_jll` for the C library and its companions on Linux.
- `SystemLibraries_jll` for everything else: the platform's own runtime (`libSystem`
  and the frameworks on macOS, the Windows DLLs, the FreeBSD base system).  No such
  package exists; the reserved UUID gives these identities a stable owner.

How a system library is named on a link line is not recorded here; that is the
concern of whoever builds the link line, keyed by these identities.
"""
const system_library_uuids = Dict{Symbol,Base.UUID}(
    :CompilerSupportLibraries_jll => Base.UUID("e66e0078-7015-5450-92f7-15fbd957f2ae"),
    :Glibc_jll => Base.UUID("452aa2e7-e185-58db-8ff9-d3c1fa4bc997"),
    :Musl_jll => Base.UUID("3490aa6f-05e0-5d3a-9648-5b0c647c155f"),
    :SystemLibraries_jll => Base.UUID("18975edd-23d9-4ae2-84dc-2cb2fbfebf39"),
)

# Table constructors, one per owner
csl(varname) = JLLLibraryDep(:CompilerSupportLibraries_jll, varname)
glibc(varname) = JLLLibraryDep(:Glibc_jll, varname)
musl(varname) = JLLLibraryDep(:Musl_jll, varname)
system(varname) = JLLLibraryDep(:SystemLibraries_jll, varname)

const linux_system_libs = Dict{String,Union{Nothing,JLLLibraryDep}}(
    # dynamic loaders: system libraries, but not something a library depends on
    "ld-linux-x86-64.so.2" => nothing,
    "ld-linux.so.2" => nothing,
    "ld-linux-armhf.so.3" => nothing,
    "ld-linux-aarch64.so.1" => nothing,
    "ld-musl-x86_64.so.1" => nothing,
    "ld-musl-i386.so.1" => nothing,
    "ld-musl-aarch64.so.1" => nothing,
    "ld-musl-armhf.so.1" => nothing,
    "ld64.so.2" => nothing,

    # C runtime; musl's `libc.so` carries no SONAME, so it is referenced by file name
    "libc.so" => musl(:libc),
    "libc.musl-x86_64.so.1" => musl(:libc),
    "libc.musl-i386.so.1" => musl(:libc),
    "libc.musl-aarch64.so.1" => musl(:libc),
    "libc.musl-armhf.so.1" => musl(:libc),
    "libc.so.6" => glibc(:libc),

    # Glibc companion libraries
    "libdl.so.2" => glibc(:libdl),
    "librt.so.1" => glibc(:librt),
    "libm.so.6" => glibc(:libm),
    "libpthread.so.0" => glibc(:libpthread),
    "libresolv.so.2" => glibc(:libresolv),
    "libutil.so.1" => glibc(:libutil),

    # Compiler support libraries
    "libgcc_s.so.1" => csl(:libgcc_s),
    "libstdc++.so.6" => csl(:libstdcxx),
    "libgfortran.so.3" => csl(:libgfortran),
    "libgfortran.so.4" => csl(:libgfortran),
    "libgfortran.so.5" => csl(:libgfortran),
    "libquadmath.so.0" => csl(:libquadmath),
    "libatomic.so.1" => csl(:libatomic),

    # LLVM's C++ runtime and unwinder
    "libc++.so.1" => system(:libcxx),
    "libcxxrt.so.1" => system(:libcxxrt),
    "libunwind.so.1" => system(:libunwind),
)

# Keys are lowercased, as macOS filesystems are case-insensitive.
const macos_system_libs = Dict{String,Union{Nothing,JLLLibraryDep}}(
    "libsystem.b.dylib" => system(:libSystem),
    "libbsm.0.dylib" => system(:libbsm),
    "libcups.2.dylib" => system(:libcups),
    "libobjc.a.dylib" => system(:libobjc),
    "libpmenergy.dylib" => system(:libpmenergy),
    "libpmsample.dylib" => system(:libpmsample),
    "libsandbox.1.dylib" => system(:libsandbox),
    "libiconv.2.dylib" => system(:libiconv),
    "libc++.1.dylib" => system(:libcxx),
    "libresolv.9.dylib" => system(:libresolv),

    # Frameworks in the SDK
    "accelerate" => system(:Accelerate),
    "appkit" => system(:AppKit),
    "applicationservices" => system(:ApplicationServices),
    "audiotoolbox" => system(:AudioToolbox),
    "audiounit" => system(:AudioUnit),
    "avfoundation" => system(:AVFoundation),
    "carbon" => system(:Carbon),
    "cfnetwork" => system(:CFNetwork),
    "cocoa" => system(:Cocoa),
    "coreaudio" => system(:CoreAudio),
    "corebluetooth" => system(:CoreBluetooth),
    "corefoundation" => system(:CoreFoundation),
    "coregraphics" => system(:CoreGraphics),
    "corelocation" => system(:CoreLocation),
    "coremedia" => system(:CoreMedia),
    "coremidi" => system(:CoreMIDI),
    "coreservices" => system(:CoreServices),
    "coretext" => system(:CoreText),
    "corevideo" => system(:CoreVideo),
    "corewlan" => system(:CoreWLAN),
    "diskarbitration" => system(:DiskArbitration),
    "forcefeedback" => system(:ForceFeedback),
    "foundation" => system(:Foundation),
    "gamecontroller" => system(:GameController),
    "imageio" => system(:ImageIO),
    "iobluetooth" => system(:IOBluetooth),
    "iokit" => system(:IOKit),
    "iosurface" => system(:IOSurface),
    "localauthentication" => system(:LocalAuthentication),
    "mediaaccessibility" => system(:MediaAccessibility),
    "metal" => system(:Metal),
    "metalkit" => system(:MetalKit),
    "opencl" => system(:OpenCL),
    "opengl" => system(:OpenGL),
    "opendirectory" => system(:OpenDirectory),
    "quartz" => system(:Quartz),
    "quartzcore" => system(:QuartzCore),
    "security" => system(:Security),
    "securityinterface" => system(:SecurityInterface),
    "systemconfiguration" => system(:SystemConfiguration),
    "videotoolbox" => system(:VideoToolbox),

    # Compiler support libraries
    "libgcc_s.1.dylib" => csl(:libgcc_s),
    "libgcc_s.1.1.dylib" => csl(:libgcc_s),
    "libstdc++.6.dylib" => csl(:libstdcxx),
    "libgfortran.3.dylib" => csl(:libgfortran),
    "libgfortran.4.dylib" => csl(:libgfortran),
    "libgfortran.5.dylib" => csl(:libgfortran),
    "libquadmath.0.dylib" => csl(:libquadmath),
)

# Keys are lowercased, as Windows filesystems are case-insensitive.
const windows_system_libs = Dict{String,Union{Nothing,JLLLibraryDep}}(
    # Core runtime libs
    "ntdll.dll" => system(:ntdll),
    "msvcrt.dll" => system(:msvcrt),
    "kernel32.dll" => system(:kernel32),
    "user32.dll" => system(:user32),
    "shell32.dll" => system(:shell32),
    "shlwapi.dll" => system(:shlwapi),
    "advapi32.dll" => system(:advapi32),
    "crypt32.dll" => system(:crypt32),
    "ws2_32.dll" => system(:ws2_32),
    "rpcrt4.dll" => system(:rpcrt4),
    "usp10.dll" => system(:usp10),
    "dwrite.dll" => system(:dwrite),
    "gdi32.dll" => system(:gdi32),
    "gdiplus.dll" => system(:gdiplus),
    "comdlg32.dll" => system(:comdlg32),
    "secur32.dll" => system(:secur32),
    "ole32.dll" => system(:ole32),
    "dbeng.dll" => system(:dbeng),
    "wldap32.dll" => system(:wldap32),
    "opengl32.dll" => system(:opengl32),
    "winmm.dll" => system(:winmm),
    "iphlpapi.dll" => system(:iphlpapi),
    "imm32.dll" => system(:imm32),
    "comctl32.dll" => system(:comctl32),
    "oleaut32.dll" => system(:oleaut32),
    "userenv.dll" => system(:userenv),
    "netapi32.dll" => system(:netapi32),
    "winhttp.dll" => system(:winhttp),
    "msimg32.dll" => system(:msimg32),
    "dnsapi.dll" => system(:dnsapi),
    "wsock32.dll" => system(:wsock32),
    "psapi.dll" => system(:psapi),
    "bcrypt.dll" => system(:bcrypt),
    "version.dll" => system(:version),
    "dbghelp.dll" => system(:dbghelp),

    # Compiler support libraries
    "libgcc_s_seh-1.dll" => csl(:libgcc_s),
    "libgcc_s_sjlj-1.dll" => csl(:libgcc_s),
    "libgfortran-3.dll" => csl(:libgfortran),
    "libgfortran-4.dll" => csl(:libgfortran),
    "libgfortran-5.dll" => csl(:libgfortran),
    "libstdc++-6.dll" => csl(:libstdcxx),
    "libquadmath-0.dll" => csl(:libquadmath),
    "libwinpthread-1.dll" => csl(:libwinpthread),
    "libgomp-1.dll" => csl(:libgomp),
)

# From the FreeBSD SDK.  Nothing packages the FreeBSD base system, so it is all
# `SystemLibraries_jll`.
const freebsd_system_libs = Dict{String,Union{Nothing,JLLLibraryDep}}(
    "libc.so.7" => system(:libc),
    "libc.so.6" => system(:libc),
    "libdl.so.1" => system(:libdl),
    "libm.so.5" => system(:libm),
    "libm.so.6" => system(:libm),
    "libthr.so.3" => system(:libthr),
    "librt.so.1" => system(:librt),
    "libutil.so.9" => system(:libutil),
    "libdevstat.so.7" => system(:libdevstat),
    "libexecinfo.so.1" => system(:libexecinfo),
    "libkvm.so.7" => system(:libkvm),
    # zlib ships in the FreeBSD base system
    "libz.so.6" => system(:libz),

    # LLVM's C++ runtime
    "libc++.so.1" => system(:libcxx),
    "libcxxrt.so.1" => system(:libcxxrt),

    # Compiler support libraries
    "libgcc_s.so.1" => csl(:libgcc_s),
    "libstdc++.so.6" => csl(:libstdcxx),
)

const NO_SYSTEM_LIBS = Dict{String,Union{Nothing,JLLLibraryDep}}()

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
# to ucrt as a backend [0].  These are system libraries, but not something a library
# depends on.
# [0]: https://mingwpy.github.io/ucrt.html
is_ucrt_forwarder(name::AbstractString, platform::AbstractPlatform) =
    os(platform) == "windows" && startswith(lowercase(name), "api-ms-win-crt-")

function is_system_library(soname::AbstractString, platform::AbstractPlatform)
    soname = lowercase(basename(soname))
    return is_ucrt_forwarder(soname, platform) || haskey(known_system_libraries(platform), soname)
end

"""
    system_library_identity(soname, platform)

The canonical identity of the system library with the given SONAME on `platform`,
or `nothing` if it is not a system library, or is one that no library depends on
(a dynamic loader, a ucrt forwarder).  Use [`is_system_library`](@ref) to tell
those two cases apart.
"""
function system_library_identity(soname::AbstractString, platform::AbstractPlatform)
    soname = lowercase(basename(soname))
    if is_ucrt_forwarder(soname, platform)
        return nothing
    end
    return get(known_system_libraries(platform), soname, nothing)
end
