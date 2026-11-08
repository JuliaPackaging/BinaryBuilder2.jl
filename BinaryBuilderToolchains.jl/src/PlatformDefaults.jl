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

"""
    macos_sdk_platform(platform::AbstractPlatform)

Return the macOS `platform` (for a `CrossPlatform`, its target) with its
`os_version` set to the Darwin kernel version of the macOS SDK (11.1,
darwin 20) that our macOS toolchain JLLs (`macOSSDK_jll`, `CCTools_jll`,
`GCC_jll`) are built against.  Those JLLs exist only for that `os_version`,
and they name their executables and sysroot directories after it (e.g.
`x86_64-apple-darwin20-as`).  They serve every deployment target, which is
selected through flags such as `-mmacosx-version-min` (see
`macos_target_kernel_version()`).
"""
function macos_sdk_platform(platform::AbstractPlatform)
    if os(platform) != "macos"
        throw(ArgumentError("Not a macOS platform: $(triplet(platform))"))
    end
    sdk_platform = deepcopy(platform)
    sdk_platform["os_version"] = string(VersionNumber(macos_kernel_version("11.1")))
    return sdk_platform
end
macos_sdk_platform(platform::CrossPlatform) = CrossPlatform(platform.host, macos_sdk_platform(platform.target))

"""
    toolchain_jll_triplet(platform::AbstractPlatform)

Return the triplet that the toolchain JLLs installed for the target
`platform` use in the names of their executables and sysroot directories.
This is `triplet(gcc_platform(platform))`, except on macOS, where it is the
triplet of `macos_sdk_platform(platform)` whatever the deployment target.
The user-visible triplet (wrapper names, `--target`, `CC_TARGET`, ...) stays
`triplet(gcc_platform(platform))`.
"""
function toolchain_jll_triplet(platform::AbstractPlatform)
    if os(platform) == "macos"
        platform = macos_sdk_platform(platform)
    end
    return triplet(gcc_platform(platform))
end
