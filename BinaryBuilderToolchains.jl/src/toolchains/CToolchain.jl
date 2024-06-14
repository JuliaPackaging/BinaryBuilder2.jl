export CToolchain
using Pkg
using Pkg.Types: PackageSpec, VersionSpec

struct CToolchain <: AbstractToolchain
    platform::CrossPlatform

    # When installing the C toolchain, we are going to generate compiler
    # wrapper scripts, and they will point to one vendor (e.g. GCC or clang)
    # as the default compiler; set `vendor` to force a choice one way
    # or the other, or leave it to default to a smart per-platform choice.
    vendor::Symbol
    deps::Vector{JLLSource}

    # If we're the default CToolchain (we assume we are) generate `cc`
    # wrapper scripts, and set `CC="cc"`, etc...
    default_ctoolchain::Bool
    host_ctoolchain::Bool

    # If this is set to true (which is the default) we won't allow packages
    # to specify a `-march`; we're in control of that.
    lock_microarchitecture::Bool

    # Extra compiler and linker flags that should be inserted.
    # We typically use these to add `-L/workspace/destdir/${target}`
    # in BinaryBuilder.
    extra_cflags::Vector{String}
    extra_ldflags::Vector{String}

    function CToolchain(platform;
                        vendor = :auto,
                        default_ctoolchain = false,
                        host_ctoolchain = false,
                        lock_microarchitecture = true,
                        gcc_version = VersionSpec("9"),
                        llvm_version = VersionSpec("*"),
                        binutils_version = v"2.38.0+4",
                        glibc_version = :oldest,
                        extra_cflags = String[],
                        extra_ldflags = String[])
        if vendor ∉ (:auto, :gcc, :clang, :gcc_bootstrap)
            throw(ArgumentError("Unknown C toolchain vendor '$(vendor)'"))
        end

        if vendor == :auto
            if os(platform.target) ∈ ("macos", "freebsd")
                vendor = :clang
            else
                vendor = :gcc
            end
        end

        if os(platform) == "linux" && isa(glibc_version, Symbol)
            # If the user asks for the oldest version of glibc, figure out what platform we're
            # building for, and use an appropriate version.
            if glibc_version == :oldest
                # TODO: Should glibc_version be embedded within the triplet somehow?
                #       Non-default glibc version is kind of a compatibility issue....
                @warn("TODO: Should glibc_version be embedded within the triplet?", maxlog=1)
                if arch(platform) ∈ ("x86_64", "i686", "powerpc64le",)
                    glibc_version = VersionSpec("2.17")
                elseif arch(platform) ∈ ("armv7l", "aarch64")
                    glibc_version = VersionSpec("2.19")
                else
                    throw(ArgumentError("Unknown oldest glibc version for architecture '$(arch)'!"))
                end
            else
                throw(ArgumentError("Invalid magic glibc_version argument :$(glibc_version)"))
            end
        end

        deps = jll_source_selection(
            vendor,
            platform,
            gcc_version,
            llvm_version,
            binutils_version,
            glibc_version,
        )

        # Concretize the JLLSource's `PackageSpec`'s version (and UUID) now:
        resolve_versions!(deps; julia_version=nothing)

        return new(
            platform,
            vendor,
            deps,
            default_ctoolchain,
            host_ctoolchain,
            lock_microarchitecture,
            string.(extra_cflags),
            string.(extra_ldflags),
        )
    end
end

