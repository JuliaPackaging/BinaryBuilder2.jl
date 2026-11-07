"""
    default_macos_kernel_version(arch::String)

Return the Darwin kernel version used as the deployment target for macOS
targets of architecture `arch` that carry no `os_version` tag: darwin 14
(macOS 10.10) for `x86_64` and darwin 20 (macOS 11.0, the first release
supporting Apple Silicon) for `aarch64`.
"""
function default_macos_kernel_version(arch::String)
    if arch == "x86_64"
        return v"14"
    elseif arch == "aarch64"
        return v"20"
    else
        throw(ArgumentError("Unknown macOS architecture '$(arch)'!"))
    end
end

"""
    macos_target_kernel_version(platform::AbstractPlatform)

Return the Darwin kernel version that a toolchain targeting the macOS
`platform` builds for: the platform's `os_version` tag if present, otherwise
`default_macos_kernel_version(arch(platform))`.  The platform itself is not
modified, so untagged platforms keep their triplet (and the cache keys and
artifact names derived from it); the deployment target chosen here is what
gets recorded as `os_version` when the build is packaged.
"""
function macos_target_kernel_version(platform::AbstractPlatform)
    if os(platform) != "macos"
        throw(ArgumentError("Not a macOS platform: $(triplet(platform))"))
    end
    return something(os_version(platform), default_macos_kernel_version(arch(platform)))
end
