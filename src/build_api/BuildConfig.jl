using Base.BinaryPlatforms
using TimerOutputs, Sandbox, BinaryBuilderToolchains
using BinaryBuilderToolchains: gcc_platform, gcc_target_triplet, platform, path_appending_merge
using Pkg.Types: PackageSpec
import BinaryBuilderSources: prepare, deploy
using MultiHashParsing

export BuildConfig, build!

"""
    BuildConfig

This structure holds all of the inputs that are needed to generate a build of a software
project in the build environment.  Things such as the project name, the list of sources,
the build script, the dependencies, etc... are all listed within this structure.  Once
the user calls `build!()`, each `BuildConfig` will get a `BuildResult` packed into the
overall `BuildMeta` object.
"""
struct BuildConfig
    # The BuildMeta object that controls all manner of things about the build.
    meta::AbstractBuildMeta

    # The name of the package being built.  This is exported as an environment variable during build
    # so that internal tooling such as "install_license" can install into intelligent paths.
    src_name::String

    # The source version; this may not be what the resultant JLL gets published under, but it will
    # be recorded as metadata in the JLL itself.  We store this as a string because upstream version
    # numbers aren't always VersionNumber-compatible, and we want to store the precise upstream version.
    src_version::String

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

    # We're going to store all sorts of timing information about our build in here
    to::TimerOutput

    function BuildConfig(meta::AbstractBuildMeta,
                         src_name::AbstractString,
                         src_version::Union{VersionNumber, String},
                         sources::Vector{<:AbstractSource},
                         target_dependencies::Vector{<:AbstractSource},
                         host_dependencies::Vector{<:AbstractSource},
                         script::AbstractString,
                         target::AbstractPlatform;
                         host::AbstractPlatform = default_host(),
                         toolchains::Vector{<:AbstractToolchain} = default_toolchains(CrossPlatform(host, target)),
                         allow_unsafe_flags::Bool = false,
                         lock_microarchitecture::Bool = true,
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
            # Target dependencies
            "/workspace/destdir/$(triplet(cross_platform.target))" => target_dependencies,
            "/usr/local" => [
                # Host dependencies (not including toolchains, those go in `/opt/$(host_triplet)`)
                host_dependencies...;
                # Also, our `BB` resources
                DirectorySource(joinpath(Base.pkgdir(@__MODULE__), "share", "bash_scripts"); target="share/bb")
            ],
            # The actual sources we're gonna build
            "/workspace/srcdir" => sources,

            # Metadata such as our build script
            "/workspace/metadir" => [GeneratedSource() do out_dir
                script_path = joinpath(out_dir, "build_script.sh")
                open(script_path, write=true) do io
                    println(io, "#!/bin/bash")
                    println(io, "set -euo pipefail")
                    println(io, "source /usr/local/share/bb/save_env_hook")
                    println(io, script)
                    println(io, "exit 0")
                end
                chmod(script_path, 0o755)
                cp(joinpath(Base.pkgdir(@__MODULE__), "share", "bash_scripts", "save_env_hook"),
                   joinpath(out_dir, ".bashrc"); force=true)
            end]
        )
        env = Dict{String,String}()
        for toolchain in toolchains
            tc_prefix = toolchain_prefix(toolchain)
            if !haskey(source_trees, tc_prefix)
                source_trees[tc_prefix] = AbstractSource[]
            end
            append!(source_trees[tc_prefix], toolchain_sources(toolchain))
            env = path_appending_merge(env, toolchain_env(toolchain, tc_prefix))
        end

        # Deduplicate JLLs; we tend to have a lot of duplicates, this ensures that
        # versions are consistent within a single prefix, and that we don't waste
        # time deploying the same JLL over and over again to the same prefix.
        # (Zlib_jll, I'm looking at you, you desirable little chap).
        for (prefix, sources) in source_trees
            jlls = JLLSource[s for s in sources if isa(s, JLLSource)]
            non_jlls = [s for s in sources if !isa(s, JLLSource)]
            jlls = deduplicate_jlls(jlls)
            source_trees[prefix] = [non_jlls..., jlls...]
        end

        prefix = "/workspace/destdir/$(triplet(cross_platform.target))"
        host_prefix = "/workspace/destdir/$(triplet(cross_platform.host))"
        env = path_appending_merge(env, Dict(
            # Things to work well with a shell
            "PATH" => "/usr/local/bin:/usr/local/sbin:/usr/bin:/usr/sbin:/bin:/sbin",
            "TERM" => "xterm-256color",
            "WORKSPACE" => "/workspace",
            "HISTFILE" => "/workspace/metadir/.bash_history",
            "HOME" => "/workspace/metadir",

            # Platform-targeting niceties
            "target" => "$(gcc_target_triplet(cross_platform.target))",
            "bb_full_target" => "$(triplet(cross_platform.target))",
            "prefix" => prefix,
            "bindir" => "$(prefix)/bin",
            "libdir" => "$(prefix)/lib",
            "shlibdir" => Sys.iswindows(cross_platform.target) ? "$(prefix)/bin" : "$(prefix)/lib",
            "includedir" => "$(prefix)/include",

            # The same things, repeated for `host`
            "MACHTYPE" => "$(gcc_target_triplet(cross_platform.host))",
            "host" => "$(gcc_target_triplet(cross_platform.host))",
            "bb_full_host" => "$(triplet(cross_platform.host))",
            "host_prefix" => host_prefix,
            "host_bindir" => "$(host_prefix)/bin",
            "host_libdir" => "$(host_prefix)/lib",
            "host_shlibdir" => Sys.iswindows(cross_platform.host) ? "$(host_prefix)/bin" : "$(host_prefix)/lib",
            "host_includedir" => "$(host_prefix)/include",

            # Misc. pieces of information
            "BB_PRINT_COMMANDS" => "true",
            "nproc" => "$(get(ENV, "BINARYBUILDER_NPROC", Sys.CPU_THREADS))",
            "SRC_NAME" => src_name,
        ))

        return new(
            meta,
            string(src_name),
            string(src_version),
            [d.package for d in target_dependencies if isa(d, JLLSource)],
            source_trees,
            env,
            allow_unsafe_flags,
            lock_microarchitecture,
            string(script),
            cross_platform,
            TimerOutput(),
        )
    end
