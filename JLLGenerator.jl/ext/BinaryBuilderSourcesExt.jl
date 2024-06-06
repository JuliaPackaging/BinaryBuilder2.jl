module BinaryBuilderSourcesExt

# Define adapters to convert from `AbstractSource` objects to `JLLSourceRecord` objects:
using BinaryBuilderSources, JLLGenerator, Pkg, TOML
JLLGenerator.JLLSourceRecord(as::AbstractSource) = JLLSourceRecord(source(as), content_hash(as))

# Define an adapter to go from a `JLLSource` to its TOML
using BinaryBuilderSources.JLLPrefixes: with_depot_path
function Base.pkgdir(j::JLLSource)
    if j.package.path !== nothing
        return j.package.path
    end
    return Pkg.Operations.find_installed(j.package.name, j.package.uuid, j.package.tree_hash)
end
function JLLGenerator.parse_toml_dict(j::JLLSource; depot::Union{Nothing,String} = nothing)
    local pkg_dir
    if depot === nothing
        pkg_dir = pkgdir(j)
    else
        with_depot_path(depot) do
            pkg_dir = pkgdir(j)
        end
    end
    jll_toml_path = joinpath(pkg_dir, "JLL.toml")
    if !isfile(jll_toml_path)
        throw(ArgumentError("JLL $(j.package.name) v$(j.package.version) has no JLL.toml file!  Was it built by BB2?"))
    end
    return parse_toml_dict(TOML.parsefile(jll_toml_path))
end

end # module
