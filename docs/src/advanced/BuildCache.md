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
    r"└ @ BinaryBuilder2 .*:\d+" => "",
    r"sha1:[0-9a-f]*" => "sha1:",
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
│   /opt/host-tools = sha1:aeb59bf95e69f2599e56e06bbd560414d887361b
│   /opt/host-x86_64-linux-gnu = sha1:aa6297d3c8acd81aa25afacb35c2aeeec7988b6a
│   /opt/target-x86_64-linux-gnu = sha1:b5835167191deda8a82f7e5e80a7b3b1ed9547ac
│   /usr/local = sha1:da39a3ee5e6b4b0d3255bfef95601890afd80709
│   /usr/share/licenses = sha1:d2d5d79765fa352588f9fc23b2abfef1a5d0fb96
│   /workspace/destdir/target-x86_64-linux-gnu = sha1:da39a3ee5e6b4b0d3255bfef95601890afd80709
│   /workspace/metadir = sha1:dd4533abf3378d54aa8fa4a16fdf257ce5483883
│   /workspace/scripts = sha1:a7189afd9cd7aa875783487b074364ffa0a276ed
│   /workspace/srcdir = sha1:da39a3ee5e6b4b0d3255bfef95601890afd80709
│ [environment]
│   BinaryBuilder2 = sha1:fe79e373b1dfa4c7f97bae0dc6cbe47d4d543a79
│   BinaryBuilderAuditor = sha1:a1cb1172a8fa24028feba7361d6950a3fa2fa7d8
│   BinaryBuilderGitUtils = sha1:3ed475af33b46cdd85519443096409c850286e4b
│   BinaryBuilderPlatformExtensions = sha1:88784383a64abcf571e47ed19a0a97349aaf6564
│   BinaryBuilderProducts = sha1:5fa7cd339ed1f8d5b8d074512da6569354ff9ac2
│   BinaryBuilderSources = sha1:6afda911aa3216dd9fb42f2c1f38c14e1c0590dc
│   BinaryBuilderToolchains = sha1:ed992a365101e14803f3615af90a75d19fdf8c00
│   JLLGenerator = sha1:586186eb59d71f70dd47d6b84e3b9e0e0819d54c
│   JLLPrefixes = sha1:6e132d90cd5e9bdb8025908e7a7971d72c0defa3
│   LazyJLLWrappers = sha1:063a7e939eb688406e360542f12e73828fea55f2
│   MultiHashParsing = sha1:f5d0a4ceb55dff17e345b169ca9564cc173afede
│   Sandbox = sha1:c7156ad981aa1501a83f5a140f08ee30692c3674
│   TreeArchival = sha1:7ea07d94f984690a10879d06491661a1270423bb
└ @ BinaryBuilder2 ~/src/BB2/src/build_api/BuildConfig.jl:284
sha1:988d8904171fc0560755647628e3aca453dc77db
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
│   /opt/host-tools = sha1:f1cf082434c34192196f61fbdbb1ed16aa86e439
│   /opt/host-x86_64-linux-gnu = sha1:37563a29022b22ec71ee081e5797eee6f2f09a06
│   /opt/target-x86_64-linux-gnu = sha1:87d462bc8c33bdf1db4f6f84f3a74109276c2ef7
│   /usr/local = sha1:da39a3ee5e6b4b0d3255bfef95601890afd80709
│   /usr/share/licenses = sha1:d2d5d79765fa352588f9fc23b2abfef1a5d0fb96
│   /workspace/destdir/target-x86_64-linux-gnu = sha1:da39a3ee5e6b4b0d3255bfef95601890afd80709
│   /workspace/metadir = sha1:08ae08a034cce835ed7908dcccec5e7120f29748
│   /workspace/scripts = sha1:a7189afd9cd7aa875783487b074364ffa0a276ed
│   /workspace/srcdir = sha1:da39a3ee5e6b4b0d3255bfef95601890afd80709
│ [environment]
│   BinaryBuilder2 = sha1:93e1cd8e0093aa24a37741f8398400f074ddfd43
│   BinaryBuilderAuditor = sha1:a1cb1172a8fa24028feba7361d6950a3fa2fa7d8
│   BinaryBuilderGitUtils = sha1:3ed475af33b46cdd85519443096409c850286e4b
│   BinaryBuilderPlatformExtensions = sha1:88784383a64abcf571e47ed19a0a97349aaf6564
│   BinaryBuilderProducts = sha1:5fa7cd339ed1f8d5b8d074512da6569354ff9ac2
│   BinaryBuilderSources = sha1:6afda911aa3216dd9fb42f2c1f38c14e1c0590dc
│   BinaryBuilderToolchains = sha1:ed992a365101e14803f3615af90a75d19fdf8c00
│   JLLGenerator = sha1:586186eb59d71f70dd47d6b84e3b9e0e0819d54c
│   JLLPrefixes = sha1:6e132d90cd5e9bdb8025908e7a7971d72c0defa3
│   LazyJLLWrappers = sha1:063a7e939eb688406e360542f12e73828fea55f2
│   MultiHashParsing = sha1:f5d0a4ceb55dff17e345b169ca9564cc173afede
│   Sandbox = sha1:c7156ad981aa1501a83f5a140f08ee30692c3674
│   TreeArchival = sha1:7ea07d94f984690a10879d06491661a1270423bb
└ @ BinaryBuilder2 ~/src/BB2/src/build_api/BuildConfig.jl:287
┌ Debug: ExtractConfig hash buffer:
│ [extraction_metadata]
│   build_hash = 5639f2e7f32018b0cd8faefa4f1aca99654b21f6
│   script_hash = sha1:da39a3ee5e6b4b0d3255bfef95601890afd80709
│ [products]
│   libfoo = ["libfoo"]
└ @ BinaryBuilder2 ~/src/BB2/src/build_api/ExtractConfig.jl:92
sha1:cea343e31a62a6ad42c3dd9404d3e5d1c36d3c03
```


## Future work

* It would be nice to not load _everything_ into memory at boot, and instead only look things up when necessary.  Otherwise, I could imagine this getting slightly unwieldy in the future, for large `BuildCache`s.
* We should come up with a good default heuristic for when to call `prune!(bc)`.
* When hacking on BB2 itself, the `BuildCache` is all but useless, because of the `[environment]` section of the `spec_hash(::BuildConfig)` changing every time.  It would be nice if the `BuildCache` was either more granular (e.g. only depended on certain functions within BB2?  Is such a thing possible?)
