using Pkg
using Pkg.Types: PackageSpec, VersionSpec, Context, EnvCache, registry_resolve!, PRESERVE_NONE
using Pkg.API: handle_package_input!
using Pkg.Operations: targeted_resolve

function resolve(pkgs::Vector{PackageSpec}; julia_version::Union{Nothing,VersionNumber}=VERSION)
    any_unresolved(pkgs) = any(pkg.uuid === nothing for pkg in pkgs)
    # There doesn't seem to be a better way to get an "empty" `EnvCache`
    # than to construct it off of an empty directory, so that's what we do
    mktempdir() do dir
        ctx = Context(;env=EnvCache(dir))

        # Don't mutate the user's input
        pkgs = copy(pkgs)

        # Normalize each pkg
        handle_package_input!.(pkgs)

        # If any are unresolved, try to resolve them:
        if any_unresolved(pkgs)
            registry_resolve!(ctx.registries, pkgs)

            # If any are still unresolved, try updating the registry
            if any_unresolved(pkgs)
                specs = [Pkg.Registry.RegistrySpec(;name=r.name, uuid=r.uuid, url=r.repo, path=r.path) for r in ctx.registries]
                Pkg.Registry.update(specs; force=true)
                # Re-create `ctx` to get the new registry states
                ctx = Context(;env=EnvCache(dir))
                registry_resolve!(ctx.registries, pkgs)

                # If any are _still_ unresolved, error out
                for pkg in pkgs
                    if pkg.uuid === nothing
                        throw(ArgumentError("Unable to resolve '$(pkg.name)', is it registered?"))
                    end
                end
            end
        end

        # Resolve to get versions
        pkgs, deps_map = Pkg.Operations.targeted_resolve(
            ctx.env,
            ctx.registries,
            pkgs,
            PRESERVE_NONE,
            julia_version,
        )
        return pkgs
    end
end

# Calls `resolve()` but only returns pkgs we asked for, in a Dict
function resolve_versions(pkgs::Vector{PackageSpec}; julia_version::Union{Nothing,VersionNumber}=VERSION)
    # Force all pkgs to have a UUID, so we can match them afterward
    registry_resolve!(Context().registries, pkgs)

    pkgs_uuids = Set(p.uuid for p in pkgs)
    pkgs = resolve(pkgs; julia_version)
    return Dict{String,PackageSpec}(pkg.name => pkg for pkg in pkgs if pkg.uuid ∈ pkgs_uuids)
end

"""
    update_pkgspec_versions!(pkgs::Vector{PackageSpec}, new_versions::Dict{String,PackageSpec})

Allows updating (in place!) a set of `PackageSpec`s with new versions.  Used
to update the internal `PackageSpec` objects of `JLLSource`s with new results
from `resolve_pkg_versions()`.
"""
function update_pkgspec_versions!(pkgs::Vector{PackageSpec}, new_versions::Dict{String,PackageSpec})
    for pkg in pkgs
        if haskey(new_versions, pkg.name)
            pkg.version = new_versions[pkg.name].version
        end
    end
    return
end

"""
    resolve_versions!(jlls::Vector{JLLSource}; julia_version)

Given a vector of `JLLSource`'s, resolve any that are not already concretized
down to a specific version, 
"""
function resolve_versions!(jlls::Vector{JLLSource}; julia_version::Union{Nothing,VersionNumber}=VERSION)
    # Get a new set of versions for the jlls' package specs
    # Ignore any package that already has a `treehash` or a `repo` field.
    already_resolved(p) = p.tree_hash !== nothing ||
                         (p.repo !== nothing && p.repo.rev !== nothing)
    jll_pkgs = [jll.package for jll in jlls if !already_resolved(jll.package)]

    # Resolve these into a new set of versions
    resolved_pkgs = resolve_versions(jll_pkgs; julia_version)

    # Apply them to the JLLSource objects.  This relies on the fact that we are
    # updating the `PackageSpec`'s `version` field in-place!
    update_pkgspec_versions!(jll_pkgs, resolved_pkgs)
end

function filter_illegal_versionspecs!(pkgs::Vector{PackageSpec})
    for pkg in pkgs
        if pkg.repo.source !== nothing || pkg.repo.rev !== nothing
            pkg.version = VersionSpec()
        end
    end
end