function jll_source_selection(vendor::Symbol, platform::CrossPlatform,
                              gcc_version,
                              llvm_version,
                              binutils_version,
                              glibc_version)
    # If we're asking for a GCCBootstrap-based toolchain, give just that and nothing else, as it contains everything.
    if vendor == :gcc_bootstrap
        return [JLLSource(
            "GCCBootstrap_jll",
            platform;
            repo=Pkg.Types.GitRepo(
                # When we push up a new build of `GCCBoostrap_jll`, we always built it
                # for the host we're actually doing the bootstrap from.  Because of this,
                # we only get a single host architecture at a time.  That's fine, but
                # it means that we need to choose branches named by the host platform.
                rev="bb2/GCCBoostrap-$(triplet(platform.host))",
                source="https://github.com/staticfloat/GCCBootstrap_jll.jl"
            ),
            #version=gcc_version,
        )]
    end

    # Collect our JLLSource objects for all of our compiler pieces:
    deps = JLLSource[]

    gcc_triplet = triplet(gcc_platform(platform.target))
    if os(platform.target) == "linux"
        # Linux builds require the kernel headers for the target platform
        push!(deps, JLLSource(
            "LinuxKernelHeaders_jll",
            platform.target,
            # LinuxKernelHeaders gets installed into `<prefix>/<triplet>/usr`
            target=joinpath(gcc_triplet, "usr")
        ))
    end

    if libc(platform.target) == "glibc"
        push!(deps, JLLSource(
            "Glibc_jll",
            platform.target;
            # TODO: Should we encode this in the platform object somehow?
            version=glibc_version,
            # This glibc is the one that gets embedded within GCC and it's for the target
            target=gcc_triplet,
        ))
    end

    # Include GCC, and it's own bundled versions of Zlib, as well as Binutils
    # These are compilers, so they take in the full cross platform.
    # TODO: Get `GCC_jll.jl` packaged so that I don't
    #       have to pull down a special commit like this!
    append!(deps, [
        JLLSource(
            "GCC_jll",
            platform;
            uuid=Base.UUID("ec15993a-68c6-5861-8652-ef539d7ffb0b"),
            repo=Pkg.Types.GitRepo(
                rev="8d632ad5f2e2c419a4e67da14bf1609ab0291b24",
                source="https://github.com/staticfloat/GCC_jll.jl"
            ),
            # eventually, include a resolved version
            # but for now, we're locked to this specific version
            version=v"9.4.0",
        ),
        JLLSource(
            "Binutils_jll",
            platform;
            version=binutils_version,
        ),
        JLLSource(
            "Zlib_jll",
            platform.target;
            # zlib gets installed into `<prefix>/<triplet>/usr`, and it's only for the target
            target=joinpath(gcc_triplet, "usr"),
        ),
    ])
end

function Base.show(io::IO, toolchain::CToolchain)
    println(io, "CToolchain ($(gcc_target_triplet(toolchain.platform)) => $(gcc_target_triplet(toolchain.platform)))")
    for dep in toolchain.deps
        println(io, " - $(dep.package.name[1:end-4]) v$(dep.package.version)")
    end
end

function toolchain_sources(toolchain::CToolchain)
    sources = AbstractSource[]

    # Create a `GeneratedSource` that, at `prepare()` time, will JIT out
    # our compiler wrappers!
    push!(sources, GeneratedSource(;target="wrappers") do out_dir
        if any(jll.package.name == "GCC_jll" for jll in toolchain.deps) || any(jll.package.name == "GCCBootstrap_jll" for jll in toolchain.deps)
            gcc_wrappers(toolchain, out_dir)
        end
        if any(jll.package.name == "Clang_jll" for jll in toolchain.deps)
            clang_wrappers(toolchain, out_dir)
        end
        if any(jll.package.name == "Binutils_jll" for jll in toolchain.deps) || any(jll.package.name == "GCCBootstrap_jll" for jll in toolchain.deps)
            binutils_wrappers(toolchain, out_dir)
        end
    end)

    @warn("TODO: Generate xcrun shim", maxlog=1)

    # Note that we eliminate the illegal "version" fields from our PackageSpec
    jll_deps = copy(toolchain.deps)
    @warn("TODO: do I need to filter these out here?", maxlog=1)
    filter_illegal_versionspecs!([jll.package for jll in jll_deps])
    append!(sources, jll_deps)
    return sources
end

