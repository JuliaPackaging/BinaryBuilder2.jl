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

    # Cache key that we use to store our generated wrappers
    cache_key::String

    # We internally create a BinutilsToolchain
    binutils_toolchain::BinutilsToolchain

    function CToolchain(platform::CrossPlatform;
                        vendor = :auto,
                        env_prefixes = [""],
                        wrapper_prefixes = ["\${triplet}-", ""],
                        lock_microarchitecture = true,
                        use_ccache = true,
                        gcc_version = VersionSpec("9"),
                        llvm_version = VersionSpec("17"),
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

        valid_cxx_runtimes = (:auto, :libcxx, :libstdcxx)
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
            glibc_version,
            use_ccache,
            compiler_runtime,
            cxx_runtime,
        )

        # Concretize the JLLSource's `PackageSpec`'s version (and UUID) now:
        resolve_versions!(deps; julia_version=nothing)

        gcc_version = nothing
        for name in ("GCC", "GCCBootstrap")
            jll = get_jll(deps, string(name, "_jll"))
            if jll !== nothing
                gcc_version = jll.package.version
                break
            end
        end

        wrapper_prefixes = string.(wrapper_prefixes)
        env_prefixes = string.(env_prefixes)
        binutils_toolchain = BinutilsToolchain(
            platform,
            get_vendor(vendor, platform);
            wrapper_prefixes,
            env_prefixes,
            use_ccache,
            gcc_version,
        )

        cache_key = string(
            triplet(platform),
            lock_microarchitecture ? "true" : "false",
            use_ccache ? "true" : "false",
            compiler_runtime,
            cxx_runtime,
            vendor,
            env_prefixes...,
            wrapper_prefixes...,
            extra_cflags...,
            extra_ldflags...,
        )
        cache_key = string(
            "CToolchain-",
            bytes2hex(sha1(cache_key))
        )

        return new(
            platform,
            vendor,
            deps,
            wrapper_prefixes,
            env_prefixes,
            lock_microarchitecture,
            use_ccache,
            compiler_runtime,
            cxx_runtime,
            linker,
            string.(extra_cflags),
            string.(extra_ldflags),
            cache_key,
            binutils_toolchain,
        )
    end
end

