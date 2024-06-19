using StyledStrings
using BinaryBuilderToolchains: gcc_platform, gcc_target_triplet
export supported_platforms

# Default to using a Linux host with the same host arch as our machine
# This just makes qemu-user-static's job easier.
default_host() = Platform(arch(HostPlatform()), "linux")

function default_toolchains(platform::CrossPlatform, host_deps::Vector{<:AbstractSource} = AbstractSource[]; host_only::Bool = false, bootstrap::Bool = false)
    toolchains = AbstractToolchain[]

    function extra_flags(platform, prefix)
        ldflags = [
            "-L$(prefix)/lib",
        ]
        if nbits(platform) == 64
            push!(ldflags, "-L$(prefix)/lib64")
        end

        return (;
            extra_ldflags=ldflags,
            extra_cflags=["-I$(prefix)/include"],
        )
    end
    
    # As long as we're not `host_only`, we add the target compiler, and it's typically the default toolchain
    if !host_only
        push!(toolchains, CToolchain(
            platform;
            vendor = bootstrap ? :bootstrap : :auto,
            default_ctoolchain = true,
            extra_flags(platform.target, "/workspace/destdir/$(triplet(platform.target))")...,
        ))
    end

    # The host toolchain (even if it's the same as the default toolchain) gets
    # different wrappers with different default flags.
    push!(toolchains, CToolchain(
        CrossPlatform(platform.host, platform.host);
        vendor = bootstrap ? :bootstrap : :auto,
        host_ctoolchain = true,
        default_ctoolchain = host_only,
        extra_flags(platform.host, "/usr/local")...,
    ))

    push!(toolchains, HostToolsToolchain(platform.host, host_deps))
    return toolchains
end

function status_style(status::Symbol)
    return Dict{Symbol,Symbol}(
        :success => :green,
        :failed => :red,
        :errored => :red,
        :cached => :green,
        :skipped => :blue,
    )[status]
end

function BinaryBuilderToolchains.supported_platforms(toolchain_types::Vector = [CToolchain]; experimental::Bool = false)
    toolchain_types = Vector{Type}(toolchain_types)

    # Drop host toolchain, we don't care about that.
    filter!(t -> t != HostToolsToolchain, toolchain_types)

    platform_sets = supported_platforms.(toolchain_types; experimental)
    return intersect(platform_sets...)
end
