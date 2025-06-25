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
* toolchain_sources(toolchain)
    - returns a vector of `AbstractSource`'s representing the dependencies
      needed to run this toolchain, relative to some installation prefix
* toolchain_env(toolchain, deployed_prefix::String)
    - returns a dictionary listing the environment variables to be added
      in to commands that use this toolchain.
* platform(toolchain)
    - returns the platform this toolchain was constructed for.  Could be
      a `CrossPlatform` (in the case of CToolchain) or a plain `Platform`
      (in the case of HostToolsToolchain).
* supported_platforms(::Type{toolchain})
    - returns a list of platforms (with no tags) that this toolchain
      supports targeting.
"""
abstract type AbstractToolchain; end

# content hash used to key things like our GeneratedSource's
import TreeArchival
const bbt_code_hash = bytes2hex(TreeArchival.treehash(@__DIR__))

function CachedGeneratedSource(f::Function, name::String; target::String)
    return GeneratedSource(f, string(name, "-", bbt_code_hash); target)
end


include("WrapperUtils.jl")
include("PathUtils.jl")
include("toolchains/CToolchain.jl")
include("toolchains/HostToolsToolchain.jl")
include("toolchains/CMakeToolchain.jl")
include("PkgUtils.jl")
include("InteractiveUtils.jl")

@setup_workload begin
    targets = [
        BBHostPlatform(),
        Platform("x86_64", "windows"),
        Platform("armv7l", "linux"; libc=:musl),
        Platform("aarch64", "macos"),
    ]
    platforms = [CrossPlatform(BBHostPlatform() => target) for target in targets]
    @compile_workload begin
        for platform in platforms
            # try/catch when running on platforms other than the typical BB2 host platforms
            # and where we have incomplete toolchain implementations
            try
                with_toolchains((p, e) -> nothing, [
                    CMakeToolchain(platform),
                    CToolchain(platform),
                    HostToolsToolchain(platform)
                ])
            catch e
                @warn("Failed to precompile support for platform", platform, e)
            end
        end
    end
end

end # module
