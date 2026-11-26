module BinaryBuilderAuditor

using Base.BinaryPlatforms
export audit!, AuditResult

include("Utils.jl")
include("JuliaLibstdcxx.jl")
include("SystemLibraries.jl")
include("AuditorToolchain.jl")
include("Scanning.jl")
include("RuntimeRequirements.jl")
include("AuditResult.jl")
include("AuditConfig.jl")
include("AuditInfo.jl")
include("LdScriptParser.jl")
include("passes/RelativeSymlink.jl")
include("passes/DanglingSymlinks.jl")
include("passes/PkgConfig.jl")
include("passes/LibtoolArchives.jl")
include("passes/LibrarySONAME.jl")
include("passes/DynamicLinkage.jl")
include("passes/CodeSigning.jl")
include("passes/StaticLibraries.jl")
include("passes/Licenses.jl")
include("passes/RuntimeRequirementChecks.jl")
include("passes/PackageChecks.jl")

function audit!(prefix::String,
                products::Vector{<:AbstractProduct},
                info::AuditInfo;
                prefix_alias::String = prefix,
                platform::AbstractPlatform = HostPlatform(),
                env::Dict{String,String} = Dict{String,String}(
                    "prefix" => prefix,
                    "bb_full_target" => triplet(platform),
                ),
                os_version::Union{Nothing,VersionNumber} = Base.BinaryPlatforms.os_version(platform),
                verbose::Bool = false,
                config::AuditConfig = AuditConfig(),
                readonly::Bool = false)
    # First, scan the prefix:
    scan = scan_files(
        prefix,
        platform,
        products,
        env;
        prefix_alias,
    )
    result = AuditResult(scan)

    # First pass; symlink translation
    if !readonly
        run_pass(result, config, :absolute_to_relative_symlinks, "absolute_to_relative_symlinks!") do
            absolute_to_relative_symlinks!(result, prefix_alias)
        end
    end

    # Ensure that every symlink points at something that exists
    run_pass(result, config, :dangling_symlinks, "dangling_symlinks") do
        dangling_symlinks(result, prefix_alias)
    end

    # Make pkg-config files relocatable
    if !readonly
        run_pass(result, config, :relocate_pkgconfig_files, "relocate_pkgconfig_files!") do
            relocate_pkgconfig_files!(result, prefix_alias)
        end
    end

    # Remove libtool archives, which hardcode build paths
    if !readonly
        run_pass(result, config, :remove_libtool_archives, "remove_libtool_archives!") do
            remove_libtool_archives!(result)
        end
    end

    # Ensure that all libraries have SONAMEs
    if !readonly
        run_pass(result, config, :ensure_sonames, "ensure_sonames!") do
            ensure_sonames!(result)
        end
    end

    # Point dependencies recorded by absolute in-prefix path at `@rpath` instead
    if !readonly
        run_pass(result, config, :relink_absolute_dependencies, "relink_absolute_dependencies!") do
            relink_absolute_dependencies!(result; prefix_alias)
        end
    end

    # Solve dynamic linkage, deriving each library product's record
    resolve_dynamic_links!(result, info; config.extra_system_libraries)

    # Describe the static archive of each library product, if any, plus any standalone static libraries
    resolve_static_libraries!(result, info)

    # Ensure that all libraries and executables have the correct RPATH setup
    if !readonly
        run_pass(result, config, :rpaths_consistent, "rpaths_consistent!") do
            rpaths_consistent!(result, info; prefix_alias, config.extra_system_libraries)
        end
    end

    # Re-sign the Mach-O binaries (macOS only); this must follow every pass that modifies binaries
    if !readonly
        ensure_codesigned!(result)
    end

    # Ensure that there are some licenses
    run_pass(result, config, :licenses_present, "licenses_present") do
        licenses_present(result)
    end

    # Record what the binaries need from their runtime, and check what the platform decides
    record_runtime_requirements!(result)
    run_pass(result, config, :check_runtime_requirements, "runtime_requirements") do
        check_runtime_requirements(result; os_version)
    end

    if verbose
        show(result.pass_results)
    end

    return result
end


# List of audit passes, arranged in-order:
#
# prefix-wide passes:
#  - [!] symlink absolute -> relative translation
#  - dangling symlink check
#  - [!] pkg-config file relocation
# object passes:
#  - ISA check
#  - OS ABI check
#  - [!] executable bit setting (mostly useful for Windows)
#  - libgfortran version check
#  - cxxabi version check
#  - CSL lib check
#  - [!] dylib check
#  - [!] ad-hoc code signing (macOS)
# library passes:
#  - dlopen() check?
#  - [!] SONAME and symlink check
# prefix-wide passes:
#  - [!] symlink removal (windows)
#  - [!] DLL -> bin (windows)
#  - [!] implib timestamp normalization (windows)
#  - license file check
#  - absolute path check
#  - case sensitivity check


include("precompile.jl")

end # module