cache_key(toolchain::CToolchain) = toolchain.cache_key
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
get_vendor(toolchain) = get_vendor(toolchain.vendor, toolchain.platform)

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
get_simple_vendor(toolchain) = get_simple_vendor(get_vendor(toolchain))


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
        macos_sdk_jll = JLLSource(
            "macOSSDK_jll",
            platform.target;
            repo=Pkg.Types.GitRepo(
                source="https://github.com/staticfloat/macOSSDK_jll.jl",
                rev="main",
            ),
            version=v"11.1",
            target=sysroot_path,
        )
        if macos_version(platform.target) !== nothing
            if VersionNumber(macos_version(platform.target)) > macos_sdk_jll.package.version
                throw(ArgumentError("We need to upgrade our macOSSDK_jll to support such a new version: $(triplet(platform.target))"))
            end
        end
        libc_jlls = [macos_sdk_jll]
    elseif os(platform.target) == "windows"
        libc_jlls = [JLLSource(
            "Mingw_jll",
            platform.target;
            repo=Pkg.Types.GitRepo(
                rev="main",
                source="https://github.com/staticfloat/Mingw_jll.jl",
            ),
            target=sysroot_path,
        )]
    elseif os(platform.target) == "freebsd"
        freebsd_sdk_jll = JLLSource(
            "FreeBSDSysroot_jll",
            platform.target;
            uuid=Base.UUID("671a10c0-f9bf-59ae-b52a-dff4adda89ae"),
            repo=Pkg.Types.GitRepo(
                source="https://github.com/staticfloat/FreeBSDSysroot_jll.jl",
                rev="main",
            ),
            version=v"14.1",
            target=sysroot_path,
        )
        libc_jlls = [freebsd_sdk_jll]
    else
        error("Unknown libc for $(triplet(platform.target))")
    end

    # Both GCC and Clang can use the GCC support libraries
    gcc_support_libs = [
        JLLSource(
            "GCC_support_libraries_jll",
            platform.target;
            uuid=Base.UUID("465c4c53-7f13-5720-b733-07d6cbd50c3b"),
            repo=Pkg.Types.GitRepo(
                rev="main",
                source="https://github.com/staticfloat/GCC_support_libraries_jll.jl",
            ),
            version=v"14.2.0",
            target=get_simple_vendor(vendor),
        ),
        JLLSource(
            "GCC_crt_objects_jll",
            platform.target;
            uuid=Base.UUID("7bc14925-bf4e-535d-80f2-90698dc22d13"),
            repo=Pkg.Types.GitRepo(
                rev="main",
                source="https://github.com/staticfloat/GCC_crt_objects_jll.jl",
            ),
            version=v"14.2.0",
            target=get_simple_vendor(vendor),
        ),
    ]

    compiler_rt_libs = [
        JLLSource(
            "LLVMCompilerRT_jll",
            platform.target;
            uuid=Base.UUID("4e17d02c-6bf5-513e-be62-445f41c75a11"),
            repo=Pkg.Types.GitRepo(
                rev="main",
                source="https://github.com/staticfloat/LLVMCompilerRT_jll.jl",
            ),
            version=v"17.0.7",
            # TODO: This should be more automatic!
            target="clang/lib/clang/17",
        )
    ]
    libstdcxx_libs = [
        JLLSource(
            "libstdcxx_jll",
            platform.target;
            uuid=Base.UUID("3ba1ab17-c18f-5d2d-9d5a-db37f286de95"),
            repo=Pkg.Types.GitRepo(
                rev="main",
                source="https://github.com/staticfloat/libstdcxx_jll.jl",
            ),
            version=v"14.2.0",
            target=get_simple_vendor(vendor),
        ),
    ]
    libcxx_libs = [
        JLLSource(
            "LLVMLibcxx_jll",
            platform.target;
            uuid=Base.UUID("899a7460-a157-599b-96c7-ccb58ef9beb5"),
            repo=Pkg.Types.GitRepo(
                rev="main",
                source="https://github.com/staticfloat/LLVMLibcxx_jll.jl",
            ),
            version=v"17.0.1",
            target=joinpath(sysroot_path, "usr"),
        ),
        JLLSource(
            "LLVMLibunwind_jll",
            platform.target;
            uuid=Base.UUID("871c935c-5660-55ad-bb68-d1283357316b"),
            repo=Pkg.Types.GitRepo(
                rev="main",
                source="https://github.com/staticfloat/LLVMLibunwind_jll.jl",
            ),
            version=v"17.0.1",
            target=joinpath(sysroot_path, "usr"),
        ),
    ]

    clang_bootstrap_jlls = [
        JLLSource(
            "LLVMBootstrap_Clang_jll",
            platform;
            uuid=Base.UUID("b81fd3a9-9257-59d0-818a-b16b9f1e1eb9"),
            repo=Pkg.Types.GitRepo(
                rev="main",
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
                rev="main",
                source="https://github.com/staticfloat/LLVMBootstrap_libLLVM_jll.jl"
            ),
            version=v"17.0.0",
            target=get_simple_vendor(vendor),
        ),
    ]

    # Same story here, but for `:gcc` on macOS
    clang_jlls = [
        JLLSource(
            "Clang_jll",
            platform;
            repo=Pkg.Types.GitRepo(
                rev="main",
                source="https://github.com/staticfloat/Clang_jll.jl",
            ),
            version=v"17.0.7",
            target=get_simple_vendor(vendor),
        ),
        JLLSource(
            "libLLVM_jll",
            platform;
            repo=Pkg.Types.GitRepo(
                rev="main",
                source="https://github.com/staticfloat/libLLVM_jll.jl",
            ),
            version=v"17.0.7",
            target=get_simple_vendor(vendor),
        ),
    ]

    # If we're asking for a bootstrap toolchain, give just that and nothing else,
    # which is why we `return` from within here.
    if vendor == :gcc_bootstrap
        if Sys.isapple(platform.target)
            append!(deps, [
                JLLSource(
                    "GCCBootstrapMacOS_jll",
                    platform;
                    uuid = Base.UUID("117daf6b-c727-5bed-b063-6a70e57c2a0e"),
                    repo=Pkg.Types.GitRepo(
                        rev="bb2/GCCBootstrap-$(triplet(platform.host))",
                        source="https://github.com/staticfloat/GCCBootstrapMacOS_jll.jl"
                    ),
                    version=v"14.2.0",
                    target="gcc",
                ),
                libc_jlls...,
            ])
        else
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
                version=v"14.2.0",
                target="gcc",
            ))
        end
        return deps
    end

    if os(platform.target) == "linux"
        # Linux builds require the kernel headers for the target platform
        push!(deps, JLLSource(
            "LinuxKernelHeaders_jll",
            platform.target;
            repo=Pkg.Types.GitRepo(
                rev="main",
                source="https://github.com/staticfloat/LinuxKernelHeaders_jll.jl"
            ),
            # LinuxKernelHeaders gets installed into `<prefix>/<triplet>/usr`
            target=joinpath(sysroot_path, "usr")
        ))
    end

    # Always include the libc
    append!(deps, libc_jlls)

    if vendor == :gcc
        # Include GCC
        # These are compilers, so they take in the full cross platform.
        # TODO: Get `GCC_jll.jl` packaged so that I don't
        #       have to pull down a special commit like this!
        append!(deps, [
            JLLSource(
                "GCC_jll",
                platform;
                uuid=Base.UUID("ec15993a-68c6-5861-8652-ef539d7ffb0b"),
                repo=Pkg.Types.GitRepo(
                    rev="main",
                    source="https://github.com/staticfloat/GCC_jll.jl",
                ),
                # eventually, include a resolved version
                # but for now, we're locked to this specific version
                version=v"14.2.0",
                target="gcc",
            ),
            gcc_support_libs...,
            libstdcxx_libs...,
        ])
    elseif vendor == :clang || vendor == :clang_bootstrap
        if vendor == :clang
            append!(deps, [
                clang_jlls...,
            ])
        else
            append!(deps, [
                clang_bootstrap_jlls...,
            ])
        end
        comp_runtime = get_compiler_runtime(compiler_runtime, platform)
        cxx_runtime = get_cxx_runtime(cxx_runtime, platform)

        # libstdc++ depends on libgcc, we don't support the libstdc++ on top of compiler-rt right now.
        if comp_runtime == :libgcc || cxx_runtime == :libstdcxx
            append!(deps, gcc_support_libs)
        end

        if comp_runtime == :compiler_rt
            append!(deps, compiler_rt_libs)
        end
        if cxx_runtime == :libstdcxx
            append!(deps, libstdcxx_libs)
        end
        if cxx_runtime == :libcxx
            # We don't add these on macOS because the SDK actually comes with these libraries available.
            # We still build them for completeness, and in the event that we actually want to use newer
            # libraries, although I'm not sure why we would want that.
            if os(platform.target) != "macos"
                append!(deps, libcxx_libs)
            end
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

