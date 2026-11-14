using BinaryBuilder2, ParallelTestRunner

# Each entry runs in a worker process of its own; the slow `BuildAPI` files run as separate
# entries so that their builds overlap.  ParallelTestRunner seeds the global RNG
# identically for every entry, but tests rely on it for unique universe names and remote
# branch names, so reseed it.
function include_test(file)
    return quote
        Random.seed!()
        include($(joinpath(@__DIR__, file)))
    end
end
testsuite = Dict{String,Expr}(
    "StorageLocations" => include_test("StorageLocationsTests.jl"),
    "MonorepoCompat" => include_test("MonorepoCompatTests.jl"),
    "ContentReflection" => include_test("ContentReflectionTests.jl"),
    "BuildCache" => include_test("BuildCacheTests.jl"),
    "ExtractConfig" => include_test("ExtractConfigTests.jl"),
    "BuildMeta" => include_test("BuildMetaTests.jl"),
    "Universes" => include_test("UniversesTests.jl"),
    "AccessToken" => include_test("AccessTokenTests.jl"),
    "PackageAudit" => include_test("PackageAuditTests.jl"),
    "BuildAPI" => include_test("BuildAPITests.jl"),
    "BuildAPI/LowLevelBuild" => include_test("BuildAPITests/LowLevelBuildTests.jl"),
    "BuildAPI/Convenience" => include_test("BuildAPITests/ConvenienceTests.jl"),
    "BuildAPI/MultiJLLOutput" => include_test("BuildAPITests/MultiJLLOutputTests.jl"),
    "BuildAPI/CustomSpec" => include_test("BuildAPITests/CustomSpecTests.jl"),
    "BuildAPI/BuildSelection" => include_test("BuildAPITests/BuildSelection.jl"),
    "BuildAPI/FrameworkProduct" => include_test("BuildAPITests/FrameworkProductTests.jl"),
)

init_code = quote
    import Random
    include($(joinpath(@__DIR__, "TestingUtils.jl")))
end

# A worker that runs builds holds on to a few GiB
runtests(BinaryBuilder2, ARGS; testsuite, init_code, memory_per_worker = 4 * 2^30)
