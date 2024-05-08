module BinaryBuilderAuditor

using Base.BinaryPlatforms
export audit!

include("Utils.jl")
include("SystemLibraries.jl")
include("Scanning.jl")
include("passes/RelativeSymlink.jl")
include("passes/LibrarySONAME.jl")
include("passes/DynamicLinkage.jl")

@warn("TODO: Add logging framework to store audit results")

struct AuditResult
    scan::ScanResult

    # These contain the learned interdependency structure of the libraries
    jll_lib_products::Vector{JLLLibraryProduct}
end


function audit!(prefix::String,
                library_products::Vector{LibraryProduct},
                dependencies::Vector{JLLInfo};
                prefix_alias::String = prefix,
                platform::AbstractPlatform = HostPlatform(),
                env::Dict{String,String} = Dict{String,String}(
                    "prefix" => prefix,
                    "bb_full_target" => triplet(platform),
                ),
                verbose::Bool = false)
    # First, scan the prefix:
    scan = scan_files(prefix, platform)

    # First pass; symlink translation
    absolute_to_relative_symlinks!(scan, prefix_alias; verbose)

    # Ensure that all libraries have SONAMEs
    ensure_sonames!(scan)

    # Solve dynamic linkage, obtaining the output JLLLibraryProduct objects
    get_library_products(jart::JLLArtifactInfo) = filter(x -> isa(x, LibraryProduct), jart.products)
    get_library_products(jll::JLLInfo, platform::AbstractPlatform) = get_library_products(select_platform(jll, platform))
    dep_libs = Dict{Symbol, Vector{JLLLibraryProduct}}(Symbol(dep.name) => get_library_products(dep, platform) for dep in dependencies)
    jll_lib_products = resolve_dynamic_links!(
        scan,
        library_products,
        dep_libs,
        env,
        verbose,
    )

    # Ensure that all libraries and executables have the correct RPATH setup
    rpaths_consistent!(scan, dep_libs; verbose)

    return AuditResult(
        scan,
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
