# Spiritually, I feel this code belongs in `JLLGenerator/BinaryBuilderProductsExt`
# as I feel it belongs more to `JLLGenerator` than it does to `BinaryBuilderProducts`.
# However, I cannot do that and have `BinaryBuilderProducts` directly depend on
# `JLLGenerator`, as that creates a dependency cycle, from `BinaryBuilderProducts`
# to `JLLGenerator` to `JLLGenerator/BinrayBuilderProductsExt` back to `BinaryBuilderProducts`.
# So assuming that we do not want `JLLGenerator` to explicitly depend on `BinaryBuilderProducts`
# (which we do not, for hygiene reasons) we instead just include the extensions' source
# directly in `BinaryBuilderProducts`.

using BinaryBuilderProducts, JLLGenerator
import BinaryBuilderProducts: AbstractProduct, ExecutableProduct, FileProduct, LibraryProduct
import JLLGenerator: AbstractJLLProduct, JLLExecutableProduct, JLLFileProduct, JLLLibraryProduct, JLLLibraryDep, AbstractProducts

# First, adapters that go from `AbstractProduct` objects to `AbstractJLLProduct` objects:
function JLLExecutableProduct(ep::ExecutableProduct, prefix::String; kwargs...)
    return JLLExecutableProduct(
        ep.varname,
        locate(ep, prefix; kwargs...),
    )
end
function AbstractJLLProduct(ep::ExecutableProduct, prefix::String; kwargs...)
    return JLLExecutableProduct(ep, prefix; kwargs...)
end

function JLLFileProduct(fp::FileProduct, prefix::String; kwargs...)
    return JLLFileProduct(
        fp.varname,
        locate(fp, prefix; kwargs...),
    )
end
function AbstractJLLProduct(fp::FileProduct, prefix::String; kwargs...)
    return JLLFileProduct(fp, prefix; kwargs...)
end

function JLLLibraryDep(lp::LibraryProduct, jll::Union{Symbol,Nothing} = nothing)
    return JLLLibraryDep(
        jll,
        lp.varname,
    )
end

function JLLLibraryProduct(lp::LibraryProduct, prefix::String;
                           jll_maps::Dict{LibraryProduct,Symbol} = Dict{LibraryProduct,Symbol}(),
                           kwargs...)
    return JLLLibraryProduct(
        lp.varname,
        locate(lp, prefix; kwargs...),
        [JLLLibraryDep(dep, get(jll_maps, dep, nothing)) for dep in lp.deps],
        lp.dlopen_flags,
    )
end
function AbstractJLLProduct(lp::LibraryProduct, prefix::String; kwargs...)
    return JLLLibraryProduct(lp, prefix; kwargs...)
end

function toposort_artifacts()
    # Topologically sort the artifacts; first, we just sort by number of dependencies,
    # then we run a loop, adding artifacts whose dependencies are all already sorted:
    artifact_names_in_order = sort(collect(keys(artifacts)), by=name->length(artifacts[name].deps))

    # Initialize `sorted` with all artifacts with zero dependencies:
    first_nonempty_dep_idx = findfirst(name -> !isempty(artifacts[name].deps), artifact_names_in_order)
    sorted = artifact_names_in_order[1:first_nonempty_dep_idx]
    artifact_names_in_order = artifact_names_in_order[first_nonempty_dep_idx:end]

    # Next, run a loop to append JLLs that have all of their dependencies 
    for iter in 1:(length(artifacts) - first_nonempty_dep_idx + 1)
        # Early-out
        if length(sorted) == length(artifacts)
            break
        end

        to_delete = Int[]
        for (idx, name) in enumerate(artifact_names_in_order)
            if all(dep ∈ sorted for dep in artifacts[name].deps)
                push!(sorted, name)
                push!(to_delete, idx)
            end
        end
        deleteat!(artifact_names_in_order, to_delete)
    end
    return 
end

# Next, to reconstruct AbstractProducts from AbstractJLLProducts, we need some
# extra (global) information, so although we define these `AbstractProduct` overrides,
# you really need to call `AbstractProducts(infos::Vector{JLLInfo})` as a top-level
# function instead.
function AbstractProduct(ep::JLLExecutableProduct; artifact, artifacts, cache)
    return get!(cache, ep) do
        return ExecutableProduct(
            ep.path,
            ep.varname,
        )
    end
end
function AbstractProduct(fp::JLLFileProduct; artifact, artifacts, cache)
    return get!(cache, fp) do
        return FileProduct(
            fp.path,
            fp.varname,
        )
    end
end
function AbstractProduct(ld::JLLLibraryDep; artifact, artifacts, cache)
    get!(cache, ld) do
        # First, determine which artifact we should be looking this up in:
        ld_artifact = if ld.mod === nothing
            artifact
        else
            # This should never happen, we have checks higher up that ensure that.
            if !haskey(artifacts, ld.mod)
                throw(ArgumentError("Dependency $(ld.mod) not found in artifact lists for $(artifact)"))
            end
            artifacts[ld.mod]
        end
        for product in ld_artifact.products
            if product.varname == ld.varname
                return AbstractProduct(product; artifact=ld_artifact, artifacts, cache)
            end
        end
        throw(ArgumentError("Unable to find matching product for $(ld)"))
    end
end
function AbstractProduct(lp::JLLLibraryProduct; artifact, artifacts, cache)
    return get!(cache, lp) do
        # For each dep, look up the appropriate library product in our dependency
        return LibraryProduct(
            lp.path,
            lp.varname;
            deps = LibraryProduct[AbstractProduct(dep; artifact, artifacts, cache) for dep in lp.deps],
            dlopen_flags = lp.flags,
        )
    end
end

# need to do it all in one go, not piecemeal like we've done above.
# This allows us to make use of information such as dependencies.
function AbstractProducts(infos::Vector{JLLInfo}, platform::AbstractPlatform)
    sym_name(info::JLLInfo) = Symbol(string(info.name, "_jll"))
    artifacts = Dict{Symbol,JLLArtifactInfo}(
        sym_name(info) => select_platform(Dict(a.platform => a for a in info.artifacts), platform) for info in infos
    )
    # This is what we will eventually return
    products = Dict{Symbol,Vector{AbstractProduct}}(
        sym_name(info) => AbstractProduct[] for info in infos
    )
    cache = Dict{Union{AbstractJLLProduct,JLLLibraryDep},AbstractProduct}()

    # Ensure that every dependency is present
    for (name, a) in artifacts
        for dep in a.deps
            if !haskey(artifacts, dep.name)
                throw(ArgumentError("JLL $(name) depends on $(dep.name) but not provided in `infos`!"))
            end
        end
    end

    # Start walking over artifacts, reconstructing each product.
    # Note that `AbstractProduct` is recursive, and makes use of our cache.
    for (jll_name, artifact) in artifacts
        for product in artifact.products
            push!(products[jll_name], AbstractProduct(product; artifact, artifacts, cache))
        end
    end
    return products
end
