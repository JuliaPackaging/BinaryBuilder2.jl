@kwdef struct HostToolsToolchain <: AbstractToolchain
    platform::Platform = HostPlatform()

    function HostToolsToolchain(platform)
        peel_target(p::Platform) = p
        peel_target(p::CrossPlatform) = p.target

        return new(
            peel_target(platform),
        )
    end
end

function toolchain_sources(toolchain::HostToolsToolchain)
    deps = JLLSource[
        # TODO: version these?
        JLLSource("GNUMake_jll", toolchain.platform),
        JLLSource("Ccache_jll", toolchain.platform),
    ]
    return deps
end
