using TimerOutputs, Sandbox, BinaryBuilderToolchains
using BinaryBuilderToolchains: gcc_platform, gcc_target_triplet, platform
using Pkg.Types: PackageSpec
import BinaryBuilderSources: prepare, deploy

export BuildConfig

"""
    BuildConfig

This structure holds all of the inputs that are needed to generate a build of a software
project in the build environment.  Things such as the project name, the list of sources,
the build script, the dependencies, etc... are all listed within this structure.  Once
the user calls `build!()`, each `BuildConfig` will get a `BuildResult` packed into the
overall `BuildMeta` object.
"""
struct BuildConfig
    # The name of the package being built.  This is exported as an environment variable during build
    # so that internal tooling such as "install_license" can install into intelligent paths.
    src_name::String

    # The source version; this may not be what the resultant JLL gets published under, but it will
    # be recorded as metadata in the JLL itself.
    src_version::VersionNumber

    # PackageSpec's that we depend on (for future consumption by the packaging step)
    pkg_deps::Vector{PackageSpec}

    # AbstractSources that must be installed in the build environment.
    # Contains sources, host dependencies, target dependencies, and toolchains.
    # Organized by installation prefix (e.g. `/opt/$(triplet)` for toolchains,
    # `/workspace/srcdir` for sources, `/workspace/destdir/$(triplet)` for dependencies, etc...)
    source_trees::Dict{String,Vector{<:AbstractSource}}
    env::Dict{String,String}

    # Flags that influence the build environment and the generated compiler wrappers
    allow_unsafe_flags::Bool
    lock_microarchitecture::Bool

    # Bash script that will perform the actual build itself
    script::String

    # The cross-platform we're using for this build
    platform::CrossPlatform
    #concrete_target::AbstractPlatform

    # We're going to store all sorts of timing information about our build in here
    to::TimerOutput

    function BuildConfig(src_name::AbstractString,
                         src_version::VersionNumber,
                         sources::Vector{<:AbstractSource},
                         dependencies::Vector{<:AbstractSource},
                         host_dependencies::Vector{<:AbstractSource},
                         script::AbstractString,
                         target::AbstractPlatform;
                         host::AbstractPlatform = Platform("x86_64", "linux"),
                         toolchains::Vector{<:AbstractToolchain} = default_toolchains(CrossPlatform(host, target)),
                         allow_unsafe_flags::Bool = false,
                         lock_microarchitecture::Bool = true,
                         target_deps::Vector{<:AbstractSource} = AbstractSource[],
                         kwargs...,
                         )
        # We're building for this cross_platform
        cross_platform = CrossPlatform(
            host,
            target,
        )

        # Helper functions to determine where different types of toolchains end up
        toolchain_prefix(toolchain::AbstractToolchain) = "/opt/$(gcc_target_triplet(platform(toolchain)))"
        toolchain_prefix(toolchain::HostToolsToolchain) = "/opt/host"

        source_trees = Dict{String,Vector{AbstractSource}}(
            "/workspace/destdir/$(triplet(cross_platform.target))" => dependencies,
            "/usr/local" => host_dependencies,
            "/workspace/srcdir" => sources,
        )
        env = Dict{String,String}(
            "PATH" => "/usr/local/bin:/usr/local/sbin:/usr/bin:/usr/sbin:/bin:/sbin",
            "TERM" => "xterm-256color",
            "WORKSPACE" => "/workspace",
            "prefix" => "/workspace/destdir/$(triplet(cross_platform.target))",
            "target" => "$(gcc_target_triplet(cross_platform.target))",
            "bb_full_target" => "$(triplet(cross_platform.target))",
            "MACHTYPE" => "$(gcc_target_triplet(cross_platform.host))",
            "bb_full_host" => "$(triplet(cross_platform.host))",
        )
        for toolchain in toolchains
            source_trees[toolchain_prefix(toolchain)] = toolchain_sources(toolchain)
            env = toolchain_env(toolchain, toolchain_prefix(toolchain); base_env = env)
        end

        return new(
            String(src_name),
            src_version,
            [d.package for d in dependencies if isa(JLLSource, d)],
            source_trees,
            env,
            allow_unsafe_flags,
            lock_microarchitecture,
            String(script),
            cross_platform,
            TimerOutput(),
        )
    end
end

# Helper function to better control when we download all our deps
# Ideally, this would be paralellized somehow.
function prepare(config::BuildConfig; verbose::Bool = false)
    @timeit config.to "prepare() - source" begin
        for (prefix, deps) in config.source_trees
            @timeit config.to prefix begin
                prepare(deps; verbose)
            end
        end
    end
end

struct DeployedBuildConfig
    config::BuildConfig

    # The temporary directory where we'll do the build
    # this needs to be cleaned up eventually.
    deploy_root::String

    # Data for our eventual SandboxConfig
    mounts::Dict{String,MountInfo}
end

function deploy(config::BuildConfig)
    deploy_root = mktempdir(builds_dir())

    mounts = Dict{String,MountInfo}(
        "/" => MountInfo(Sandbox.debian_rootfs(;platform = config.platform.host), MountType.Overlayed),
    )

    @timeit config.to "deploy() - source_trees" begin
        for (prefix, srcs) in config.source_trees
            mount_type = MountType.Overlayed

            @error("TODO: Experiment with removing files from the lower directory and see what happens in the overlay?!")
            # Special-case some mounts to be read-write so we can get the result back out again
            #if prefix ∈ ("/workspace/srcdir", "/workspace/destdir/$(triplet(config.platform.target))")
            #    mount_type = MountType.ReadWrite
            #end

            # Strip leading slashes so that `joinpath()` works as expected
            host_path = joinpath(deploy_root, lstrip(prefix, '/'))
            mounts[prefix] = MountInfo(host_path, mount_type)
            mkpath(host_path)
            @timeit config.to prefix deploy(srcs, host_path)
        end
    end

    return DeployedBuildConfig(
        config,
        deploy_root,
        mounts,
    )
end

function build(dconfig::DeployedBuildConfig)
    sandbox_config = SandboxConfig(dconfig; verbose)
    with_executor() do exe
        run(exe, sandbox_config, shell)
    end
end

function Sandbox.SandboxConfig(dconfig::DeployedBuildConfig; verbose::Bool = false)
    return SandboxConfig(
        dconfig.mounts,
        dconfig.config.env;
        hostname = "bb8",
        pwd = "/workspace/srcdir",
        persist = true,
        stdin,
        stdout,
        stderr,
        verbose,
        multiarch=[dconfig.config.platform.host],
    )
end

function runshell(dconfig::DeployedBuildConfig; verbose::Bool = false, shell::Cmd=`/bin/bash`)
    sandbox_config = SandboxConfig(dconfig; verbose)
    with_executor() do exe
        run(exe, sandbox_config, shell)
    end
end
function runshell(config::BuildConfig; verbose::Bool = false, kwargs...)
    prepare(config; verbose)
    runshell(deploy(config); verbose, kwargs...)
end
