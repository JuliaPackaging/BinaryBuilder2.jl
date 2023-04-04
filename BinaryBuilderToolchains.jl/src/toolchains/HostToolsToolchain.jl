export HostToolsToolchain

@kwdef struct HostToolsToolchain <: AbstractToolchain
    platform::Platform = HostPlatform()

    function HostToolsToolchain(platform)
        peel_host(p::Platform) = p
        peel_host(p::CrossPlatform) = p.host

        return new(
            peel_host(platform),
        )
    end
end

function toolchain_sources(toolchain::HostToolsToolchain)
    deps = JLLSource[
        # TODO: version these?
        JLLSource("GNUMake_jll", toolchain.platform),
        JLLSource("Patchelf_jll", toolchain.platform),
        JLLSource("Ccache_jll", toolchain.platform),
    ]
    @warn("TODO: Generate wrapper scripts for Patchelf")
    return deps
end

function toolchain_env(::HostToolsToolchain, deployed_prefix::String; base_ENV = ENV)
    PATH = [
        joinpath(deployed_prefix, "wrappers"),
        split(get(base_ENV, "PATH", ""), ":")...,
    ]
    env = Dict{String,String}(
        "PATH" => join(PATH, ":"),
        "PATCHELF" => "patchelf",
    )
    return env
end
