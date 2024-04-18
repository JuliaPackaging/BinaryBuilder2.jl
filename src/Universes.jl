using Pkg.Registry: RegistrySpec
using Artifacts
using JLLGenerator
using Random, TOML
using BinaryBuilderGitUtils
import LazyJLLWrappers
import LocalRegistry

export Universe, register!, in_universe

const updated_registries = Set{Base.UUID}()

function update_and_checkout_registries!(registries::Vector{RegistrySpec},
                                         depot_path::String;
                                         cache_dir::String = joinpath(source_download_cache(), "registry_clones"),
                                         force::Bool = false)
    # For each registry, update it and then check it out into the given `depot_path`
    # if it does not already exist there.
    mkpath(joinpath(depot_path, "registries"))
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
                symlink(
                    shared_dir,
                    joinpath(depot_path, name);
                    dir_target = true,
                )
            end
        catch e
            rethrow()
        end

        # Ensure the registries are up to date, with our commits replayed on top
        update_and_checkout_registries!(registries, depot_path; kwargs...)

        # Ensure that this universe's environment uses our version of LazyJLLWrappers,
        # since we may be testing things or have some local patch.
        uni = new(depot_path, registries)
        Pkg.activate(environment_path(uni)) do
            Pkg.develop(;path=joinpath(Base.pkgdir(LazyJLLWrappers)))
        end

        return uni
    end
end

Artifacts.artifact_path(u::Universe, hash::Base.SHA1) = joinpath(u.depot_path, "artifacts", bytes2hex(hash.bytes))

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
function in_universe(f::Function, u::Universe; extra_depots::Vector{String} = String[], append_bundled_depot_path::Bool = true)
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
        if isdefined(Base, :append_bundled_depot_path)
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
        f(env)
    finally
        # No matter what happens, reset the DEPOT_PATH to what it should be.
        empty!(Base.DEPOT_PATH)
        append!(Base.DEPOT_PATH, old_depot_path)
    end
end

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
    register!(u::Universe, jll::JLLInfo)

Given a `JLLInfo`, generate the JLL out into the `dev` folder of the given universe,
"""
function register!(u::Universe, jll::JLLInfo)
    in_universe(u) do env
        # If there already happens to be a JLL with this name registered
        # in one of the registries for this universe, clone it and check
        # it out to `dev/$(jll.name)!`
        jll_repo_url = get_package_repo(u, jll.name)
        jll_repo_path = joinpath(source_download_cache(), "jll_clones", "$(jll.name)_jll")
        rm(jll_repo_path; force=true, recursive=true)
        if jll_repo_url !== nothing
            clone!(jll_repo_url, jll_repo_path)
        else
            # If there does not already exists a JLL by this name, just
            # create a new bare git repo.
            init!(jll_repo_path)
        end
        jll_path = joinpath(u.depot_path, "dev", "$(jll.name)_jll")
        rm(jll_path; force=true, recursive=true)
        checkout!(jll_repo_path, jll_path)

        # Next, generate the JLL in-place and commit it
        generate_jll(jll_path, jll)
        commit!(jll_path, "$(jll.name) v$(jll.version)")

        # Next, add that JLL to the universe's environment
        Pkg.activate(environment_path(u)) do
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
end

import Pkg
function Pkg.instantiate(u::Universe; kwargs...)
    in_universe(u) do env
        Pkg.activate(u.depot_path)
        Pkg.instantiate(; kwargs...)
    end
end
