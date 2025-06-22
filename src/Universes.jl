using Pkg.Registry: RegistrySpec, RegistryInstance, uuids_from_name
using Artifacts
using JLLGenerator
using Random, TOML
using BinaryBuilderGitUtils
using KeywordArgumentExtraction
import LazyJLLWrappers
import LocalRegistry
import TreeArchival
using Scratch, Pkg, Dates
using gh_cli_jll
import Sandbox: cleanup
using Logging

export Universe, in_universe

const allow_github_authentication::Ref{Bool} = Ref(true)

function update_registries!(registries::Vector{RegistrySpec},
                            depot_path::String;
                            verbose::Bool = false)
    # For each registry, update it and then check it out into the given `depot_path`
    # if it does not already exist there.
    mkpath(joinpath(depot_path, "registries"))
    registry_update_toml_path = joinpath(depot_path, "scratchspaces", string(Scratch.find_uuid(Pkg)), "registry_updates.toml")
    if !isfile(registry_update_toml_path)
        registry_update_log = Dict{String, Any}()
    else
        registry_update_log = TOML.parsefile(registry_update_toml_path)
    end

    Pkg.Registry.download_registries(verbose ? stdout : devnull, registries, depot_path)
    
    for reg in registries
        # We arbitrarily add a month onto here, making the (hopefully well-founded) assertion
        # that we will never have a build that takes more than a month.
        registry_update_log[string(reg.uuid)] = now() + Month(1)
    end
    # Also don't ever try to update our local registry
    registry_update_log[string(_BB2_LOCAL_REGISTRY_UUID)] = now() + Month(1)

    # Tell Pkg not to try to update any of these registries, ever.  We'll always be the one to do so.
    mkpath(dirname(registry_update_toml_path))
    open(registry_update_toml_path; write=true) do io
        TOML.print(io, registry_update_log)
    end

    # Finally, load each registry into a `RegistryInstance` for future use:
    return [RegistryInstance(registry_path(depot_path, reg.name)) for reg in registries]
end

const _BB2_LOCAL_REGISTRY_UUID = Base.UUID("79727473-6967-6552-6c61-636f4c324242")
function create_local_registry(depot_path::String)
    local_reg_spec = Pkg.Registry.RegistrySpec(;
            name = "BB2LocalRegistry",
            uuid = _BB2_LOCAL_REGISTRY_UUID,
            path = joinpath(depot_path, "registries", "BB2LocalRegistry") ,
        )
    if !isdir(local_reg_spec.path)
        with_logger(NullLogger()) do
            LocalRegistry.create_registry(local_reg_spec.path, local_reg_spec.path; push=false)
        end
    end
    return local_reg_spec
end

