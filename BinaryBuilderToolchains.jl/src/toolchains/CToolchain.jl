export CToolchain
using Pkg, SHA
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

    # If this is set to true (which is the default) we allow `ccache` to accelerate
    # our compilation and linking with `gcc` and `clang`.
    use_ccache::Bool

    # Clang options, we can use different runtime libs (:libgcc, :compiler_rt),
    # different c++ runtimes (:libstdcxx, :libcxx), and different linkers (:ld, :lld)
    compiler_runtime::Symbol
    cxx_runtime::Symbol
    linker::Symbol

    # Extra compiler and linker flags that should be inserted.
    # We typically use these to add `-L/workspace/destdir/${target}`
    # in BinaryBuilder.
    extra_cflags::Vector{String}
    extra_ldflags::Vector{String}

    function CToolchain(platform::CrossPlatform;
                        vendor = :auto,
                        env_prefixes = [""],
                        wrapper_prefixes = ["\${triplet}-", ""],
                        lock_microarchitecture = true,
                        use_ccache = true,
                        gcc_version = VersionSpec("9"),
                        llvm_version = VersionSpec("*"),
                        binutils_version = v"2.38.0+4",
                        glibc_version = :oldest,
                        compiler_runtime = :auto,
                        cxx_runtime = :auto,
                        linker = :auto,
                        extra_cflags = String[],
                        extra_ldflags = String[])
        function _check_valid(val, valid_set, name)
            if val ∉ valid_set
                throw(ArgumentError("Invalid value '$(val)' for `$(name)`, must be one of $(valid_set)"))
            end
        end
        valid_vendors = (:auto, :gcc, :clang, :bootstrap, :gcc_bootstrap, :clang_bootstrap)
        _check_valid(vendor, valid_vendors, "vendor")

        valid_cxx_runtimes = (:auto, :libcxx, :libstdxx)
        _check_valid(cxx_runtime, valid_cxx_runtimes, "cxx_runtime")

        valid_compiler_runtimes = (:auto, :libgcc, :compiler_rt)
        _check_valid(compiler_runtime, valid_compiler_runtimes, "compiler_runtime")

        if get_vendor(vendor, platform) ∈ (:gcc, :gcc_bootstrap)
            if cxx_runtime == :libcxx
                throw(ArgumentError("GCC cannot use libcxx, must use libstdc++!"))
            end
            if compiler_runtime == :compiler_rt
                throw(ArgumentError("GCC cannot use compiler_rt, must use libgcc!"))
            end
        end

        if isempty(wrapper_prefixes)
            throw(ArgumentError("Cannot have empty wrapper prefixes!  Did you mean [\"\"]?"))
        end
        if isempty(env_prefixes)
            throw(ArgumentError("Cannot have empty env prefixes!  Did you mean [\"\"]?"))
        end

        if os(platform.target) == "linux" && isa(glibc_version, Symbol)
            # If the user asks for the oldest version of glibc, figure out what platform we're
            # building for, and use an appropriate version.
            if glibc_version == :oldest
                # TODO: Should glibc_version be embedded within the triplet somehow?
                #       Non-default glibc version is kind of a compatibility issue....
                @warn("TODO: Should glibc_version be embedded within the triplet?", maxlog=1)
                if arch(platform.target) ∈ ("x86_64", "i686", "powerpc64le",)
                    glibc_version = v"2.17"
                elseif arch(platform.target) ∈ ("armv6l", "armv7l", "aarch64")
                    glibc_version = v"2.19"
                else
                    throw(ArgumentError("Unknown oldest glibc version for architecture '$(platform.target)'!"))
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
            use_ccache,
            compiler_runtime,
            cxx_runtime,
        )

        # Concretize the JLLSource's `PackageSpec`'s version (and UUID) now:
        resolve_versions!(deps; julia_version=nothing)

        return new(
            platform,
            vendor,
            deps,
            string.(wrapper_prefixes),
            string.(env_prefixes),
            lock_microarchitecture,
            use_ccache,
            compiler_runtime,
            cxx_runtime,
            linker,
            string.(extra_cflags),
            string.(extra_ldflags),
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

# This one only returns `gcc` or `clang`, no `bootstrap` distinction.
function get_simple_vendor(vendor::Symbol)
    if vendor == :clang_bootstrap
        return "clang"
    elseif vendor == :gcc_bootstrap
        return "gcc"
    else
        return string(vendor)
    end
end
get_simple_vendor(toolchain::CToolchain) = get_simple_vendor(get_vendor(toolchain))


function auto_chooser(criteria, val, platform, choices)
    if val == :auto
        if criteria(platform)
            return choices[1]
        else
            return choices[2]
        end
    end
    return val
end

function get_compiler_runtime(runtime::Symbol, platform::AbstractPlatform)
    compiler_rt_default(p) = os(target_if_crossplatform(p)) ∈ ("macos", "freebsd")
    return auto_chooser(compiler_rt_default, runtime, platform, (:compiler_rt, :libgcc))
end
get_compiler_runtime(ct::CToolchain) = get_compiler_runtime(ct.compiler_runtime, ct.platform)
function get_compiler_runtime_str(x)
    compiler_runtime = get_compiler_runtime(x)
    if compiler_runtime == :compiler_rt
        return "compiler-rt"
    elseif compiler_runtime == :libgcc
        return "libgcc"
    else
        throw(ArgumentError("Unknown compiler runtime '$(compiler_runtime)'"))
    end
end


function get_cxx_runtime(runtime::Symbol, platform::AbstractPlatform)
    libcxx_default(p) = os(target_if_crossplatform(p)) ∈ ("macos", "freebsd")
    return auto_chooser(libcxx_default, runtime, platform, (:libcxx, :libstdcxx))
end
get_cxx_runtime(ct::CToolchain) = get_cxx_runtime(ct.cxx_runtime, ct.platform)
function get_cxx_runtime_str(args...)
    cxx_runtime = string(get_cxx_runtime(args...))
    return replace(cxx_runtime, r"xx$" => "++")
end


function get_linker(linker::Symbol, platform::AbstractPlatform)
    lld_default(p) = os(target_if_crossplatform(p)) ∈ ("macos", "freebsd")
    return auto_chooser(lld_default, linker, platform, (:lld, :ld))
end
get_linker(ct::CToolchain) = get_linker(ct.linker, ct.platform)


function jll_source_selection(vendor::Symbol, platform::CrossPlatform,
                              gcc_version,
                              llvm_version,
                              binutils_version,
                              glibc_version,
                              use_ccache,
                              compiler_runtime,
                              cxx_runtime)
    # Collect our JLLSource objects for all of our compiler pieces:
    deps = JLLSource[]
    sysroot_path = joinpath(get_simple_vendor(vendor), triplet(gcc_platform(platform.target)))

    if libc(platform.target) == "glibc"
        # Manual version selection, drop this once these are registered!
        if v"2.17" == glibc_version
            glibc_repo = Pkg.Types.GitRepo(
                rev="2f33ece6d34f813332ff277ffaea52b075f1af67",
                source="https://github.com/staticfloat/Glibc_jll.jl"
            )
        elseif v"2.19" == glibc_version
            glibc_repo = Pkg.Types.GitRepo(
                rev="a3d1c4ed6e676a47c4659aeecc8f396a2233757d",
                source="https://github.com/staticfloat/Glibc_jll.jl"
            )
        else
            error("Don't know how to install Glibc $(glibc_version)")
        end

        libc_jlls = [JLLSource(
            "Glibc_jll",
            platform.target;
            uuid=Base.UUID("452aa2e7-e185-58db-8ff9-d3c1fa4bc997"),
            # TODO: Should we encode this in the platform object somehow?
            version=glibc_version,
            repo=glibc_repo,
            # This glibc is the one that gets embedded within GCC and it's for the target
            target=sysroot_path,
        )]
    elseif libc(platform.target) == "musl"
        libc_jlls = [JLLSource(
            "Musl_jll",
            platform.target;
            repo=Pkg.Types.GitRepo(
                rev="827bfab690e1cab77b4d48e1a250c8acd3547443",
                source="https://github.com/staticfloat/Musl_jll.jl"
            ),
            target=sysroot_path,
        )]
    elseif os(platform.target) == "macos"
        @warn("Take in `macos_version(platform.target)` and feed that to `macOSSDK_jll.jl` here", maxlog=1)
        libc_jlls = [JLLSource(
            "macOSSDK_jll",
            platform.target;
            repo=Pkg.Types.GitRepo(
                source="https://github.com/staticfloat/macOSSDK_jll.jl",
                rev="main",
            ),
            version=v"11.1",
            target=sysroot_path,
        )]
    elseif os(platform.target) == "windows"
        libc_jlls = [JLLSource(
            "Mingw_jll",
            platform.target;
            repo=Pkg.Types.GitRepo(
                rev="bb2/GCCBootstrap",
                source="https://github.com/staticfloat/Mingw_jll.jl",
            ),
            target=sysroot_path,
        )]
    else
        error("Unknown libc for $(triplet(platform.target))")
    end

    if os(platform.target) == "macos"
        binutils_jlls = [
            JLLSource(
                "CCTools_jll",
                platform;
                uuid=Base.UUID("1e42d1a4-ec21-5f39-ae07-c1fb720fbc4b"),
                repo=Pkg.Types.GitRepo(
                    rev="bb2/ClangBootstrap",
                    source="https://github.com/staticfloat/CCTools_jll.jl",
                ),
                # eventually, include a resolved version
                version=v"986.0.0",
                target=get_simple_vendor(vendor),
            ),
            JLLSource(
                "libtapi_jll",
                platform.host;
                uuid=Base.UUID("defda0c2-6d1f-5f19-8ead-78afca958a10"),
                repo=Pkg.Types.GitRepo(
                    rev="bb2/ClangBootstrap",
                    source="https://github.com/staticfloat/libtapi_jll.jl",
                ),
                # eventually, include a resolved version
                version=v"1300.6.0",
                target=get_simple_vendor(vendor),
            ),
            JLLSource("ldid_jll", platform.host),
        ]
    else
        binutils_jlls = [JLLSource(
            "Binutils_jll",
            platform;
            repo=Pkg.Types.GitRepo(
                #rev="bb2/GCC",
                rev="36a3c2374c0e546ae3bc9223e3de6cb4b0d55371",
                source="https://github.com/staticfloat/Binutils_jll.jl",
            ),
            # eventually, include a resolved version
            version=v"2.41.0",
            target=get_simple_vendor(vendor),
        )]
    end

    # Both GCC and Clang can use the GCC support libraries
    gcc_support_libs = [
        JLLSource(
            "GCC_support_libraries_jll",
            platform.target;
            uuid=Base.UUID("465c4c53-7f13-5720-b733-07d6cbd50c3b"),
            repo=Pkg.Types.GitRepo(
                rev="bb2/GCC",
                source="https://github.com/staticfloat/GCC_support_libraries_jll.jl",
            ),
            version=v"9.4.0",
            target=get_simple_vendor(vendor),
        ),
        JLLSource(
            "GCC_crt_objects_jll",
            platform.target;
            uuid=Base.UUID("7bc14925-bf4e-535d-80f2-90698dc22d13"),
            repo=Pkg.Types.GitRepo(
                rev="bb2/GCC",
                source="https://github.com/staticfloat/GCC_crt_objects_jll.jl",
            ),
            version=v"9.4.0",
            target=get_simple_vendor(vendor),
        ),
    ]
    libstdcxx_libs = [
        JLLSource(
            "libstdcxx_jll",
            platform.target;
            uuid=Base.UUID("3ba1ab17-c18f-5d2d-9d5a-db37f286de95"),
            repo=Pkg.Types.GitRepo(
                rev="bb2/GCC",
                source="https://github.com/staticfloat/libstdcxx_jll.jl",
            ),
            version=v"9.4.0",
            target=get_simple_vendor(vendor),
        ),
    ]
    

    # If we're asking for a bootstrap toolchain, give just that and nothing else,
    # which is why we `return` from within here.
    if vendor == :gcc_bootstrap
        push!(deps, JLLSource(
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
            target="gcc",
        ))
        return deps
    end

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
            target=joinpath(sysroot_path, "usr")
        ))
    end

    # Always include the libc
    append!(deps, libc_jlls)

    if vendor == :gcc
        # Include GCC as well as Binutils
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
                    source="https://github.com/staticfloat/GCC_jll.jl",
                ),
                # eventually, include a resolved version
                # but for now, we're locked to this specific version
                version=v"9.4.0",
                target="gcc",
            ),
            gcc_support_libs...,
            libstdcxx_libs...,
            binutils_jlls...,
        ])
    elseif vendor == :clang || vendor == :clang_bootstrap
        if vendor == :clang
            append!(deps, [
                JLLSource(
                    "Clang_jll",
                    platform;
                    repo=Pkg.Types.GitRepo(
                        rev="bb2/GCC",
                        source="https://github.com/staticfloat/Clang_jll.jl",
                    ),
                    version=v"17.0.7",
                    target="clang",
                ),
                binutils_jlls...,
            ])
        else
            append!(deps, [
                JLLSource(
                    "LLVMBootstrap_Clang_jll",
                    platform;
                    uuid=Base.UUID("b81fd3a9-9257-59d0-818a-b16b9f1e1eb9"),
                    repo=Pkg.Types.GitRepo(
                        rev="bb2/ClangBootstrap",
                        source="https://github.com/staticfloat/LLVMBootstrap_Clang_jll.jl"
                    ),
                    version=v"17.0.0",
                    target="clang",
                ),
                JLLSource(
                    "LLVMBootstrap_libLLVM_jll",
                    platform;
                    uuid=Base.UUID("de72bca2-3cdf-50cb-9084-6e985cd8d9f3"),
                    repo=Pkg.Types.GitRepo(
                        rev="bb2/ClangBootstrap",
                        source="https://github.com/staticfloat/LLVMBootstrap_libLLVM_jll.jl"
                    ),
                    version=v"17.0.0",
                    target="clang",
                ),
                binutils_jlls...,
            ])
        end
        if get_compiler_runtime(compiler_runtime, platform) == :libgcc
            append!(deps, gcc_support_libs)
        end
        if get_cxx_runtime(cxx_runtime, platform) == :libstdcxx
            append!(deps, libstdcxx_libs)
        end
    else
        throw(ArgumentError("Invalid vendor '$(vendor)'!"))
    end

    return deps
