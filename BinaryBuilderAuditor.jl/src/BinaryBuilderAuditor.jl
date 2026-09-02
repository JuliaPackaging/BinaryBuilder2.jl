module BinaryBuilderAuditor

using Base.BinaryPlatforms
export audit!, AuditResult

include("Utils.jl")
include("SystemLibraries.jl")
include("AuditorToolchain.jl")
include("Scanning.jl")
include("AuditResult.jl")
include("AuditInfo.jl")
include("LdScriptParser.jl")
include("passes/RelativeSymlink.jl")
include("passes/LibrarySONAME.jl")
include("passes/DynamicLinkage.jl")
include("passes/StaticLibraries.jl")
include("passes/Licenses.jl")

function audit!(prefix::String,
                products::Vector{<:AbstractProduct},
                info::AuditInfo;
                prefix_alias::String = prefix,
                platform::AbstractPlatform = HostPlatform(),
                env::Dict{String,String} = Dict{String,String}(
                    "prefix" => prefix,
                    "bb_full_target" => triplet(platform),
                ),
                verbose::Bool = false,
                readonly::Bool = false)
    # First, scan the prefix:
    scan = scan_files(
        prefix,
        platform,
        products,
        env,
    )
    result = AuditResult(scan)

    # First pass; symlink translation
    if !readonly
        absolute_to_relative_symlinks!(result, prefix_alias)
    end

    # Ensure that all libraries have SONAMEs
    if !readonly
        ensure_sonames!(result)
    end

    # Solve dynamic linkage, deriving each library product's record
    resolve_dynamic_links!(result, info)

    # Describe the static archive of each library product, if any, plus any standalone static libraries
    resolve_static_libraries!(result, info)

    # Ensure that all libraries and executables have the correct RPATH setup
    if !readonly
        rpaths_consistent!(result, info)
    end

    # Ensure that there are some licenses
    licenses_present(result)

    if verbose
        show(result.pass_results)
    end

    return result
end


# List of audit passes, arranged in-order:
#
# prefix-wide passes:
#  - [!] symlink absolute -> relative translation
# object passes:
#  - ISA check
#  - OS ABI check
#  - [!] executable bit setting (mostly useful for Windows)
#  - libgfortran version check
#  - cxxabi version check
#  - CSL lib check
#  - [!] dylib check
#  - codesign check
# library passes:
#  - dlopen() check?
#  - [!] SONAME and symlink check
# prefix-wide passes:
#  - [!] .la file removal
#  - [!] symlink removal (windows)
#  - [!] DLL -> bin (windows)
#  - [!] implib timestamp normalization (windows)
#  - license file check
#  - absolute path check
#  - case sensitivity check


end # module
