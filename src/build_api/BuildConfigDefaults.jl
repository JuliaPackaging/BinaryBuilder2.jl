using StyledStrings
using BinaryBuilderToolchains: gcc_platform
export supported_platforms, make_target_spec_plan, apply_spec_plan

# Default to using a Linux host with the same host arch as our machine
# This just makes qemu-user-static's job easier.
default_host() = Platform(arch(HostPlatform()), "linux")

function make_target_spec_plan(;host_toolchains::Vector = [CToolchain(), HostToolsToolchain()],
                                target_toolchains::Vector = [CToolchain()],
                                target_dependencies::Vector = [],
                                host_dependencies::Vector = [],
                                cross_compiler::Bool = false)
    host_toolchains = Vector{PlatformlessWrapper{<:AbstractToolchain}}(host_toolchains)
    target_toolchains = Vector{PlatformlessWrapper{<:AbstractToolchain}}(target_toolchains)
    host_dependencies = Vector{ConvenienceSource}(host_dependencies)
    target_dependencies = Vector{ConvenienceSource}(target_dependencies)
    # Cross-compilation terminology is confusing.  Autotools defines the following terms:
    #  - `build`: the machine that is currently running your compilers
    #  - `host`: the machine that will run the built code
    #  - `target`: the machine that will run the code built by the code currently being built.
    # However, in the BB2 world, we typically refer to things as just `host` and `target`,
    # where `target` can itself be a `CrossPlatform` that denotes that the thing we're building
    # is itself a cross-compiler. that runs on `target.host` and compiles for `target.target`.
    # Here we build a mapping from environment variable names to the actual platform objects,
    # and in the rare event that we are dealing with a cross-compiler being built, we use the
    # autotools names `build/host/target`, but in the other 99% of all cases, we use just the
    # `host/target` names.
    if cross_compiler
        return [
            BuildTargetSpec(
                "build",
                host_toolchains,
                host_dependencies,
                Set([:host]),
            ),
            BuildTargetSpec(
                "host",
                target_toolchains,
                target_dependencies,
                Set([:default]),
            ),
            BuildTargetSpec(
                "target",
                target_toolchains,
                AbstractSource[],
                Set(Symbol[]),
            ),
        ]
    else
        return [
            BuildTargetSpec(
                "host",
                host_toolchains,
                host_dependencies,
                Set([:host]),
            ),
            BuildTargetSpec(
                "target",
                target_toolchains,
                target_dependencies,
                Set([:default]),
            ),
        ]
    end
end

function apply_spec_plan(target_spec_plan::Vector,
                         host::Platform,
                         target::AbstractPlatform)
    target_spec_plan = Vector{PlatformlessWrapper{BuildTargetSpec}}(target_spec_plan)

    # Separate out our `host` and `default` specs, which we must always have.
    flags(plan::PlatformlessWrapper{BuildTargetSpec}) = plan.args[4]
    host_specs = filter(plan -> :host ∈ flags(plan), target_spec_plan)
    default_specs = filter(plan -> :default ∈ flags(plan), target_spec_plan)

    if length(host_specs) != 1 || length(default_specs) != 1
        throw(ArgumentError("apply_spec_plan() requires exactly 1 `:host` spec (got $(length(host_specs))), and 1 `:default` spec (got $(length(default_specs))!"))
    end

    target_specs = BuildTargetSpec[
        # We always have a "host" (or "build", see `default_target_spec_plan`) target spec,
        # which refers to the machine these tools are running on.
        apply_platform(only(host_specs), CrossPlatform(host => host)),
        # The "default" spec refers to the machine that `cc` builds for, which is
        # usually the "target" (but is the "host" in the event that we're building
        # a cross-compiler with these cross-compilers).
        apply_platform(only(default_specs), CrossPlatform(host => host_if_crossplatform(target))),
    ]
    if isa(target, CrossPlatform)
        if length(target_spec_plan) == 3
            other_specs = filter(plan -> !any((:host, :default) .∈ (flags(plan),)), target_spec_plan)
            # If we're dealing with a cross-compiler, add on the "target" spec.
            push!(target_specs, apply_platform(only(other_specs), CrossPlatform(host => target.target)))
        else
            throw(ArgumentError("For cross-compilers, you must specify 3 target spec plans, see `is_crosscompiler` in `default_target_spec_plan()`"))
        end
    else
        if length(target_spec_plan) != 2
            throw(ArgumentError("Non-canadian cross builds require 2 target spec plans"))
        end
    end
    return target_specs
end

function default_spec_generator(;kwargs...)
    spec_plan = make_target_spec_plan(;kwargs...)
    return (host, platform) -> apply_spec_plan(spec_plan, host, platform)
end

function status_style(status::Symbol)
    return Dict{Symbol,Symbol}(
        :success => :green,
        :failed => :red,
        :errored => :red,
        :cached => :green,
        :skipped => :blue,
    )[status]
end

function BinaryBuilderToolchains.supported_platforms(toolchain_types::Vector = [CToolchain]; experimental::Bool = false)
    toolchain_types = Vector{Type}(toolchain_types)

    # Drop host toolchain, we don't care about that.
    filter!(t -> t != HostToolsToolchain, toolchain_types)

    platform_sets = supported_platforms.(toolchain_types; experimental)
    return intersect(platform_sets...)
end
