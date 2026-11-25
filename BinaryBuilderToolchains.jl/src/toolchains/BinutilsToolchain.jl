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
            check_jll_pins(binutils_jll_source_selection(vendor, platform)),
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


# The version of `ld64` in the CCTools_jll below (`ld -v`).  Update it with CCTools_jll.
const cctools_ld64_version = "711"

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
                macos_sdk_platform(platform);
                uuid=Base.UUID("1e42d1a4-ec21-5f39-ae07-c1fb720fbc4b"),
                version=v"986.0.1",
                target=simple_vendor,
            ),
        ])

        if simple_vendor != "clang"
            append!(deps, [
                JLLSource(
                    "LLVMBootstrap_Clang_jll",
                    platform;
                    uuid=Base.UUID("b81fd3a9-9257-59d0-818a-b16b9f1e1eb9"),
                    repo=Pkg.Types.GitRepo(
                        rev=pinned_rev("LLVMBootstrap_Clang_jll", "bb2/GCCBootstrap-$(triplet(platform.host))"),
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
                        rev=pinned_rev("LLVMBootstrap_libLLVM_jll", "bb2/GCCBootstrap-$(triplet(platform.host))"),
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
            version=v"2.41.1",
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
    gcc_triplet = toolchain.vendor == :gcc_bootstrap ? gcc_target_triplet(p) : toolchain_jll_triplet(p)

    # Clang toolchains use `llvm-ar`, `llvm-ranlib` and `llvm-nm`, which read the LLVM
    # bitcode that `clang -flto` emits: GNU `ar` and `ranlib` leave bitcode members out of
    # the archive index (which `lld` needs on Windows), and GNU `nm` can't read bitcode at
    # all.  macOS uses `llvm-ar` and `llvm-ranlib` with every vendor.
    use_llvm_tools = get_simple_vendor(toolchain.vendor) == "clang"

    # These tools don't need anything fancy; just `compiler_wrapper()`
    simple_tools = String[]
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
            _warn_nondeterministic_definition(io, "uses the '--insert-timestamp' flag which embeds timestamps")

            # Warn if someone has asked for timestamps
            flagmatch(io, [flag"--insert-timestamp"]) do io
                println(io, "warn_nondeterministic")
            end

            # Default to not using timestamps
            flagmatch(io, [!flag"--insert-timestamp", !flag"--no-insert-timestamp"]) do io
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
        if !isa(toolchain.gcc_version, VersionNumber) || use_llvm_tools
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

        # Stripping a macOS binary invalidates its code signature.  The auditor
        # ad-hoc re-signs every Mach-O binary once the build is finished, so tell
        # `strip` not to warn about it.
        if Sys.isapple(p)
            append_flags(io, :PRE, ["-no_code_signature_warning"])
        end
    end

    function _as_wrapper(io)
        if Sys.isapple(p)
            # Warn if someone has asked for timestamps
            flagmatch(io, [!flag"-arch"]) do io
                # macOS likes to use `arm64`, not `aarch64`:
                arch_str = arch(p) == "aarch64" ? "arm64" : arch(p)
                append_flags(io, :PRE, ["-arch", arch_str])
            end

            # Pin the minimum macOS version to the target's deployment target
            append_flags(io, :PRE, "-mmacosx-version-min=$(macos_version(macos_target_kernel_version(p)))")

            # Tell the `as` executable how to find our clang.  We use a special name here
            # so that our wrapper for this doesn't conflict with an actual clang.
            println(io, "export CCTOOLS_CLANG_AS_EXECUTABLE='$(triplet(gcc_platform(p)))-clang-as'")
        end

        # If `ccache` is allowed, sneak `ccache` in as the first argument to `PROG`
        add_ccache_preamble(io, toolchain)
    end

    # Simple `clang` wrapper for being used as `clang-as`
    function _clang_as_wrapper(io)
        append_flags(io, :PRE, [
            # Set the `target` for `clang` so it generates the right kind of code
            "--target=$(triplet(gcc_platform(p)))",
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

    # `clang -fuse-ld=<name>` looks for a linker called `ld64.<name>` when targeting
    # macOS, and `ld.<name>` everywhere else.  Our clang wrappers pass `-fuse-ld=<triplet>`
    # so that clang links through this wrapper rather than the bare `ld` executable.
    ld_fuse_name = string(Sys.isapple(p) ? "ld64." : "ld.", triplet(gcc_platform(p)))
    compiler_wrapper(_ld_wrapper, joinpath(dir, ld_fuse_name), "$(toolchain_prefix)/bin/$(gcc_triplet)-ld")

    # `as` is a simple tool, except that on macOS it needs an `-arch` specified:
    make_tool_wrappers(toolchain, dir, "as", "$(gcc_triplet)-as"; wrapper=_as_wrapper, toolchain_prefix)

    # Our `as` on macOS subs out to `${triplet}-clang-as`, so we generate that here,
    # which in turn subs out to `clang`.
    if Sys.isapple(p)
        make_tool_wrappers(toolchain, dir, "clang-as", "clang"; wrapper=_clang_as_wrapper, toolchain_prefix)
    end

    # `nm` is a simple tool, except that it can take in `--plugin` for LTO
    nm_name = use_llvm_tools ? "llvm-nm" : "$(gcc_triplet)-nm"
    make_tool_wrappers(toolchain, dir, "nm", nm_name; wrapper=_nm_wrapper, toolchain_prefix)

    # `strip` needs determinism flags, and on macOS the code signature warning silenced
    make_tool_wrappers(toolchain, dir, "strip", "$(gcc_triplet)-strip"; wrapper=_strip_wrapper_pre, toolchain_prefix)

    # c++filt uses `llvm-cxxfilt` on macOS, `c++filt` elsewhere
    cxxfilt_name = Sys.isapple(p) ? "llvm-cxxfilt" : "$(gcc_triplet)-c++filt"
    make_tool_wrappers(toolchain, dir, "c++filt", cxxfilt_name; toolchain_prefix)

    ar_name = (Sys.isapple(p) || use_llvm_tools) ? "llvm-ar" : "$(gcc_triplet)-ar"
    make_tool_wrappers(toolchain, dir, "ar", ar_name; wrapper=_ar_wrapper, toolchain_prefix)

    ranlib_name = (Sys.isapple(p) || use_llvm_tools) ? "llvm-ranlib" : "$(gcc_triplet)-ranlib"
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

function toolchain_sources(toolchain::BinutilsToolchain; build_sandbox_prefix::Union{Nothing,String} = nothing)
    sources = AbstractSource[]

    installing_jll(name) = get_jll(toolchain, name) !== nothing
    push!(sources, CachedGeneratedSource(cache_key(toolchain); target="wrappers") do out_dir
        binutils_wrappers(toolchain, out_dir)
    end)
    append!(sources, toolchain.deps)

    # We only ever use the latest binutils, no version selection
    return sources
end

function toolchain_env(toolchain::BinutilsToolchain, deployed_prefix::String;
                       build_sandbox_prefix::Union{Nothing,String} = nothing)
    env = Dict{String,String}()

    insert_PATH!(env, :PRE, [
        joinpath(deployed_prefix, "wrappers"),
        joinpath(deployed_prefix, get_simple_vendor(toolchain), "bin")
    ])

    function set_envvars!(env, toolchain, key::String, value::String)
        for envvar_prefix in toolchain.env_prefixes
            env["$(envvar_prefix)$(key)"] = value
        end
    end

    wrapper_prefixes = replace.(toolchain.wrapper_prefixes, ("\${triplet}" => triplet(gcc_platform(toolchain.platform.target)),))
    wrapper_prefix = wrapper_prefixes[argmax(length.(wrapper_prefixes))]

    # Binutils mappings
    set_envvars!(env, toolchain, "AR", "$(wrapper_prefix)ar")
    set_envvars!(env, toolchain, "AS", "$(wrapper_prefix)as")
    set_envvars!(env, toolchain, "CXXFILT", "$(wrapper_prefix)c++filt")
    set_envvars!(env, toolchain, "LD", "$(wrapper_prefix)ld")
    set_envvars!(env, toolchain, "NM", "$(wrapper_prefix)nm")
    set_envvars!(env, toolchain, "RANLIB", "$(wrapper_prefix)ranlib")
    set_envvars!(env, toolchain, "OBJCOPY", "$(wrapper_prefix)objcopy")
    set_envvars!(env, toolchain, "OBJDUMP", "$(wrapper_prefix)objdump")
    set_envvars!(env, toolchain, "STRIP", "$(wrapper_prefix)strip")

    if Sys.isapple(toolchain.platform.target)
        set_envvars!(env, toolchain, "DSYMUTIL", "$(wrapper_prefix)dsymutil")
        set_envvars!(env, toolchain, "LIPO", "$(wrapper_prefix)lipo")
    end

    if !Sys.isapple(toolchain.platform.target)
        set_envvars!(env, toolchain, "READELF", "$(wrapper_prefix)readelf")
    end

    if Sys.iswindows(toolchain.platform.target)
        set_envvars!(env, toolchain, "DLLTOOL", "$(wrapper_prefix)dlltool")
        set_envvars!(env, toolchain, "WINDRES", "$(wrapper_prefix)windres")
        set_envvars!(env, toolchain, "WINMC", "$(wrapper_prefix)winmc")
    end

    # platform extensions for this target
    set_envvars!(env, toolchain, "exeext", Sys.iswindows(toolchain.platform.target) ? ".exe" : "")
    set_envvars!(env, toolchain, "dlext", platform_dlext(toolchain.platform.target))

    # OS version variables
    if Sys.isapple(toolchain.platform.target)
        kernel_version = macos_target_kernel_version(toolchain.platform.target)
        set_envvars!(env, toolchain, "MACOSX_DEPLOYMENT_TARGET", macos_version(kernel_version))
    end

    if Sys.isfreebsd(toolchain.platform.target)
        function default_freebsd_sdk_version()
            return v"14.1"
        end
        freebsd_version = something(
            os_version(toolchain.platform.target),
            default_freebsd_sdk_version(),
        )
        set_envvars!(env, toolchain, "FREEBSD_TARGET_SDK", "$(freebsd_version.major).$(freebsd_version.minor)")
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
        Platform("riscv64", "linux"),

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

