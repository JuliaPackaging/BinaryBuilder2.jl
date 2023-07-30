module BB2

using Reexport
@reexport using TreeArchival
@reexport using MultiHashParsing
@reexport using BinaryBuilderSources
@reexport using BinaryBuilderToolchains
@reexport using Base.BinaryPlatforms

include("ExtractKwargs.jl")
include("Preferences.jl")
include("Products.jl")
include("BuildAPI.jl")


include("build_env/Toolchains.jl")

include("Compat.jl")
include("precompile.jl")
end