function toolchain_env(toolchain::CToolchain, deployed_prefix::String)
    env = Dict{String,String}()

    insert_PATH!(env, :PRE, [
        joinpath(deployed_prefix, "wrappers"),
        joinpath(deployed_prefix, "bin"),
    ])

    function set_envvars(envvar_prefix::String, tool_prefix::String)
        env["$(envvar_prefix)AR"] = "$(tool_prefix)ar"
        env["$(envvar_prefix)AS"] = "$(tool_prefix)as"
        env["$(envvar_prefix)CC"] = "$(tool_prefix)cc"
        env["$(envvar_prefix)CXX"] = "$(tool_prefix)c++"
        env["$(envvar_prefix)LD"] = "$(tool_prefix)ld"
        env["$(envvar_prefix)NM"] = "$(tool_prefix)nm"
        env["$(envvar_prefix)RANLIB"] = "$(tool_prefix)ranlib"
        env["$(envvar_prefix)OBJCOPY"] = "$(tool_prefix)objcopy"
        env["$(envvar_prefix)OBJDUMP"] = "$(tool_prefix)objdump"
        env["$(envvar_prefix)STRIP"] = "$(tool_prefix)strip"

        if Sys.isapple(toolchain.platform.target)
            env["$(envvar_prefix)DSYMUTIL"] = "$(tool_prefix)dsymutil"
            env["$(envvar_prefix)LIPO"] = "$(tool_prefix)lipo"
        end

        if !Sys.isapple(toolchain.platform.target)
            env["$(envvar_prefix)READELF"] = "$(tool_prefix)readelf"
        end

        if Sys.iswindows(toolchain.platform.target)
            env["$(envvar_prefix)DLLTOOL"] = "$(tool_prefix)dlltool"
            env["$(envvar_prefix)WINDRES"] = "$(tool_prefix)windres"
            env["$(envvar_prefix)WINMC"] = "$(tool_prefix)winmc"
        end
    end

    # Even though the default toolchain generated the non-triplet-prefixed names,
    # we prefer to be explicit whenever possible.  It makes it a lot easier to
    # debug when things aren't what we expect.
    tool_prefix = toolchain.host_ctoolchain ? "host-$(gcc_target_triplet(toolchain.platform.target))-" : "$(gcc_target_triplet(toolchain.platform.target))-"
    if toolchain.default_ctoolchain
        set_envvars("", tool_prefix)
    end
    if toolchain.host_ctoolchain
        set_envvars("HOST", tool_prefix)
    end
    return env
end

function platform(toolchain::CToolchain)
    return toolchain.platform
end



"""
    compile_flagmatch(f, io)

Convenience function for CToolchain wrappers, using `flagmatch()` to match
only when a compiler invocation is performing compilation.  As of this
writing, this only excludes the case where `clang` has been invoked as an
assembler via the `-x assembler` flag.
"""
function compile_flagmatch(f::Function, io::IO)
    flagmatch(f, io, [!flag"-x assembler", !flag"-v"r])
end

"""
    link_flagmatch(f, io)

Convenience function for CToolchain wrappers, using `flagmatch()` to match
only when a compiler invocation is performing linking.  This excludes the cases
where the compiler has been invoked to preprocess, compile without linking, act
as an assembler, etc...
"""
function link_flagmatch(f::Function, io::IO)
    flagmatch(f, io, [!flag"-c", !flag"-E", !flag"-M", !flag"-fsyntax-only", !flag"-x assembler", !flag"-v"r])
end


