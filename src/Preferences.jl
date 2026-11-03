## This file contains the various preferences that can be set to change BinaryBuilder2's behavior.
## Currently, this includes functionality such as the following:
#
#  * Storage directories
#    - You can override things like the location where Sources are downloaded to,
#      where `ccache` stores its objects, etc...  By default, these are all stored
#      in scratchspaces in your main Julia depot (usually `~/.julia`)

using ScratchSpaceGarbageCollector, Scratch, Preferences, Dates
using Base.ScopedValues: ScopedValue

"""
    StorageLocation

A named directory tree managed by a scratch-space `Arena`.  Unless overridden, the
`Arena` is created once per process from the `<name>_depot` and `<name>_max_age_hours`
preferences, the first time it is requested via `arena()`.  It can be replaced
within a dynamic scope through the `override` `ScopedValue`, e.g.
`with(f, loc.override => other_arena)`.
"""
struct StorageLocation
    name::String
    default::OncePerProcess{Arena}
    override::ScopedValue{Union{Nothing,Arena}}
end

function StorageLocation(name::String)
    default = OncePerProcess{Arena}() do
        max_age = @load_preference(string(name, "_max_age_hours"), "240")
        depot_path = @load_preference(string(name, "_depot"), first(Base.DEPOT_PATH))
        return Arena(
            @pkg_uuid(),
            name,
            [MaxAgePolicy(Hour(parse(Int, max_age)))];
            depot_path,
        )
    end
    return StorageLocation(name, default, ScopedValue{Union{Nothing,Arena}}(nothing))
end

arena(loc::StorageLocation) = something(loc.override[], loc.default())

# All storage locations, keyed by name.  Used by `with_storage_locations()` in the test suite.
const storage_locations = Dict{Symbol,StorageLocation}()

macro define_storage_location(name, sub_module = nothing)
    location_name = Symbol(string(name, "_location"))
    initializer = Symbol(string("init_", name))
    return quote
        const $(esc(location_name)) = StorageLocation($(string(name)))
        function $(esc(initializer))()
            # Set submodule functions to point to our function, if necessary.
            if $(esc(sub_module)) !== nothing
                getproperty($(esc(sub_module)), $(QuoteNode(Symbol(string("_", name)))))[] = $(esc(name))
            end
        end
        push!(init_hooks, $(esc(initializer)))

        Base.@__doc__ function $(esc(name))(subpath::AbstractString)
            return @get_scratch!(arena($(esc(location_name))), subpath)
        end

        storage_locations[Symbol($(string(name)))] = $(esc(location_name))
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
    jll_resolve_cache()

Returns the path of the directory that maps a set of `JLLSource` specifications to the
artifact paths they resolved to.  Note that this must live in a fixed depot rather than
`Base.DEPOT_PATH[1]`, as `in_universe()` repoints that at an ephemeral universe depot,
and anything cached there is thrown away when the universe is.  This can be set through
the `jll_resolve_cache` preference.
"""
@define_storage_location jll_resolve_cache BinaryBuilderSources

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

"""
    access_tokens

Tokens used to authenticate the `git` and `gh` operations we run, (e.g. pushing JLLs and
registry updates, or cloning private repositories for `GitSource`s) set through the
`access_tokens` preference.  This is a tree of nested
tables keyed by host, organization and repository.  A token given in place of a table
applies to everything beneath that point, and more specific entries win, e.g.:

    [access_tokens."github.com"]
    JuliaBinaryWrappers = "<token for all of JuliaBinaryWrappers>"

    [access_tokens."github.com".JuliaRegistries]
    General = "<token for JuliaRegistries/General>"

Anything without a configured token uses the default credentials, (e.g. `gh`'s login).
This can also be set as a preference of `BinaryBuilderGitUtils`; if both are set, ours
replaces it entirely.
"""
function init_access_tokens()
    if @has_preference("access_tokens")
        set_access_tokens!(@load_preference("access_tokens"))
    end
end
push!(init_hooks, init_access_tokens)
