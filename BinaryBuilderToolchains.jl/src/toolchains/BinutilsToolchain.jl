export BinutilsToolchain

"""
    BinutilsToolchain

This toolchain is typically used within `CToolchain`, the only reason it's
split out like this is so that during bootstrap for macOS and FreeBSD, we
can deploy Binutils while bootstrapping our compilers.  This is taken care
of for us by crosstool-ng
"""
struct BinutilsToolchain <: AbstractToolchain
    platform::CrossPlatform

    # See CToolchain for explanation of these fields
    vendor::Symbol
    deps::Vector{JLLSource}
    wrapper_prefixes::Vector{String}
    env_prefixes::Vector{String}
    use_ccache::Bool

    # We must store the GCC version (if we have one) so that we can
    # find our LTO plugins.
    gcc_version::Union{Nothing,VersionNumber}
    cache_key::String

    function BinutilsToolchain(platform::CrossPlatform,
                               vendor::Symbol;
                               wrapper_prefixes = ["\${triplet}-", ""],
                               env_prefixes = [""],
                               use_ccache = true,
                               gcc_version = nothing)
        cache_key = string(
            triplet(platform),
            vendor,
            env_prefixes...,
            wrapper_prefixes...,
            use_ccache ? "true" : "false",
            gcc_version,
        )
        cache_key = string(
            "BinutilsToolchain-",
            bytes2hex(sha1(cache_key))
        )
        return new(
            platform,
            vendor,
            binutils_jll_source_selection(vendor, platform),
            wrapper_prefixes,
            env_prefixes,
            use_ccache,
            gcc_version,
            cache_key,
        )
    end
end

function Base.show(io::IO, toolchain::BinutilsToolchain)
    println(io, "BinutilsToolchain ($(toolchain.platform))")
    for dep in toolchain.deps
        println(io, " - $(dep.package.name[1:end-4]) v$(dep.package.version)")
    end
end


function binutils_jll_source_selection(vendor, platform)
    deps = JLLSource[]
    # If this is a crosstool-ng based "gcc bootstrap" toolchain, binutils is already included.
    if os(platform.target) ∈ ("linux", "windows") && vendor ∈ (:gcc_bootstrap,)
        return deps
    end
    simple_vendor = get_simple_vendor(vendor)

    if os(platform.target) == "macos"
        append!(deps, [
            JLLSource(
                "CCTools_jll",
                platform;
                uuid=Base.UUID("1e42d1a4-ec21-5f39-ae07-c1fb720fbc4b"),
                repo=Pkg.Types.GitRepo(
                    rev="bb2/GCCBootstrap-x86_64-linux-gnu",
                    source="https://github.com/staticfloat/CCTools_jll.jl",
                ),
                # eventually, include a resolved version
                version=v"986.0.0",
                target=simple_vendor,
            ),
            # JLLSource(
            #     "libtapi_jll",
            #     platform.host;
            #     uuid=Base.UUID("defda0c2-6d1f-5f19-8ead-78afca958a10"),
            #     repo=Pkg.Types.GitRepo(
            #         rev="bb2/GCCBootstrap-x86_64-linux-gnu",
            #         source="https://github.com/staticfloat/libtapi_jll.jl",
            #     ),
            #     # eventually, include a resolved version
            #     version=v"1300.6.0",
            #     target=simple_vendor,
            # ),
            JLLSource("ldid_jll", platform.host),
        ])

        if simple_vendor != "clang"
            append!(deps, [
                JLLSource(
                    "LLVMBootstrap_Clang_jll",
                    platform;
                    uuid=Base.UUID("b81fd3a9-9257-59d0-818a-b16b9f1e1eb9"),
                    repo=Pkg.Types.GitRepo(
                        rev="bb2/GCCBootstrap-$(triplet(platform.host))",
                        source="https://github.com/staticfloat/LLVMBootstrap_Clang_jll.jl"
                    ),
                    version=v"17.0.0",
                    target=get_simple_vendor(vendor),
                ),
                JLLSource(
                    "LLVMBootstrap_libLLVM_jll",
                    platform;
                    uuid=Base.UUID("de72bca2-3cdf-50cb-9084-6e985cd8d9f3"),
                    repo=Pkg.Types.GitRepo(
                        rev="bb2/GCCBootstrap-$(triplet(platform.host))",
                        source="https://github.com/staticfloat/LLVMBootstrap_libLLVM_jll.jl"
                    ),
                    version=v"17.0.0",
                    target=get_simple_vendor(vendor),
                ),
            ])
        end
    else
        push!(deps, JLLSource(
            "Binutils_jll",
            platform;
            repo=Pkg.Types.GitRepo(
                rev="bb2/GCCBootstrap-x86_64-linux-gnu",
                source="https://github.com/staticfloat/Binutils_jll.jl",
            ),
            # eventually, include a resolved version
            version=v"2.41.0",
            target=simple_vendor,
        ))
    end
    return deps
