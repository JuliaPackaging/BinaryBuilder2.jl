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

function Dependency(name_or_pkgspec)
    return Dependency(JLLSource(name_or_pkgspec), false, false)
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
function BinaryBuilder2.build_tarballs(ARGS::Vector{String}, src_name::String, src_version, sources, script, platforms, products, dependencies; julia_compat::String = "1.6", compilers::Vector{Symbol} = [:c], kwargs...)
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
    )
end

end
