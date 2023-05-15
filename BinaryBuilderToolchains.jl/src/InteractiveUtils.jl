using Scratch

export with_toolchains, runshell

function filter_env_vars(env)
    return filter(env) do (k, v)
        # When running tests from within a `make test` or similar,
        # these can cause real havoc on the make within the toolchain.
        return k ∉ (
            "MAKEFLAGS",
            "GNUMAKEFLAGS",
            # Perhaps I should filter out external `CFLAGS`, `CPPFLAGS`, `LDFLAGS`, etc?
        )
    end
end

const default_appending_keys = Set([
    "PATH",
    "LD_LIBRARY_PATH",
    "DYLD_LIBRARY_PATH",
    "DYLD_FALLBACK_LIBRARY_PATH",
])

"""
    path_appending_merge(env, others...; appending_keys)

Merges `env` dictionaries, but intelligently merges entries that correspond to
`PATH`-like lists, such as `PATH`, `LD_LIBRARY_PATH`, etc... as denoted in
`appending_keys`.  Defaults to `default_appending_keys`.
"""
function path_appending_merge(env, others...; appending_keys::Set{String}=default_appending_keys, sep=":")
    # This is basically taken from the implementation of `merge()`
    env = Base._typeddict(env, others...)

    if Base.haslength(env)
        sz = length(env)
        for other in others
            if Base.haslength(other)
                sz += length(other)
            end
        end
        sizehint!(env, sz)
    end

    for other in others
        for (k, v) in other
            # If this key already exists in `env` and it's an appending key, append it!
            if k ∈ keys(env) && k ∈ appending_keys
                env[k] = string(env[k], sep, v)
            else
                env[k] = v
            end
        end
    end
    return env
end


"""
    with_toolchains(f::Function, toolchains::Vector{AbstractToolchain};
                    env::Dict{String,String} = ENV,
                    deploy_dir::String = mktempdir(),
                    verbose::Bool = false)

Call `f(prefix, env)` with the given `toolchains` deployed and ready to go
within `deploy_root`.  Use this to quickley set up the given toolchains for
usage with `run()` commands as follows:

    with_toolchains(toolchains) do (prefix, env)
        cd(build_path) do
            run(addenv(`make install`, env))
        end
    end

The `prefix` is given in the event that you want to do something with the
deployed toolchains, however most users will not need to use it for anything.
By default, the commands will inherit the current environment, set the `env`
keyword argument to prevent this.  Note that a few known conflicting
environment variables are automatically filtered out from the external
environment, see `filter_env_vars()` for more detail.
"""
function with_toolchains(f::Function, toolchains::Vector{<:AbstractToolchain};
                         deploy_dir::Union{Nothing,String} = nothing,
                         env = ENV,
                         verbose::Bool = false)
    # Prepare all sources.  We do this in one `prepare()` invocation, as
    # there can be efficiency benefits, especially when `deploy()`'ing later.
    srcs = reduce(vcat, toolchain_sources.(toolchains))
    prepare(srcs; verbose)

    function deploy_and_run(prefix)
        # Deploy the sources to `prefix`
        deploy(srcs, prefix)

        # Generate the env, given that we know the `prefix` we've deployed to
        env = reduce(path_appending_merge, [
            toolchain_env.(toolchains, Ref(prefix))...,
            filter_env_vars(env),
        ])
        f(prefix, env)
    end

    # If no `deploy_dir` was given, generate a temporary one that exists only
    # for the lifetime of this function.  Otherwise, use the given directory.
    if deploy_dir === nothing
        mktempdir(deploy_and_run, @get_scratch!("tempdirs"))
    else
        deploy_and_run(deploy_dir)
    end
end

"""
    runshell(toolchains::Vector{AbstractToolchain})

Convenience function to launch a shell with the generated wrapper scripts for
the given toolchains
"""
function runshell(toolchains::Vector{<:AbstractToolchain}; shell::Cmd = `/bin/bash`, kwargs...)
    with_toolchains(toolchains; kwargs...) do (prefix, env)
        run(ignorestatus(setenv(shell, env)))
    end
end

# Easy way to get e.g. a default `CToolchain` for the current host platform
function runshell(toolchain_types::Vector{DataType}; kwargs...)
    platform = CrossPlatform(HostPlatform() => HostPlatform())
    toolchains = [T(platform) for T in toolchain_types]
    return runshell(toolchains; kwargs...)
end
runshell(x::Union{<:AbstractToolchain,Type{<:AbstractToolchain}}; kwargs...) = runshell([x]; kwargs...)