end

# Helper function to better control when we download all our deps
# Ideally, this would be paralellized somehow.
function prepare(config::BuildConfig; verbose::Bool = false)
    @timeit config.to "prepare" begin
        for (prefix, deps) in config.source_trees
            @timeit config.to prefix begin
                prepare(deps; verbose, depot=config.meta.universe.depot_path)
            end
        end
    end
end

function deploy(config::BuildConfig; verbose::Bool = false, deploy_root::String = mktempdir(builds_dir()))
    # Ensure the `config` has been prepared
    prepare(config; verbose)

    # This is the temporary directory into which we will unpack/deploy sources,
    # run the actual build itself, etc...
    mounts = Dict{String,MountInfo}(
        "/" => MountInfo(Sandbox.debian_rootfs(;platform = config.platform.host), MountType.Overlayed),
    )

    @timeit config.to "deploy" begin
        for (idx, (prefix, srcs)) in enumerate(config.source_trees)
            mount_type = MountType.Overlayed

            # Strip leading slashes so that `joinpath()` works as expected,
            # prefix with `idx` so that we can overlay multiple disparate folders
            # onto eachother in the sandbox, without clobbering each directory on
            # the host side.
            host_path = joinpath(deploy_root, string(idx, "-", lstrip(prefix, '/')))
            mounts[prefix] = MountInfo(host_path, mount_type)

            # Avoid deploying a second time if we're coming at this a second time
            if !isdir(host_path)
                mkpath(host_path)
                @timeit config.to prefix deploy(srcs, host_path)
            end
        end
    end
    return mounts
end

import Sandbox: SandboxConfig
function SandboxConfig(config::BuildConfig,
                       mounts::Dict{String,MountInfo};
                       env = config.env,
                       stdout = stdout,
                       stdin = stdin,
                       stderr = stderr,
                       verbose::Bool = false,
                       pwd = "/workspace/srcdir",
                       kwargs...)
    return SandboxConfig(
        mounts,
        env;
        hostname = "bb8",
        persist = true,
        pwd,
        stdin,
        stdout,
        stderr,
        verbose,
        # TODO: Add `config.platform.target` here as well!
        multiarch = [config.platform.host],
        kwargs...,
    )
end

function runshell(config::BuildConfig; verbose::Bool = false, shell::Cmd = `/bin/bash`)
    mounts = deploy(config; verbose)
    sandbox_config = SandboxConfig(config, mounts; verbose)
    with_executor() do exe
        run(exe, sandbox_config, setenv(shell, config.env))
    end
end

function run_trycatch(exe::SandboxExecutor, config::SandboxConfig, cmd::Cmd)
    local run_status
    run_exception = nothing
    try
        if success(run(exe, config, ignorestatus(cmd)))
            run_status = :success
        else
            run_status = :failed
        end
    catch e
        if isa(e, InterruptException)
            cleanup(exe)
            rethrow(e)
        end
        run_status = :errored
        run_exception = e
    end
    return run_status, run_exception
end

function build!(config::BuildConfig; deploy_root::String = mktempdir(builds_dir()), stdout::IO = stdout, stderr::IO = stderr)
    @warn("TODO: Check config tree hashes, don't build again if not necessary", maxlog=1)

    mounts = deploy(config; verbose=config.meta.verbose, deploy_root)
    sandbox_config = SandboxConfig(
        config, mounts;
        # TODO: Spit these out into a logfile or something
        stdout,
        stderr,
        verbose=config.meta.verbose,
    )
    local run_status, run_exception
    exe = Sandbox.preferred_executor()()
    @timeit config.to "build" begin
        run_status, run_exception = run_trycatch(exe, sandbox_config, `/workspace/metadir/build_script.sh`)
    end

    result = BuildResult(
        config,
        run_status,
        run_exception,
        exe,
        mounts,
        Dict{String,String}(),
    )
    config.meta.builds[config] = result
    return result
end