"""
    Universe

A Universe creates an ephemeral depot with a set of registries, a default
environment, and dev'ed packages representing packages built by BinaryBuilder.
The Universe configuration also controls how and where built packages are
deployed, e.g. to which registry and which 
"""
struct Universe
    name::Union{Nothing,String}
    depot_path::String
    registries::Vector{RegistrySpec}
    registry_instances::Vector{RegistryInstance}
    persistent::Bool

    # `deploy_org` here refers to a Github organization/user to deploy to.
    # If this is specified, `Foo_jll` will be deployed to `https://github.com/$(deploy_org)/Foo_jll.jl`
    # and the registry changes will be pushed to `https://github.com/$(deploy_org)/General`
    deploy_org::Union{Nothing,String}

    # This allows overriding which registry gets pushed to; this is most useful
    # for Yggdrasil, where we usually run with `deploy_org = "JuliaBinaryWrappers"`
    # but `registry_url = "https://github.com/JuliaRegistries/General"`.
    registry_url::Union{Nothing,String}

    function Universe(name::Union{Nothing,AbstractString} = nothing;
                      depot_dir::AbstractString = universes_dir(),
                      deploy_org::Union{Nothing,AbstractString} = nothing,
                      registries::Vector{RegistrySpec} = copy(Pkg.Registry.DEFAULT_REGISTRIES),
                      registry_url::Union{Nothing,AbstractString} = nothing,
                      persistent::Bool = false,
                      kwargs...)
        @ensure_all_kwargs_consumed_header()
        if isempty(registries)
            throw(ArgumentError("Must pass at least one registry to `Universe()`!"))
        end
        depot_path = joinpath(
            depot_dir,
            something(name, string(Dates.format(now(), "yyyy-mm-dd-HH-MM-SS"), "-", randstring(4))),
        )
        mkpath(depot_path)
        depot_path = abspath(depot_path)

        # We always attempt to share the `artifacts` and `packages` directories of our universe with the `jllsource_depot`.
        for dir_name in ("artifacts", "packages")
            shared_dir = joinpath(BinaryBuilderSources.default_jll_source_depot(), dir_name)
            mkpath(shared_dir)
            if !ispath(joinpath(depot_path, dir_name))
                symlink(
                    shared_dir,
                    joinpath(depot_path, dir_name);
                    dir_target = true,
                )
            end
        end

        # Ensure the upstream registries are up to date
        registry_instances = update_registries!(registries, depot_path)

        # Create our own, empty registry we'll register things into.
        local_reg_spec = create_local_registry(depot_path)
        insert!(registries, 1, local_reg_spec)
        insert!(registry_instances, 1, RegistryInstance(local_reg_spec.path))

        if deploy_org !== nothing
            # Authenticate to GitHub, then ensure that we are either deploying to our
            # user, or an organization we are a part of
            if allow_github_authentication[]
                ensure_gh_authenticated()
                if deploy_org != gh_user() && deploy_org ∉ gh_orgs()
                    throw(ArgumentError("deploy target '$(deploy)' not a user/organization we have access to!"))
                end
            end
        end

        # Ensure that this universe's environment uses our version of LazyJLLWrappers,
        # since we may be testing things or have some local patch.
        uni = new(
            name === nothing ? nothing : string(name),
            depot_path,
            registries,
            registry_instances,
            persistent,
            deploy_org,
            string(registry_url),
        )
        prune!(uni)
        dev_bb2_packages(uni)

        # If we are not persistent, clean this universe up at the end of our run
        if !persistent
            atexit() do
                cleanup(uni)
            end
        end

        @ensure_all_kwargs_consumed_check(kwargs)
        return uni
    end
end

function cleanup(uni::Universe; silent::Bool = false)
    if !uni.persistent && isdir(uni.depot_path)
        if !silent
            @info("Cleaning up universe", depot_path=uni.depot_path)
        end
        rm(uni.depot_path; force=true, recursive=true)
    end
end

function Base.show(io::IO, uni::Universe)
    println(io, "Universe$(uni.name === nothing ? "" : " $(uni.name)")")
    println(io, "  Registries:")
    for reg in uni.registries
        println(io, "   - $(reg.name) [$(reg.uuid)]")
    end
    println(io, "  Depot Path: $(uni.depot_path)")
    if uni.deploy_org !== nothing
        println(io, "  Deploy target: https://github.com/$(uni.deploy_org)")
    end
end

Artifacts.artifact_path(u::Universe, hash::Base.SHA1) = joinpath(u.depot_path, "artifacts", bytes2hex(hash.bytes))
Artifacts.artifact_path(u::Universe, hash::SHA1Hash) = artifact_path(u, Base.SHA1(hash))
Artifacts.artifact_path(hash::SHA1Hash) = artifact_path(Base.SHA1(hash))

