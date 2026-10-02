using JLLGenerator
export AuditInfo, AuditDependencyInfo

struct AuditDependencyInfo
    # Library products of the JLL, for the platform being audited
    libs::Vector{AbstractJLLProduct}
    # Location where its artifact is unpacked
    artifact_dir::Union{Nothing,String}
end
AuditDependencyInfo(libs::Vector{<:AbstractJLLProduct}; artifact_dir::Union{Nothing,String} = nothing) =
    AuditDependencyInfo(libs, artifact_dir)

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
    # The dependencies of those dependencies, which are installed but never linked against
    transitive_deps::Dict{Symbol,AuditDependencyInfo}
end

function AuditInfo(deps::Dict{Symbol,AuditDependencyInfo};
                   transitive_deps::Dict{Symbol,AuditDependencyInfo} = Dict{Symbol,AuditDependencyInfo}())
    sonames = Dict{String,AuditLibraryInfo}()
    for (jll_name, dep) in deps, lib in dep.libs
        isa(lib, JLLStaticLibraryProduct) && continue # static archives have no SONAME
        sonames[basename(lib.soname)] = AuditLibraryInfo(jll_name, lib.varname, lib.path)
    end
    return AuditInfo(deps, sonames, transitive_deps)
end
AuditInfo() = AuditInfo(Dict{Symbol,AuditDependencyInfo}())
