module BinaryBuilderPlatformExtensions

using Reexport
@reexport using Base.BinaryPlatforms

include("AnyPlatform.jl")
include("CrossPlatform.jl")
include("PlatformProperties.jl")
include("Microarchitectures.jl")
include("Utils.jl")

end # module BinaryBuilderPlatformExtensions