end

cache_key(toolchain::BinutilsToolchain) = toolchain.cache_key

function add_ccache_preamble(io, toolchain)
    if toolchain.use_ccache
        println(io, """
        # If `ccache` is available, use it!
        if which ccache >/dev/null; then
            PROG=( ccache "compiler_check=string:$(cache_key(toolchain))" "\${PROG[@]}" )
        fi
        """)
    end
end

function binutils_wrappers(toolchain::BinutilsToolchain, dir::String)
    p = toolchain.platform.target
    toolchain_prefix = "\$(dirname \"\${WRAPPER_DIR}\")/$(get_simple_vendor(toolchain.vendor))"
    gcc_triplet = toolchain.vendor == :gcc_bootstrap ? gcc_target_triplet(p) : triplet(gcc_platform(p))

    # These tools don't need anything fancy; just `compiler_wrapper()`
    simple_tools = String[]
    @warn("TODO: Verify that `as` does not need adjusted MACOSX_DEPLOYMENT_TARGET", maxlog=1)
    @warn("TODO: Add in `ld.64` and `ld.target-triplet` again", maxlog=1)
    # Apple has some extra simple tools
    if Sys.isapple(p)
        append!(simple_tools, [
            "install_name_tool",
            "lipo",
            "otool",
        ])
    else
        # Everyone except for `macOS` has a `readelf` command.
        append!(simple_tools, [
            "readelf",
        ])
    end

    # Windows has some extra simple tools
    if Sys.iswindows(p)
        append!(simple_tools, [
            "windres",
            "winmc",
        ])
    end

    function _ld_wrapper(io)
        if Sys.iswindows(p)
            _warn_nondeterministic_definition(io, "uses the '--insert-timestamps' flag which embeds timestamps")

            # Warn if someone has asked for timestamps
            flagmatch(io, [flag"--insert-timestamps"]) do io
                println(io, "warn_nondeterministic")
            end

            # Default to not using timestamps
            flagmatch(io, [!flag"--insert-timestamps", !flag"--no-insert-timestamps"]) do io
                append_flags(io, :PRE, "--no-insert-timestamp")
            end
        end

        # If `ccache` is allowed, sneak `ccache` in as the first argument to `PROG`
        add_ccache_preamble(io, toolchain)
    end

    # Many of our tools have nondeterministic
    function _warn_nondeterministic_definition(io, nondeterminism_description="uses flags that cause nondeterministic output!")
        println(io, """
        NONDETERMINISTIC=0
        warn_nondeterministic() {
            if [[ "\${NONDETERMINISTIC}" != "1" ]]; then
                echo "Non-reproducibility alert: This '\$0' invocation $(nondeterminism_description)." >&2
                echo "\$0 flags: \${ARGS[@]}" >&2
                echo "Continuing build, but please repent." >&2
            fi
            NONDETERMINISTIC=1
        }
        """)
    end

    # Some tools can load an LTO plugin.  We make sure this happens by passing in
    # `--plugin` automatically if the plugin exists.  This is not necessary on newer
    # binutils builds which properly install a symlink in `lib/bfd_plugins/`, but
    # doesn't hurt anything, so we just always do it.
    function lto_plugin_args(io::IO)
        if !isa(toolchain.gcc_version, VersionNumber)
            return
        end

        # We have the version glob here because our patch version may not actually
        # correspond to the true patch version.  It would be nice to inspect the
        # JLL.toml for the GCC build and determine the true `src_version here,
        # but that's an incredibly low-priority TODO.
        majmin = string(toolchain.gcc_version.major, ".", toolchain.gcc_version.minor)
        plugin_path = "`compgen -G \"$(toolchain_prefix)/libexec/gcc/$(gcc_triplet)/$(majmin)*/liblto_plugin.so\"`"
        bash_if_statement(io, "-f $(plugin_path)") do io
            append_flags(io, :POST, "--plugin=$(plugin_path)")
        end
    end

    # `ar` and `ranlib` have special treatment due to determinism requirements.
    # Additionally, we use the `llvm-` prefixed tools on macOS.
    function _ar_wrapper(io)
        # We need to detect the `-U` flag that is passed to `ar`.  Unfortunately,
        # `ar` accepts many forms of its arguments, and we want to catch all of them.
        _warn_nondeterministic_definition(io, "uses the '-U' flag which embeds timestamps")

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

            # Also find examples like `ar -ruD` or `ar ruD`
            if [[ " ${ARGS[0]} " == *'u'* ]]; then
                ARGS[0]=$(echo "${ARGS[0]}" | tr -d u)
            fi
        fi
        """)

        # If we've got a `liblto_plugin`, load it in:
        lto_plugin_args(io)
    end

    # Multiple tools (`ranlib`, `strip`) have a `-U` or `-D` option that switches them
    # from nondeterministic mode to determinstic mode.  We, of course, _always_ want
    # deterministic mode, and so do some common option parsing here. `ar` is a special
    # case due to handling the `-u` flag, which is why it has all that extra logic above.
    function _simple_U_D_determinism(io)
        _warn_nondeterministic_definition(io, "uses the '-U' flag which embeds UIDs and timestamps")
        # Warn the user if they provide `-U` in their build script
        flagmatch(io, [flag"-[^-]*U.*"r]) do io
            println(io, "warn_nondeterministic")
        end

        # If there's no `-U`, and we haven't already provided `-D`, insert it!
        flagmatch(io, [!flag"-[^-]*U.*"r, !flag"-[^-]*D.*"r]) do io
            append_flags(io, :PRE, "-D")
        end
    end

    function _ranlib_wrapper(io)
        _simple_U_D_determinism(io)

        # ranlib can take in `--plugin`
        lto_plugin_args(io)
    end

    function _nm_wrapper(io)
        # nm can take in `--plugin`
        lto_plugin_args(io)
    end

    function _strip_wrapper_pre(io)
        _simple_U_D_determinism(io)

        # On non-apple platforms, there's nothing else to be done!
        if !Sys.isapple(p)
            return
        end

        # Otherwise, we need to do some RATHER ONEROUS parsing.
        # We need to identify every file touched by `strip` and then
        # re-sign them all using `ldid`.  Because `strip` can take
        # multiple output files, we end up doing a bunch of custom
        # argument parsing here to identify all files that will be signed.
        println(io, raw"""
        FILES_TO_SIGN=()
        # Parse arguments to figure out what files are being stripped,
        # so we know what to re-sign after all is said and done.
        get_files_to_sign()
        {
            for ARG_IDX in "${!ARGS[@]}"; do
                # If `-o` is passed, that's the only file to sign, ignore
                # everything else and finish off immediately.
                if [[ "${ARGS[ARG_IDX]}" == "-o" ]] && (( ARG_IDX + 1 < ${#ARGS[@]} )); then
                    FILES_TO_SIGN=( "${ARGS[ARG_IDX+1]}" )
                    return
                elif [[ "${ARGS[ARG_IDX]}" == "-o"* ]]; then
                    filename="${ARGS[ARG_IDX}]}"
                    FILES_TO_SIGN=( "${filename%%-o}" )
                    return
                fi

                # Otherwise, we collect arguments we don't know what to do with,
                # assuming they are files we should be signing.
                if [[ "${ARGS[ARG_IDX]}" != -* ]]; then
                    FILES_TO_SIGN+=( "${ARGS[ARG_IDX]}" )
                fi
            done
        }
        """)

        # Tell `strip` not to complain about us invalidating a code signature, since
        # we're gonna fix it up with `ldid` immediately afterward.
        append_flags(io, :PRE, ["-no_code_signature_warning"])
    end

    function _strip_wrapper_post(io)
        # On non-apple platforms, we don't need to do anything
        if !Sys.isapple(p)
            return
        end

        println(io, raw"""
        # Re-sign all files listed in `FILES_TO_SIGN`
        for file in "${FILES_TO_SIGN[@]}"; do
            ldid -S "${file}"
        done
        """)
    end

    function _as_wrapper(io)
        if Sys.isapple(p)
            # Warn if someone has asked for timestamps
            flagmatch(io, [!flag"-arch"]) do io
                # macOS likes to use `arm64`, not `aarch64`:
                arch_str = arch(p) == "aarch64" ? "arm64" : arch(p)
                append_flags(io, :PRE, ["-arch", arch_str])
            end

            # Tell the `as` executable how to find our clang.  We use a special name here
            # so that our wrapper for this doesn't conflict with an actual clang.
            println(io, "export CCTOOLS_CLANG_AS_EXECUTABLE='$(gcc_triplet)-clang-as'")
        end

        # If `ccache` is allowed, sneak `ccache` in as the first argument to `PROG`
        add_ccache_preamble(io, toolchain)
    end

    # Simple `clang` wrapper for being used as `clang-as`
    function _clang_as_wrapper(io)
        append_flags(io, :PRE, [
            # Set the `target` for `clang` so it generates the right kind of code
            "--target=$(gcc_triplet)",
        ])

        # If `ccache` is allowed, sneak `ccache` in as the first argument to `PROG`
        add_ccache_preamble(io, toolchain)
    end

    # For all simple tools, create the target-specific name, and the basename if we're the default toolchain
    for tool in simple_tools
        make_tool_wrappers(toolchain, dir, tool, "$(gcc_triplet)-$(tool)"; toolchain_prefix)
    end

    # `ld` is a simple tool, except that it can be wrapped with `ccache`:
    make_tool_wrappers(toolchain, dir, "ld", "$(gcc_triplet)-ld"; wrapper=_ld_wrapper, toolchain_prefix)

    # `as` is a simple tool, except that on macOS it needs an `-arch` specified:
    make_tool_wrappers(toolchain, dir, "as", "$(gcc_triplet)-as"; wrapper=_as_wrapper, toolchain_prefix)

    # Our `as` on macOS subs out to `$(gcc_triplet)-clang-as`, so we generate that here,
    # which in turn subs out to `clang`.
    if Sys.isapple(p)
        make_tool_wrappers(toolchain, dir, "clang-as", "clang"; wrapper=_clang_as_wrapper, toolchain_prefix)
    end

    # `nm` is a simple tool, except that it can take in `--plugin` for LTO
    make_tool_wrappers(toolchain, dir, "nm", "$(gcc_triplet)-nm"; wrapper=_nm_wrapper, toolchain_prefix)

    # `strip` needs complicated option parsing if we're on macOS
    make_tool_wrappers(toolchain, dir, "strip", "$(gcc_triplet)-strip"; wrapper=_strip_wrapper_pre, post_func=_strip_wrapper_post, toolchain_prefix)

    # c++filt uses `llvm-cxxfilt` on macOS, `c++filt` elsewhere
    cxxfilt_name = Sys.isapple(p) ? "llvm-cxxfilt" : "$(gcc_triplet)-c++filt"
    make_tool_wrappers(toolchain, dir, "c++filt", cxxfilt_name; toolchain_prefix)

    ar_name = Sys.isapple(p) ? "llvm-ar" : "$(gcc_triplet)-ar"
    make_tool_wrappers(toolchain, dir, "ar", ar_name; wrapper=_ar_wrapper, toolchain_prefix)

    ranlib_name = Sys.isapple(p) ? "llvm-ranlib" : "$(gcc_triplet)-ranlib"
    make_tool_wrappers(toolchain, dir, "ranlib", ranlib_name; wrapper=_ranlib_wrapper, toolchain_prefix)

    objcopy_name = Sys.isapple(p) ? "llvm-objcopy" : "$(gcc_triplet)-objcopy"
    make_tool_wrappers(toolchain, dir, "objcopy", objcopy_name; toolchain_prefix)

    objdump_name = Sys.isapple(p) ? "llvm-objdump" : "$(gcc_triplet)-objdump"
    make_tool_wrappers(toolchain, dir, "objdump", objdump_name; toolchain_prefix)

    if Sys.isapple(p)
        # dsymutil is just called `dsymutil`
        make_tool_wrappers(toolchain, dir, "dsymutil", "dsymutil"; toolchain_prefix)
    end

    # dlltool needs some determinism fixes as well
    if Sys.iswindows(p)
        function _dlltool_wrapper(io)
            append_flags(io, :PRE, ["--temp-prefix", "/tmp/dlltool-\${ARGS_HASH}"])
        end
        make_tool_wrappers(toolchain, dir, "dlltool", "$(gcc_triplet)-dlltool"; wrapper=_dlltool_wrapper, toolchain_prefix)
    end
end

function toolchain_sources(toolchain::BinutilsToolchain)
    sources = AbstractSource[]

    installing_jll(name) = get_jll(toolchain, name) !== nothing
    push!(sources, CachedGeneratedSource(cache_key(toolchain); target="wrappers") do out_dir
        binutils_wrappers(toolchain, out_dir)
    end)
    append!(sources, toolchain.deps)

    # We only ever use the latest binutils, no version selection
    return sources
end

function toolchain_env(toolchain::BinutilsToolchain, deployed_prefix::String)
    env = Dict{String,String}()

    insert_PATH!(env, :PRE, [
        joinpath(deployed_prefix, "wrappers"),
        joinpath(deployed_prefix, get_simple_vendor(toolchain), "bin")
    ])

    function set_envvars(envvar_prefix::String, tool_prefix::String)
        env["$(envvar_prefix)AR"] = "$(tool_prefix)ar"
        env["$(envvar_prefix)AS"] = "$(tool_prefix)as"
        env["$(envvar_prefix)CXXFILT"] = "$(tool_prefix)c++filt"
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

    wrapper_prefixes = replace.(toolchain.wrapper_prefixes, ("\${triplet}" => triplet(gcc_platform(toolchain.platform.target)),))
    wrapper_prefix = wrapper_prefixes[argmax(length.(wrapper_prefixes))]
    for env_prefix in toolchain.env_prefixes
        set_envvars(env_prefix, wrapper_prefix)
    end

    if Sys.isapple(toolchain.platform.target)
        # If toolchain platform already has an `os_version`, we need to obey that, otherwise we
        # use the default deployment targets for the architecture being built:
        function default_macos_kernel_version(arch)
            if arch == "x86_64"
                return 14
            elseif arch == "aarch64"
                return 20
            else
                throw(ArgumentError("Unknown macOS architecture '$(arch)'!"))
            end
        end

        kernel_version = something(
            os_version(toolchain.platform.target),
            default_macos_kernel_version(arch(toolchain.platform.target))
        )
        env["MACOSX_DEPLOYMENT_TARGET"] = macos_version(kernel_version)
    end

    if Sys.isfreebsd(toolchain.platform.target)
        function default_freebsd_sdk_version()
            return v"14.1"
        end
        freebsd_version = something(
            os_version(toolchain.platform.target),
            default_freebsd_sdk_version(),
        )
        env["FREEBSD_TARGET_SDK"] = "$(freebsd_version.major).$(freebsd_version.minor)"
    end

    return env
end

platform(toolchain::BinutilsToolchain) = toolchain.platform

function supported_platforms(::Type{BinutilsToolchain}; experimental::Bool = false)
    # Maybe make this inspect the supported platforms of GCC_jll or something like that?
    return [
        Platform("x86_64", "linux"),
        Platform("i686", "linux"),
        Platform("aarch64", "linux"),
        Platform("armv6l", "linux"),
        Platform("armv7l", "linux"),
        Platform("ppc64le", "linux"),

        Platform("x86_64", "linux"; libc="musl"),
        Platform("i686", "linux"; libc="musl"),
        Platform("aarch64", "linux"; libc="musl"),
        Platform("armv6l", "linux"; libc="musl"),
        Platform("armv7l", "linux"; libc="musl"),

        Platform("x86_64", "windows"),
        Platform("i686", "windows"),

        # These os version numbers come from the currently-default macOSSDK_jll and FreeBSDSysroot_jll versions
        Platform("x86_64", "macos"; os_version=string(macos_kernel_version("11.1"))),
        Platform("aarch64", "macos"; os_version=string(macos_kernel_version("11.1"))),

        Platform("x86_64", "freebsd"; os_version="14.1"),
        Platform("aarch64", "freebsd"; os_version="14.1"),
    ]
end

