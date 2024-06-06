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
                                         depot_path::String;
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
Building and deploying into a registry
"""
struct Universe
    depot_path::String
    registries::Vector{RegistrySpec}
    
    function Universe(depot_path::AbstractString = joinpath(universes_dir(), string(round(Int, time()), "-", randstring(4)));
                      registries::Vector{RegistrySpec} = Pkg.Registry.DEFAULT_REGISTRIES,
                      persistent::Bool = false,
                      kwargs...)
        if isempty(registries)
            throw(ArgumentError("Must pass at least one registry to `Universe()`!"))
        end
        depot_path = String(depot_path)
        mkpath(depot_path)
        depot_path = abspath(depot_path)

        # We always attempt to share the `artifacts` and `packages` directories of our universe with the `jllsource_depot`.
        try
            for name in ("artifacts", "packages")
                shared_dir = joinpath(BinaryBuilderSources.default_jll_source_depot(), name)
                mkpath(shared_dir)
                if !ispath(joinpath(depot_path, name))
                    symlink(
                        shared_dir,
                        joinpath(depot_path, name);
                        dir_target = true,
                    )
                end
            end
        catch
            rethrow()
        end

        # Ensure the registries are up to date, with our commits replayed on top
        update_and_checkout_registries!(registries, depot_path; kwargs...)

        # Ensure that this universe's environment uses our version of LazyJLLWrappers,
        # since we may be testing things or have some local patch.
        uni = new(depot_path, registries)
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

function exported_artifact_filename(jll_name::String,
                                    build_name::String,
                                    auxiliary_name::Union{Nothing,String},
                                    version::VersionNumber,
                                    platform::AbstractPlatform)
    ret = jll_name

    # If this is the default build, we just omit default for brevity
    if build_name != "default"
        ret = string(ret, "-", build_name)
    end

    if auxiliary_name !== nothing
        ret = string(ret, "-", auxiliary_name)
    end

    ret = string(ret, "-v", version, "-", triplet(platform))
    return string(ret, ".tar.gz")
end

"""
    export_artifacts!(u::Universe, jll::JLLInfo, deploy_target::String, output_dir::String)
"""
function export_artifacts!(uni::Universe, jll::JLLInfo, tag_name::String,
                           deploy_target::String, output_dir::String;
                           compressor::String="gzip")
    function update_binding!(binding, filepath)
        if deploy_target != "local"
            tarball_hash = open(io -> SHA256Hash(sha256(io)), filepath)
            filename = basename(filepath)
            push!(binding.download_sources, JLLArtifactSource(
                string("https://github.com/$(deploy_target)/$(jll.name)_jll.jl/releases/download/$(tag_name)/$(filename)"),
                tarball_hash,
            ))
        end
    end

    for build in jll.builds
        # Archive the main artifact
        # This will expand to something like `/tmp/foo/readline-v1.0.0-x86_64-linux-gnu.tar.gz`
        exported_artifact_path = joinpath(output_dir, exported_artifact_filename(
            jll.name,
            build.name,
            nothing,
            jll.version,
            build.platform,
        ))
        TreeArchival.archive(
            artifact_path(uni, build.artifact.treehash),
            exported_artifact_path,
            compressor,
        )
        # Update the binding
        update_binding!(build.artifact, exported_artifact_path)
        
        # Next, archive each auxilliary artifact as well
        for (aux_name, art) in build.auxilliary_artifacts
            exported_artifact_path = joinpath(output_dir, exported_artifact_filename(
                jll.name,
                build.name,
                aux_name,
                jll.version,
                build.platform,
            ))

            TreeArchival.archive(
                artifact_path(uni, art.treehash),
                exported_artifact_path,
                compressor,
            )
            update_binding!(art, exported_artifact_path)
        end
    end
end

function deploy_jll(jll_path::String, deploy_target::String, jll_name::String,
                    tag_name::String, binaries_dir::String)
    # Early-exit if we're not actually deploying this up somewhere
    if deploy_target == "local"
        return
    end

    github_remote = "https://github.com/$(deploy_target)/$(jll_name)_jll.jl"
    remote_url!(jll_path, deploy_target, github_remote)
    push!(jll_path, deploy_target; force=true)

    # Upload binaries to a github release attached to the tag we just pushed
    create_cmd = `$(gh()) release create --repo $(deploy_target)/$(jll_name)_jll.jl $(tag_name) --title $(tag_name) --notes "" --verify-tag $(readdir(binaries_dir; join=true))`
    if !success(create_cmd)
        run(`$(gh()) release delete --yes --repo $(deploy_target)/$(jll_name)_jll.jl $(tag_name)`)
        run(create_cmd)
    end
end

"""
    register_jll!(u::Universe, jll::JLLInfo, deploy_target::String)

Given a `JLLInfo`, generate the JLL out into the `dev` folder of the given universe,
"""
function register_jll!(u::Universe, jll::JLLInfo, deploy_target::String; skip_artifact_export::Bool = false)
    # There are three possible control flows here:
    #  - The remote JLL repository already exists and we are deploying
    #    -> Clone it, fork it on github and push back up to it
    #  - The remote JLL repository already exists and we are not deploying
    #    -> Clone it
    #  - The remote JLL repository does not exist and we are deploying
    #    -> Create a new repo, clone it, and push back up to it
    #  - The remote JLL repository does not exit and we are not deploying
    #    -> Create a local bare repo
    jll_repo_url = get_package_repo(u, "$(jll.name)_jll")
    jll_repo_path = joinpath(source_download_cache(), "jll_clones", "$(jll.name)_jll")
    rm(jll_repo_path; force=true, recursive=true)
    if deploy_target != "local"
        fork_url = "https://github.com/$(deploy_target)/$(jll.name)_jll.jl"
        if jll_repo_url === nothing
            jll_repo_url = fork_url
            gh_create("$(deploy_target)/$(jll.name)_jll.jl")
        else
            gh_fork(jll_repo_url, deploy_target)
            clone!(fork_url, jll_repo_path)
        end
    else
        if jll_repo_url !== nothing
            clone!(jll_repo_url, jll_repo_path)
        else
            init!(jll_repo_path)
        end
    end

    jll_path = joinpath(u.depot_path, "dev", "$(jll.name)_jll")
    rm(jll_path; force=true, recursive=true)
    checkout!(jll_repo_path, jll_path, head_branch(jll_repo_path))

    export_dir = joinpath(u.depot_path, "tarballs", string(jll.name, "-v", jll.version))
    rm(export_dir; force=true, recursive=true)
    mkpath(export_dir)

    # First, we have to archive each artifact into a tarball
    # and update the JLLArtifactBinding with some download sources (if non-local deploy)
    tag_name = "v$(jll.version)"
    if !skip_artifact_export
        export_artifacts!(u, jll, tag_name, deploy_target, export_dir)
    end

    # Next, generate the JLL in-place and commit it
    generate_jll(jll_path, jll)
    commit!(jll_path, "$(jll.name) v$(jll.version)")
    tag!(jll_path, tag_name; force=true)
    deploy_jll(jll_path, deploy_target, jll.name, tag_name, export_dir)

    in_universe(u) do env
        # Next, add that JLL to the universe's environment
        Pkg.develop(;path=jll_path)
    end

    # Finally, register it into the universe's registry
    LocalRegistry.register(
        jll_path;
        registry=registry_path(u, first(u.registries)),
        commit=true,
        push=false,
        repo=jll_repo_url,
    )
end

import Pkg
function Pkg.instantiate(u::Universe; kwargs...)
    in_universe(u) do env
        Pkg.instantiate(; kwargs...)
    end
end
