## This file contains the various preferences that can be set to change BinaryBuilder2's behavior.
## Currently, this includes functionality such as the following:
#
#  * Storage directories
#    - You can override things like the location where Sources are downloaded to,
#      where `ccache` stores its objects, etc...  By default, these are all stored
#      in scratchspaces in your main Julia depot (usually `~/.julia`)

using ScratchSpaceGarbageCollector, Scratch, Preferences, Dates

# Used by `with_storage_locations()` in the test suite
const storage_locations = Dict{Symbol,Ref{Arena}}()

macro define_storage_location(name, sub_module = nothing)
    arena_name = Symbol(string(name, "_arena"))
    initializer = Symbol(string("init_", name))
    return quote
        const $(esc(arena_name)) = Ref{Arena}()
        function $(esc(initializer))()
            # Load values from preferences
            max_age = @load_preference($(string(esc(name), "_max_age_hours")), "240")
            depot_path = @load_preference($(string(esc(name),"_depot")), first(Base.DEPOT_PATH))

            # Initialize our arena
            $(esc(arena_name))[] = Arena(
                @pkg_uuid(),
                $(string(name)),
                [MaxAgePolicy(Hour(parse(Int, max_age)))];
                depot_path,
            )

            # Set submodule functions to point to our function, if necessary.
            if $(esc(sub_module)) !== nothing
                getproperty($(esc(sub_module)), $(QuoteNode(Symbol(string("_", name)))))[] = $(esc(name))
            end
        end
        push!(init_hooks, $(esc(initializer)))

        Base.@__doc__ function $(esc(name))(subpath::AbstractString)
            # This can happen e.g. in precompile workloads
            if !isassigned($(esc(arena_name)))
                $(esc(initializer))()
            end
            return @get_scratch!($(esc(arena_name))[], subpath)
        end

        # Add this storage location to our mapping of storage locations
        storage_locations[Symbol($(string(name)))] = $(esc(arena_name))
    end
end


"""
    source_download_cache()

Returns the path of the directory used to store downloaded sources, e.g. where
`AbstractSource`s get stored when you call `prepare()`.  This can be set
through the `source_download_cache` preference.
"""
@define_storage_location source_download_cache BinaryBuilderSources



"""
    ccache_cache()

Returns the path of the directory used to store `ccache` state.  This can be
set through the `ccache_cache` preference.
"""
@define_storage_location ccache_cache

"""
    builds_dir()

Returns the path of the directory used to store in-progress build files.  This can
be set through the `builds_dir` preference.
"""
@define_storage_location builds_dir

"""
    universes_dir()

Returns the path of the directory used to store universes, the collection of mini-
depots used to store registries and environments listing just-built JLLs.  Universes
can be useful to have around for local testing, but are ultimately ephemeral.  This
can be set through the `universes_dir` preference.
"""
@define_storage_location universes_dir
