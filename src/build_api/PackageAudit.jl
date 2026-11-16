using BinaryBuilderAuditor: audit_package, PassResult

# The Julia compat bound a JLL gets when its recipe doesn't set `julia_compat`
const DEFAULT_JULIA_COMPAT = "1.6"

"""
    PackageAuditError

Thrown when the package-level audit (`BinaryBuilderAuditor.audit_package()`) of a JLL
fails, e.g. because its `julia_compat` admits a Julia whose bundled libstdc++ can't load
its binaries.
"""
struct PackageAuditError <: Exception
    jll_name::String
    julia_compat::String
    pass_results::Dict{String,Vector{PassResult}}
end

function Base.showerror(io::IO, e::PackageAuditError)
    print(io, "Package audit of $(e.jll_name)_jll (julia_compat \"$(e.julia_compat)\") failed:")
    for name in sort(collect(keys(e.pass_results))), r in e.pass_results[name]
        r.status == :fail || continue
        print(io, "\n  [$(name)] $(r.identifier)")
        if r.message !== nothing
            print(io, ": ", r.message)
        end
    end
end

"""
    package_runtime_requirements(named_extractions)

The runtime requirements recorded for each extraction in `named_extractions` (a mapping
from extraction name to `ExtractResult`s), labelled by platform triplet, and also by
extraction name when there is more than one.
"""
function package_runtime_requirements(named_extractions)
    multiple = length(named_extractions) > 1
    reqs = Pair{String,RuntimeRequirements}[]
    for (name, extractions) in named_extractions, e in extractions
        e.runtime_requirements === nothing && continue
        label = triplet(e.config.platform)
        push!(reqs, (multiple ? "$(name)/$(label)" : label) => e.runtime_requirements)
    end
    return sort!(reqs; by = first)
end

"""
    audit_package!(jll_name, julia_compat, named_extractions)

Run the package-level audit over `named_extractions`, throwing a `PackageAuditError` if it
fails.  Extractions with no recorded runtime requirements (e.g. failed ones) are skipped.
"""
function audit_package!(jll_name::AbstractString, julia_compat::AbstractString, named_extractions)
    pass_results = audit_package(julia_compat, package_runtime_requirements(named_extractions))
    if !success(pass_results)
        throw(PackageAuditError(string(jll_name), string(julia_compat), pass_results))
    end
    return pass_results
end
