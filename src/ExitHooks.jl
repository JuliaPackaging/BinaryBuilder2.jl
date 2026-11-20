# We explicitly order these operations to ensure that, e.g. all cleanups happen before
@kwdef struct ExitHooks
    # Things to save
    build_caches::Vector{BuildCache} = BuildCache[]

    # Things to cleanup
    universes::Vector{Universe} = Universe[]
    build_results::Vector{BuildResult} = BuildResult[]

    # Metas to check, to ensure that all build_hash'es were properly consumed
    build_metas::Vector{BuildMeta} = BuildMeta[]
end

Base.push!(eh::ExitHooks, bc::BuildCache) = push!(eh.build_caches, bc)
Base.push!(eh::ExitHooks, uni::Universe) = push!(eh.universes, uni)
Base.push!(eh::ExitHooks, br::BuildResult) = push!(eh.build_results, br)
Base.push!(eh::ExitHooks, meta::BuildMeta) = push!(eh.build_metas, meta)

"""
    atexit(eh::ExitHooks)

Perform cleanup of all objects registered with `eh`.  This is called automatically
at process exit, but can be eagerly called at any time.
"""
function Base.atexit(eh::ExitHooks; exit_process::Bool=true)
    # Check build hashes first: recomputing them needs the universe depots that
    # the cleanups below may delete.
    hash_check_failed = false
    for meta in copy(eh.build_metas)
        try
            check_build_hashes_consumed(meta)
        catch e
            if isa(e, UnconsumedBuildHashesError)
                @error(sprint(showerror, e))
            else
                @error("Unable to check build hashes", exception=(e, catch_backtrace()))
            end
            hash_check_failed = true
        end
    end
    empty!(eh.build_metas)

    for bc in eh.build_caches
        try
            save_cache(bc)
        catch e
            @warn("Unable to save cache", cache_dir=bc.cache_dir, exception=(e, catch_backtrace()))
        end
    end
    empty!(eh.build_caches)

    for uni in eh.universes
        try
            cleanup(uni)
        catch e
            @warn("Unable to cleanup universe", depot_path=uni.depot_path, exception=(e, catch_backtrace()))
        end
    end
    empty!(eh.universes)
    for br in eh.build_results
        try
            Sandbox.cleanup(br)
        catch e
            @warn("Unable to cleanup BuildResult", exception=(e, catch_backtrace()))
        end
    end
    empty!(eh.build_results)

    if hash_check_failed && exit_process
        exit(1)
    end
end

const get_exit_hooks = Base.OncePerProcess{ExitHooks}() do
    eh = ExitHooks()
    atexit() do
        atexit(eh)
    end
    return eh
end
