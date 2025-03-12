import Pkg
using BinaryBuilderPlatformExtensions, BinaryBuilderSources
using BinaryBuilderToolchains: AbstractToolchain, resolve_versions!, insert_PATH!, gcc_target_triplet
import BinaryBuilderToolchains: toolchain_env, toolchain_sources
export AuditorToolchain

"""
    AuditorToolchain

This toolchain contains the tools necessary for the BinaryBuilder auditor to function,
such as as `patchelf` and `install_name_tool`.
"""
struct AuditorToolchain <: AbstractToolchain
    platform::CrossPlatform
    deps::Vector{AbstractSource}

    function AuditorToolchain(platform::CrossPlatform)
        tools = JLLSource[]
        if Sys.islinux(platform.target)
            push!(tools,
                # We used to version Patchelf with date-based versions, but then
                # we switched to actual upstream version numbers; Pkg chooses the
                # date-based versions because they're higher, so we have to explicitly
                # choose the correct version number here
                JLLSource(
                    "Patchelf_jll",
                    platform.host;
                    version=v"0.17.2+0",
                ),
            )
        elseif Sys.isapple(platform.target)
            push!(tools,
                JLLSource(
                    "CCTools_jll",
                    platform;
                    uuid=Base.UUID("1e42d1a4-ec21-5f39-ae07-c1fb720fbc4b"),
                    repo=Pkg.Types.GitRepo(
                        rev="main",
                        source="https://github.com/staticfloat/CCTools_jll.jl",
                    ),
                    # eventually, include a resolved version
                    version=v"986.0.0",
                ),
            )
        end

        julia_version = nothing
        if haskey(tags(platform), "julia_version")
            julia_version = VersionNumber(platform["julia_version"])
        end
        resolve_versions!(tools; julia_version)

        return new(
            platform,
            tools,
        )
    end
end

function Base.show(io::IO, toolchain::AuditorToolchain)
    println(io, "AuditorToolchain ($(triplet(toolchain.platform)))")
    for dep in toolchain.deps
        println(io, " - $(dep.package.name[1:end-4]) v$(dep.package.version)")
    end
end

patchelf_filename(toolchain::AuditorToolchain) = "patchelf"
install_name_tool_filename(toolchain::AuditorToolchain) = "$(gcc_target_triplet(toolchain.platform.target))-install_name_tool"
function toolchain_sources(toolchain::AuditorToolchain)
    return toolchain.deps
end
function toolchain_env(toolchain::AuditorToolchain, deployed_prefix::String)
    env = Dict{String,String}()
    if Sys.islinux(toolchain.platform.target)
        env["PATCHELF"] = patchelf_filename(toolchain)
    elseif Sys.isapple(toolchain.platform.target)
        env["INSTALL_NAME_TOOL"] = install_name_tool_filename(toolchain)
    end

    insert_PATH!(env, :PRE, [
        joinpath(deployed_prefix, "bin"),
    ])
    return env
end
platform(toolchain::AuditorToolchain) = toolchain.platform

function supported_platforms(::Type{AuditorToolchain}; experimental::Bool = false)
    return [
        Platform("x86_64", "linux"),
        Platform("aarch64", "linux"),
    ]
end
