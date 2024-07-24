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

    # Allows adding a special prefix to the beginning of our wrapper scripts.
    # Used to force the host toolchain to have e.g. `build-x86_64-linux-gnu-gcc`
    # which is separate from `x86_64-linux-gnu-gcc`, which has different automatic
    # include directories, for instance.  Defaults to `""`
    wrapper_prefixes::Vector{String}

    # Allows adding special prefix(es) to the beginning of our environment variables.
    # This enables defining `CC` and `TARGETCC` and `TARGET_CC`, if we so wish.
    env_prefixes::Vector{String}

    # If this is set to true (which is the default) we won't allow packages
    # to specify a `-march`; we're in control of that.
    lock_microarchitecture::Bool

    # Extra compiler and linker flags that should be inserted.
    # We typically use these to add `-L/workspace/destdir/${target}`
    # in BinaryBuilder.
    extra_cflags::Vector{String}
    extra_ldflags::Vector{String}

    # Concretized versions of our tools
    tool_versions::Dict{String,VersionNumber}

    function CToolchain(platform;
                        vendor = :auto,
                        env_prefixes = [""],
                        wrapper_prefixes = ["\${triplet}-", ""],
                        lock_microarchitecture = true,
                        gcc_version = VersionSpec("9"),
                        llvm_version = VersionSpec("*"),
                        binutils_version = v"2.38.0+4",
                        glibc_version = :oldest,
                        extra_cflags = String[],
                        extra_ldflags = String[])
        if vendor ∉ (:auto, :gcc, :clang, :bootstrap)
            throw(ArgumentError("Unknown C toolchain vendor '$(vendor)'"))
        end

        if isempty(wrapper_prefixes)
            throw(ArgumentError("Cannot have empty wrapper prefixes!  Did you mean [\"\"]?"))
        end
        if isempty(env_prefixes)
            throw(ArgumentError("Cannot have empty env prefixes!  Did you mean [\"\"]?"))
        end

        if os(platform) == "linux" && isa(glibc_version, Symbol)
            # If the user asks for the oldest version of glibc, figure out what platform we're
            # building for, and use an appropriate version.
            if glibc_version == :oldest
                # TODO: Should glibc_version be embedded within the triplet somehow?
                #       Non-default glibc version is kind of a compatibility issue....
                @warn("TODO: Should glibc_version be embedded within the triplet?", maxlog=1)
                if arch(platform) ∈ ("x86_64", "i686", "powerpc64le",)
                    glibc_version = v"2.17"
                elseif arch(platform) ∈ ("armv7l", "aarch64")
                    glibc_version = v"2.19"
                else
                    throw(ArgumentError("Unknown oldest glibc version for architecture '$(arch)'!"))
                end
            else
                throw(ArgumentError("Invalid magic glibc_version argument :$(glibc_version)"))
            end
        end

        deps = jll_source_selection(
            get_vendor(vendor, platform),
            platform,
            gcc_version,
            llvm_version,
            binutils_version,
            glibc_version,
        )

        # Concretize the JLLSource's `PackageSpec`'s version (and UUID) now:
        resolve_versions!(deps; julia_version=nothing)

        jll_versions = Dict{String,Any}()
        function record_jll_version(name, names)
            for jll in deps
                if jll.package.name ∈ names
                    jll_versions[name] = jll.package.version
                end
            end
        end

        record_jll_version("GCC", ("GCC_jll", "GCCBootstrap_jll"))
        record_jll_version("LLVM", ("Clang_jll",))
        record_jll_version("Binutils", ("Binutils_jll",))
        record_jll_version("Glibc", ("Glibc_jll",))

        return new(
            platform,
            vendor,
            deps,
            string.(wrapper_prefixes),
            string.(env_prefixes),
            lock_microarchitecture,
            string.(extra_cflags),
            string.(extra_ldflags),
            jll_versions,
        )
    end
end

function get_vendor(vendor::Symbol, platform::AbstractPlatform)
    clang_default(p) = os(target_if_crossplatform(p)) ∈ ("macos", "freebsd")
    if vendor == :auto
        if clang_default(platform)
            return :clang
        else
            return :gcc
        end
    end
    if vendor == :bootstrap
        if clang_default(platform)
            return :clang_bootstrap
        else
            return :gcc_bootstrap
        end
    end
    return vendor
