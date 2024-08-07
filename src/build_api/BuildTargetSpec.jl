using BinaryBuilderToolchains: gcc_platform

struct BuildTargetSpec
    name::String
    platform::CrossPlatform
    toolchains::Vector{AbstractToolchain}
    dependencies::Vector{AbstractSource}

    # Flags can be one of:
    #  `:host`    -- this is a toolchain for the build machine itself
    #  `:default` -- this is the "default" toolchain, and should be invokable by `cc`, etc...
    flags::Set{Symbol}

    function BuildTargetSpec(name::AbstractString,
                            platform::CrossPlatform,
                            toolchains::Vector,
                            dependencies::Vector,
                            flags::Union{Vector,Set})
        name = String(name)
        flags = Set{Symbol}(flags)
        toolchains = Vector{ConvenienceToolchain}(toolchains)
        dependencies = Vector{ConvenienceSource}(dependencies)

        # Concretize dependencies for `platform`
        dependencies = apply_platform.(dependencies, (platform.target,))

        # Concretize toolchains for `platform`
        toolchains = map(toolchains) do toolchain
            toolchain = alter_toolchain(name, flags, target_prefix(name, platform, flags), toolchain)
            return apply_platform(toolchain, platform)
        end

        return new(name, platform, toolchains, dependencies, flags)
    end
end

function Base.show(io::IO, bts::BuildTargetSpec)
    print(io, "TargetSpec($(bts.name), $(string(bts.platform)), $(bts.toolchains))")
end

# This is where JLLSources get installed
function target_prefix(name::String, platform::CrossPlatform, flags::Set{Symbol})
    if :host ∈ flags
        return "/usr/local"
    else
        return string("/workspace/destdir/$(name)-$(triplet(platform.target))")
    end
end
target_prefix(bts::BuildTargetSpec) = target_prefix(bts.name, bts.platform, bts.flags)
# This is where toolchains get installed
function toolchain_prefix(bts::BuildTargetSpec, ::AbstractToolchain)
    return string("/opt/$(bts.name)-$(triplet(bts.platform.target))")
end
# The HostToolsToolchain gets put into its own place to minimize
# conflicts with bootstrap CToolchains.
toolchain_prefix(bts::BuildTargetSpec, ::HostToolsToolchain) = "/opt/$(bts.name)-tools"

function alter_toolchain(name::String, flags::Set{Symbol}, target_prefix::String, pw::PlatformlessWrapper{CToolchain})
    # Alter this object to contain extra flags, prefixes, etc...
    pw = copy(pw)

    # Add CFLAGS and LDFLAGS for the install prefix
    pw.kwargs[:extra_cflags] = String[
        get(pw.kwargs, :extra_cflags, String[])...,
        "-I$(target_prefix)/include",
    ]
    pw.kwargs[:extra_ldflags] = String[
        get(pw.kwargs, :extra_ldflags, String[])...,
        "-L$(target_prefix)/lib",
    ]

    # wrapper_prefixes control the naming of the wrapper bash scripts for the toolchains
    wrapper_prefixes = String[]
    # env_prefixes control the naming of environment variables that point to our wrappers
    env_prefixes = String[]
    
    # if `name` is "host", this makes a "host-x86_64-linux-gnu-gcc" wrapper.
    push!(wrapper_prefixes, string(name, "-\${triplet}-"))
    push!(wrapper_prefixes, "\${triplet}-")
    # if `name` is `"host`", this makes "$HOSTCC" and "$HOST_CC" envvars
    append!(env_prefixes, [
        uppercase(name),
        string(uppercase(name), "_"),
    ])

    # If `:default` is set in our flags, make a `x86_64-linux-gnu-gcc` wrapper
    # as well as a `gcc` wrapper and point `$CC` at our compiler.
    if :default ∈ flags
        append!(wrapper_prefixes, ["\${triplet}-", ""])
        push!(env_prefixes, "")
    end
    pw.kwargs[:wrapper_prefixes] = wrapper_prefixes
    pw.kwargs[:env_prefixes] = env_prefixes
    return pw