"""
    gcc_wrappers(toolchain::CToolchain, dir::String)

Generate wrapper scripts (using `compiler_wrapper()`) into `dir` to launch
tools like `gcc`, `g++`, etc... from `GCC_jll` with appropriate flags
interposed.  Typically only generates wrappers with target triplets suffixed,
however if `toolchain.default_ctoolchain` is set, also generates the generic
wrapper names `cc`, `gcc`, `c++`, etc...
"""
function gcc_wrappers(toolchain::CToolchain, dir::String)
    gcc_version = only(jll.package.version for jll in toolchain.deps if jll.package.name ∈ ("GCC_jll", "GCCBootstrap_jll"))
    p = toolchain.platform.target
    toolchain_prefix = "\$(dirname \"\${WRAPPER_DIR}\")"

    function _gcc_wrapper(tool_name, tool_target)
        compiler_wrapper(joinpath(dir, tool_name), "$(toolchain_prefix)/bin/$(tool_target)") do io

            # Fail out noisily if `-march` is set, but we're locking microarchitectures.
            if toolchain.lock_microarchitecture
                flagmatch(io, [flag"-march=.*"r]) do io
                    println(io, """
                    echo "BinaryBuilder: Cannot force an architecture via -march (check lock_microarchitecture setting)" >&2
                    exit 1
                    """)
                end
            end
            
            compile_flagmatch(io) do io
                if Sys.islinux(p) || Sys.isfreebsd(p)
                    # Help GCCBootstrap find its own libraries under
                    # `/opt/${target}/${target}/lib{,64}`.  Note: we need to push them directly in
                    # the wrappers before any additional arguments because we want this path to have
                    # precedence over anything else.  In this way for example we avoid libraries
                    # from `CompilerSupportLibraries_jll` in `${libdir}` are picked up by mistake.
                    @warn("TODO: determine if this is actually needed", maxlog=1)
                    libdir = "$(toolchain_prefix)/$(gcc_target_triplet(p))/lib" * (nbits(p) == 32 ? "" : "64")
                    append_flags(io, :POST, ["-L$(libdir)", "-Wl,-rpath-link,$(libdir)"])
                end

                if toolchain.lock_microarchitecture
                    append_flags(io, :PRE, get_march_flags(arch(p), march(p), "gcc"))
                end

                # Add any extra CFLAGS the user has requested of us
                append_flags(io, :PRE, toolchain.extra_cflags)

                @warn("TODO: add sanitize compile flags!", maxlog=1)
                #sanitize_compile_flags!(p, flags)
            end

            # Force proper cxx11 string ABI usage, if it is set at all
            if cxxstring_abi(p) == "cxx11"
                append_flags(io, :PRE, "-D_GLIBCXX_USE_CXX11_ABI=1")
            elseif cxxstring_abi(p) == "cxx03"
                append_flags(io, :PRE, "-D_GLIBCXX_USE_CXX11_ABI=0")
            end

            if Sys.isapple(p)
                if os_version(p) === nothing
                    @warn("TODO: macOS builds should always denote their `os_version`!", platform=triplet(p), maxlog=1)
                end

                # Simulate some of the `__OSX_AVAILABLE()` macro usage that is broken in GCC
                if something(os_version(p), v"14") < v"16"
                    # Disable usage of `clock_gettime()`
                    append_flags(io, :PRE, "-D_DARWIN_FEATURE_CLOCK_GETTIME=0")
                end

                # Always compile for a particular minimum macOS verison
                append_flags(io, :PRE, "-mmacosx-version-min=$(macos_version(p))")

                if gcc_version.major in (4, 5)
                    push!(flags, "-Wl,-syslibroot,$(toolchain_prefix)/$(gcc_target_triplet(p))/sys-root")
                end
            end

            # Use hash of arguments to provide the random seed, for increased reproducibility,
            # but only do this if it has not already been specified:
            flagmatch(io, [!flag"-frandom-seed"r]) do io
                append_flags(io, :PRE, "-frandom-seed=0x\${ARGS_HASH}")
            end

            # Add link-time-only flags
            link_flagmatch(io) do io
                # Yes, it does seem that the inclusion of `/lib64` on `powerpc64le` was fixed
                # in GCC 6, broken again in GCC 7, and then fixed again in GCC 8+
                if arch(p) == "powerpc64le" && Sys.islinux(p) && gcc_version.major in (4, 5, 7)
                    append_flags(io, :POST, [
                        "-L$(toolchain_prefix)/$(gcc_target_triplet(p))/sys-root/lib64",
                        "-Wl,-rpath-link,$(toolchain_prefix)/$(gcc_target_triplet(p))/sys-root/lib64",
                    ])
                end

                # When we use `install_name_tool` to alter dylib IDs and whatnot, we need
                # to have extra space in the MachO headers so we can expand names, if necessary.
                if Sys.isapple(p)
                    append_flags(io, :POST, "-headerpad_max_install_names")
                end

                # Do not embed timestamps, for reproducibility:
                # https://github.com/JuliaPackaging/BinaryBuilder.jl/issues/1232
                if Sys.iswindows(p) && gcc_version ≥ v"5"
                    append_flags(io, :POST, "-Wl,--no-insert-timestamp")
                end

                # Add any extra linker flags that the user has requested of us
                append_flags(io, :POST, toolchain.extra_ldflags)

                @warn("TODO: sanitize_link_flags()", maxlog=1)
            end
        end
    end

    @warn("TODO: Add ccache ability back in", maxlog=1)

    # Generate target-specific wrappers always.  If we're a host toolchain, prefix with `host-`
    # so that when doing a native build, you can call `host-x86_64-linux-gnu-gcc` and `x86_64-linux-gnu-gcc`
    # separately, to disambiguate which should be used.
    triplet_prefix = toolchain.host_ctoolchain ? "host-$(gcc_target_triplet(p))" : "$(gcc_target_triplet(p))"
    _gcc_wrapper("$(triplet_prefix)-gcc$(exeext(p))", "$(gcc_target_triplet(p))-gcc$(exeext(p))")
    _gcc_wrapper("$(triplet_prefix)-g++$(exeext(p))", "$(gcc_target_triplet(p))-g++$(exeext(p))")

    if toolchain.vendor == :gcc || toolchain.vendor == :gcc_bootstrap
        _gcc_wrapper("$(triplet_prefix)-cc$(exeext(p))",  "$(gcc_target_triplet(p))-gcc$(exeext(p))")
        _gcc_wrapper("$(triplet_prefix)-c++$(exeext(p))", "$(gcc_target_triplet(p))-g++$(exeext(p))")
        _gcc_wrapper("$(triplet_prefix)-cpp$(exeext(p))", "$(gcc_target_triplet(p))-cpp$(exeext(p))")
    end

    # Generate generalized wrapper if we're the default toolchain (woop woop) (and more if
    # the C toolchain "vendor" is GCC!)
    if toolchain.default_ctoolchain
        _gcc_wrapper("gcc$(exeext(p))", "$(gcc_target_triplet(p))-gcc$(exeext(p))")
        _gcc_wrapper("g++$(exeext(p))", "$(gcc_target_triplet(p))-g++$(exeext(p))")

        if toolchain.vendor == :gcc || toolchain.vendor == :gcc_bootstrap
            _gcc_wrapper("cc$(exeext(p))",  "$(gcc_target_triplet(p))-gcc$(exeext(p))")
            _gcc_wrapper("c++$(exeext(p))", "$(gcc_target_triplet(p))-g++$(exeext(p))")
            _gcc_wrapper("cpp$(exeext(p))", "$(gcc_target_triplet(p))-cpp$(exeext(p))")
        end
    end
