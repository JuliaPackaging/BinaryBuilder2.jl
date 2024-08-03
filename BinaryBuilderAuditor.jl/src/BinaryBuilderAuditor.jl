module BinaryBuilderAuditor

using Base.BinaryPlatforms
export audit!, AuditResult

include("Utils.jl")
include("SystemLibraries.jl")
include("Scanning.jl")
include("AuditResult.jl")
include("passes/RelativeSymlink.jl")
include("passes/LibrarySONAME.jl")
include("passes/DynamicLinkage.jl")
include("passes/Licenses.jl")


function audit!(prefix::String,
                library_products::Vector{LibraryProduct},
                dependencies::Vector{JLLInfo};
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
        library_products,
        env,
    )
    pass_results = Dict{String,Vector{PassResult}}()

    # First pass; symlink translation
    if !readonly
        absolute_to_relative_symlinks!(scan, pass_results, prefix_alias)
    end

    # Ensure that all libraries have SONAMEs
    if !readonly
        ensure_sonames!(scan, pass_results)
    end

    # Solve dynamic linkage, obtaining the output JLLLibraryProduct objects
    get_library_products(jart::JLLBuildInfo) = filter(x -> isa(x, JLLLibraryProduct), jart.products)
    get_library_products(jll::JLLInfo, platform::AbstractPlatform) = get_library_products(select_platform(jll, platform))
    dep_libs = Dict{Symbol, Vector{JLLLibraryProduct}}(Symbol(dep.name) => get_library_products(dep, platform) for dep in dependencies)
    jll_lib_products = resolve_dynamic_links!(scan, pass_results, dep_libs)

    # Ensure that all libraries and executables have the correct RPATH setup
    if !readonly
        rpaths_consistent!(scan, pass_results, dep_libs)
    end

    # Ensure that there are some licenses
    licenses_present(scan, pass_results)

    if verbose
        print_results(pass_results)
    end

    return AuditResult(
        scan,
        pass_results,
        jll_lib_products,
    )
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
