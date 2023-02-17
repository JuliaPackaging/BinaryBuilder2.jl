@kwdef struct HostToolchain <: AbstractToolchain
    platform::Platform = HostPlatform()

    function HostToolchain(platform)
        peel_target(p::Platform) = p
        peel_target(p::CrossPlatform) = p.target

        return new(
            peel_target(platform),
        )
    end
end


toolchain_prefix(::HostToolchain) = "/usr/local"
function toolchain_deps(toolchain::HostToolchain)
    deps = JLLSource[
        # TODO: version these?
        JLLSource("GNUMake_jll", toolchain.platform),
        JLLSource("Ccache_jll", toolchain.platform),
    ]
    return deps
end
