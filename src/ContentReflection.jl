using MultiHashParsing, TreeArchival

const pkg_list = [
    :BinaryBuilder2,
    :BinaryBuilderAuditor, :BinaryBuilderGitUtils, :BinaryBuilderPlatformExtensions,
    :BinaryBuilderProducts, :BinaryBuilderSources, :BinaryBuilderToolchains,
    :JLLGenerator, :LazyJLLWrappers, :MultiHashParsing, :Sandbox, :JLLPrefixes, :TreeArchival
]
for pkg_name in pkg_list
    if pkg_name == :BinaryBuilder2
        continue
    end
    @eval import $(pkg_name)
end
function pkg_treehash(pkg_name::Symbol)
    if pkg_name == :BinaryBuilder2
        pkg_dir = dirname(@__DIR__)
    else
        pkg_dir = Base.pkgdir(getproperty(@__MODULE__, pkg_name))
    end
    return SHA1Hash(TreeArchival.treehash(joinpath(pkg_dir, "src")))
end
const treehash_cache = Dict{String, SHA1Hash}(string(pkg_name) => pkg_treehash(pkg_name) for pkg_name in pkg_list)

"""
    bb_package_treehashes()

Returns a dictionary mapping name to treehash for every BinaryBuilder2-associated package
that should be considered as sensitive toward reproducible building.  See the definition
of `content_hash(::BuildConfig)` for more.
"""
function bb_package_treehashes()
    return treehash_cache
end
