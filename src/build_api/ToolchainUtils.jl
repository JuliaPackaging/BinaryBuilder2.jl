

is_target_toolchain(toolchain::Type{HostToolsToolchain}) = false
is_target_toolchain(toolchain::Type{<:AbstractToolchain}) = true
is_target_toolchain(toolchain::AbstractToolchain) = is_target_toolchain(typeof(toolchain))

function ctoolchain_extra_flags(platform, prefix)
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