end

function binutils_wrappers(toolchain::CToolchain, dir::String)
    p = toolchain.platform.target
    toolchain_prefix = "\$(dirname \"\${WRAPPER_DIR}\")"
    triplet_prefix = toolchain.host_ctoolchain ? "host-$(gcc_target_triplet(p))" : "$(gcc_target_triplet(p))"

    # Most tools don't need anything fancy; just `compiler_wrapper()`
    simple_tools = [
        "as",
        "ld",
        "nm",
        "objcopy",
        "objdump",
        "strip",
    ]
    @warn("TODO: Verify that `as` does not need adjusted MACOSX_DEPLOYMENT_TARGET", maxlog=1)
    @warn("TODO: Add in `ld.64` and `ld.target-triplet` again", maxlog=1)
    if Sys.isapple(p)
        append!(simple_tools, [
            "dsymutil",
            "install_name_tool",
            "lipo",
            "otool",
        ])
    end
    if Sys.iswindows(p)
        append!(simple_tools, [
            "windres",
            "winmc",
        ])
    end
    if !Sys.isapple(p)
        # Amusingly, windows binutils does have a `readelf`.
        append!(simple_tools, [
            "readelf",
        ])
    end

    # Helper function to make many tool symlinks
    # `tool` is the name that we export, (which will be prefixed by
    # our target triplet) e.g. `ar`.  `tool_target` is the name of
    # the wrapped executable (e.g. `llvm-ar`).
    function make_tool_symlinks(tool, tool_target; wrapper::Function = identity)
        compiler_wrapper(wrapper,
            joinpath(dir, "$(gcc_target_triplet(p))-$(tool)"),
            "$(toolchain_prefix)/bin/$(tool_target)"
        )
        if toolchain.default_ctoolchain
            compiler_wrapper(wrapper,
                joinpath(dir, tool),
                "$(toolchain_prefix)/bin/$(tool_target)"
            )
        end
    end

    # For all simple tools, create the target-specific name, and the basename if we're the default toolchain
    for tool in simple_tools
        make_tool_symlinks("$(triplet_prefix)-$(tool)", "$(gcc_target_triplet(p))-$(tool)")
        if toolchain.default_ctoolchain
            make_tool_symlinks(tool, "$(gcc_target_triplet(p))-$(tool)")
        end
    end

    # c++filt uses `llvm-cxxfilt` on macOS, `c++filt` elsewhere
    cxxfilt_name = Sys.isapple(p) ? "llvm-cxxfilt" : "$(gcc_target_triplet(p))-c++filt"
    make_tool_symlinks("$(triplet_prefix)-c++filt", cxxfilt_name)
    if toolchain.default_ctoolchain
        make_tool_symlinks("c++filt", cxxfilt_name)
    end

    # `ar` and `ranlib` have special treatment due to determinism requirements.
    # Additionally, we use the `llvm-` prefixed tools on macOS.
    function _ar_wrapper(tool_name, tool_target)
        compiler_wrapper(joinpath(dir, tool_name), "$(toolchain_prefix)/bin/$(tool_target)") do io
            # We need to detect the `-U` flag that is passed to `ar`.  Unfortunately,
            # `ar` accepts many forms of its arguments, and we want to catch all of them.
            println(io, raw"""
            NONDETERMINISTIC=0
            warn_nondeterministic() {
                if [[ "${NONDETERMINISTIC}" != "1" ]]; then
                    echo "Non-reproducibility alert: This 'ar' invocation uses the '-U' flag which embeds timestamps." >&2
                    echo "ar flags: ${ARGS[@]}" >&2
                    echo "Continuing build, but please repent." >&2
                fi
                NONDETERMINISTIC=1
            }
            """)

            # We'll start with the easy stuff; `-U` by itself, as any argument!
            flagmatch(io, [flag"-U"]) do io
                println(io, "warn_nondeterministic")
            end

            # However, the more traditional way to use `ar` is to mash a bunch of
            # single-letter flags together into the first argument.  This can be
            # preceeded by a dash, but doesn't have to be (sigh).
            flagmatch(io, [flag"-?[^-]*U.*"r]; match_target="\${ARGS[0]}") do io
                println(io, "warn_nondeterministic")
            end

            # Figure out if we've already set `-D`
            flagmatch(io, [flag"-D"]) do io
                println(io, "DETERMINISTIC=1")
            end
            flagmatch(io, [flag"-?[^-]*D"r]; match_target="\${ARGS[0]}") do io
                println(io, "DETERMINISTIC=1")
            end

            # If we haven't already set `-U`, _and_ we haven't already set `-D`, then
            # we'll try to set `-D`:
            flagmatch(io, [!flag"--.*"r]; match_target="\${ARGS[0]}") do io
                # If our first flag is not a double-dashed option, we will just
                # slap `D` onto the end of it:
                println(io, raw"""
                if [[ "${NONDETERMINISTIC}" != "1" ]] && [[ "${DETERMINISTIC}" != "1" ]]; then
                    ARGS[0]="${ARGS[0]}D"
                    DETERMINISTIC="1"
                fi
                """)
            end

            # Eliminate the `u` option, as it's incompatible with `D` and is just an optimization
            println(io, raw"""
            if [[ "${DETERMINISTIC}" == "1" ]]; then
                for ((i=0; i<"${#ARGS[@]}"; ++i)); do
                    if [[ "${ARGS[i]}" == "-u" ]]; then
                        unset ARGS[$i]
                    fi
                done

                # Also find examles like `ar -ruD` or `ar ruD`
                if [[ " ${ARGS[0]} " == *'u'* ]]; then
                    ARGS[0]=$(echo "${ARGS[0]}" | tr -d u)
                fi
            fi
            """)
        end
    end

    function _ranlib_wrapper(tool_name, tool_target)
        compiler_wrapper(joinpath(dir, tool_name), "$(toolchain_prefix)/bin/$(tool_target)") do io
            # Warn the user if they provide `-U` in their build script
            flagmatch(io, [flag"-[^-]*U.*"r]) do io
                println(io, raw"""
                echo "Non-reproducibility alert: This 'ranlib' invocation uses the '-U' flag which embeds timestamps." >&2
                echo "ranlib flags: ${ARGS[@]}" >&2
                echo "Continuing build, but please repent." >&2
                """)
            end

            # If there's no `-U`, and we haven't already provided `-D`, insert it!
            flagmatch(io, [!flag"-[^-]*U.*"r, !flag"-[^-]*D.*"]) do io
                append_flags(io, :PRE, "-D")
            end
        end
    end

    ar_name = Sys.isapple(p) ? "llvm-ar" : "$(gcc_target_triplet(p))-ar"
    ranlib_name = Sys.isapple(p) ? "llvm-ranlib" : "$(gcc_target_triplet(p))-ranlib"
    _ar_wrapper("$(triplet_prefix)-ar", ar_name)
    _ranlib_wrapper("$(triplet_prefix)-ranlib", ranlib_name)
    if toolchain.default_ctoolchain
        _ar_wrapper("ar", ar_name)
        _ranlib_wrapper("ranlib", ranlib_name)
    end

    # dlltool needs some determinism fixes as well
    function _dlltool_wrapper(tool_name, tool_target)
        compiler_wrapper(joinpath(dir, tool_name), "$(toolchain_prefix)/bin/$(tool_target)") do io
            append_flags(io, :PRE, ["--temp-prefix", "/tmp/dlltool-\${ARGS_HASH}"])
        end
    end
    if Sys.iswindows(p)
        _dlltool_wrapper("$(triplet_prefix)-dlltool", "$(gcc_target_triplet(p))-dlltool")
        if toolchain.default_ctoolchain
            _dlltool_wrapper("dlltool", "$(gcc_target_triplet(p))-dlltool")
        end
    end
