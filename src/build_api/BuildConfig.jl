using Base.BinaryPlatforms
using TimerOutputs, Sandbox, BinaryBuilderToolchains
using BinaryBuilderToolchains: gcc_platform, platform, path_appending_merge
using Pkg.Types: PackageSpec
import BinaryBuilderSources: prepare, deploy
using MultiHashParsing, SHA, OutputCollectors

export BuildConfig, build!, cleanup




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
    # If no explicit `version_series` is given in the packaging step, we will attempt to parse this
    # version as a `VersionNumber` and use its `major.minor` as the version series to publish under.
    src_version::String

    # AbstractSources that must be installed in the build environment.
    # Contains sources, host dependencies, target dependencies, and toolchains.
    # Organized by installation prefix (e.g. `/opt/$(triplet)` for toolchains,
    # `/workspace/srcdir` for sources, `/workspace/destdir/$(triplet)` for dependencies, etc...)
    source_trees::Dict{String,Vector{<:AbstractSource}}
    env::Dict{String,String}

    # Bash script that will perform the actual build itself
    script::String

    # In general, `toolchains` will have only a single entry, because
    # we will be building a library to run on a particular machine.  However, we
    # fully support building more complex projects, such as compilers that are
    # made on the `build` machine, to run on the `host` machine, to themselves
    # build things for the `target` machine.  In such a situation, we need
    # toolchains for both the `host` and `target` present (and likely `build` too,
    # if there's any bootstrapping to be done).  This dictionary maps from `name`
    # (such as "host" or "target") to groups of toolchains.  See the comments in
    # `split_toolchains()` for more.
    target_specs::Vector{BuildTargetSpec}

    # We're going to store all sorts of timing information about our build in here
    to::TimerOutput

    # Our content hash; we cache it because we may need to ask for it multiple times
    content_hash::Ref{Union{Nothing,SHA1Hash}}

    function BuildConfig(meta::AbstractBuildMeta,
                         src_name::AbstractString,
                         src_version::Union{VersionNumber, String},
                         sources::Vector,
                         target_specs::Vector{BuildTargetSpec},
                         script::AbstractString;
                         kwargs...,
                         )
        sources = Vector{AbstractSource}(sources)
        if count(bts -> :host ∈ bts.flags, target_specs) != 1
            throw(ArgumentError("Invalid `target_specs`, must have exactly one marked as `:host`!"))
        end
        host = get_host_target_spec(target_specs).platform.host

        # Dependencies for each target's prefix
        target_deps = [target_prefix(bts) => bts.dependencies for bts in target_specs]
        source_trees = Dict{String,Vector{AbstractSource}}(
            # Target dependencies
            target_deps...,
            # The actual sources we're gonna build
            source_prefix() => sources,

            # BB shell scripts
            scripts_prefix() => [DirectorySource(
                joinpath(Base.pkgdir(@__MODULE__), "share", "bash_scripts")
            )],

            # Metadata such as our build script
            metadir_prefix() => [GeneratedSource() do out_dir
                # Generate a `.bashrc` that contains all sorts of `source` statements and whatnot
                bashrc_path = joinpath(out_dir, ".bashrc")
                open(bashrc_path; write=true) do io
                    println(io, "#!/bin/bash")
                    println(io, "export PATH=$(scripts_prefix())/bin:\${PATH}")
                    println(io, "source $(scripts_prefix())/shell_customization")

                    # Always keep this one last, since it starts saving bash history from that point on.
                    println(io, "source $(scripts_prefix())/save_env_hook")
                end
                chmod(bashrc_path, 0o755)

                script_path = joinpath(out_dir, "build_script.sh")
                open(script_path, write=true) do io
                    println(io, "#!/bin/bash")
                    println(io, "set -euo pipefail")
                    println(io, "source $(metadir_prefix())/.bashrc")

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


        ## Environment setup
        env = Dict{String,String}()
        for bts in target_specs
            env, source_trees = apply_toolchains(bts, env, source_trees)
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

        env = path_appending_merge(env, Dict(
            # Things to work well with a shell
            "PATH" => "/usr/local/bin:/usr/local/sbin:/usr/bin:/usr/sbin:/bin:/sbin",
            "TERM" => "xterm-256color",
            "TERMINFO" => "/lib/terminfo",
            "WORKSPACE" => "/workspace",
            "HISTFILE" => "$(metadir_prefix())/.bash_history",
            "HOME" => metadir_prefix(),
            "MACHTYPE" => "$(triplet(gcc_platform(host)))",

            # Misc. pieces of information
            "BB_PRINT_COMMANDS" => "true",
            "nproc" => get(ENV, "BINARYBUILDER_NPROC", string(Sys.CPU_THREADS)),
            "SRC_NAME" => src_name,

            # ccache
            "CCACHE_DIR" => "/var/cache/ccache",
        ))

        return new(
            meta,
            string(src_name),
            string(src_version),
            source_trees,
            env,
            string(script),
            target_specs,
            TimerOutput(),
            Ref{Union{SHA1Hash,Nothing}}(nothing),
        )
    end
end
AbstractBuildMeta(config::BuildConfig) = config.meta
get_host_target_spec(config::BuildConfig) = get_host_target_spec(config.target_specs)
function get_target_spec(config::BuildConfig, name::String)
    for bts in config.target_specs
        if bts.name == name
            return bts
        end
    end
    return nothing
end
#=
"""
    target_mapping(config::BuildConfig)

Returns dictionary mapping target name (e.g. "host", "target", etc...) to the
cross-platform representing the cross compiler used to compile for each target.
For most builds, this will contain two mappings, one for the host, one for the
target, however for more complicated builds there can be more than just those.
"""
function target_mapping(toolchains_mapping::Dict{String,<:Vector{<:AbstractToolchain}})
    mapping = Dict{String,CrossPlatform}()
    for (name, toolchains) in toolchains_mapping
        target_toolchains = filter(is_target_toolchain, toolchains)
        if isempty(target_toolchains)
            continue
        end
        mapping[name] = first(target_toolchains).platform
    end
    return mapping
end
target_mapping(config::BuildConfig) = target_mapping(config.toolchains)
BBHostPlatform(config::BuildConfig) = first(values(target_mapping(config))).host

function host_mapping_key(mapping::Dict{String,CrossPlatform})
    if haskey(mapping, "build")
        return "build"
    elseif haskey(mapping, "host")
        return "host"
    else
        return nothing
    end
end
host_mapping_key(config::BuildConfig) = host_mapping_key(target_mapping(config))

function guess_target_key(mapping::Dict{String,CrossPlatform})
    if haskey(mapping, "build") && haskey(mapping, "host")
        return "host"
    elseif haskey(mapping, "host") && haskey(mapping, "target")
        return "target"
    else
        return nothing
    end
end
guess_target_key(config::BuildConfig) = guess_target_key(target_mapping(config))

function guess_target(mapping::Dict{String,CrossPlatform})
    if length(mapping) == 2 && haskey(mapping, "target")
        # Simple case that 99% of people will be using
        return return mapping["target"].target
    elseif length(mapping) == 3 && haskey(mapping, "target") && haskey(mapping, "host")
        # Canuck mode oot and aboot.  Only the bravest souls,
        # Tim Horton's in hand, will attempt a build like this.
        return CrossPlatform(mapping["host"].target => mapping["target"].target)
    else
        # Science has gone too far!
        return nothing
    end
end
guess_target(config::BuildConfig) = guess_target(target_mapping(config))
=#
function target_platform_string(config::BuildConfig)
    function get_spec_by_name(name)
        for bts in config.target_specs
            if bts.name == name
                return bts
            end
        end
        return nothing
    end
    function is_canadian()
        return length(config.target_specs) == 3 &&
               get_spec_by_name("build") !== nothing &&
               get_spec_by_name("host") !== nothing &&
               get_spec_by_name("target") !== nothing
    end
    host = get_host_target_spec(config.target_specs).platform.host
    if length(config.target_specs) == 2
        idx = findfirst(bts -> :host ∉ bts.flags, config.target_specs)
        target = config.target_specs[idx].platform.target
        return string(triplet(host), " => ", triplet(target))
    elseif is_canadian()
        # Canuck mode oot and aboot.  Only the bravest souls,
        # Tim Horton's in hand, will attempt a build like this.
        return string(
            triplet(get_spec_by_name("build").platform.target),
            " => ",
            triplet(get_spec_by_name("host").platform.target),
            " => ",
            triplet(get_spec_by_name("target").platform.target),
        )
    else
        # Science has gone too far!
        return string(triplet(host), " => ?")
    end
end
get_default_target_spec(config::BuildConfig) = get_default_target_spec(config.target_specs)

function Base.show(io::IO, config::BuildConfig)
    print(io, "BuildConfig($(config.src_name), $(config.src_version), $(target_platform_string(config)))")
end

function BinaryBuilderSources.content_hash(config::BuildConfig)
    if config.content_hash[] === nothing
        # We will collect all information as a string (including hashes of dependencies)
        # and then hash that whole thing to generate our content-hash.
        hash_buffer = IOBuffer()

        @timeit config.to "content_hash" begin
            # Metadata about the build itslef,
            println(hash_buffer, "[build_metadata]")
            println(hash_buffer, "  script_hash = $(SHA1Hash(sha1(config.script)))")

            # A section on our targets
            println(hash_buffer, "[target_specs]")
            for bts in config.target_specs
                println(hash_buffer, "  $(bts.name): ", triplet(bts.platform))
            end

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
        buffer_data = take!(hash_buffer)
        config.content_hash[] = SHA1Hash(sha1(buffer_data))
    end
    return config.content_hash[]::SHA1Hash
end

# Helpers so I don't have to hard-code paths everywhere
host_prefix() = "/usr/local"
source_prefix() = "/workspace/srcdir"
scripts_prefix() = "/workspace/scripts"
metadir_prefix() = "/workspace/metadir"

# Helper function to better control when we download all our deps
# Ideally, this would be paralellized somehow.
function prepare(config::BuildConfig; verbose::Bool = false)
    @timeit config.to "prepare" begin
        universe = config.meta.universe
        for (prefix, deps) in config.source_trees
            # We install different source trees in different environments.
            @timeit config.to prefix begin
                mktempdir() do project_dir
                    # We have some special magic to work here; oftentimes, when we perform
                    # multiple builds within the same universe, we do so because we want to
                    # make use of a previous build in a new one.  To effect this, we copy
                    # our universe's environment in to all of our source trees, so that
                    # if we build, e.g. `Zlib_jll`, we use that `Zlib_jll` for everything
                    # in the rest of the build.
                    cp(dirname(environment_path(universe)), project_dir; force=true)
                    # This verbose needs like a `verbose = verbose_level >= 2` or something
                    prepare(deps; verbose=false, project_dir, depot=depot_path(universe))
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
        "/" => MountInfo(Sandbox.debian_rootfs(;platform = get_host_target_spec(config).platform.host), MountType.Overlayed),
        "/var/cache/ccache" => MountInfo(ccache_cache(), MountType.ReadWrite),
    )

    @timeit config.to "deploy" begin
        for (idx, (prefix, srcs)) in enumerate(config.source_trees)
            # Strip leading slashes so that `joinpath()` works as expected,
            # prefix with `idx` so that we can overlay multiple disparate folders
            # onto eachother in the sandbox, without clobbering each directory on
            # the host side.
            host_path = joinpath(deploy_root, string(idx, "-", lstrip(prefix, '/')))
            mounts[prefix] = MountInfo(host_path, MountType.Overlayed)

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
        # TODO: Add targets here as well, for bootstrapping!
        multiarch = [get_host_target_spec(config).platform.host],
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

function runshell(config::BuildConfig; verbose::Bool = AbstractBuildMeta(config).verbose, shell::Cmd = `/bin/bash`)
    mounts = deploy(config; verbose)
    sandbox_config = SandboxConfig(config, mounts; verbose)
    with_executor() do exe
        run(exe, sandbox_config, shell)
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
                disable_cache::Bool = false,
                debug_modes = AbstractBuildMeta(config).debug_modes,
                verbose::Bool = AbstractBuildMeta(config).verbose)
    meta = AbstractBuildMeta(config)
    meta.builds[config] = nothing

    # If we're asking for a dry run, skip out
    if :build ∈ meta.dry_run
        if verbose
            @info("Dry-run build", config)
        end
        result = BuildResult_skipped(config)
        meta.builds[config] = result
        return result
    end

    # Hit our build cache and see if we've already done this exact build.
    if build_cache_enabled(meta) && !disable_cache && !isempty(extract_arg_hints)
        prepare(config; verbose)
        build_hash = content_hash(config)
        if all(haskey(meta.build_cache, build_hash, extract_content_hash(args...)) for args in extract_arg_hints)
            if verbose
                @info("Build cached", config, build_hash=content_hash(config))
            end
            result = BuildResult_cached(config)
            meta.builds[config] = result
            return result
        end
    end

    # Write build script out into a logfile
    build_log_io = IOBuffer()
    mounts = deploy(config; verbose, deploy_root)
    sandbox_config, collector = sandbox_and_collector(
        build_log_io, config, mounts;
        verbose,
    )
    local run_status, run_exception
    exe = Sandbox.preferred_executor()()
    if "build-start" ∈ debug_modes
        @warn("Launching debug shell")
        runshell(config; verbose)
    end

    @timeit config.to "build" begin
        run_status, run_exception = run_trycatch(exe, sandbox_config, `$(metadir_prefix())/build_script.sh`)
        if run_status != :success && verbose
            @error("Build failed", run_status, run_exception)
        end
    end
    wait(collector)
    build_log = String(take!(build_log_io))

    # Generate "log" artifact that will later be packaged up.
    log_artifact_hash = in_universe(meta.universe) do env
        Pkg.Artifacts.create_artifact() do artifact_dir
            open(joinpath(artifact_dir, "$(config.src_name)-build.log"); write=true) do io
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

    if "build-stop" ∈ debug_modes || ("build-error" ∈ debug_modes && run_status != :success)
        @warn("Launching debug shell")
        if !verbose
            for line in split(build_log, "\n")[end-50:end]
                printstyled(line; color=:red)
                println()
            end
        end
        runshell(result; verbose)
    end
    return result
end