raw"""
    in_universe(f::Function, u::Universe;
                extra_depots::Vector{String} = String[],
                append_bundled_depot_path::Bool = true)

Opens the dimensional portal, transporting execution of `f(env)` into the provided
universe, causing all `Pkg` operations to resolve with respect to that universe.
Also adds the default bundled depots and any extra depots desired by the user as
specified by `extra_depots` and `append_bundled_depot_path`.  This is most commonly
used to allow artifacts and packages to be loaded from a shared cache depot.

             .,-:;//;:=,
         . :H@@@MM@M#H/.,+%;,
      ,/X+ +M@@M@MM%=,-%HMMM@X/,
     -+@MM; $M@@MH+-,;XMMMM@MMMM@+-
    ;@M@@M- XM@X;. -+XXXXXHHH@M@M#@/.
  ,%MM@@MH ,@%=            .---=-=:=,.
  -@#@@@MX .,              -%HX$$%%%+;
 =-./@M@M$                  .;@MMMM@MM:
 X@/ -$MM/                    .+MM@@@M$
,@M@H: :@:                    . -X#@@@@-
,@@@MMX, .                    /H- ;@M@M=
.H@@@@M@+,                    %MM+..%#$.
 /MMMM@MMH/.                  XM@MH; -;
  /%+%$XHH@$=              , .H@@@@MX,
   .=--------.           -%H.,@@@@@MX,
   .%MM@@@HHHXX$$$%+- .:$MMX -M@@MM%.
     =XMMM@MM@MM#H;,-+HMM@M+ /MMMX=
       =%@M@M#@$-.=$@MM@@@M; %M%=
         ,:+$+-,/H#MMMMMMM@- -,
               =++%%%%+/:-.
"""
function in_universe(f::Function, u::Universe;
                     extra_depots::Vector{String} = String[],
                     append_bundled_depot_path::Bool = true)
    # Save old `DEPOT_PATH`
    old_depot_path = copy(Base.DEPOT_PATH)

    # force-set `DEPOT_PATH` to just our Universe's depot, with the stdlib depots included
    empty!(Base.DEPOT_PATH)
    append!(Base.DEPOT_PATH, [
        abspath(u.depot_path),
        extra_depots...,
    ])
    if append_bundled_depot_path
        # On Julia v1.11+, this is simple because of https://github.com/JuliaLang/julia/commit/9443c761871c4db9c3213a1e01804286292c3f4d
        if isdefined(Base, :append_bundled_depot_path!)
            Base.append_bundled_depot_path!(Base.DEPOT_PATH)
        else
            # On older Julias, we need to drop the default user depot.
            temp_DEPOT_PATH = String[]
            Base.append_default_depot_path!(temp_DEPOT_PATH)
            pop!(temp_DEPOT_PATH)
            append!(Base.DEPOT_PATH, temp_DEPOT_PATH)
        end
    end

    # Ensure that subprocesses use the correct depot path
    env = Dict("JULIA_DEPOT_PATH" => join(Base.DEPOT_PATH, ":"))

    try
        # Invoke the user function
        Pkg.activate(environment_path(u)) do
            f(env)
        end
    finally
        # No matter what happens, reset the DEPOT_PATH to what it should be.
        empty!(Base.DEPOT_PATH)
        append!(Base.DEPOT_PATH, old_depot_path)
    end
end

depot_path(u::Universe) = u.depot_path
function environment_path(u::Universe)
    env_path = joinpath(u.depot_path, "environments", "binarybuilder")
    mkpath(env_path)
    touch(joinpath(env_path, "Project.toml"))
end

function registry_path(depot_path::String, reg_name::String)
    toml_path = joinpath(depot_path, "registries", string(reg_name, ".toml"))
    if isfile(toml_path)
        return toml_path
    else
        return joinpath(depot_path, "registries", reg_name)
    end
end

function registry_path(u::Universe, registry::RegistrySpec)
    return registry_path(u.depot_path, registry.name)
end

# It would be nice if `Pkg.Registry` just exported something like this
function Pkg.Registry.parsefile(reg_inst::RegistryInstance, path::String)
    return Pkg.Registry.parsefile(reg_inst.in_memory_registry, reg_inst.path, path)
end

function registry_package_lookup(f::Function, u::Universe, pkg_name::String, pkg_file::String; registries = u.registry_instances)
    for reg_inst in registries
        pkg_uuids = uuids_from_name(reg_inst, pkg_name)
        if isempty(pkg_uuids)
            continue
        end

        # I don't think this should ever really have more than one, let's just
        # error if that happens so that we can think about what to actually do.
        pkg_uuid = only(pkg_uuids)
        pkg_subpath = joinpath(reg_inst.pkgs[pkg_uuid].path, pkg_file)

        # `parsefile()` does not gracefully deal with missing files, so we catch
        # errors here and just skip over missing files.
        pkg_data = try
            Pkg.Registry.parsefile(reg_inst, pkg_subpath)
        catch e
            if !isa(e, SystemError)
                rethrow(e)
            end
            nothing
        end
        if pkg_data !== nothing
            f(pkg_data)
        end
    end
