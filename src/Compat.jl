module Compat

# This file contains compatability adapters to keep old recipes still building with new BB
using ..BinaryBuilder2
using ..JLLPrefixes: VersionSpec, PkgSpec
using ..BinaryBuilderProducts, ..BinaryBuilderSources
export VersionSpec, PkgSpec, PackageSpec
export Product, Dependency, BuildDependency, HostBuildDependency

const Product = AbstractProduct
const Dependency = PlatformlessWrapper{JLLSource}
BinaryBuilder2.PlatformlessWrapper{JLLSource}(name::String) = JLLSource(;name)
const PackageSpec = PkgSpec

# We smuggle `HostBuildDependency`'s through by inserting a sentinel value into the `kwargs` object:
BuildDependency(x) = PlatformlessWrapper{JLLSource}(x; build_dependency=true)
HostBuildDependency(x) = PlatformlessWrapper{JLLSource}(x; host=true, build_dependency=true)

# Map BinaryBuilder1 syntax to BB2 syntax
function BinaryBuilder2.build_tarballs(ARGS::Vector{String}, src_name::String, src_version, sources, script, platforms, products, dependencies; julia_compat::String = "1.6", kwargs...)
    # Separate out the dependencies into target dependencies and host dependencies
    target_dependencies = AbstractSource[]
    target_build_time_dependencies = AbstractSource[]
    host_dependencies = AbstractSource[]

    # We've smuggled information into the PlatformlessWrapper kwargs,
    # this strips that information out again
    function strip_dep_kwargs(dep::PlatformlessWrapper{T}) where {T}
        return PlatformlessWrapper{T}(
            dep.args,
            filter(kwargs) do (k, v)
                return k ∉ (:build_dependency, :host)
            end,
        )
    end

    # Use the smuggled kwargs to sort our dependencies into target/target_build/host dependencies
    for dep in dependencies
        if :build_dependency ∈ keys(dep.kwargs)
            if :host ∈ keys(dep.kwargs)
                dep = strip_dep_kwargs(dep)
                push!(host_dependencies, dep)
            else
                dep = strip_dep_kwargs(dep)
                push!(target_build_time_dependencies, dep)
            end
        else
            push!(target_dependencies, dep)
        end
    end

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
        julia_compat,
    )
end

end