end
get_vendor(ct::CToolchain) = get_vendor(ct.vendor, ct.platform)

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
                # When we push up a new build of `GCCBootstrap_jll`, we always built it
                # for the host we're actually doing the bootstrap from.  Because of this,
                # we only get a single host architecture at a time.  That's fine, but
                # it means that we need to choose branches named by the host platform.
                rev="bb2/GCCBootstrap-$(triplet(platform.host))",
                source="https://github.com/staticfloat/GCCBootstrap_jll.jl"
            ),
            version=v"9.4.0",
        )]
    end

    # Collect our JLLSource objects for all of our compiler pieces:
    deps = JLLSource[]

    gcc_triplet = triplet(gcc_platform(platform.target))
    if os(platform.target) == "linux"
        # Linux builds require the kernel headers for the target platform
        push!(deps, JLLSource(
            "LinuxKernelHeaders_jll",
            platform.target;
            repo=Pkg.Types.GitRepo(
                rev="bb2/GCC",
                source="https://github.com/staticfloat/LinuxKernelHeaders_jll.jl"
            ),
            # LinuxKernelHeaders gets installed into `<prefix>/<triplet>/usr`
            target=joinpath(gcc_triplet, "usr")
        ))
    end

    if libc(platform.target) == "glibc"
        # Manual version selection, drop this once these are registered!
        if v"2.17" == glibc_version
            glibc_repo = Pkg.Types.GitRepo(
                rev="1ae9e1bdd75523bf0f027a9a740888ee6aad22ac",
                source="https://github.com/staticfloat/Glibc_jll.jl"
            )
        elseif v"2.19" == glibc_version
            glibc_repo = Pkg.Types.GitRepo(
                rev="d436c3277e9bce583bcc5c469849fc9809bf86e9",
                source="https://github.com/staticfloat/Glibc_jll.jl"
            )
        else
            error("Don't know how to install Glibc $(glibc_version)")
        end

        push!(deps, JLLSource(
            "Glibc_jll",
            platform.target;
            uuid=Base.UUID("452aa2e7-e185-58db-8ff9-d3c1fa4bc997"),
            # TODO: Should we encode this in the platform object somehow?
            version=glibc_version,
            repo=glibc_repo,
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
                rev="bb2/GCC",
                source="https://github.com/staticfloat/GCC_jll.jl"
            ),
            # eventually, include a resolved version
            # but for now, we're locked to this specific version
            version=v"9.4.0",
        ),
        JLLSource(
            "Binutils_jll",
            platform;
            repo=Pkg.Types.GitRepo(
                rev="bb2/GCC",
                source="https://github.com/staticfloat/Binutils_jll.jl"
            ),
            # eventually, include a resolved version
            version=v"2.41.2",
        ),
        #=
        JLLSource(
            "Zlib_jll",
            platform.target;
            repo=Pkg.Types.GitRepo(
                rev="bb2/GCC",
                source="https://github.com/staticfloat/Zlib_jll.jl"
            ),
            # zlib gets installed into `<prefix>/<triplet>/usr`, and it's only for the target
            target=joinpath(gcc_triplet, "usr"),
        ),
        =#
    ])
end

function Base.show(io::IO, toolchain::CToolchain)
    println(io, "CToolchain ($(toolchain.platform))")
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
        env["$(envvar_prefix)CPP"] = "$(tool_prefix)cpp"
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

    # We can have multiple wrapper prefixes, we always use the longest one
    # as that's typically the most specific.
    wrapper_prefixes = replace.(toolchain.wrapper_prefixes, ("\${triplet}" => triplet(toolchain.platform.target),))
    wrapper_prefix = wrapper_prefixes[argmax(length.(wrapper_prefixes))]
    for env_prefix in toolchain.env_prefixes
        set_envvars(env_prefix, wrapper_prefix)
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


