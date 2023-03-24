using Scratch

export runshell

"""
    runshell(toolchains::Vector{AbstractToolchain})

Convenience function to launch a shell with the generated wrapper scripts for
the given toolchains
"""
function runshell(toolchains::Vector{<:AbstractToolchain})
    srcs = vcat(toolchain_sources.(toolchains)...)
    prepare(srcs)

    # Use a scratch space here so that it's more likely that we have a
    # deployment directory that is on the same filesystem as our artifacts.
    # This allows JLLPrefixes to use the `hardlink` deployment strategy,
    # which is a big time (and space) savings for large artifacts!
    mktempdir(@get_scratch!("tempdirs")) do prefix
        deploy(srcs, prefix)
        
        env = copy(ENV)
        for toolchain in toolchains
            env = toolchain_env(toolchain, prefix; base_ENV=env)
        end
        return run(ignorestatus(addenv(`/bin/bash`, env)))
    end
end

# Easy way to get e.g. a default `CToolchain` for the current host platform
function runshell(toolchain_types::Vector{DataType})
    platform = CrossPlatform(HostPlatform() => HostPlatform())
    toolchains = [T(platform) for T in toolchain_types]
    return runshell(toolchains)
end
runshell(x::Union{<:AbstractToolchain,Type{<:AbstractToolchain}}) = runshell([x])
