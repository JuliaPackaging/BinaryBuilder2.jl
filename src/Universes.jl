using Pkg.Registry: RegistrySpec
using Artifacts
using JLLGenerator
using Random, TOML
using BinaryBuilderGitUtils
import LazyJLLWrappers
import LocalRegistry
import TreeArchival
using Scratch, Pkg, Dates
using gh_cli_jll

export Universe, in_universe

const updated_registries = Set{Base.UUID}()

function update_and_checkout_registries!(registries::Vector{RegistrySpec},
                                         depot_path::String,
                                         branch_name::String;
                                         cache_dir::String = joinpath(source_download_cache(), "registry_clones"),
                                         force::Bool = false)
    # For each registry, update it and then check it out into the given `depot_path`
    # if it does not already exist there.
    mkpath(joinpath(depot_path, "registries"))
    registry_update_toml_path = joinpath(depot_path, "scratchspaces", string(Scratch.find_uuid(Pkg)), "registry_updates.toml")
    if !isfile(registry_update_toml_path)
        registry_update_log = Dict{String, Any}()
    else
        registry_update_log = TOML.parsefile(registry_update_toml_path)
    end

    for reg in registries
        reg_checkout_path = joinpath(depot_path, "registries", reg.name)
        if force
            rm(reg_checkout_path; recursive=true, force=true)
        end

        # If the registry is not checked out locally, update our clone, then check it out
        if !isdir(reg_checkout_path)
            reg_clone_path = joinpath(cache_dir, reg.name)
            # Only hit the network if we haven't updated this registry this session
            if force || reg.uuid ∉ updated_registries
                clone!(reg.url, reg_clone_path)
                push!(updated_registries, reg.uuid)
            end
            head_commit = only(log(reg_clone_path; limit=1))
            checkout!(reg_clone_path, reg_checkout_path, head_commit)
            branch!(reg_checkout_path, branch_name)
        end
        # We arbitrarily add a month onto here, making the optimistic assertion that we will
        # never have a build that takes more than a month.
        registry_update_log[string(reg.uuid)] = now() + Month(1)
    end

    # Tell Pkg not to try to update any of these registries, ever.  We'll always be the one to do so.
    mkpath(dirname(registry_update_toml_path))
    open(registry_update_toml_path; write=true) do io
        TOML.print(io, registry_update_log)
    end
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
                      registries::Vector{RegistrySpec} = Pkg.Registry.DEFAULT_REGISTRIES,
                      registry_url::Union{Nothing,AbstractString} = nothing,
                      persistent::Bool = false,
                      kwargs...)
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
        try
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
        catch
            rethrow()
        end

        # Ensure the registries are up to date, with our commits replayed on top
        update_and_checkout_registries!(registries, depot_path, "bb2/$(name)"; kwargs...)

        if deploy_org !== nothing
            # Authenticate to GitHub, then ensure that we are either deploying to our
            # user, or an organization we are a part of
            ensure_gh_authenticated()
            if deploy_org != gh_user() && deploy_org ∉ gh_orgs()
                throw(ArgumentError("deploy target '$(deploy)' not a user/organization we have access to!"))
            end
        end

        # Ensure that this universe's environment uses our version of LazyJLLWrappers,
        # since we may be testing things or have some local patch.
        uni = new(
            name === nothing ? nothing : string(name),
            depot_path,
            registries,
            deploy_org,
            string(registry_url),
        )
        prune!(uni)
        in_universe(uni) do env
            Pkg.resolve(;io=devnull)
            Pkg.develop(;path=joinpath(Base.pkgdir(LazyJLLWrappers)), io=devnull)
        end

        # If we are not persistent, clean this universe up at the end of our run
        if !persistent
            atexit() do
                rm(depot_path; force=true, recursive=true)
            end
        end

        return uni
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

function registry_path(u::Universe, registry::RegistrySpec)
    return joinpath(u.depot_path, "registries", registry.name)
end

function registry_package_lookup(f::Function, registry_path::String, pkg_name::String)
    reg_toml_path = joinpath(registry_path, "Registry.toml")
    reg_data = Base.parsed_toml(reg_toml_path)
    for (uuid, data) in reg_data["packages"]
        if data["name"] == pkg_name
            return f(joinpath(registry_path, data["path"]))
        end
    end
    return nothing
end

function registry_package_lookup(f::Function, u::Universe, pkg_name::String)
    registry_package_lookup(registry_path(u, first(u.registries)), pkg_name) do pkg_path
        return f(pkg_path)
    end
end

"""
    get_package_repo(u::Universe, pkg_name::String)

Given a package name, return the repository url for that package by looking
through the set of registries within `u`.
"""
function get_package_repo(u::Universe, pkg_name::String)
    registry_package_lookup(u, pkg_name) do pkg_path
        pkg_project_toml_path = joinpath(pkg_path, "Package.toml")
        return TOML.parsefile(pkg_project_toml_path)["repo"]
    end
end

function get_package_versions(u::Universe, pkg_name::String)
    registry_package_lookup(u, pkg_name) do pkg_path
        pkg_versions_toml_path = joinpath(pkg_path, "Versions.toml")
        return parse.(VersionNumber, collect(keys(TOML.parsefile(pkg_versions_toml_path))))
    end
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

    for build in jll.builds
        # Archive the main artifact
        # This will expand to something like `/tmp/foo/readline-v1.0.0-x86_64-linux-gnu.tar.gz`
        exported_artifact_path = joinpath(output_dir, exported_artifact_filename(
            build.name,
            nothing,
            jll.version,
            build.platform,
        ))
        TreeArchival.archive(
            artifact_path(u, build.artifact.treehash),
            exported_artifact_path,
            compressor,
        )
        # Update the binding
        update_binding!(build.artifact, exported_artifact_path)
        
        # Next, archive each auxilliary artifact as well
        for (aux_name, art) in build.auxilliary_artifacts
            exported_artifact_path = joinpath(output_dir, exported_artifact_filename(
                build.name,
                aux_name,
                jll.version,
                build.platform,
            ))

            TreeArchival.archive(
                artifact_path(u, art.treehash),
                exported_artifact_path,
                compressor,
            )
            update_binding!(art, exported_artifact_path)
        end
    end
