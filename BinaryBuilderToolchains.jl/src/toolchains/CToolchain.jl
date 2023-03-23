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
    default_ctoolchain::Bool

    function CToolchain(platform;
                        vendor = :auto,
                        default_ctoolchain = false,
                        gcc_version = VersionSpec("9"),
                        llvm_version = VersionSpec("*"),
                        binutils_version = v"2.38.0+4",
                        glibc_version = :oldest)
        if vendor ∉ (:auto, :gcc, :clang)
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
                if arch(platform) ∈ ("x86_64", "i686")
                    glibc_version = VersionSpec("2.12.2")
                elseif arch(platform) ∈ ("powerpc64le",)
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
                repo=Pkg.Types.GitRepo(
                    rev="6e04e57d78fe742bcc357e7e7349dbe6e8ae4e2f",
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

        # Concretize the JLLSource's `PackageSpec`'s version now:
        resolve_versions!(deps; julia_version=nothing)

        return new(
            platform,
            vendor,
            deps,
            default_ctoolchain,
        )
    end
end

function Base.show(io::IO, toolchain::CToolchain)
    println(io, "CToolchain ($(gcc_target_triplet(toolchain.platform)) => $(gcc_target_triplet(toolchain.platform)))")
    for dep in toolchain.deps
        println(io, " - $(dep.package.name[1:end-4]) v$(dep.package.version)")
    end
end

function gcc_target_triplet(target::AbstractPlatform)
    tags = Dict{Symbol,String}()
    for tag in ("call_abi", "libc")
        if haskey(target, tag)
            tags[Symbol(tag)] = target[tag]
        end
    end
    return triplet(Platform(arch(target), os(target); tags...))
end
gcc_target_triplet(platform::CrossPlatform) = gcc_target_triplet(platform.target)

function toolchain_sources(toolchain::CToolchain)
    sources = AbstractSource[]

    # Create a `GeneratedSource` that, at `prepare()` time, will JIT out
    # our compiler wrappers!
    push!(sources, GeneratedSource(;target="wrappers") do out_dir
        if any(jll.package.name == "GCC_jll" for jll in toolchain.deps)
            gcc_wrappers(toolchain, out_dir)
        end

        if any(jll.package.name == "Clang_jll" for jll in toolchain.deps)
            clang_wrappers(toolchain, out_dir)
        end
    end)

    # Add the JLLs as well.
    # Note that we eliminate the illegal "version" fields from our PackageSpec
    # objects here, because we occasionally 
    jll_deps = copy(toolchain.deps)
    filter_illegal_versionspecs!([jll.package for jll in jll_deps])
    append!(sources, jll_deps)
    return sources
end

function toolchain_env(toolchain::CToolchain, deployed_prefix::String; base_ENV = ENV)
    PATH = [
        joinpath(deployed_prefix, "wrappers"),
        split(get(base_ENV, "PATH", ""), ":")...,
    ]
    env = Dict{String,String}(
        "PATH" => join(PATH, ":"),
    )
    return env
end




"""
    compile_flagmatch(f, io)

Convenience function for CToolchain wrappers, using `flagmatch()` to match
only when a compiler invocation is performing compilation.  As of this
writing, this only excludes the case where `clang` has been invoked as an
assembler via the `-x assembler` flag.
"""
function compile_flagmatch(f::Function, io::IO)
    flagmatch(f, io, [!flag"-x assembler"])
end

"""
    link_flagmatch(f, io)

Convenience function for CToolchain wrappers, using `flagmatch()` to match
only when a compiler invocation is performing linking.  This excludes the cases
where the compiler has been invoked to preprocess, compile without linking, act
as an assembler, etc...
"""
function link_flagmatch(f::Function, io::IO)
    flagmatch(f, io, [!flag"-c", !flag"-E", !flag"-M", !flag"-fsyntax-only", !flag"-x assembler"])
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
    gcc_version = only(jll.package.version for jll in toolchain.deps if jll.package.name == "GCC_jll")
    p = toolchain.platform.target
    toolchain_prefix = "\$(dirname \"\${WRAPPER_DIR}\")"

    function _gcc_wrapper(tool_name, tool_target)
        compiler_wrapper(joinpath(dir, tool_name), "$(toolchain_prefix)/bin/$(tool_target)") do io
            compile_flagmatch(io) do io
                if Sys.islinux(p) || Sys.isfreebsd(p)
                    # Help GCCBootstrap find its own libraries under
                    # `/opt/${target}/${target}/lib{,64}`.  Note: we need to push them directly in
                    # the wrappers before any additional arguments because we want this path to have
                    # precedence over anything else.  In this way for example we avoid libraries
                    # from `CompilerSupportLibraries_jll` in `${libdir}` are picked up by mistake.
                    libdir = "$(toolchain_prefix)/$(gcc_target_triplet(p))/lib" * (nbits(p) == 32 ? "" : "64")
                    append_flags(io, :PRE, ["-L$(libdir)", "-Wl,-rpath-link,$(libdir)"])
                end
            end
            # Force proper cxx11 string ABI usage, if it is set at all
            if cxxstring_abi(p) == "cxx11"
                append_flags(io, :PRE, "-D_GLIBCXX_USE_CXX11_ABI=1")
            elseif cxxstring_abi(p) == "cxx03"
                append_flags(io, :PRE, "-D_GLIBCXX_USE_CXX11_ABI=0")
            end

            if Sys.isapple(p)
                if os_version(p) === nothing
                    @warn("TODO: macOS builds should always denote their `os_version`!", platform=triplet(p))
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
            flagmatch(io, [!flag"-frandom-seed*"]) do io
                append_flags(io, :PRE, "-frandom-seed=0x\${ARGS_HASH}")
            end
        end
    end

    # Generate target-specific wrappers always:
    _gcc_wrapper("$(gcc_target_triplet(p))-gcc$(exeext(p))", "$(gcc_target_triplet(p))-gcc$(exeext(p))")
    _gcc_wrapper("$(gcc_target_triplet(p))-g++$(exeext(p))", "$(gcc_target_triplet(p))-g++$(exeext(p))")

    # Generate generalized wrapper if we're the default toolchain (woop woop) (and more if
    # the C toolchain "vendor" is GCC!)
    if toolchain.default_ctoolchain
        _gcc_wrapper("gcc$(exeext(p))", "$(gcc_target_triplet(p))-gcc$(exeext(p))")
        _gcc_wrapper("g++$(exeext(p))", "$(gcc_target_triplet(p))-g++$(exeext(p))")

        if toolchain.vendor == :gcc
            _gcc_wrapper("cc$(exeext(p))",  "$(gcc_target_triplet(p))-gcc$(exeext(p))")
            _gcc_wrapper("c++$(exeext(p))", "$(gcc_target_triplet(p))-g++$(exeext(p))")
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

    _clang_wrapper("clang-$(gcc_target_triplet(p))", "clang-$(gcc_target_triplet(p))")
    _clang_wrapper("clang++-$(gcc_target_triplet(p))", "clang++-$(gcc_target_triplet(p))")

    # Generate generalized wrapper if we're the default toolchain (woop woop) (and more if
    # the C toolchain "vendor" is clang!)
    if toolchain.default_ctoolchain
        _clang_wrapper("clang", "clang-$(gcc_target_triplet(p))")
        _clang_wrapper("clang++", "clang++-$(gcc_target_triplet(p))")

        if toolchain.vendor == :clang
            _clang_wrapper("cc", "clang-$(gcc_target_triplet(p))")
            _clang_wrapper("c++", "clang++-$(gcc_target_triplet(p))")
        end
    end
end
