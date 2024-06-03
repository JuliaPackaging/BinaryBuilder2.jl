using Base.BinaryPlatforms
using TimerOutputs, Sandbox, BinaryBuilderToolchains
using BinaryBuilderToolchains: gcc_platform, gcc_target_triplet, platform, path_appending_merge
using Pkg.Types: PackageSpec
import BinaryBuilderSources: prepare, deploy
using MultiHashParsing, SHA, OutputCollectors

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

    # Our content hash; we compute it once up-front because we may need to ask for it multiple times
    content_hash::Ref{SHA1Hash}

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
        # We put the "host" toolchain in a separate location because there are cases where we want to
        # compile from aarch64-linux-gnu -> aarch64-linux-gnu, but use e.g. different GCC versions.
        # So it's easiest if we separate the host toolchian from any other potential triplet target.
        toolchain_prefix(toolchain::AbstractToolchain) = "/opt/$(gcc_target_triplet(platform(toolchain)))"
        toolchain_prefix(toolchain::HostToolsToolchain) = "/opt/host"

        source_trees = Dict{String,Vector{AbstractSource}}(
            # Target dependencies
            target_prefix(cross_platform) => target_dependencies,
            host_prefix(cross_platform) => [
                # Host dependencies (not including toolchains, those go in `/opt/host`)
                host_dependencies...;
                # Also, our `BB` resources
                DirectorySource(joinpath(Base.pkgdir(@__MODULE__), "share", "bash_scripts"); target="share/bb")
            ],
            # The actual sources we're gonna build
            "/workspace/srcdir" => sources,

            # Metadata such as our build script
            "/workspace/metadir" => [GeneratedSource() do out_dir
                # Generate a `.bashrc` that contains all sorts of `source` statements and whatnot
                bashrc_path = joinpath(out_dir, ".bashrc")
                open(bashrc_path; write=true) do io
                    println(io, "#!/bin/bash")
                    println(io, "source /usr/local/share/bb/hostcc_env")

                    # Always keep this one last, since it starts saving bash history from that point on.
                    println(io, "source /usr/local/share/bb/save_env_hook")
                end
                chmod(bashrc_path, 0o755)

                script_path = joinpath(out_dir, "build_script.sh")
                open(script_path, write=true) do io
                    println(io, "#!/bin/bash")
                    println(io, "set -euo pipefail")
                    println(io, "source /workspace/metadir/.bashrc")
                    # Save history on every DEBUG invocation
                    println(io, "trap save_history DEBUG")
                    println(io, script)

                    # Turn history saving off so that we don't see `exit 0`
                    println(io, "trap - DEBUG")
                    println(io, "exit 0")
                end
                chmod(script_path, 0o755)
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

        target_prefix_path = target_prefix(cross_platform)
        host_prefix_path = host_prefix(cross_platform)
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
            "prefix" => target_prefix_path,
            "bindir" => "$(target_prefix_path)/bin",
            "libdir" => "$(target_prefix_path)/lib",
            "shlibdir" => Sys.iswindows(cross_platform.target) ? "$(target_prefix_path)/bin" : "$(target_prefix_path)/lib",
            "includedir" => "$(target_prefix_path)/include",
            "dlext" => dlext(cross_platform.target)[2:end],

            # The same things, repeated for `host`
            "MACHTYPE" => "$(gcc_target_triplet(cross_platform.host))",
            "host" => "$(gcc_target_triplet(cross_platform.host))",
            "bb_full_host" => "$(triplet(cross_platform.host))",
            "host_prefix" => host_prefix_path,
            "host_bindir" => "$(host_prefix_path)/bin",
            "host_libdir" => "$(host_prefix_path)/lib",
            "host_shlibdir" => Sys.iswindows(cross_platform.host) ? "$(host_prefix_path)/bin" : "$(host_prefix_path)/lib",
            "host_includedir" => "$(host_prefix_path)/include",

            # Misc. pieces of information
            "BB_PRINT_COMMANDS" => "true",
            "nproc" => get(ENV, "BINARYBUILDER_NPROC", string(Sys.CPU_THREADS)),
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
            Ref{SHA1Hash}(),
        )
    end
end

function BinaryBuilderSources.content_hash(config::BuildConfig)
    if !isassigned(config.content_hash)
        # We will collect all information as a string (including hashes of dependencies)
        # and then hash that whole thing to generate our content-hash.
        hash_buffer = IOBuffer()

        @timeit config.to "content_hash" begin
            # Metadata about the build itslef,
            println(hash_buffer, "[build_metadata]")
            println(hash_buffer, "  platform = $(triplet(config.platform))")
            println(hash_buffer, "  allow_unsafe_flags = $(config.allow_unsafe_flags)")
            println(hash_buffer, "  lock_microarchitecture = $(config.lock_microarchitecture)")
            println(hash_buffer, "  script_hash = $(SHA1Hash(sha1(config.script)))")

            # First, a section on source trees (e.g. all dependencies, toolchains, etc...)
            println(hash_buffer, "[source_trees]")
            for prefix in sort(collect(keys(config.source_trees)))
                deps = config.source_trees[prefix]
                println(hash_buffer, "  $(prefix) = $(content_hash(deps))")
            end

            # Next, the subset of the environment that includes all `BinaryBuilder*` packages
            # and anything with the name `JLL` in it:
            println(hash_buffer, "[environment]")
            package_treehashes = bb_package_treehashes()
            for pkg_name in sort(collect(keys(package_treehashes)))
                println(hash_buffer, "  $(pkg_name) = $(package_treehashes[pkg_name])")
            end
        end
        config.content_hash[] = SHA1Hash(sha1(take!(hash_buffer)))
    end
    return config.content_hash[]
end

target_prefix(cross_platform::CrossPlatform) = string("/workspace/destdir/", triplet(cross_platform.target))
host_prefix(cross_platform::CrossPlatform) = "/usr/local" #string("/workspace/destdir/", triplet(cross_platform.host))
target_prefix(config::BuildConfig) = target_prefix(config.platform)
host_prefix(config::BuildConfig) = host_prefix(config.platform)

# Helper function to better control when we download all our deps
# Ideally, this would be paralellized somehow.
function prepare(config::BuildConfig; verbose::Bool = false)
    @timeit config.to "prepare" begin
        universe = config.meta.universe
        for (prefix, deps) in config.source_trees
            # We install different source trees in different environments.
            @timeit config.to prefix begin
                mktempdir() do project_dir
                    # The "target prefix" gets special treatment; we copy the "main" Universe's environment in,
                    # because we want previous registrations within this universe to take effect.
                    if prefix == target_prefix(config)
                        cp(dirname(environment_path(universe)), project_dir; force=true)
                    end
                    prepare(deps; verbose, project_dir, depot=depot_path(universe))
                end
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

function sandbox_and_collector(log_io::IO,
                               args...;
                               verbose::Bool = false,
                               kwargs...)
    pipes = Dict("stdout" => Pipe(), "stderr" => Pipe())
    styles = Dict("stderr" => :red)
    outputs = IO[log_io]
    if verbose
        push!(outputs, stdout)
    end
    collector = OutputCollector(
        pipes,
        outputs,
        styles,
    )
    sandbox_config = SandboxConfig(
        args...;
        stdout=pipes["stdout"],
        stderr=pipes["stderr"],
        verbose,
    )
    return sandbox_config, collector
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

function build!(config::BuildConfig;
                deploy_root::String = mktempdir(builds_dir()),
                extract_arg_hints::Vector{<:Tuple} = Tuple[],
                disable_cache::Bool = false)
    meta = config.meta
    # Hit our build cache and see if we've already done this exact build.
    if build_cache_enabled(meta) && !disable_cache && !isempty(extract_arg_hints)
        build_hash = content_hash(config)
        if all(haskey(meta.build_cache, build_hash, extract_content_hash(args...)) for args in extract_arg_hints)
            return BuildResult_cached(config)
        end
    end

    # Write build script out into a logfile
    build_log_io = IOBuffer()
    mounts = deploy(config; verbose=meta.verbose, deploy_root)
    sandbox_config, collector = sandbox_and_collector(
        build_log_io, config, mounts;
        verbose=meta.verbose,
    )
    local run_status, run_exception
    exe = Sandbox.preferred_executor()()
    if "build-start" ∈ meta.debug_modes
        @warn("Launching debug shell")
        runshell(config; verbose=meta.verbose)
    end

    @timeit config.to "build" begin
        run_status, run_exception = run_trycatch(exe, sandbox_config, `/workspace/metadir/build_script.sh`)
    end
    wait(collector)
    build_log = String(take!(build_log_io))

    # Generate "log" artifact that will later be packaged up.
    log_artifact_hash = in_universe(meta.universe) do env
        Pkg.Artifacts.create_artifact() do artifact_dir
            open(joinpath(artifact_dir, "build.log"); write=true) do io
                write(io, build_log)
            end
        end
    end
    log_artifact_hash = SHA1Hash(log_artifact_hash)

    # Parse out the environment from the build
    if run_status != :errored
        env = parse_metadir_env(exe, config, mounts)
    else
        env = Dict{String,String}()
    end

    result = BuildResult(
        config,
        run_status,
        run_exception,
        exe,
        mounts,
        build_log,
        log_artifact_hash,
        env,
    )
    meta.builds[config] = result

    if "build-stop" ∈ meta.debug_modes || ("build-error" ∈ meta.debug_modes && run_status != :success)
        @warn("Launching debug shell")
        runshell(result; verbose=meta.verbose)
    end
    return result
end
