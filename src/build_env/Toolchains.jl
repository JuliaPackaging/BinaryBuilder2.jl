using Pkg.Types: VersionSpec

"""
    AbstractToolchain

An `AbstractToolchain` represents a set of JLLs that should be downloaded to
provide some kind of build capability; an example of which is the C toolchain
which is used in almost every recipe, but fortran, go, rust, etc.. are all
other toolchains which can be included in the build environment.

All toolchains must define the following methods:

* Constructor
    - used to configure tool versions, etc...
* toolchain_deps(::T, platform)
    - (returns a vector of `AbstractDependency`'s representing the dependencies
       needed to run this toolchain)

TODO: express compiler wrappers as an AbstractDependency called a ComputedDependency
that gets the `config` object (or similar) and generates the wrappers out to a
directory which then gets mounted in!
"""
abstract type AbstractToolchain; end

# C/C++ cross-compilers!  Both GCC and Clang!
include("toolchains/c_toolchain.jl")

# Biting off more than I can chew?  I don't even know what that means...
#include("toolchains/fortran_toolchain.jl")
#include("toolchains/go_toolchain.jl")
#include("toolchains/rust_toolchain.jl")

# General host tools that are target-independent, like `Make`, `ccache`, etc...
include("toolchains/host_toolchain.jl")


function default_toolchains(platform::CrossPlatform)
    return AbstractToolchain[
        # One C toolchain that targets our actualy target
        CToolchain(;platform = platform),

        # One C toolchain that targets our host!
        CToolchain(;platform = CrossPlatform(platform.host, platform.host)),
        HostToolchain(;platform = platform.host)
    ]
end


"""
    toolchain_map(platform, target_deps, host_deps, toolchains)

Takes in the list of target/host dependencies and toolchain objects, returning a `Dict`
mapping sandbox prefixes to the appropriate lists of sources to download.  This 
"""
function toolchain_map(platform::CrossPlatform,
                       target_deps::Vector{<:JLLSource} = JLLSource[],
                       host_deps::Vector{<:JLLSource} = JLLSource[],
                       toolchains::Vector{<:AbstractToolchain} = default_toolchains(platform))
    dep_trees = Dict{String,Vector{JLLSource}}()

    function append_tree!(dep_trees, prefix, jlls)
        if !haskey(dep_trees, prefix)
            dep_trees[prefix] = JLLSource[]
        end
        append!(dep_trees[prefix], jlls)
    end
    
    # For each toolchain, throw it into the relevant dependency trees:
    for toolchain in toolchains
        append_tree!(
            dep_trees,
            toolchain_prefix(toolchain),
            toolchain_deps(toolchain),
        )
    end

    # Next, add all target dependencies into `/workspace/destdir`
    append_tree!(dep_trees, "/workspace/destdir", target_deps)

    # Add more custom host deps to `/usr/local`
    append_tree!(dep_trees, "/usr/local", host_deps)

    # Finally, let's de-duplicate our JLL sources being installed in each tree,
    # respecting version bounds if they are given:
    for (prefix, jlls) in dep_trees
        # Find duplicates
        dups_by_name = Dict{String,Vector{JLLSource}}()
        for jll in jlls
            if !haskey(dups_by_name, jll.package.name)
                dups_by_name[jll.package.name] = JLLSource[]
            end
            push!(dups_by_name[jll.package.name], jll)
        end

        # If we find any duplicates, make sure they can resolve down to a single JLL:
        final_jlls = JLLSource[]
        for (name, jlls) in dups_by_name
            # Check version bounds are fulfillable:
            versions = [jll.package.version for jll in jlls]
            version = foldl(intersect, versions)
            if isempty(version)
                @error("Invalid multiple version constraints on JLL", name, versions)
                throw(ArgumentError("Invalid multiple version constraints!"))
            end

            # Check all other fields are identical:
            if any(jll.package.url != jlls[1].package.url for jll in jlls) ||
               any(jll.package.repo != jlls[1].package.repo for jll in jlls) ||
               any(jll.package.uuid != jlls[1].package.uuid for jll in jlls) ||
               any(jll.target != jlls[1].target for jll in jlls)
                @error("Invalid multiple source specifications on JLL", name, jlls)
                throw(ArgumentError("Invalid multiple source specifications!"))
            end

            # Create new JLLSource object with collapsed version spec
            new_pkgspec = deepcopy(jlls[1].package)
            new_pkgspec.version = version
            push!(final_jlls, JLLSource(new_pkgspec, jlls[1].platform; target=jlls[1].target))
        end
        dep_trees[prefix] = final_jlls
    end
    return dep_trees
end

