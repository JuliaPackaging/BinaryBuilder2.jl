using BinaryBuilderToolchains: gcc_platform, gcc_target_triplet

function default_toolchains(platform::CrossPlatform, host_deps::Vector{<:AbstractSource} = AbstractSource[]; host_only::Bool = false)
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
            default_ctoolchain = true,
            extra_flags(platform.target, "/workspace/destdir/$(triplet(platform.target))")...,
        ))
    end

    # The host toolchain (even if it's the same as the default toolchain) gets
    # different wrappers with different default flags.
    push!(toolchains, CToolchain(
        CrossPlatform(platform.host, platform.host);
        host_ctoolchain = true,
        default_ctoolchain = host_only,
        extra_flags(platform.host, "/usr/local")...,
    ))

    push!(toolchains, HostToolsToolchain(platform.host, host_deps))
    return toolchains
end
