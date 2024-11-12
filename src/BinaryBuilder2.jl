module BinaryBuilder2

using Reexport
@reexport using TreeArchival
@reexport using MultiHashParsing
@reexport using BinaryBuilderSources
@reexport using BinaryBuilderToolchains
@reexport using BinaryBuilderProducts
@reexport using Base.BinaryPlatforms

include("Preferences.jl")
include("ContentReflection.jl")
include("GitHubUtils.jl")
include("Universes.jl")
include("PlatformlessWrappers.jl")

abstract type AbstractBuildMeta; end

include("build_api/BuildTargetSpec.jl")
include("build_api/BuildConfigDefaults.jl")
include("build_api/BuildConfig.jl")
include("build_api/BuildResult.jl")
include("build_api/ExtractConfig.jl")
include("build_api/ExtractResult.jl")
include("build_api/ExtractSpec.jl")
include("build_api/PackageConfig.jl")
include("build_api/PackageResult.jl")
include("BuildCache.jl")
include("build_api/BuildMeta.jl")
include("build_api/Convenience.jl")

include("Compat.jl")
include("Maintenance.jl")
include("precompile.jl")
end