end

"""
    get_package_repo(uni::Universe, pkg_name::String)

Given a package name, return the repository url for that package by looking
through the set of registries within `uni`.  In the event that multiple
unique repository URLs are found for a single package, print a warning, but
arbitrarily choose the first as the true URL.
"""
function get_package_repo(uni::Universe, pkg_name::String; kwargs...)
    repos = String[]
    registry_package_lookup(uni, pkg_name, "Package.toml"; kwargs...) do d
        push!(repos, d["repo"])
    end
    repos = unique(repos)
    if length(repos) > 1
        @warn("Multiple package repositories found for '$(pkg_name)', arbitrarily using one!", repos)
    end
    if isempty(repos)
        return nothing
    end
    return first(repos)
end

"""
    get_package_versions(uni::Universe, pkg_name::String)

Given a package name, return the list of versions for that package by looking
through the set of registries within `uni`.  Combines the set of all versions
across all registries in `uni`.
"""
function get_package_versions(uni::Universe, pkg_name::String; kwargs...)
    versions = VersionNumber[]
    registry_package_lookup(uni, pkg_name, "Versions.toml"; kwargs...) do d
        append!(versions, parse.(VersionNumber, collect(keys(d))))
    end
    return versions
end

"""
    prune!(u::Universe)

Given a universe, look through its default 'binarybuilder' environment
and remove any deps that no longer exist.  This helps when previous builds
in a persistent universe have been canceled.
"""
function prune!(u::Universe)
    env_path = joinpath(u.depot_path, "environments", "binarybuilder", "Project.toml")
    if isfile(env_path)
        proj = try
            TOML.parsefile(env_path)
        catch
            nothing
        end
        if proj !== nothing && haskey(proj, "deps") && !isempty(proj["deps"])
            filter!(proj["deps"]) do (dep_name, _)
                # Special-case our insertion of LazyJLLWrappers from Universe()
                if dep_name == "LazyJLLWrappers"
                    return true
                end
                return isfile(joinpath(u.depot_path, "dev", dep_name, "JLL.toml"))
            end
            open(env_path, write=true) do io
                TOML.print(io, proj)
            end
        end
    end
end

function dev_bb2_packages(uni::Universe)
    in_universe(uni) do env
        Pkg.resolve(;io=devnull)
        # Add our version of LazyJLLWrappers, just in case someone wants to
        # load a JLL that they built locally, and they're depending on some
        # features that they've added to LazyJLLWrappers.
        Pkg.develop(;path=joinpath(Base.pkgdir(LazyJLLWrappers)), io=devnull)
    end
end


function contains_jll(u::Universe, name::String)
    if !endswith(name, "_jll")
        name = "$(name)_jll"
    end
    in_universe(u) do env
        ctx = Pkg.Types.Context()
        pkg_entries = collect(values(filter(((uuid, pkg_entry),) -> pkg_entry.name == name && pkg_entry.path !== nothing, ctx.env.manifest.deps)))
        if isempty(pkg_entries)
            return false
        end
        pkg_entry = only(pkg_entries)
        return startswith(pkg_entry.path, u.depot_path)
    end
end

function registered_jlls(u::Universe)
    in_universe(u) do env
        ctx = Pkg.Types.Context()
        return map(pkg_entry -> pkg_entry.name,
            values(filter(ctx.env.manifest.deps) do (uuid, pkg_entry)
                return pkg_entry.path !== nothing &&
                       endswith(pkg_entry.name, "_jll") &&
                       startswith(pkg_entry.path, joinpath(u.depot_path, "dev"))
            end)
        )
    end
end