end

"""
    deploy_jll(jll_path::String, deploy_org::String, jll_name::String
               tag_name::String, binaries_dir::String)

Deploy a jll to its repo in the given `deploy_org`.  Create a release to hold
the binaries and upload the binaries alongside the code.
"""
function deploy_jll(jll_path::String, deploy_org::Union{Nothing,String}, jll_name::String,
                    tag_name::String, binaries_dir::String)
    # Early-exit if we're not actually deploying this up somewhere
    if deploy_org === nothing
        return
    end

    # Tag the JLL
    tag!(jll_path, tag_name; force=true)

    # Push it up to the github remote
    github_remote = "https://github.com/$(deploy_org)/$(jll_name)_jll.jl"
    remote_url!(jll_path, deploy_org, github_remote)
    push!(jll_path, deploy_org; force=true)

    # Upload binaries to a github release attached to the tag we just pushed
    create_cmd = `$(gh()) release create --repo $(deploy_org)/$(jll_name)_jll.jl $(tag_name) --title $(tag_name) --notes "" --verify-tag $(readdir(binaries_dir; join=true))`
    if !success(create_cmd)
        run(`$(gh()) release delete --yes --repo $(deploy_org)/$(jll_name)_jll.jl $(tag_name)`)
        run(create_cmd)
    end
end

"""
    register_jll!(u::Universe, jll::JLLInfo)

Given a `JLLInfo`, generate the JLL out into the `dev` folder of the given universe,
upload the JLL and its binaries to the universe's `deploy_org`, and push up the
registry changes as well.
"""
function register_jll!(u::Universe, jll::JLLInfo; skip_artifact_export::Bool = false)
    # There are four possible control flows here:
    #  - The remote JLL repository already exists and we are deploying
    #    -> Clone it, fork it on github and push back up to it
    #  - The remote JLL repository already exists and we are not deploying
    #    -> Clone it
    #  - The remote JLL repository does not exist and we are deploying
    #    -> Create a new repo, clone it, and push back up to it
    #  - The remote JLL repository does not exit and we are not deploying
    #    -> Create a local bare repo
    jll_repo_url = get_package_repo(u, "$(jll.name)_jll")
    jll_bare_repo = joinpath(source_download_cache(), "jll_clones", "$(jll.name)_jll")
    rm(jll_bare_repo; force=true, recursive=true)
    if u.deploy_org !== nothing
        fork_org_repo = "$(u.deploy_org)/$(jll.name)_jll.jl"
        fork_url = "https://github.com/$(fork_org_repo)"
        if jll_repo_url === nothing
            jll_repo_url = fork_url
            gh_create(fork_org_repo)
        else
            if !gh_repo_exists(fork_org_repo)
                gh_fork(jll_repo_url, u.deploy_org)
            end
        end
        clone!(fork_url, jll_bare_repo)
    else
        if jll_repo_url === nothing
            jll_repo_url = jll_bare_repo
            init!(jll_bare_repo)
        else
            clone!(jll_repo_url, jll_bare_repo)
        end
    end

    jll_path = joinpath(u.depot_path, "dev", "$(jll.name)_jll")
    export_dir = joinpath(u.depot_path, "tarballs", string(jll.name, "-v", jll.version))
    rm(jll_path; force=true, recursive=true)
    rm(export_dir; force=true, recursive=true)
    mkpath(export_dir)

    checkout!(jll_bare_repo, jll_path, head_branch(jll_bare_repo))
    if u.name !== nothing
        branch!(jll_path, "bb2/$(u.name)")
    end

    # First, we have to archive each artifact into a tarball
    # and update the JLLArtifactBinding with some download sources (if non-local deploy)
    if u.name !== nothing
        tag_name = "v$(jll.version)-$(u.name)"
    else
        tag_name = "v$(jll.version)"
    end
    if !skip_artifact_export
        export_artifacts!(u, jll, tag_name, export_dir)
    end

    # Next, generate the JLL in-place and commit it
    generate_jll(jll_path, jll)
    commit!(jll_path, "$(jll.name) v$(jll.version)")
    deploy_jll(jll_path, u.deploy_org, jll.name, tag_name, export_dir)

    in_universe(u) do env
        # Next, add that JLL to the universe's environment
        Pkg.develop(;path=jll_path)
    end

    # Finally, register it into the universe's registry
    reg_path = registry_path(u, first(u.registries))
    LocalRegistry.register(
        jll_path;
        registry=reg_path,
        commit=true,
        push=false,
        repo=jll_repo_url,
    )

    # Push the registry branch up
    if u.deploy_org !== nothing
        reg = first(u.registries)
        reg_org_repo = "$(u.deploy_org)/$(reg.name)"
        if !gh_repo_exists(reg_org_repo)
            gh_fork(reg.url, u.deploy_org)
        end
        remote_url!(reg_path, u.deploy_org, "https://github.com/$(reg_org_repo)")
        push!(reg_path, u.deploy_org; force=true)
    end
end

import Pkg
function Pkg.instantiate(u::Universe; kwargs...)
    in_universe(u) do env
        Pkg.instantiate(; kwargs...)
    end
end
