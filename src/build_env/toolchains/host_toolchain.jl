@kwdef struct HostToolchain <: AbstractToolchain
end

function toolchain_deps(toolchain::HostToolchain, platform::CrossPlatform)
    deps = AbstractDependency[
        # TODO: version these?
        JLLDependency("GNUMake_jll"; platform.host),
        JLLDependency("Ccache_jll"; platform.host),
    ]
    return deps
end
