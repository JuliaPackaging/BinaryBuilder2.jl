using Base.BinaryPlatforms
using OrderedCollections
using BinaryBuilderToolchains

# Re-export some useful defines
export Platform, AnyPlatform, CrossPlatform, HostPlatform



"""
    platform_exeext(p::AbstractPlatform)

Get the executable extension for the given Platform.  Includes the leading `.`.
"""
platform_exeext(p::AbstractPlatform) = Sys.iswindows(p) ? ".exe" : ""