end
alter_toolchain(::String, ::Set{Symbol}, ::String, pw::PlatformlessWrapper) = pw
alter_toolchain(::String, ::Set{Symbol}, ::String, toolchain::AbstractToolchain) = toolchain

# Each toolchain target gets its own directory-like environment variables
function add_target_dir_envs(env, target_prefix_path, platform, name)
    # If `name` is `""`, we want to export things like `${prefix}`.
    # If `name` is `"target"`, we want to export things like `${target_prefix}`.
    function name_maker(name, attribute)
        if isempty(name)
            return attribute
        else
            return string(name, "_", attribute)
        end
    end

    return path_appending_merge(env, Dict(
        name => "$(triplet(gcc_platform(platform)))",
        "bb_full_$(name)" => "$(triplet(platform))",
        name_maker(name, "prefix") => target_prefix_path,
        name_maker(name, "bindir") => "$(target_prefix_path)/bin",
        name_maker(name, "libdir") => "$(target_prefix_path)/lib",
        name_maker(name, "shlibdir") => Sys.iswindows(platform) ? "$(target_prefix_path)/bin" : "$(target_prefix_path)/lib",
        name_maker(name, "includedir") => "$(target_prefix_path)/include",
        name_maker(name, "dlext") => dlext(platform)[2:end],
        name_maker(name, "nbits") => string(nbits(platform)),
    ))
end

function apply_toolchains(bts::BuildTargetSpec,
                          env::Dict{String,String},
                          source_trees::Dict{String,Vector{AbstractSource}})
    # Set target dir envs such as `${target_prefix}`
    env = add_target_dir_envs(env, target_prefix(bts), bts.platform.target, bts.name)
    if :default ∈ bts.flags
        # If we're the default, also set `${prefix}`
        env = add_target_dir_envs(env, target_prefix(bts), bts.platform.target, "")
    end

    for toolchain in bts.toolchains
        # Add toolchain environment variables
        tc_prefix = toolchain_prefix(bts, toolchain)
        env = path_appending_merge(env, toolchain_env(toolchain, tc_prefix))

        # Add the source trees for these toolchains
        if !haskey(source_trees, tc_prefix)
            source_trees[tc_prefix] = AbstractSource[]
        end
        append!(source_trees[tc_prefix], toolchain_sources(toolchain))
    end

    return env, source_trees
end

function get_default_target_spec(specs::Vector{BuildTargetSpec})
    idx = findfirst(bts -> :default ∈ bts.flags, specs)
    if idx === nothing
        return nothing
    end
    return specs[idx]
end
function get_host_target_spec(specs::Vector{BuildTargetSpec})
    idx = findfirst(bts -> :host ∈ bts.flags, specs)
    if idx === nothing
        return nothing
    end
    return specs[idx]
end


# PlatformlessWrapper support
function BuildTargetSpec(name::String,
                         toolchains::Vector,
                         dependencies::Vector,
                         flags::Set{Symbol})
    toolchains = Vector{PlatformlessWrapper{<:AbstractToolchain}}(toolchains)
    dependencies = Vector{ConvenienceSource}(dependencies)
    return PlatformlessWrapper{BuildTargetSpec}(;args=[name, toolchains, dependencies, flags])
end

function apply_platform(pw::PlatformlessWrapper{BuildTargetSpec}, platform::CrossPlatform)
    name, toolchains, dependencies, flags = pw.args
    return BuildTargetSpec(
        name,
        platform,
        toolchains,
        dependencies,
        flags,
    )
end
function PlatformlessWrapper(bts::BuildTargetSpec)
    return BuildTargetSpec(
        bts.name,
        PlatformlessWrapper.(bts.toolchains),
        PlatformlessWrapper.(bts.dependencies),
        bts.flags,
    )
end
