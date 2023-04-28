module TestingUtils
using BB2: storage_locations

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


end # module TestingUtils

using .TestingUtils
