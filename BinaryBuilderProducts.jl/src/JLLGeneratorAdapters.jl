# Define adapters to convert from `AbstractProduct` objects to `JLLProduct` objects:
import JLLGenerator: AbstractJLLProduct

function JLLGenerator.AbstractJLLProduct(ep::ExecutableProduct, prefix::String; kwargs...)
    return JLLExecutableProduct(
        ep.varname,
        locate(ep, prefix; kwargs...),
    )
end

function JLLGenerator.AbstractJLLProduct(fp::FileProduct, prefix::String; kwargs...)
    return JLLFileProduct(
        fp.varname,
        locate(fp, prefix; kwargs...),
    )
end

function JLLGenerator.JLLLibraryDep(lp::LibraryProduct, jll::Union{Symbol,Nothing} = nothing)
    return JLLLibraryDep(
        jll,
        lp.varname,
    )
end

function JLLGenerator.AbstractJLLProduct(lp::LibraryProduct, prefix::String; jll_maps::Dict{LibraryProduct,Symbol} = Dict{LibraryProduct,Symbol}(), kwargs...)
    return JLLLibraryProduct(
        lp.varname,
        locate(lp, prefix; kwargs...),
        [JLLLibraryDep(dep, get(jll_maps, dep, nothing)) for dep in lp.deps],
        lp.dlopen_flags,
    )
end