function get_jll(deps::Vector{JLLSource}, name::String)
    for jll in deps
        if jll.package.name == name
            return jll
        end
    end
    return nothing
end
get_jll(toolchain, name::String) = get_jll(toolchain.deps, name)

function toolchain_sources(toolchain::CToolchain)
    sources = AbstractSource[]

    installing_jll(name) = get_jll(toolchain, name) !== nothing
    # Create a `GeneratedSource` that, at `prepare()` time, will JIT out
    # our compiler wrappers.  We store it with a cache key that is sensitive
    # to basically all inputs, so that it can be cached.
    push!(sources, CachedGeneratedSource(cache_key(toolchain); target="wrappers") do out_dir
        if installing_jll("GCC_jll") || installing_jll("GCCBootstrap_jll") || installing_jll("GCCBootstrapMacOS_jll")
            gcc_wrappers(toolchain, out_dir)
        end
        if installing_jll("Clang_jll") || installing_jll("LLVMBootstrap_Clang_jll")
            clang_wrappers(toolchain, out_dir)
        end
    end)

    append!(sources, toolchain_sources(toolchain.binutils_toolchain))
    append!(sources, toolchain.deps)
    return sources
end

function toolchain_env(toolchain::CToolchain, deployed_prefix::String)
    env = Dict{String,String}()

    insert_PATH!(env, :PRE, [
        joinpath(deployed_prefix, "wrappers"),
        joinpath(deployed_prefix, get_simple_vendor(toolchain), "bin")
    ])

    function set_envvars(envvar_prefix::String, tool_prefix::String)
        env["$(envvar_prefix)CC"] = "$(tool_prefix)cc"
        env["$(envvar_prefix)CXX"] = "$(tool_prefix)c++"
        env["$(envvar_prefix)CPP"] = "$(tool_prefix)cpp"
        env["$(envvar_prefix)CC_TARGET"] = triplet(gcc_platform(toolchain.platform.target))
    end

    # We can have multiple wrapper prefixes, we always use the longest one
    # as that's typically the most specific.
    wrapper_prefixes = replace.(toolchain.wrapper_prefixes, ("\${triplet}" => triplet(gcc_platform(toolchain.platform.target)),))
    wrapper_prefix = wrapper_prefixes[argmax(length.(wrapper_prefixes))]
    for env_prefix in toolchain.env_prefixes
        set_envvars(env_prefix, wrapper_prefix)
    end

    # Merge in Binutils environment variables
    merge!(env, toolchain_env(toolchain.binutils_toolchain, deployed_prefix))
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
    flagmatch(f, io, [!flag"-x assembler", !flag"-v"])
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
        tool_prefixed = string(replace(wrapper_prefix, "\${triplet}" => triplet(gcc_platform(toolchain.platform.target))), tool)
        compiler_wrapper(wrapper,
            post_func,
            joinpath(output_dir, "$(tool_prefixed)"),
            "$(toolchain_prefix)/bin/$(tool_target)"
        )
    end