end

function Base.show(io::IO, toolchain::CToolchain)
    println(io, "CToolchain ($(toolchain.platform))")
    for dep in toolchain.deps
        println(io, " - $(dep.package.name[1:end-4]) v$(dep.package.version)")
    end
end

function get_jll(toolchain::CToolchain, name::String)
    for jll in toolchain.deps
        if jll.package.name == name
            return jll
        end
    end
    return nothing
end

function toolchain_sources(toolchain::CToolchain)
    sources = AbstractSource[]

    installing_jll(name) = get_jll(toolchain, name) !== nothing
    # Create a `GeneratedSource` that, at `prepare()` time, will JIT out
    # our compiler wrappers!
    push!(sources, GeneratedSource(;target="wrappers") do out_dir
        if installing_jll("GCC_jll") || installing_jll("GCCBootstrap_jll")
            gcc_wrappers(toolchain, out_dir)
        end
        if installing_jll("Clang_jll") || installing_jll("LLVMBootstrap_Clang_jll")
            clang_wrappers(toolchain, out_dir)
        end
        if installing_jll("Binutils_jll") || installing_jll("CCTools_jll") || installing_jll("GCCBootstrap_jll")
            binutils_wrappers(toolchain, out_dir)
        end
    end)

    @warn("TODO: Generate xcrun shim", maxlog=1)

    # Note that we eliminate the illegal "version" fields from our PackageSpec
    jll_deps = copy(toolchain.deps)
    #@warn("TODO: do I need to filter these out here?", maxlog=1)
    #filter_illegal_versionspecs!([jll.package for jll in jll_deps])
    append!(sources, jll_deps)
    return sources
