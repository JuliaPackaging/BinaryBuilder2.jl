module TestingUtils
using BinaryBuilderPlatformExtensions, BinaryBuilderToolchains
using BinaryBuilder2: storage_locations, make_target_spec_plan

# A helper function to set storage locations, mostly for testing
function with_storage_locations(f::Function, mappings::Dict{Symbol,String})
    old_mappings = Dict{Symbol,String}()

    # First, ensure that all the mappings are kosher
    for var in keys(mappings)
        if !haskey(storage_locations, var)
            error("Invalid storage location variable '$(var)'")
        end
    end

    # Next, save the old values and set the new values:
    for (var, new_value) in mappings
        old_mappings[var] = storage_locations[var]()
        storage_locations[var](new_value)
    end

    # Invoke `f()`
    try
        f()
    finally
        # Restore the old values
        for (var, old_value) in old_mappings
            storage_locations[var](old_value)
        end
    end
end
export with_storage_locations

# Create a temporary directory and redirect _all_ storage locations to subpaths of that temporary directory
function with_temp_storage_locations(f::Function)
    mktempdir() do tempdir
        mappings = Dict(var => joinpath(tempdir, string(var)) for var in keys(storage_locations))
        with_storage_locations(f, mappings)
    end
end
export with_temp_storage_locations

# We often don't allow ccache usage in tests
native_arch = arch(HostPlatform())
alien_arch = native_arch == "x86_64" ? "aarch64" : "x86_64"
native_linux = Platform(native_arch, "linux")
alien_linux = Platform(alien_arch, "linux")
spec_plan = make_target_spec_plan(;
    host_toolchains=[CToolchain(;use_ccache=false), HostToolsToolchain()],
    target_toolchains=[CToolchain(;use_ccache=false)],
)
export native_arch, alien_arch, alien_linux, native_linux, spec_plan


using BinaryBuilder2: BinaryBuilderToolchains, DirectorySource
cxx_string_abi_source =  DirectorySource(joinpath(
    pkgdir(BinaryBuilderToolchains),
    "test",
    "testsuite",
    "CToolchain"
))
export cxx_string_abi_source

end # module TestingUtils

using .TestingUtils
