using Test, BinaryBuilderToolchains

# Clear out environment variables that can cause problems
for flagvar in ("C", "CPP", "CXX", "LD")
    delete!(ENV, "$(flagvar)FLAGS")
end
for libvar in ("LD", "DYLD")
    delete!(ENV, "$(libvar)_LIBRARY_PATH")
    delete!(ENV, "$(libvar)_FALLBACK_LIBRARY_PATH")
end

include("common.jl")
include("PkgUtilsTests.jl")
include("WrapperUtilsTests.jl")
include("CToolchainTests.jl")
include("HostToolsToolchainTests.jl")
include("CMakeToolchainTests.jl")
