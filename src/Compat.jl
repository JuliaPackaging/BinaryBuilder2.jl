module Compat

# This file contains compatability adapters to keep old recipes still building with new BB
using ..BinaryBuilder2
using ..JLLPrefixes: VersionSpec, PkgSpec
using ..BinaryBuilderProducts, ..BinaryBuilderSources, ..BinaryBuilderToolchains
export VersionSpec, PkgSpec, PackageSpec
export Product, Dependency, BuildDependency, HostBuildDependency

const Product = AbstractProduct
const PackageSpec = PkgSpec

struct Dependency
    jll::Union{JLLSource,PlatformlessWrapper{JLLSource}}
    host::Bool
    build_dependency::Bool
end

"""
    Dependency(name_or_pkgspec; compat = nothing)

A BinaryBuilder1-style target dependency.  `compat` is the `[compat]` entry recorded
for it in the generated JLL, see `jll_compat()`.
"""
function Dependency(name_or_pkgspec; compat::Union{Nothing,AbstractString} = nothing)
    return Dependency(JLLSource(name_or_pkgspec; compat), false, false)
end

function BuildDependency(name_or_pkgspec)
    return Dependency(JLLSource(name_or_pkgspec), false, true)
end

function HostBuildDependency(name_or_pkgspec)
    return Dependency(JLLSource(name_or_pkgspec), true, true)
end

"""
    compilers_to_toolchains(compilers::Vector{Symbol})

Map a BinaryBuilder1-style `compilers` list (e.g. `[:c]`) to a `(target_toolchains,
host_toolchains)` tuple.  The host always receives `HostToolsToolchain()`.
"""
function compilers_to_toolchains(compilers::Vector{Symbol})
    target_toolchains = []
    host_toolchains = []
    for compiler in unique(compilers)
        if compiler == :c
            # BinaryBuilder1's `:c` compiler set always came with CMake as well
            append!(target_toolchains, [CToolchain(), CMakeToolchain()])
            append!(host_toolchains, [CToolchain(), CMakeToolchain()])
        else
            throw(ArgumentError("BinaryBuilder1 compiler `:$(compiler)` is not yet supported by BinaryBuilder2"))
        end
    end
    push!(host_toolchains, HostToolsToolchain())
    return target_toolchains, host_toolchains
end

# Map BinaryBuilder1 syntax to BB2 syntax
function BinaryBuilder2.build_tarballs(ARGS::Vector{String}, src_name::String, src_version, sources, script, platforms, products, dependencies; julia_compat::String = "1.6", augment_platform_block::String = "", compilers::Vector{Symbol} = [:c], kwargs...)
    # Separate out the dependencies into target dependencies and host dependencies
    target_dependencies = []
    target_build_time_dependencies = []
    host_dependencies = []

    for dep in dependencies
        if dep.build_dependency
            if dep.host
                push!(host_dependencies, dep.jll)
            else
                push!(target_build_time_dependencies, dep.jll)
            end
        else
            push!(target_dependencies, dep.jll)
        end
    end

    target_toolchains, host_toolchains = compilers_to_toolchains(compilers)

    return build_tarballs(;
        src_name,
        src_version,
        sources,
        script,
        platforms,
        products,
        target_dependencies,
        target_build_time_dependencies,
        host_dependencies,
        target_toolchains,
        host_toolchains,
        julia_compat,
        augment_platform_block,
    )
end

end
