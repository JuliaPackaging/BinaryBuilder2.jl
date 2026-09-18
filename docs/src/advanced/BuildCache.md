# BuildCache

```@docs; canonical=false
BuildCache
```

## Type Usage

The identifying hash of a [`BuildConfig`](@ref) is defined by `spec_hash(::BuildConfig)`, which is sensitive to:
 * [`BuildTargetSpec`](@ref BuildTargetSpec) objects, representing all compilers.
 * [`BuildConfig`](@ref BuildConfig) source trees, containing all dependencies.
 * [`BuildConfig`](@ref BuildConfig) script.
 * BinaryBuilder2 and dependent module source hashes.

To see this in action, you can run `spec_hash(build_config)` with a logger set to debug, and it will print out both the hash and all the inputs that went into the hash.
Note that you must call `prepare(build_config)` first, to instantiate all dependencies.

```@meta
DocTestSetup = quote
    using BinaryBuilder2, Logging
    using BinaryBuilder2: spec_hash
    include(joinpath(pkgdir(BinaryBuilder2), "test", "TestingUtils.jl"))
    meta = BuildMeta(;dry_run=["all"])
    bts = apply_spec_plan(spec_plan, native_linux, native_linux)
    build_config = BuildConfig(meta, "foo", v"1.0.0", [], bts, "true")
    prepare(build_config)

    build_result = build!(build_config)
    extract_config = ExtractConfig(build_result, "", [LibraryProduct("libfoo", :libfoo)])
end
DocTestTeardown = nothing
DocTestFilters = [
    # Don't be sensitive to line numbers
    r"└ @ BinaryBuilder2 .*:\d+" => "",

    # Don't be sensitive to hashes changing
    r"sha1:[0-9a-f]*" => "sha1:",

    # Don't be sensitive to triplets changing; remove this once we're on Julia v1.14+
    # which contains this fix: https://github.com/JuliaLang/julia/pull/63169
    r"[^ ]+-linux-gnu-target[^ ]+" => "",
]
```

```jldoctest
julia> debug_logger = ConsoleLogger(stderr, Logging.Debug)
       with_logger(debug_logger) do
           spec_hash(build_config; force_recompute=true)
       end
┌ Debug: BuildConfig hash buffer:
│ [build_metadata]
│   script_hash = sha1:5ffe533b830f08a0326348a9160afafc8ada44db
│ [target_specs]
│   host: x86_64-linux-gnu-target_libc+glibc-target_os+linux-target_arch+x86_64
│   target: x86_64-linux-gnu-target_libc+glibc-target_os+linux-target_arch+x86_64
│ [source_trees]
│   /opt/host-tools = sha1:1d4ecf643eebe9e4b731b0af45538904c8e95d89
│   /opt/host-x86_64-linux-gnu = sha1:d50e1659ae2d8c757231737299a5b3906cecad41
│   /opt/target-x86_64-linux-gnu = sha1:6c77f92e1cfc9bd8c377cb3e7a2c3a76f255c14c
│   /usr/local = sha1:da39a3ee5e6b4b0d3255bfef95601890afd80709
│   /usr/share/licenses = sha1:d2d5d79765fa352588f9fc23b2abfef1a5d0fb96
│   /workspace/destdir/target-x86_64-linux-gnu = sha1:da39a3ee5e6b4b0d3255bfef95601890afd80709
│   /workspace/metadir = sha1:298035f1ce8bd043c0d7f4fd532c553835faf873
│   /workspace/scripts = sha1:a7189afd9cd7aa875783487b074364ffa0a276ed
│   /workspace/srcdir = sha1:da39a3ee5e6b4b0d3255bfef95601890afd80709
│ [environment]
│   BinaryBuilder2 v1.1.1 = sha1:4758218aa21f6c83f3fd16464f8c83ecb2ad55eb
│   BinaryBuilderAuditor v0.2.1 = sha1:5e79774883047f008ce3e0d868be067644f3263f
│   BinaryBuilderGitUtils v0.2.0 = sha1:1012f01043d47329fc976fdfe6ebb17d2feb4b35
│   BinaryBuilderPlatformExtensions v0.2.0 = sha1:1b9c6386a00f29e6b6a7f423f59f4a97deac8e15
│   BinaryBuilderProducts v0.2.1 = sha1:1a53e7003742d423374236453b61014bf144aae2
│   BinaryBuilderSources v0.2.0 = sha1:488299903ba079e4ee6a202d1a34515ec0d30e25
│   BinaryBuilderToolchains v0.3.2 = sha1:178bf48348178ea0ed3cd727faf1c3f99352b738
│   JLLGenerator v0.5.1 = sha1:e4abe47e3b786a3d8ea54c3d2945eb364da6be7b
│   JLLPrefixes v0.4.2 = sha1:ffa37008d2c195492c50fad49e18906b524c3552
│   KeywordArgumentExtraction v1.2.0 = sha1:4131dc24111f7e6708381b6194452df6e611239f
│   LazyJLLWrappers v1.2.0 = sha1:4c752d4bd3bf91be149cb57cc7b62e5987f14d22
│   MultiHashParsing v0.2.1 = sha1:ff1ccf39c899dbad78cf5dadb9d8f55e6405fdc7
│   Sandbox v2.1.4 = sha1:2ae8f3cc0a6c40ad2e283a0147e065c21480e51a
│   ScratchSpaceGarbageCollector v0.1.2 = sha1:9671df55bab8965e27397e40ccc71f81ecb4ddc2
│   TreeArchival v0.2.0 = sha1:f13cb32318ba8fa878ab174e40f68ba875fe134a
└ @ BinaryBuilder2 ~/src/BB2/src/build_api/BuildConfig.jl:287
sha1:7f12c865b28ab25410fc9ca13a8086246a439fb6
```

