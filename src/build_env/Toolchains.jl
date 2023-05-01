using BinaryBuilderToolchains: gcc_platform, gcc_target_triplet

#=
"""
    deduplicate_jlls(jlls::Vector{JLLSource})

When compiling for the native architecture, our host and target triplets are
the same; this results in both host dependencies and target dependencies co-
existing in the same location.
"""
function deduplicate_jlls(jlls::Vector{JLLSource})
    seen_jlls = Dict{String,JLLSource}()
    for jll in jlls
        name = jll.package.name
        if name ∈ keys(seen_jlls)
            new_version = seen_jlls[name].package.version ∩ jll.package.version
            if isempty(new_version)
                throw(ArgumentError("Impossible constraints on $(name): $(seen_jlls[name].package.version) ∩ $(jll.package.version)"))
            end
            seen_jlls[name].package.version = new_version
        end
    end
    return values(seen_jlls)
end
=#

function default_toolchains(platform::CrossPlatform, host_deps::Vector{<:AbstractSource} = AbstractSource[])
    toolchains = AbstractToolchain[]

    function extra_flags(platform, prefix)
        ldflags = [
            "-L$(prefix)/lib",
        ]
        if nbits(platform) == 64
            push!(ldflags, "-L$(prefix)/lib64")
        end

        return (;
            extra_ldflags=ldflags,
            extra_cflags=["-I$(prefix)/include"],
        )
    end
    
    # We _always_ have the target compiler, and it's typically the default toolchain
    push!(toolchains, CToolchain(platform; default_ctoolchain = true, extra_flags(platform.target, "/workspace/destdir/$(triplet(platform.target))")...))

    # The host toolchain (even if it's the same as the default toolchain) gets
    # different wrappers with different default flags.
    push!(toolchains, CToolchain(CrossPlatform(platform.host, platform.host); host_ctoolchain = true, extra_flags(platform.host, "/usr/local")...))

    push!(toolchains, HostToolsToolchain(platform.host, host_deps))
    return toolchains
end