# Helper function to make many tool symlinks
# `tool` is the name that we export, (which will be prefixed by
# our target triplet) e.g. `ar`.  `tool_target` is the name of
# the wrapped executable (e.g. `llvm-ar`).
function make_tool_wrappers(toolchain, output_dir, tool, tool_target; wrapper::Function = identity)
    # Helpful little hack to make our scripts more relocatable
    toolchain_prefix = "\$(dirname \"\${WRAPPER_DIR}\")"

    for wrapper_prefix in toolchain.wrapper_prefixes
        tool_prefixed = string(replace(wrapper_prefix, "\${triplet}" => triplet(toolchain.platform.target)), tool)
        compiler_wrapper(wrapper,
            joinpath(output_dir, "$(tool_prefixed)"),
            "$(toolchain_prefix)/bin/$(tool_target)"
        )
    end
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
    gcc_version = toolchain.tool_versions["GCC"]
    p = toolchain.platform.target
    toolchain_prefix = "\$(dirname \"\${WRAPPER_DIR}\")"

    function _gcc_wrapper(io)
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
                @warn("TODO: determine if this flag prepending is actually needed", maxlog=1)
                libdir = "$(toolchain_prefix)/$(gcc_target_triplet(p))/lib" * (nbits(p) == 32 ? "" : "64")
                append_flags(io, :POST, ["-L$(libdir)", "-Wl,-rpath-link,$(libdir)"])
            end

            if toolchain.lock_microarchitecture
                append_flags(io, :PRE, get_march_flags(arch(p), march(p), "gcc"))
            end

            # Add any extra CFLAGS the user has requested of us
            append_flags(io, :PRE, toolchain.extra_cflags)

            # Add on `-fsanitize-memory` if our platform has a santization tag applied
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

    @warn("TODO: Add ccache ability back in", maxlog=1)

    # gcc, g++
    make_tool_wrappers(toolchain, dir, "gcc", "$(gcc_target_triplet(p))-gcc"; wrapper=_gcc_wrapper)
    make_tool_wrappers(toolchain, dir, "g++", "$(gcc_target_triplet(p))-g++"; wrapper=_gcc_wrapper)

    if get_vendor(toolchain) ∈ (:gcc, :gcc_bootstrap)
        make_tool_wrappers(toolchain, dir, "cc", "$(gcc_target_triplet(p))-gcc"; wrapper=_gcc_wrapper)
        make_tool_wrappers(toolchain, dir, "c++", "$(gcc_target_triplet(p))-g++"; wrapper=_gcc_wrapper)
        make_tool_wrappers(toolchain, dir, "cpp", "$(gcc_target_triplet(p))-cpp"; wrapper=_gcc_wrapper)
    end
end

function binutils_wrappers(toolchain::CToolchain, dir::String)
    p = toolchain.platform.target

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


    # `ar` and `ranlib` have special treatment due to determinism requirements.
    # Additionally, we use the `llvm-` prefixed tools on macOS.
    function _ar_wrapper(io)
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

    function _ranlib_wrapper(io)
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

    # For all simple tools, create the target-specific name, and the basename if we're the default toolchain
    for tool in simple_tools
        make_tool_wrappers(toolchain, dir, tool, "$(gcc_target_triplet(p))-$(tool)")
    end

    # c++filt uses `llvm-cxxfilt` on macOS, `c++filt` elsewhere
    cxxfilt_name = Sys.isapple(p) ? "llvm-cxxfilt" : "$(gcc_target_triplet(p))-c++filt"
    make_tool_wrappers(toolchain, dir, "c++filt", cxxfilt_name)

    ar_name = Sys.isapple(p) ? "llvm-ar" : "$(gcc_target_triplet(p))-ar"
    make_tool_wrappers(toolchain, dir, "ar", ar_name; wrapper=_ar_wrapper)

    ranlib_name = Sys.isapple(p) ? "llvm-ranlib" : "$(gcc_target_triplet(p))-ranlib"
    make_tool_wrappers(toolchain, dir, "ranlib", ranlib_name; wrapper=_ranlib_wrapper)

    # dlltool needs some determinism fixes as well
    if Sys.iswindows(p)
        function _dlltool_wrapper(io)
            append_flags(io, :PRE, ["--temp-prefix", "/tmp/dlltool-\${ARGS_HASH}"])
        end
        make_tool_wrappers(toolchain, dir, "dlltool", "$(gcc_target_triplet(p))-dlltool"; wrapper=_dlltool_wrapper)
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

    function _clang_wrapper(io)
        append_flags(io, :PRE, [
            # Set the `target` for `clang` so it generates the right kind of code
            "--target=$(gcc_target_triplet(p))",
            # Set the sysroot
            "--sysroot=$(toolchain_prefix)/$(gcc_target_triplet(p))/sys-root",
            # Set the GCC toolchain location
            "--gcc-toolchain=$(toolchain_prefix)",
        ])
    end

    make_tool_wrappers(toolchain, dir, "clang", "$(gcc_target_triplet(p))-clang"; wrapper=_clang_wrapper)
    make_tool_wrappers(toolchain, dir, "clang++", "$(gcc_target_triplet(p))-clang++"; wrapper=_clang_wrapper)
end



function supported_platforms(::Type{CToolchain}; experimental::Bool = false)
    # Maybe make this inspect the supported platforms GCC_jll or something like that?
    return [
        Platform("x86_64", "linux"),
        Platform("i686", "linux"),
        Platform("aarch64", "linux"),
        Platform("armv7l", "linux"),
        Platform("ppc64le", "linux"),
#=
        Platform("x86_64", "linux"; libc="musl"),
        Platform("i686", "linux"; libc="musl"),
        Platform("aarch64", "linux"; libc="musl"),
        Platform("armv6l", "linux"; libc="musl"),
        Platform("armv7l", "linux"; libc="musl"),

        Platform("x86_64", "windows"),
        Platform("i686", "windows"),
=#
    ]
end
