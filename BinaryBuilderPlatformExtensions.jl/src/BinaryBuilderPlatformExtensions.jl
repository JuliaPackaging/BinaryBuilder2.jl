module BinaryBuilderPlatformExtensions

using Reexport
@reexport using Base.BinaryPlatforms
export BBHostPlatform

"""
    BBHostPlatform()

This provides a stripped-down form of `HostPlatform()` that does not include
constraints on the julia version, the libgfortran version, etc...
This is useful when you need the most generic form of what will work on the
host machine, but don't care about compatibility with all of Julia's deps.
This platform will include arch, os, libc type and cxxstring_abi.
"""
function BBHostPlatform()
    julia_host = HostPlatform()
    return Platform(arch(julia_host), os(julia_host); libc=libc(julia_host))
end

include("AnyPlatform.jl")
include("CrossPlatform.jl")
include("PlatformProperties.jl")
include("Microarchitectures.jl")
include("Utils.jl")

end # module BinaryBuilderPlatformExtensions
