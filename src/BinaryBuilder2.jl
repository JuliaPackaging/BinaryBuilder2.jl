module BinaryBuilder2

# A way for various pieces of BB2 to run things at `__init__` time
const init_hooks = Function[]

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


function __init__()
    for hook in init_hooks
        try
            hook()
        catch e
            @error("Init hook failed!", e)
        end
    end
end


end # module