"""
    reset_timeline!(u::Universe)

Reset a universe back to its pristine state.  Removes all previous registrations
and clears the environment of the dev'ed JLLs.
"""
function reset_timeline!(u::Universe)
    # Update registries to the latest, but skip the first one since
    # it's our local registry and it errors out if we try to update it.
    u.registry_instances[2:end] .= update_registries!(u.registries[2:end], u.depot_path)

    # Clear out our local registry and recreate it
    rm(joinpath(u.depot_path, "registries", "BB2LocalRegistry"); force=true, recursive=true)
    create_local_registry(u.depot_path)

    # Clear environment
    rm(joinpath(u.depot_path, "environments", "binarybuilder"); force=true, recursive=true)

    # Re-dev any BB2 packages we need
    dev_bb2_packages(u)
end

"""
    exported_artifact_filename(jll_name, build_name, auxiliary_name, verison, platform)

Given the parameters for an artifact within a JLL, generate its filename.
In full generality, this will look something like the following:

    Readline-debug-build_log-v1.0.0-x86_64-linux-gnu.tar.gz
"""
function exported_artifact_filename(build_name::String,
                                    auxiliary_name::Union{Nothing,String},
                                    version::VersionNumber,
                                    platform::AbstractPlatform)
    ret = build_name
    if auxiliary_name !== nothing
        ret = string(ret, "-", auxiliary_name)
    end

    ret = string(ret, "-v", version, "-", triplet(platform))
    return string(ret, ".tar.gz")
end

"""
    export_artifacts!(u::Universe, jll::JLLInfo, tag_name::String, output_dir::String)

Given the built artifacts referenced by `jll`, export them to compressed
archives in `output_dir`, and update the `JLLArtifactBinding` objects
within `jll` to point to the location they will eventually be uploaded
to.  This function does not do the actual uploading, it merely fills
out the directory and the `jll` object.
"""
function export_artifacts!(u::Universe, jll::JLLInfo, tag_name::String,
                           output_dir::String; compressor::String="gzip")
    function update_binding!(binding, filepath)
        if u.deploy_org !== nothing
            tarball_hash = open(io -> SHA256Hash(sha256(io)), filepath)
            filename = basename(filepath)
            push!(binding.download_sources, JLLArtifactSource(
                string("https://github.com/$(u.deploy_org)/$(jll.name)_jll.jl/releases/download/$(tag_name)/$(filename)"),
                tarball_hash,
            ))
        end
    end

    # This will expand to something like `/tmp/foo/readline-v1.0.0-x86_64-linux-gnu.tar.gz`
    function get_tarball_path(build, name)
        return joinpath(output_dir, exported_artifact_filename(
            build.name,
            name,
            jll.version,
            build.platform,
        ))
    end

    # Archive each artifact, multi-threaded
    @sync begin
        for build in jll.builds
            Threads.@spawn begin
                # Archive the main artifact
                rm(get_tarball_path(build, nothing); force=true)
                try
                    TreeArchival.archive(
                        artifact_path(u, build.artifact.treehash),
                        get_tarball_path(build, nothing),
                        compressor,
                    )
                catch e
                    @error(
                        "Unable to export artifact",
                        artifact_path=artifact_path(u, build.artifact.treehash),
                        tarball_path=get_tarball_path(build, nothing),
                        compressor,
                        jll.name,
                        build.name,
                    )
                    rethrow(e)
                end
                update_binding!(build.artifact, get_tarball_path(build, nothing))

                # Next, archive each auxilliary artifact as well
                for (aux_name, art) in build.auxilliary_artifacts
                    TreeArchival.archive(
                        artifact_path(u, art.treehash),
                        get_tarball_path(build, aux_name),
                        compressor,
                    )
                    update_binding!(art, get_tarball_path(build, aux_name))
                end
            end
        end
    end
end

