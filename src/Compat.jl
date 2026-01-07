module Compat

# This file contains compatability adapters to keep old recipes still building with new BB
using ..BinaryBuilder2
using ..JLLPrefixes: VersionSpec, PkgSpec
using ..BinaryBuilderProducts, ..BinaryBuilderSources
export VersionSpec, PkgSpec, PackageSpec
export Product, Dependency

const Product = AbstractProduct
const Dependency = JLLSource
const PackageSpec = PkgSpec

# Map BinaryBuilder1 syntax to BB2 syntax
function BinaryBuilder2.build_tarballs(ARGS::Vector{String}, src_name::String, src_version, sources, script, platforms, products, dependencies; julia_compat::String = "1.6", kwargs...)
    return build_tarballs(;
        src_name,
        src_version,
        sources,
        script,
        platforms,
        products,
        target_dependencies=dependencies,
        julia_compat,
    )
end

end
