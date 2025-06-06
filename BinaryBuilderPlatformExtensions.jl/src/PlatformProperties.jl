export macos_version, macos_kernel_version, nbits, proc_family, exeext, dlext

function macos_version(kernel_version::Integer)
    # See https://en.wikipedia.org/wiki/Darwin_(operating_system)#Release_history
    kernel_to_macos = Dict(
        12 => "10.8",
        13 => "10.9",
        14 => "10.10",
        15 => "10.11",
        16 => "10.12",
        17 => "10.13",
        18 => "10.14",
        19 => "10.15",
        20 => "11.0",
        21 => "12.0",
        22 => "13.0",
        23 => "14.0",
        24 => "15.0",
    )
    return get(kernel_to_macos, kernel_version, nothing)
end
macos_version(v::VersionNumber) = macos_version(v.major)

"""
    macos_kernel_version(v::VersionNumber)

Return the kernel version from a macOS VersionNumber, e.g. when given
`10.10`` return `14`.  If given a VersionNumber outside of what we
understand, return the closest valid number.
"""
function macos_kernel_version(v::VersionNumber)
    if v.major < 10
        return 12
    elseif v.major == 10
        if v.minor <= 8
            return 12
        else
            return min(12 + (v.minor - 8), 19)
        end
    else
        return 20 + (v.major - 11)
    end
end
macos_kernel_version(s::String) = macos_kernel_version(VersionNumber(s))

"""
    macos_version(p::AbstractPlatform)

If no `os_version` is specified in `p`, return `nothing`.  Otherwise, map the kernel
version through `macos_version(::Int)` to get a string like `"10.15"`.

```jldoctest
julia> macos_version(Platform("x86_64", "macos"; os_version="18"))
"10.14"
```
"""
function macos_version(p::AbstractPlatform)
    if os(p) != "macos"
        return nothing
    end
    if os_version(p) === nothing
        return nothing
    end
    return macos_version(os_version(p))
end

function macos_kernel_version(p::AbstractPlatform)
    if os(p) != "macos"
        return nothing
    end
    if os_version(p) === nothing
        return nothing
    end
    return Int(os_version(p).major)
end


"""
    nbits(p::AbstractPlatform)

Return the number of bits in the architecture of the given Platform.
Usually either 32 or 64.
"""
function nbits(p::AbstractPlatform)
    if arch(p) ∈ ("x86_64", "aarch64", "powerpc64le")
        return 64
    elseif arch(p) ∈ ("i686", "armv7l", "armv6l")
        return 32
    else
        error("Unknown number of bits for architecture of platform $(triplet(p))")
    end
end
# We have to give an answer (e.g. when the target of a build is `AnyPlatform`),
# so just default to a reasonable choice
nbits(::AnyPlatform) = 64
nbits(cp::CrossPlatform) = nbits(cp.target)

"""
    proc_family(p::AbstractPlatform)

Return the processor family of the architecture of the given Platform.
Usually one of "intel", "arm" or "power".
"""
function proc_family(p::AbstractPlatform)
    if arch(p) in ("x86_64", "i686")
        return "intel"
    elseif arch(p) in ("armv6l", "armv7l", "aarch64")
        return "arm"
    elseif arch(p) == "powerpc64le"
        return "power"
    else
        error("Unknown processor family for architecture of platform $(triplet(p))")
    end
end
proc_family(::AnyPlatform) = "any"
proc_family(cp::CrossPlatform) = proc_family(cp.target)


"""
    exeext(p::AbstractPlatform)

Return the executable extension for the given platform.  Currently only Windows
platforms return ".exe", all other platforms return "".
"""
function exeext(p::AbstractPlatform)
    if Sys.iswindows(p)
        return ".exe"
    else
        return ""
    end
end
exeext(::AnyPlatform) = ""
exeext(cp::CrossPlatform) = exeext(cp.target)

"""
    dlext(p::AbstractPlatform)

Return the dynamic library extension for the given platform.
"""
function dlext(p::AbstractPlatform)
    if Sys.iswindows(p)
        return ".dll"
    elseif Sys.isapple(p)
        return ".dylib"
    else
        return ".so"
    end
end
dlext(::AnyPlatform) = ""
dlext(cp::CrossPlatform) = dlext(cp.target)