"""
    deploy_jll(jll_path::String, deploy_org::String, jll_name::String
               tag_name::String, binaries_dir::String)

Deploy a jll to its repo in the given `deploy_org`.  Create a release to hold
the binaries and upload the binaries alongside the code.
"""
function deploy_jll(jll_path::String,
                    deploy_org::Union{Nothing,String},
                    branch_name::Union{Nothing,String},
                    jll_name::String,
                    tag_name::String,
                    binaries_dir::String,
                    verbose::Bool)
    # Early-exit if we're not actually deploying this up somewhere
    if deploy_org === nothing
        return
    end

    # Tag the JLL
    tag!(jll_path, tag_name; force=true)

    # Push it up to the github remote
    if verbose
        repo_url = "https://github.com/$(deploy_org)/$(jll_name)_jll.jl"
        if branch_name !== nothing
            repo_url = "$(repo_url)/tree/$(branch_name)"
        end 
        @info("Pushing JLL code", repo_url)
    end
    github_remote = "https://github.com/$(deploy_org)/$(jll_name)_jll.jl"
    remote_url!(jll_path, deploy_org, github_remote)
    push!(jll_path, deploy_org; force=true)

    # Upload binaries to a github release attached to the tag we just pushed
    if verbose
        @info("Uploading artifacts to GitHub release",
            url="https://github.com/$(deploy_org)/$(jll_name)_jll.jl/releases/$(tag_name)",
        )
    end
    create_cmd = `$(gh()) release create --repo $(deploy_org)/$(jll_name)_jll.jl $(tag_name) --title $(tag_name) --notes "" --verify-tag $(readdir(binaries_dir; join=true))`
    if !success(create_cmd)
        run(`$(gh()) release delete --yes --repo $(deploy_org)/$(jll_name)_jll.jl $(tag_name)`)
        run(create_cmd)
    end
end

function init_jll_repo(u::Universe, jll_name::String)
    # There are four possible control flows here:
    #  - The remote JLL repository already exists and we are deploying
    #    -> Clone it, fork it on github and push back up to it
    #  - The remote JLL repository already exists and we are not deploying
    #    -> Clone it
    #  - The remote JLL repository does not exist and we are deploying
    #    -> Create a new repo, clone it, and push back up to it
    #  - The remote JLL repository does not exist and we are not deploying
    #    -> Create a local bare repo

    # Note that we search for the "upstream" repo URL here only in our non-BB2Local registry
    jll_repo_url = get_package_repo(u, "$(jll_name)_jll"; registries=u.registry_instances[2:end])
    jll_bare_repo = joinpath(source_download_cache(), "jll_clones", "$(jll_name)_jll")

    # This is the case if this was previously registered within this
    # universe when it did not exist previously.  In this case, nuke it.
    if jll_repo_url == jll_bare_repo
        jll_repo_url = nothing
    end

    rm(jll_bare_repo; force=true, recursive=true)
    if u.deploy_org !== nothing
        fork_org_repo = "$(u.deploy_org)/$(jll_name)_jll.jl"
        fork_url = "https://github.com/$(fork_org_repo)"
        if jll_repo_url === nothing
            if !gh_repo_exists(fork_org_repo)
                @debug("Creating and cloning JLL fork", fork_url)
                gh_create(fork_org_repo)
                sleep(1)
            end
        else
            if !gh_repo_exists(fork_org_repo)
                @debug("Forking and cloning JLL", fork_url)
                gh_fork(jll_repo_url, u.deploy_org)
                sleep(1)
            else
                @debug("Cloning existing JLL fork", fork_url)
            end
        end
        jll_repo_url = fork_url
        clone!(fork_url, jll_bare_repo)
    else
        if jll_repo_url === nothing
            jll_repo_url = jll_bare_repo
            @debug("Initializing JLL repo", jll_bare_repo)
            init!(jll_bare_repo)
        else
            @debug("Cloning existing JLL repo", jll_repo_url)
            clone!(jll_repo_url, jll_bare_repo)
        end
    end
    return jll_repo_url, jll_bare_repo
end

const fetched_registries = Set{Base.UUID}()
function get_registry_clone(uni::Universe, reg::RegistrySpec, branch_name::String;
                            cache_dir::String = joinpath(source_download_cache(), "registry_clones"),
                            force::Bool = false)
    reg_checkout_path = joinpath(uni.depot_path, "deploy_registries", reg.name)
    if force
        rm(reg_checkout_path; recursive=true, force=true)
    end

    reg_clone_path = joinpath(cache_dir, reg.name)
    # Only hit the network if we haven't fetched this registry this session
    if force || reg.uuid ∉ fetched_registries
        clone!(reg.url, reg_clone_path)
        push!(fetched_registries, reg.uuid)
    end

    if !isdir(reg_checkout_path)
        # Check out the head commit to that path
        head_commit = only(log(reg_clone_path; limit=1))
        reg_branch_name = branch_name !== nothing ? branch_name : head_branch(reg_clone_path)
        checkout!(reg_clone_path, reg_checkout_path, head_commit)

        # Make sure we're on the right branch name
        branch!(reg_checkout_path, reg_branch_name)
    end

    return reg_checkout_path
