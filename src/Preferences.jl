## This file contains the various preferences that can be set to change BinaryBuilder2's behavior.
## Currently, this includes functionality such as the following:
#
#  * Storage directories
#    - You can override things like the location where Sources are downloaded to,
#      where `ccache` stores its objects, etc...  By default, these are all stored
#      in scratchspaces in your main Julia depot (usually `~/.julia`)

using Scratch, Preferences

# Used by `with_storage_locations()` in the test suite
const storage_locations = Dict{Symbol, Function}()

macro define_storage_location(name, default, sub_module = nothing)
    refvar = Symbol(string("_", name))
    return quote
        # A caching variable so that we don't have to lookup preferences and scratch
        # spaces too often, as those should not change within a session
        const $(esc(refvar)) = Ref{String}()

        Base.@__doc__ function $(esc(name))()
            global $(esc(refvar))
            if !isassigned($(esc(refvar)))
                return $(esc(name))(@load_preference($(string(name)), $(esc(default))))
            end
            return $(esc(refvar))[]
        end

        function $(esc(name))(new_value::String)
            $(esc(refvar))[] = new_value
            if $(esc(sub_module)) !== nothing
                getproperty($(esc(sub_module)), $(QuoteNode(name)))(new_value)
            else
                return $(esc(refvar))[]
            end
        end

        # Add this storage location to our mapping of storage locations
        storage_locations[Symbol($(string(name)))] = $(esc(name))
    end
end

"""
    source_download_cache()

Returns the path of the directory used to store downloaded sources, e.g. where
`AbstractSource`s get stored when you call `prepare()`.  This can be set
through the `source_download_cache` preference.
"""
@define_storage_location source_download_cache @get_scratch!("source_download_cache") BinaryBuilderSources

"""
    ccache_cache()

Returns the path of the directory used to store `ccache` state.  This can be
set through the `ccache_cache` preference.
"""
@define_storage_location ccache_cache @get_scratch!("ccache_cache")

"""
    builds_dir()

Returns the path of the directory used to store in-progress build files.  This can
be set through the `builds_dir` preference.
"""
@define_storage_location builds_dir @get_scratch!("builds")

"""
    universes_dir()

Returns the path of the directory used to store universes, the collection of mini-
depots used to store registries and environments listing just-built JLLs.  Universes
can be useful to have around for local testing, but are ultimately ephemeral.  This
can be set through the `universes_dir` preference.
"""
@define_storage_location universes_dir @get_scratch!("universes")
