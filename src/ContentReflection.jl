using SHA

const pkg_list = [
    :BinaryBuilder2,
    :BinaryBuilderAuditor, :BinaryBuilderGitUtils, :BinaryBuilderPlatformExtensions,
    :BinaryBuilderProducts, :BinaryBuilderSources, :BinaryBuilderToolchains,
    :JLLGenerator, :LazyJLLWrappers, :MultiHashParsing, :Sandbox, :JLLPrefixes,
    :TreeArchival, :ScratchSpaceGarbageCollector, :KeywordArgumentExtraction,
    # Don't include LazyJLLWrappers here because it only runs on the client
]

# Import everything
for pkg_name in pkg_list
    if pkg_name == :BinaryBuilder2
        continue
    end
    @eval import $(pkg_name)
end

struct MonorepoPackageHash
    name::String
    hash::SHA1Hash
    version::VersionNumber
end
function MonorepoPackageHash(pkg_name::Symbol)
    if pkg_name == :BinaryBuilder2
        pkg_module = @__MODULE__
        pkg_dir = dirname(@__DIR__)
    else
        pkg_module = getproperty(@__MODULE__, pkg_name)
        pkg_dir = Base.pkgdir(pkg_module)
    end

    src_hash = bytes2hex(SHA1Hash(TreeArchival.treehash(joinpath(pkg_dir, "src"))))
    project_hash = bytes2hex(SHA1Hash(sha1(read(joinpath(pkg_dir, "Project.toml")))))
    pkg_hash = SHA1Hash(sha1(string(src_hash, project_hash)))

    return MonorepoPackageHash(
        string(pkg_name),
        pkg_hash,
        pkgversion(pkg_module),
    )
end
const treehash_cache = Dict{String, MonorepoPackageHash}(string(pkg_name) => MonorepoPackageHash(pkg_name) for pkg_name in pkg_list)

"""
    bb_package_treehashes()

Returns a dictionary mapping name to treehash for every BinaryBuilder2-associated package
that should be considered as sensitive toward reproducible building.  See the definition
of `spec_hash(::BuildConfig)` for more.
"""
function bb_package_treehashes()
    return treehash_cache
end