The same can be done for an `ExtractConfig` object (note that it prints out the `BuildConfig` object as well during debugging, because it hashes that as an input as well!)
```jldoctest
julia> debug_logger = ConsoleLogger(stderr, Logging.Debug)
       with_logger(debug_logger) do
           spec_hash(extract_config; force_recompute=true)
       end
┌ Debug: BuildConfig hash buffer:
│ [build_metadata]
│   script_hash = sha1:5ffe533b830f08a0326348a9160afafc8ada44db
│ [target_specs]
│   host: x86_64-linux-gnu-target_libc+glibc-target_os+linux-target_arch+x86_64
│   target: x86_64-linux-gnu-target_libc+glibc-target_os+linux-target_arch+x86_64
│ [source_trees]
│   /opt/host-tools = sha1:1d4ecf643eebe9e4b731b0af45538904c8e95d89
│   /opt/host-x86_64-linux-gnu = sha1:d50e1659ae2d8c757231737299a5b3906cecad41
│   /opt/target-x86_64-linux-gnu = sha1:2111269ff032099054985dda538d761ea64994c5
│   /usr/local = sha1:da39a3ee5e6b4b0d3255bfef95601890afd80709
│   /usr/share/licenses = sha1:d2d5d79765fa352588f9fc23b2abfef1a5d0fb96
│   /workspace/destdir/target-x86_64-linux-gnu = sha1:da39a3ee5e6b4b0d3255bfef95601890afd80709
│   /workspace/metadir = sha1:298035f1ce8bd043c0d7f4fd532c553835faf873
│   /workspace/scripts = sha1:a7189afd9cd7aa875783487b074364ffa0a276ed
│   /workspace/srcdir = sha1:da39a3ee5e6b4b0d3255bfef95601890afd80709
│ [environment]
│   BinaryBuilder2 v1.1.1 = sha1:4758218aa21f6c83f3fd16464f8c83ecb2ad55eb
│   BinaryBuilderAuditor v0.2.1 = sha1:5e79774883047f008ce3e0d868be067644f3263f
│   BinaryBuilderGitUtils v0.2.0 = sha1:1012f01043d47329fc976fdfe6ebb17d2feb4b35
│   BinaryBuilderPlatformExtensions v0.2.0 = sha1:1b9c6386a00f29e6b6a7f423f59f4a97deac8e15
│   BinaryBuilderProducts v0.2.1 = sha1:1a53e7003742d423374236453b61014bf144aae2
│   BinaryBuilderSources v0.2.0 = sha1:488299903ba079e4ee6a202d1a34515ec0d30e25
│   BinaryBuilderToolchains v0.3.2 = sha1:178bf48348178ea0ed3cd727faf1c3f99352b738
│   JLLGenerator v0.5.1 = sha1:e4abe47e3b786a3d8ea54c3d2945eb364da6be7b
│   JLLPrefixes v0.4.2 = sha1:ffa37008d2c195492c50fad49e18906b524c3552
│   KeywordArgumentExtraction v1.2.0 = sha1:4131dc24111f7e6708381b6194452df6e611239f
│   LazyJLLWrappers v1.2.0 = sha1:4c752d4bd3bf91be149cb57cc7b62e5987f14d22
│   MultiHashParsing v0.2.1 = sha1:ff1ccf39c899dbad78cf5dadb9d8f55e6405fdc7
│   Sandbox v2.1.4 = sha1:2ae8f3cc0a6c40ad2e283a0147e065c21480e51a
│   ScratchSpaceGarbageCollector v0.1.2 = sha1:9671df55bab8965e27397e40ccc71f81ecb4ddc2
│   TreeArchival v0.2.0 = sha1:f13cb32318ba8fa878ab174e40f68ba875fe134a
└ @ BinaryBuilder2 ~/src/BB2/src/build_api/BuildConfig.jl:287
┌ Debug: ExtractConfig hash buffer:
│ [extraction_metadata]
│   build_hash = sha1:f811e60f4b3532774a19cf2cfaafdbbf8091b447
│   script_hash = sha1:da39a3ee5e6b4b0d3255bfef95601890afd80709
│ [products]
│   libfoo = ["libfoo"]
└ @ BinaryBuilder2 ~/src/BB2/src/build_api/ExtractConfig.jl:101
sha1:3a128df517cc353985d1f0fac3371c974562e6df
```


## Future work

* It would be nice to not load _everything_ into memory at boot, and instead only look things up when necessary.  Otherwise, I could imagine this getting slightly unwieldy in the future, for large `BuildCache`s.
* We should come up with a good default heuristic for when to call `prune!(bc)`.
* When hacking on BB2 itself, the `BuildCache` is all but useless, because of the `[environment]` section of the `spec_hash(::BuildConfig)` changing every time.  It would be nice if the `BuildCache` was either more granular (e.g. only depended on certain functions within BB2?  Is such a thing possible?)