end


"""
    clang_wrappers(toolchain::CToolchain, dir::String)

Generate wrapper scripts (using `compiler_wrapper()`) into `dir` to launch
tools like `gcc`, `g++`, etc... from `GCC_jll` with appropriate flags
interposed.
"""
function clang_wrappers(toolchain::CToolchain, dir::String)
    p = toolchain.platform.target
    toolchain_prefix = "\$(dirname \"\${WRAPPER_DIR}\")"
    triplet_prefix = toolchain.host_ctoolchain ? "host-$(gcc_target_triplet(p))" : "$(gcc_target_triplet(p))"

    function _clang_wrapper(tool_name, tool_target)
        compiler_wrapper(joinpath(dir, tool_name), "$(toolchain_prefix)/bin/$(tool_target)") do io
            append_flags(io, :PRE, [
                # Set the `target` for `clang` so it generates the right kind of code
                "--target=$(gcc_target_triplet(p))",
                # Set the sysroot
                "--sysroot=$(toolchain_prefix)/$(gcc_target_triplet(p))/sys-root",
                # Set the GCC toolchain location
                "--gcc-toolchain=$(toolchain_prefix)",
            ])
        end
    end

    _clang_wrapper("$(triplet_prefix)-clang", "$(gcc_target_triplet(p))-clang")
    _clang_wrapper("$(triplet_prefix)-clang++", "$(gcc_target_triplet(p))-clang++")

    # Generate generalized wrapper if we're the default toolchain (woop woop) (and more if
    # the C toolchain "vendor" is clang!)
    if toolchain.default_ctoolchain
        _clang_wrapper("clang", "$(gcc_target_triplet(p))-clang")
        _clang_wrapper("clang++", "$(gcc_target_triplet(p))-clang++")

        if toolchain.vendor == :clang
            _clang_wrapper("cc", "$(gcc_target_triplet(p))-clang")
            _clang_wrapper("c++", "$(gcc_target_triplet(p))-clang++")
        end
    end
end



function supported_platforms(::Type{CToolchain}; experimental::Bool = false)
    # Maybe make this inspect the supported platforms GCC_jll or something like that?
    return [
        Platform("x86_64", "linux"),
        Platform("i686", "linux"),
        Platform("aarch64", "linux"),
        Platform("armv7l", "linux"),
        Platform("ppc64le", "linux"),
    ]
end
