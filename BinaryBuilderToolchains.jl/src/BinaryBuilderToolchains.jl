module BinaryBuilderToolchains
using Base.BinaryPlatforms, BinaryBuilderSources, Reexport
using PrecompileTools: @setup_workload, @compile_workload
using Pkg.Types: VersionSpec

# These are so useful to anyone who's using us, just reexport them.
@reexport using BinaryBuilderPlatformExtensions

export AbstractToolchain, toolchain_sources, toolchain_env, platform, supported_platforms

"""
    AbstractToolchain

An `AbstractToolchain` represents a set of JLLs that should be downloaded to
provide some kind of build capability; an example of which is the C toolchain
which is used in almost every recipe, but fortran, go, rust, etc.. are all
other toolchains which can be included in the build environment.

All toolchains must define the following methods:

* Constructor
    - used to configure tool versions, etc...
* toolchain_sources(toolchain; build_sandbox_prefix = nothing)
    - returns a vector of `AbstractSource`'s representing the dependencies
      needed to run this toolchain, relative to some installation prefix
* toolchain_env(toolchain, deployed_prefix::String; build_sandbox_prefix = nothing)
    - returns a dictionary listing the environment variables to be added
      in to commands that use this toolchain.
* platform(toolchain)
    - returns the platform this toolchain was constructed for.  Could be
      a `CrossPlatform` (in the case of CToolchain) or a plain `Platform`
      (in the case of HostToolsToolchain).
* supported_platforms(::Type{toolchain})
    - returns a list of platforms (with no tags) that this toolchain
      supports targeting.

`toolchain_sources()` and `toolchain_env()` both take `build_sandbox_prefix`: the prefix
the toolchain gets deployed at when it is used within a build sandbox, or `nothing`
otherwise.  Toolchains that set themselves up differently there use it; others ignore it.
"""
abstract type AbstractToolchain; end

# content hash used to key things like our GeneratedSource's
import TreeArchival
import Sandbox
using SHA: sha1
const bbt_code_hash = bytes2hex(TreeArchival.treehash(@__DIR__))

"""
    CachedGeneratedSource(f::Function, name::String; target::String)

A wrapper around GeneratedSource that applies a BinaryBuilderToolchains hash
to the end of `name` to ensure that this gets invalidated if the source of BBT
(or any of its dependencies) are modified.
"""
function CachedGeneratedSource(f::Function, name::String; target::String)
    return GeneratedSource(f, string(name, "-", bbt_code_hash); target)
end


include("JLLPins.jl")
include("PlatformDefaults.jl")
include("WrapperUtils.jl")
include("PathUtils.jl")
include("toolchains/BinutilsToolchain.jl")
include("toolchains/CToolchain.jl")
include("toolchains/CToolchainPlatformExtensions.jl")
include("toolchains/HostToolsToolchain.jl")
include("toolchains/CMakeToolchain.jl")
include("PkgUtils.jl")
include("InteractiveUtils.jl")

@setup_workload begin
    native_linux = Platform(arch(BBHostPlatform()), "linux")
    targets = [
        native_linux,
        Platform("x86_64", "windows"),
        Platform("armv7l", "linux"; libc=:musl),
        Platform("aarch64", "macos"; os_version=v"20"),
    ]
    platforms = [CrossPlatform(native_linux => target) for target in targets]
    # Resolving toolchain JLL versions only needs the installed registries
    old_offline = Pkg.OFFLINE_MODE[]
    Pkg.offline(true)
    try
        @compile_workload begin
            for platform in platforms
                # Not every toolchain supports every platform
                try
                    toolchains = [
                        CMakeToolchain(platform),
                        CToolchain(platform),
                        HostToolsToolchain(platform)
                    ]
                    reduce(vcat, toolchain_sources.(toolchains))
                    foldl(path_appending_merge, [
                        toolchain_env.(toolchains, ("/opt/toolchains",))...,
                        filter_env_vars(ENV),
                    ])
                catch e
                    @debug("Failed to precompile support for platform", platform, exception=(e, catch_backtrace()))
                end
            end
        end
    finally
        Pkg.offline(old_offline)
    end
end

end # module
