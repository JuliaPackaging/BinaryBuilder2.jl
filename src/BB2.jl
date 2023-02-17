module BB2

using TreeArchival, MultiHashParsing

include("ExtractKwargs.jl")
include("PlatformExtensions.jl")
include("GitUtils.jl")
include("Sources.jl")
include("Preferences.jl")
include("Dependencies.jl")
include("Products.jl")
include("BuildMeta.jl")


include("build_env/Toolchains.jl")
include("build_env/Sandbox.jl")

end
