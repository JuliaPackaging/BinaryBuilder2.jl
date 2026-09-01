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
        if Sys.isapple(platform.target)
            push!(tools,
                JLLSource(
                    "CCTools_jll",
                    platform;
                    uuid=Base.UUID("1e42d1a4-ec21-5f39-ae07-c1fb720fbc4b"),
                    repo=Pkg.Types.GitRepo(
                        rev="bb2/GCCBootstrap-x86_64-linux-gnu",
                        source="https://github.com/staticfloat/CCTools_jll.jl",
                    ),
                    # eventually, include a resolved version
                    version=v"986.0.0",
                ),
            )
        elseif Sys.islinux(platform.target) || Sys.isbsd(platform.target)
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

# Memoization for `deployed_auditor_toolchain()`.  These are `OncePerProcess` so that a
# cache populated during precompilation (which would point at temporary directories that
# no longer exist) can never be baked into the package image.
const _auditor_toolchains = Base.OncePerProcess{Dict{String,AuditorToolchain}}() do
    return Dict{String,AuditorToolchain}()
end
const _auditor_toolchain_prefixes = Base.OncePerProcess{Dict{String,String}}() do
    return Dict{String,String}()
end
const _auditor_toolchain_lock = Base.OncePerProcess{ReentrantLock}() do
    return ReentrantLock()
end

# Identifies the set of tools a toolchain will deploy.  Note that this is deliberately
# _not_ the toolchain's platform: every ELF target audits with the same host `Patchelf`,
# so they can all share a single deployment.
function toolchain_signature(toolchain::AuditorToolchain)
    return join(
        ("$(jll.package.name)/$(jll.package.version)/$(triplet(jll.platform))/$(jll.target)"
         for jll in toolchain.deps),
        ";",
    )
end

"""
    deployed_auditor_toolchain(platform::CrossPlatform)

Return a `(toolchain, prefix)` pair for the `AuditorToolchain` of the given platform,
deploying it into a temporary prefix if we have not already done so.  Resolving and
deploying these tools costs an appreciable fraction of a second, and `audit!()` runs
once per platform, so we memoize them for the lifetime of the process.  The prefixes
come from `mktempdir()`, which deletes them at process exit.
"""
function deployed_auditor_toolchain(platform::CrossPlatform)
    @lock _auditor_toolchain_lock() begin
        toolchain = get!(() -> AuditorToolchain(platform), _auditor_toolchains(), triplet(platform))
        prefix = get!(_auditor_toolchain_prefixes(), toolchain_signature(toolchain)) do
            srcs = toolchain_sources(toolchain)
            prepare(srcs)
            prefix = mktempdir()
            deploy(srcs, prefix)
            return prefix
        end
        return (toolchain, prefix)
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
    if Sys.isapple(toolchain.platform.target)
        env["INSTALL_NAME_TOOL"] = install_name_tool_filename(toolchain)
    elseif Sys.islinux(toolchain.platform.target) || Sys.isbsd(toolchain.platform.target)
        env["PATCHELF"] = patchelf_filename(toolchain)
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
