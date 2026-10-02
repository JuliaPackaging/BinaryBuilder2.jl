using JLLGenerator
export AuditInfo, AuditDependencyInfo

struct AuditDependencyInfo
    # library products of the JLL, for the platform being audited
    libs::Vector{JLLLibraryProduct}
end

struct AuditLibraryInfo
    # The JLL's package name, e.g. `:Zlib_jll`
    jll_name::Symbol
    # Product varname providing this library
    varname::Symbol
    # Relative to that JLL's prefix, path to library
    path::String
end

struct AuditInfo
    # Each dependency, keyed by package name (`:Zlib_jll`)
    deps::Dict{Symbol,AuditDependencyInfo}
    sonames::Dict{String,AuditLibraryInfo}
end

function AuditInfo(deps::Dict{Symbol,AuditDependencyInfo})
    sonames = Dict{String,AuditLibraryInfo}()
    for (jll_name, dep) in deps, lib in dep.libs
        sonames[basename(lib.soname)] = AuditLibraryInfo(jll_name, lib.varname, lib.path)
    end
    return AuditInfo(deps, sonames)
end
AuditInfo() = AuditInfo(Dict{Symbol,AuditDependencyInfo}())