end

"""
    add_microarchitectural_flags(io, toolchain)

Insert into your compiler wrapper definition near the top to error out if the user
supplies a `-march` flag when `lock_microarchitecture` has been set to `true`.
If compiling, also inserts a `-march` flag to set the microarchitectural level
the toolchain is locked to.  For more details, see `expand_microarchitectures()`.
"""
function add_microarchitectural_flags(io, toolchain)
    # Fail out noisily if `-march` is set, but we're locking microarchitectures.
    if toolchain.lock_microarchitecture
        # Don't do the `-march` check if we're being invoked with `-integrated-as`
        # which only happens when `as` invokes `clang`, targeting macOS
        flagmatch(io, [!flag"-integrated-as", flag"-march=.*"r]) do io
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

"""
    add_macos_flags(io, toolchain)

This adds flags like `-mmacosx-version-min`, depending on our `os_version`
embedded within a triplet.  If there is no such tag embedded within the
triplet, it is not added.  This method also adds some compiler-flag-based
workarounds for GCC brokenness.
"""
function add_macos_flags(io, toolchain)
    if Sys.isapple(toolchain.platform.target)
        macos_ver = macos_version(toolchain.platform.target)
        if macos_ver === nothing
            @warn("TODO: macOS builds should always denote their `os_version`!",
                  platform=triplet(toolchain.platform.target), maxlog=1)
        end
    
        compile_flagmatch(io) do io
            # Simulate some of the `__OSX_AVAILABLE()` macro usage that is broken in GCC
            if get_simple_vendor(toolchain) == "gcc"
                if something(os_version(toolchain.platform.target), v"14") < v"16"
                    # Disable usage of `clock_gettime()`
                    append_flags(io, :PRE, "-D_DARWIN_FEATURE_CLOCK_GETTIME=0")
                end
            end

            # Always compile for a particular minimum macOS version
            if macos_ver !== nothing
                append_flags(io, :PRE, "-mmacosx-version-min=$(macos_version(toolchain.platform.target))")
            end
        end

        link_flagmatch(io) do io
            # When we use `install_name_tool` to alter dylib IDs and whatnot, we need
            # to have extra space in the MachO headers so we can expand names, if necessary.
            append_flags(io, :POST, "-Wl,-headerpad_max_install_names")

            # Always compile for a particular minimum macOS version
            if macos_ver !== nothing
                append_flags(io, :PRE, "-Wl,-sdk_version,$(macos_version(toolchain.platform.target))")
            end
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
    p = toolchain.platform.target
    toolchain_prefix = "\$(dirname \"\${WRAPPER_DIR}\")/gcc"
    gcc_version = something(toolchain.binutils_toolchain.gcc_version, v"0")

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
            if Sys.iswindows(p)
                append_flags(io, :POST, "-Wl,--no-insert-timestamp")
            end

            @warn("TODO: sanitize_link_flags()", maxlog=1)
        end

        add_ccache_preamble(io, toolchain)
    end

    # gcc, g++
    gcc_triplet = get_vendor(toolchain) == :gcc_bootstrap ? gcc_target_triplet(p) : triplet(gcc_platform(p))
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
    # Purposefully not using `gcc_target_triplet()` because we want the distinction between the two arms
    gcc_triplet = triplet(gcc_platform(p))
    toolchain_prefix = "\$(dirname \"\${WRAPPER_DIR}\")/clang"

    function _clang_wrapper(io; is_clangxx::Bool = false)
        # Calculate the sysroot.  Annoyingly, clang doesn't find mingw with a triplet-specific sysroot,
        # and it doesn't find glibc _without_ a triplet-specific sysroot.
        clang_sysroot = Sys.iswindows(p) ? "$(toolchain_prefix)" : "$(toolchain_prefix)/$(gcc_triplet)"

        # Teach `clang` how to respond to `-print-sysroot`.  This is needed for our CMake scripts.
        flagmatch(io, [flag"-print-sysroot"]) do io
            println(io, "echo \"$(clang_sysroot)\"")
            println(io, "exit 0")
        end

        append_flags(io, :PRE, [
            # Set the `target` for `clang` so it generates the right kind of code
            "--target=$(gcc_triplet)",
            # Set the sysroot so it can find things like glibc, mingw, etc...
            "--sysroot=$(clang_sysroot)",
        ])

        if is_clangxx
            # It's extremely rare, but some packages (such as `libc++` itself) manually set
            # the `--stdlib` flag, so let's let them do their thing.
            flagmatch(io, [!flag"--stdlib=.*"r, !flag"--nostdlib++"]) do io
                append_flags(io, :PRE, [
                    # Set the C++ runtime library, but only in clang++
                    "--stdlib=$(get_cxx_runtime_str(toolchain))",
                ])
            end
        end

        if get_compiler_runtime(toolchain) == :libgcc_s || get_cxx_runtime(toolchain) == :libstdcxx
            append_flags(io, :PRE, [
                # Set the GCC install dir; this is required on some platforms because
                # our triplet isn't default (e.g. `armv7l` instead of `arm`) so clang can't find it.
                "--gcc-install-dir=\$(compgen -G \"$(toolchain_prefix)/lib/gcc/$(gcc_triplet)/*\")",
            ])
        end

        compile_flagmatch(io) do io
            if Sys.iswindows(p) && arch(p) == "i686"
                # Ensure that we're using SJLJ exceptions on 32-bit windows, to match our mingw builds.
                append_flags(io, :PRE, ["-fsjlj-exceptions"])
            end
        end

        link_flagmatch(io) do io
            append_flags(io, :PRE, [
                # Set the runtime library
                "--rtlib=$(get_compiler_runtime_str(toolchain))",
            ])

            # clang doesn't invoke the `ld` wrapper, it invokes the binary directly,
            # so we have to include this here as well.
            if Sys.iswindows(p)
                append_flags(io, :PRE, ["-Wl,--no-insert-timestamp"])
            end
        end

        add_microarchitectural_flags(io, toolchain)
        add_cxxabi_flags(io, toolchain)
        add_user_flags(io, toolchain)
        add_macos_flags(io, toolchain)

        # If `ccache` is allowed, sneak `ccache` in as the first argument to `PROG`
        add_ccache_preamble(io, toolchain)
    end

    if Sys.isapple(p)
        function _xcrun_wrapper(io)
            flagmatch(io, [flag"--show-sdk-path"]) do io
                println(io, raw"""
                "${CC}" -print-sysroot
                exit 0
                """)
            end
            flagmatch(io, [flag"--show-sdk-version"]) do io
                println(io, raw"""
                echo "${MACOSX_DEPLOYMENT_TARGET}"
                exit 0
                """)
            end
        end
        make_tool_wrappers(toolchain, dir, "xcrun", "exec"; wrapper=_xcrun_wrapper, toolchain_prefix)
    end

    make_tool_wrappers(toolchain, dir, "clang", "clang"; wrapper=_clang_wrapper, toolchain_prefix)
    make_tool_wrappers(toolchain, dir, "clang++", "clang++"; wrapper=io -> _clang_wrapper(io; is_clangxx = true), toolchain_prefix)
    make_tool_wrappers(toolchain, dir, "clang-scan-deps", "clang-scan-deps"; toolchain_prefix)
    if get_vendor(toolchain) ∈ (:clang, :clang_bootstrap)
        make_tool_wrappers(toolchain, dir, "cc", "clang"; wrapper=_clang_wrapper, toolchain_prefix)
        make_tool_wrappers(toolchain, dir, "c++", "clang++"; wrapper=io -> _clang_wrapper(io; is_clangxx = true), toolchain_prefix)
    end
end

# Sub off to BinutilsToolchain
supported_platforms(::Type{CToolchain}; experimental::Bool = false) = supported_platforms(BinutilsToolchain; experimental)