end

function toolchain_env(toolchain::CToolchain, deployed_prefix::String)
    env = Dict{String,String}()

    if get_vendor(toolchain) ∈ (:gcc, :gcc_bootstrap)
        insert_PATH!(env, :PRE, [
            joinpath(deployed_prefix, "gcc", "bin"),
        ])
    end

    if get_vendor(toolchain) ∈ (:clang, :clang_bootstrap)
        insert_PATH!(env, :PRE, [
            joinpath(deployed_prefix, "clang", "bin"),
        ])
    end

    insert_PATH!(env, :PRE, [
        joinpath(deployed_prefix, "wrappers"),
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

    sdk_jll = get_jll(toolchain, "macOSSDK_jll")
    if sdk_jll !== nothing
        env["MACOSX_DEPLOYMENT_TARGET"] = string(
            sdk_jll.package.version.major,
            ".",
            sdk_jll.package.version.minor,
        )
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


# Helper function to make many tool wrappers at once
# `tool` is the name that we export, (which will be prefixed by
# our target triplet) e.g. `ar`.  `tool_target` is the name of
# the wrapped executable (e.g. `llvm-ar`).
function make_tool_wrappers(toolchain, output_dir, tool, tool_target;
                            wrapper::Function = identity,
                            post_func::Function = identity,
                            toolchain_prefix::String = "\$(dirname \"\${WRAPPER_DIR}\")")
    for wrapper_prefix in toolchain.wrapper_prefixes
        tool_prefixed = string(replace(wrapper_prefix, "\${triplet}" => triplet(toolchain.platform.target)), tool)
        compiler_wrapper(wrapper,
            post_func,
            joinpath(output_dir, "$(tool_prefixed)"),
            "$(toolchain_prefix)/bin/$(tool_target)"
        )
    end
end

"""
    march_check(io, toolchain)

Insert into your compiler wrapper definition near the top to error out if the user
supplies a `-march` flag when `lock_microarchitecture` has been set to `true`.
If compiling, also inserts a `-march` flag to set the microarchitectural level
the toolchain is locked to.  For more details, see `expand_microarchitectures()`.
"""
function add_microarchitectural_flags(io, toolchain)
    # Fail out noisily if `-march` is set, but we're locking microarchitectures.
    if toolchain.lock_microarchitecture
        flagmatch(io, [flag"-march=.*"r]) do io
            println(io, """
            echo "BinaryBuilder: Cannot force an architecture via -march (check lock_microarchitecture setting)" >&2
            exit 1
            """)
        end

        # Also insert `-march=foo` where `foo` is defined by the microarchitectural level of `p`.
        compile_flagmatch(io) do io
            march_flags = get_march_flags(
                arch(toolchain.platform.target),
                march(toolchain.platform.target),
                get_simple_vendor(toolchain),
            )
            append_flags(io, :PRE, march_flags)
        end
    end
end

"""
    add_cxxabi_flags(io, toolchain)

Insert into your compiler wrapper definition so that when using `libstdc++` as the
backing C++ runtime, the correct cxx11 string ABI is used.  This will forcibly
insert `-D_GLIBCXX_USE_CXX11_ABI=[1|0]` arguments to the compiler.  For more
details, see `expand_cxxstring_abis()`.
"""
function add_cxxabi_flags(io, toolchain)
    if get_cxx_runtime(toolchain) == :libstdcxx
        compile_flagmatch(io) do io
            # Force proper cxx11 string ABI usage, if it is set at all
            if cxxstring_abi(toolchain.platform.target) == "cxx11"
                append_flags(io, :PRE, "-D_GLIBCXX_USE_CXX11_ABI=1")
            elseif cxxstring_abi(toolchain.platform.target) == "cxx03"
                append_flags(io, :PRE, "-D_GLIBCXX_USE_CXX11_ABI=0")
            end
        end
    end
end

"""
    add_user_flags(io, toolchain)

The user can insert "extra" CFLAGS and LDFLAGS that they want our CToolchain
to use; this adds them to the relevant PRE and POST flag lists.
"""
function add_user_flags(io, toolchain)
    compile_flagmatch(io) do io
        # Add any extra CFLAGS the user has requested of us
        append_flags(io, :PRE, toolchain.extra_cflags)
    end
    link_flagmatch(io) do io
        # Add any extra linker flags that the user has requested of us
        append_flags(io, :POST, toolchain.extra_ldflags)
    end
end

function add_macos_flags(io, toolchain)
    if Sys.isapple(toolchain.platform.target)
        if os_version(toolchain.platform.target) === nothing
            @warn("TODO: macOS builds should always denote their `os_version`!", platform=triplet(toolchain.platform.target), maxlog=1)
        end
    
        compile_flagmatch(io) do io
            # Simulate some of the `__OSX_AVAILABLE()` macro usage that is broken in GCC
            if get_simple_vendor(toolchain) == "gcc"
                if something(os_version(toolchain.platform.target), v"14") < v"16"
                    # Disable usage of `clock_gettime()`
                    append_flags(io, :PRE, "-D_DARWIN_FEATURE_CLOCK_GETTIME=0")
                end
            end
            
            # Always compile for a particular minimum macOS verison
            #append_flags(io, :PRE, "-mmacosx-version-min=$(macos_version(toolchain.platform.target))")
        end

        link_flagmatch(io) do io
            # When we use `install_name_tool` to alter dylib IDs and whatnot, we need
            # to have extra space in the MachO headers so we can expand names, if necessary.
            append_flags(io, :POST, "-Wl,-headerpad_max_install_names")
            #append_flags(io, :PRE, "-Wl,-sdk_version,$(macos_version(toolchain.platform.target))")
        end
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
    gcc_version = v"0.0.0"
    for name in ("GCC", "GCCBootstrap")
        jll = get_jll(toolchain, string(name, "_jll"))
        if jll !== nothing
            gcc_version = jll.package.version
            break
        end
    end

    # Build hash of compiler JLLs that we will feed to `ccache` to identify our
    # specific compiler set:
    compiler_treehash = ""
    for jll_name in ("GCCBootstrap", "GCC", "GCC_support_libraries", "GCC_crt_objects", "Binutils")
        jll = get_jll(toolchain, string(jll_name, "_jll"))
        if jll !== nothing
            compiler_treehash = string(compiler_treehash, jll.package.tree_hash)
        end
    end
    compiler_treehash = bytes2hex(sha256(compiler_treehash))

    p = toolchain.platform.target
    toolchain_prefix = "\$(dirname \"\${WRAPPER_DIR}\")/gcc"

    function _gcc_wrapper(io)
        add_microarchitectural_flags(io, toolchain)
        add_cxxabi_flags(io, toolchain)
        add_user_flags(io, toolchain)
        add_macos_flags(io, toolchain)

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

            # Add on `-fsanitize-memory` if our platform has a santization tag applied
            @warn("TODO: add sanitize compile flags!", maxlog=1)
            #sanitize_compile_flags!(p, flags)
        end

        if Sys.isapple(p)
            # Older GCC versions need the syslibroot specified directly
            if gcc_version.major in (4, 5)
                push!(flags, "-Wl,-syslibroot,$(toolchain_prefix)/$(gcc_target_triplet(p))")
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

            # Do not embed timestamps, for reproducibility:
            # https://github.com/JuliaPackaging/BinaryBuilder.jl/issues/1232
            if Sys.iswindows(p) && gcc_version ≥ v"5"
                append_flags(io, :POST, "-Wl,--no-insert-timestamp")
            end

            @warn("TODO: sanitize_link_flags()", maxlog=1)
        end

        # If `ccache` is allowed, sneak `ccache` in as the first argument to `PROG`
        if toolchain.use_ccache
            println(io, """
            # If `ccache` is available, use it!
            if which ccache >/dev/null; then
                PROG=( ccache "compiler_check=string:$(compiler_treehash)" "\${PROG[@]}" )
            fi
            """)
        end
    end

    # gcc, g++
    gcc_triplet = toolchain.vendor == :bootstrap ? gcc_target_triplet(p) : triplet(gcc_platform(p))
    make_tool_wrappers(toolchain, dir, "gcc", "$(gcc_triplet)-gcc"; wrapper=_gcc_wrapper, toolchain_prefix)
    make_tool_wrappers(toolchain, dir, "g++", "$(gcc_triplet)-g++"; wrapper=_gcc_wrapper, toolchain_prefix)

    if get_vendor(toolchain) ∈ (:gcc, :gcc_bootstrap)
        make_tool_wrappers(toolchain, dir, "cc", "$(gcc_triplet)-gcc"; wrapper=_gcc_wrapper, toolchain_prefix)
        make_tool_wrappers(toolchain, dir, "c++", "$(gcc_triplet)-g++"; wrapper=_gcc_wrapper, toolchain_prefix)
        make_tool_wrappers(toolchain, dir, "cpp", "$(gcc_triplet)-cpp"; wrapper=_gcc_wrapper, toolchain_prefix)
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
    gcc_triplet = gcc_target_triplet(p)
    toolchain_prefix = "\$(dirname \"\${WRAPPER_DIR}\")/clang"

    function _clang_wrapper(io; is_clangxx::Bool = false)
        # Teach `clang` how to respond to `-print-sysroot`.  This is needed for our CMake scripts.
        flagmatch(io, [flag"-print-sysroot"]) do io
            println(io, "echo \"$(toolchain_prefix)/$(gcc_triplet)\"")
            println(io, "exit 0")
        end

        append_flags(io, :PRE, [
            # Set the `target` for `clang` so it generates the right kind of code
            "--target=$(gcc_triplet)",
            # Set the sysroot
            "--sysroot=$(toolchain_prefix)/$(gcc_triplet)",
        ])

        link_flagmatch(io) do io
            append_flags(io, :PRE, [
                # Set the runtime library
                "--rtlib=$(get_compiler_runtime_str(toolchain))",
            ])
        end

        if is_clangxx
            append_flags(io, :PRE, [
                # Set the C++ runtime library, but only in clang++
                "--stdlib=$(get_cxx_runtime_str(toolchain))",
            ])
        end

        add_microarchitectural_flags(io, toolchain)
        add_cxxabi_flags(io, toolchain)
        add_user_flags(io, toolchain)
        add_macos_flags(io, toolchain)

        if Sys.isapple(p)
            if os_version(p) === nothing
                @warn("TODO: macOS builds should always denote their `os_version`!", platform=triplet(p), maxlog=1)
            end
        end
    end

    make_tool_wrappers(toolchain, dir, "clang", "clang"; wrapper=_clang_wrapper, toolchain_prefix)
    make_tool_wrappers(toolchain, dir, "clang++", "clang++"; wrapper=io -> _clang_wrapper(io; is_clangxx = true), toolchain_prefix)
    if get_vendor(toolchain) ∈ (:clang, :clang_bootstrap)
        make_tool_wrappers(toolchain, dir, "cc", "clang"; wrapper=_clang_wrapper, toolchain_prefix)
        make_tool_wrappers(toolchain, dir, "c++", "clang++"; wrapper=io -> _clang_wrapper(io; is_clangxx = true), toolchain_prefix)
    end
end


function binutils_wrappers(toolchain::CToolchain, dir::String)
    p = toolchain.platform.target
    toolchain_prefix = "\$(dirname \"\${WRAPPER_DIR}\")/$(get_simple_vendor(toolchain))"

    # Most tools don't need anything fancy; just `compiler_wrapper()`
    simple_tools = [
        "as",
        "nm",
        "objcopy",
        "objdump",
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

    function _ld_wrapper(io)
        # If `ccache` is allowed, sneak `ccache` in as the first argument to `PROG`
        if toolchain.use_ccache
            println(io, """
            # If `ccache` is available, use it!
            if which ccache >/dev/null; then
                PROG=( ccache "\${PROG[@]}" )
            fi
            """)
        end
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

    function _strip_wrapper_pre(io)
        # On non-apple platforms, we don't need to do anything
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

    # For all simple tools, create the target-specific name, and the basename if we're the default toolchain
    gcc_triplet = toolchain.vendor == :bootstrap ? gcc_target_triplet(p) : triplet(gcc_platform(p))
    for tool in simple_tools
        make_tool_wrappers(toolchain, dir, tool, "$(gcc_triplet)-$(tool)"; toolchain_prefix)
    end

    # `ld` is a simple tool, except that it can be wrapped with `ccache`:
    make_tool_wrappers(toolchain, dir, "ld", "$(gcc_triplet)-ld"; wrapper=_ld_wrapper, toolchain_prefix)

    # `strip` needs complicated option parsing if we're on macOS
    make_tool_wrappers(toolchain, dir, "strip", "$(gcc_triplet)-strip"; wrapper=_strip_wrapper_pre, post_func=_strip_wrapper_post, toolchain_prefix)

    # c++filt uses `llvm-cxxfilt` on macOS, `c++filt` elsewhere
    cxxfilt_name = Sys.isapple(p) ? "llvm-cxxfilt" : "$(gcc_triplet)-c++filt"
    make_tool_wrappers(toolchain, dir, "c++filt", cxxfilt_name; toolchain_prefix)

    ar_name = Sys.isapple(p) ? "llvm-ar" : "$(gcc_triplet)-ar"
    make_tool_wrappers(toolchain, dir, "ar", ar_name; wrapper=_ar_wrapper, toolchain_prefix)

    ranlib_name = Sys.isapple(p) ? "llvm-ranlib" : "$(gcc_triplet)-ranlib"
    make_tool_wrappers(toolchain, dir, "ranlib", ranlib_name; wrapper=_ranlib_wrapper, toolchain_prefix)

    # dlltool needs some determinism fixes as well
    if Sys.iswindows(p)
        function _dlltool_wrapper(io)
            append_flags(io, :PRE, ["--temp-prefix", "/tmp/dlltool-\${ARGS_HASH}"])
        end
        make_tool_wrappers(toolchain, dir, "dlltool", "$(gcc_triplet)-dlltool"; wrapper=_dlltool_wrapper, toolchain_prefix)
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

        Platform("x86_64", "linux"; libc="musl"),
        Platform("i686", "linux"; libc="musl"),
        Platform("aarch64", "linux"; libc="musl"),
        Platform("armv6l", "linux"; libc="musl"),
        Platform("armv7l", "linux"; libc="musl"),

        Platform("x86_64", "windows"),
        Platform("i686", "windows"),
    ]
end
