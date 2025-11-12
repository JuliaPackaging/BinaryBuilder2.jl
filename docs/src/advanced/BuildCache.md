# BuildCache

```@docs; canonical=false
BuildCache
```

## Type Usage

The identifying hash of a [`BuildConfig`](@ref) is defined by `content_hash(::BuildConfig)`, which is sensitive to:
 * [`BuildTargetSpec`](@ref BuildTargetSpec) objects, representing all compilers.
 * [`BuildConfig`](@ref BuildConfig) source trees, containing all dependencies.
 * [`BuildConfig`](@ref BuildConfig) script.
 * BinaryBuilder2 and dependent module source hashes.

To see this in action, you can run `content_hash(build_config)` with a logger set to debug, and it will print out both the hash and all the inputs that went into the hash.
Note that you must call `prepare(build_config)` first, to instantiate all dependencies.

```@meta
DocTestSetup = quote
    using BinaryBuilder2, Logging
    include(joinpath(pkgdir(BinaryBuilder2), "test", "TestingUtils.jl"))
    meta = BuildMeta(;dry_run=[:all])
    bts = apply_spec_plan(spec_plan, native_linux, native_linux)
    build_config = BuildConfig(meta, "foo", v"1.0.0", [], bts, "true")
    prepare(build_config)

    build_result = build!(build_config)
    extract_config = ExtractConfig(build_result, "", [LibraryProduct("libfoo", :libfoo)])
end
DocTestTeardown = nothing
DocTestFilters = [
    r"└ @ BinaryBuilder2 .*:\d+" => "",
]
```

```jldoctest; filter = r"sha1:[0-9a-f]*" => "sha1:"
julia> debug_logger = ConsoleLogger(stderr, Logging.Debug)
       with_logger(debug_logger) do
           content_hash(build_config)
       end
┌ Debug: BuildConfig hash buffer:
│ [build_metadata]
│   script_hash = sha1:5ffe533b830f08a0326348a9160afafc8ada44db
│ [target_specs]
│   host: x86_64-linux-gnu-target_libc+glibc-target_os+linux-target_arch+x86_64
│   target: x86_64-linux-gnu-target_libc+glibc-target_os+linux-target_arch+x86_64
│ [source_trees]
│   /opt/host-tools = sha1:d4db020257bc3aa566a1c6e41af7bb5e32e7f50c
│   /opt/host-x86_64-linux-gnu = sha1:f57b6680090c11abad985747482b97c96de4933e
│   /opt/target-x86_64-linux-gnu = sha1:be793bbc30404cdc9c503920609b1960f2749e72
│   /usr/local = sha1:4b825dc642cb6eb9a060e54bf8d69288fbee4904
│   /workspace/destdir/target-x86_64-linux-gnu = sha1:4b825dc642cb6eb9a060e54bf8d69288fbee4904
│   /workspace/metadir = sha1:3726d5ef86735b899b0e0318fb70aa3996d4bb0b
│   /workspace/scripts = sha1:954bda634f4ae9af9809bf8c2ef8dc0635371f59
│   /workspace/srcdir = sha1:4b825dc642cb6eb9a060e54bf8d69288fbee4904
│ [environment]
│   BinaryBuilder2 = sha1:3ddf37ada38608e339b8b57cadb6f8fa2f114e48
│   BinaryBuilderAuditor = sha1:7b57f76acc7a5316a7c971e2d49b7d6e37082552
│   BinaryBuilderGitUtils = sha1:3ed475af33b46cdd85519443096409c850286e4b
│   BinaryBuilderPlatformExtensions = sha1:88784383a64abcf571e47ed19a0a97349aaf6564
│   BinaryBuilderProducts = sha1:398a224667bb526b540360939f1722b8585ef385
│   BinaryBuilderSources = sha1:4a69afbd9a06a5b2d427530f8715d38e074cc441
│   BinaryBuilderToolchains = sha1:278e1a5456f2d945b134b68f68fe485a98ae7f13
│   JLLGenerator = sha1:45f9b5d62809319c354a5bec6069a48761383756
│   JLLPrefixes = sha1:da5d4cc9374f84071a7b3516be2d7f11e7efa057
│   LazyJLLWrappers = sha1:5dfd8340ea302aa85a2af4f43a2fc68cb99c7ddb
│   MultiHashParsing = sha1:228565c940b960eab137ebb2aee5a43c7b09ed34
│   Sandbox = sha1:df96f7f53fde76cc19df57dba14b8ccd7e894188
│   TreeArchival = sha1:7ea07d94f984690a10879d06491661a1270423bb
└ @ BinaryBuilder2 ~/src/BB2-universe/src/build_api/BuildConfig.jl:270
sha1:9e033f8cfa11877471d1aba5413c4f4f3768f3af
```

The same can be done for an `ExtractConfig` object:
```jldoctest; filter = r"sha1:[0-9a-f]*" => "sha1:"
julia> debug_logger = ConsoleLogger(stderr, Logging.Debug)
       with_logger(debug_logger) do
           content_hash(extract_config)
       end
┌ Debug: ExtractConfig hash buffer:
│ [extraction_metadata]
│   script_hash = sha1:da39a3ee5e6b4b0d3255bfef95601890afd80709
│ [products]
│   libfoo = ["libfoo"]
└ @ BinaryBuilder2 ~/src/BB2-universe/src/build_api/ExtractConfig.jl:94
sha1:1f5859bb69b59fd500735ab26bbe4bcfa9565853
```


## Future work

* It would be nice to not load _everything_ into memory at boot, and instead only look things up when necessary.  Otherwise, I could imagine this getting slightly unwieldy in the future, for large `BuildCache`s.
* We should come up with a good default heuristic for when to call `prune!(bc)`.
* When hacking on BB2 itself, the `BuildCache` is all but useless, because of the `[environment]` section of the `content_hash(::BuildConfig)` changing every time.  It would be nice if the `BuildCache` was either more granular (e.g. only depended on certain functions within BB2?  Is such a thing possible?)