end

"""
    register_jll!(u::Universe, jll::JLLInfo)

Given a `JLLInfo`, generate the JLL out into the `dev` folder of the given universe,
upload the JLL and its binaries to the universe's `deploy_org`, and push up the
registry changes as well.
"""
function register_jll!(u::Universe, jll::JLLInfo; skip_artifact_export::Bool = false, verbose::Bool = false)
    # Clone/fork/init ourselves a git repo
    if verbose
        @info("Initializing JLL repository", name=jll.name)
    end
    jll_repo_url, jll_bare_repo = init_jll_repo(u, jll.name)

    jll_path = joinpath(u.depot_path, "dev", "$(jll.name)_jll")
    export_dir = joinpath(u.depot_path, "tarballs", string(jll.name, "-v", jll.version))
    rm(jll_path; force=true, recursive=true)
    rm(export_dir; force=true, recursive=true)
    mkpath(export_dir)

    uni_branch_name = "bb2/$(u.name)"
    if u.name !== nothing
        if isbranch(jll_bare_repo, uni_branch_name)
            src_branch = uni_branch_name
        else
            src_branch = head_branch(jll_bare_repo)
        end
    else
        src_branch = head_branch(jll_bare_repo)
    end

    checkout!(jll_bare_repo, jll_path, src_branch)
    if u.name !== nothing
        branch!(jll_path, uni_branch_name)
    end

    # First, we have to archive each artifact into a tarball
    # and update the JLLArtifactBinding with some download sources (if non-local deploy)
    if u.name !== nothing
        tag_name = "v$(jll.version)-$(u.name)"
    else
        tag_name = "v$(jll.version)"
    end
    if !skip_artifact_export
        if verbose
            @info("Compressing artifacts", num_artifacts=length(jll.builds))
        end
        export_artifacts!(u, jll, tag_name, export_dir)
    end

    # Next, generate the JLL in-place and commit it
    generate_jll(jll_path, jll)
    commit!(jll_path, "$(jll.name) v$(jll.version)")
    deploy_jll(jll_path, u.deploy_org, uni_branch_name, jll.name, tag_name, export_dir, verbose)

    in_universe(u) do env
        # Next, add that JLL to the universe's environment
        Pkg.develop(;path=jll_path)
    end

    # Finally, register it into the universe's local BB2 registry
    reg_path = registry_path(u, first(u.registries))
    LocalRegistry.register(
        jll_path;
        registry=reg_path,
        commit=true,
        push=false,
        # We add `.git` here to better match what is already in the General repository
        repo="$(jll_repo_url).git",
    )

    # Reload our cached RegistryInstance
    u.registry_instances[1] = RegistryInstance(reg_path)

    # Push the registry branch up
    if u.deploy_org !== nothing
        # If we're deploying, we actually need to re-register into our target registry (usually `General`)
        # In order to do that, we also need to make a clone of General, so let's do that here:
        target_reg = first(u.registries[2:end])
        target_reg_path = get_registry_clone(u, target_reg, uni_branch_name)

        LocalRegistry.register(
            jll_path;
            registry=target_reg_path,
            commit=true,
            push=false,
            repo=jll_repo_url,
        )

        reg_org_repo = "$(u.deploy_org)/$(target_reg.name)"
        if !gh_repo_exists(reg_org_repo)
            gh_fork(reg.url, u.deploy_org)
        end
        remote_url!(target_reg_path, u.deploy_org, "https://github.com/$(reg_org_repo)")
        push!(target_reg_path, u.deploy_org; force=true)
    end
end

import Pkg
function Pkg.instantiate(u::Universe; kwargs...)
    in_universe(u) do env
        Pkg.instantiate(; kwargs...)
    end
end
