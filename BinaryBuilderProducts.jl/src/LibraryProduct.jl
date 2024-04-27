using JLLGenerator, ObjectFile
using JLLGenerator: default_rtld_flags, rtld_flags
export resolve_dependency_links!

"""
    LibraryProduct(paths::Vector{String}, varname::Symbol;
                   deps=LibraryProduct[],
                   dlopen_flags=Symbol[])

Declares a `LibraryProduct` that points to a library located within the prefix.
`paths` contain valid paths for this library, `varname` is the name of the
variable in the JLL package that can be used to call into the library.  The
flags to pass to `dlopen` can be specified as a vector of `Symbols` with the
`dlopen_flags` keyword argument.

Each element of `path` takes the form `[dirname/]basename[.versioned-ext]`
where `dirname` and `versioned-ext` are optional and can be omitted.
Accordingly, the following three paths will all find the same library:

* `lib/libnettle.so.6`
* `lib/libnettle`
* `libnettle.so.6`
* `libnettle`

On non-Windows targets, omitting `dirname` will automatically prepend `lib`,
while on Windows targets `bin` will be prepended.  Omitting the versioned
extension will allow any version of the library to be used (usually not a
problem as there's typically only one version of a library at a time).
"""
struct LibraryProduct <: AbstractProduct
    paths::Vector{String}
    varname::Symbol
    deps::Vector{LibraryProduct}
    dlopen_flags::typeof(default_rtld_flags)

    function LibraryProduct(paths::Vector{<:AbstractString},
                            varname::Symbol;
                            deps::Vector{LibraryProduct} = LibraryProduct[],
                            dlopen_flags::Union{Vector{Symbol},typeof(default_rtld_flags)} = default_rtld_flags)
        if isa(dlopen_flags, Vector{Symbol})
            dlopen_flags = rtld_flags(dlopen_flags)
        end
        if isdefined(Base, varname)
            error("`$(varname)` is already defined in Base")
        end
        return new(string.(paths), varname, deps, dlopen_flags)
    end
end
LibraryProduct(path::AbstractString, args...; kwargs...) = LibraryProduct([path], args...; kwargs...)

"""
    valid_dl_path(path, platform)

Returns `true` if `path` represents a valid dynamic library path (e.g. `libfoo.so.X` on
Linux/FreeBSD, `libfoo-X.dll` on Windows, `libfoo.X.dylib` on macOS) as specified by
`Base.BinaryPlatforms.parse_dl_name_version()`.  Returns `false` otherwise
"""
function valid_dl_path(path, platform)
    try
        parse_dl_name_version(path, os(platform))
        return true
    catch
        return false
    end
end

function default_product_dir(::Type{LibraryProduct}, platform::AbstractPlatform)
    if Sys.iswindows(platform)
        return "bin"
    else
        return "lib"
    end
end

"""
    locate(lp::LibraryProduct, prefix::Prefix;
           env::Dict{String,String},
           verbose::Bool = false)

If the given library exists (under any reasonable name) and is `dlopen()`able,
(assuming it was built for the current platform) return its location.  Note
that the `dlopen()` test is only run if the current platform matches the given
`platform` keyword argument, as cross-compiled libraries cannot be `dlopen()`ed
on foreign platforms.
"""
function locate(lp::LibraryProduct, prefix::String;
                env::Dict{String,String} = Dict{String,String}(),
                platform::AbstractPlatform = parse(Platform, env_checked_get(env, "bb_full_target")),
                verbose::Bool = false)
    for path in lp.paths
        path = path_prefix_transformation(LibraryProduct, path, prefix, env)
        libname = basename(path)

        if verbose
            @info("locate()", path, readdir(dirname(path)))
        end

        # Skip non-existant directories
        path_dir = dirname(path)
        if !isdir(path_dir)
            continue
        end

        for f in readdir(path_dir)
            # Skip any names that aren't a valid dynamic library for the given
            # platform (note this will cause problems if something compiles a `.so`
            # on OSX, for instance)
            if !valid_dl_path(f, platform)
                continue
            end

            parsed_libname, parsed_version = parse_dl_name_version(f, os(platform))
            if parsed_libname == libname
                return prefix_remove(joinpath(path_dir, f), prefix)
            end
        end
    end
    return nothing
end

function is_system_library(libname, platform)
    libname = basename(libname)

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
        return libname ∈ vcat(loaders, c_runtimes, cxx_runtimes, csl_libs)
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
        return lowercase(libname) ∈ ignore_libs
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
        return lowercase(libname) ∈ vcat(runtime_libs, csl_libs)
    elseif os(platform) == "freebsd"
        # From FreeBSD SDK
        sdk_libs = [
            "libdevstat.sos.7",
            "libdl.so.1",
            "libexecinfo.so.1",
            "libkvm.so.7",
            "libutil.so.9",
        ]
        return libname ∈ sdk_libs
    else
        return false
    end
end

"""
    resolve_dependency_links!(libs::Vector{LibraryProduct}, deps::Vector{LibraryProduct})

Given a set of `LibraryProduct`s, try to resolve their dynamic linkage to other
known dependencies.  In BinaryBuilder terminology, `libs` should be the libraries
for the current JLL being built, and `deps` should be all libraries from
dependency JLLs.

This function will open each library found by iterating over `libs`, inspect its
dynamic links, then attempt to categorize that linkage into one of three categories:

- A link against a library in this JLL (from `libs`)
- A link against a library in one of our dependencies (from `deps`)
- A system library that should be ignored (e.g. `libc`)

If the linkage does not fit into any of these categories, an error is thrown.
"""
function resolve_dependency_links!(libs::Vector{LibraryProduct},
                                   prefix::String,
                                   env::Dict{String,String};
                                   platform = parse(Platform, env_checked_get(env, "bb_full_target")))
    # Locate all libraries
    libs_by_path = Dict{String,LibraryProduct}()
    for lib in libs
        lib_subpath = locate(lib, prefix; env, platform)
        if lib_subpath === nothing
            throw(ArgumentError("Unable to locate library $(lib.varname)"))
        end
        libs_by_path[joinpath(prefix, lib_subpath)] = lib
    end

    for (lib_path, lib) in libs_by_path
        # If this library already has deps filled out, skip it.
        if !isempty(lib.deps)
            continue
        end

        # Next, peel it like a delicious tangerine
        readmeta(lib_path) do ohs
            ohs = filter(oh -> platforms_match(Platform(oh), platform), ohs)
            if isempty(ohs)
                throw(ArgumentError("No matching dynamic objects found in '$(lib_path)': Found $(Platform.(ohs)) but looking for $(platform)"))
            end

            # There should only ever be one that matches
            oh = only(ohs)

            # Find all dependency paths:
            for (libname, resolved) in find_libraries(oh)
                # Check to see if it matches any of the libraries in `libs`:
                function search_same_lib(resolved, libs_by_path)
                    for (other_lib_path, other_lib) in libs_by_path
                        if samefile(resolved, other_lib_path)
                            return other_lib
                        end
                    end
                    return nothing
                end

                dep_lib = search_same_lib(resolved, libs_by_path)
                if dep_lib !== nothing
                    push!(lib.deps, dep_lib)
                    resolved = nothing
                    continue
                end

                # Filter out system libraries we don't want to pay attention to
                if is_system_library(resolved, platform)
                    continue
                end

                throw(ArgumentError("Unable to resolve dependency '$(libname)/$(resolved)' for '$(lib_path)'"))
            end
        end
    end
end
