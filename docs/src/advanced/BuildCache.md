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

    # Don't be sensitive to hashes or versions changing
    r"sha1:[0-9a-f]*" => "sha1:",
    r" v[0-9\.]* " => " ",

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
│   host: aarch64-linux-gnu-target_libc+glibc-target_os+linux-target_arch+aarch64
│   target: aarch64-linux-gnu-target_libc+glibc-target_os+linux-target_arch+aarch64
│ [source_trees]
│   /opt/host-aarch64-linux-gnu = sha1:c93a7338fd433ea0cf05412797c3a2f2f56ed4fc
│     - GeneratedSource: wrappers sha1:50d3349f37e70c5afea24df916b5ccda46d4686a
│     - GeneratedSource: wrappers sha1:29ac0578502558d5588c5852490360daa930ab1d
│     - JLLSource Binutils_jll gcc sha1:73b1ecaf836cc6ddbd739d57a5cd80d4d450760e
│     - JLLSource LinuxKernelHeaders_jll gcc/aarch64-linux-gnu/usr sha1:dcd821e0679fc7c79bf3a7bc5a4198a6a7a70be3
│     - JLLSource Glibc_jll gcc/aarch64-linux-gnu sha1:fd018f9f6a0f73d37aa3563eb01db457b9dbc87e
│     - JLLSource GCC_jll gcc sha1:9135e6a48ea24ed3d4bfaf82248b1e3989bf3f72
│     - JLLSource GCC_support_libraries_jll gcc sha1:fb8379c58b375ef8cdc65b4c64c93fa6a80ba79d
│     - JLLSource GCC_crt_objects_jll gcc sha1:9d1f3b2d2fcc2841f092656b9c368c092f93ce4e
│     - JLLSource libstdcxx_jll gcc sha1:dc8638083d3f446fa010285ab8fffcb04de0d360
│   /opt/host-tools = sha1:a99b8f8ac8873e38db58d88a841a347c6ac6aa84
│     - GeneratedSource: etc/certs sha1:8528365da6b8dbe06c1d18059e7579fae48a628f
│     - GeneratedSource: wrappers sha1:ef2d319bfb84a499bfa6f3683b240c5d3f6a9a93
│     - JLLSource automake_jll  sha1:0473257b95998d068e017f28d493c91104b2401a
│     - JLLSource autoconf_jll  sha1:e6bf4dc3edb532a45199ebebb690994fb77bab03
│     - JLLSource Bison_jll  sha1:45114dd3d9a0e32f6a88ab7d09b54764d9772507
│     - JLLSource Ccache_jll  sha1:429af3de201dbce885b8a9977151ac262d1d9d08
│     - JLLSource file_jll  sha1:767774b8baf3ce5b7914b848902988d9d8699e74
│     - JLLSource flex_jll  sha1:9313ac5d8d5bfffa5e4d746d0c20bed007a3de0a
│     - JLLSource gawk_jll  sha1:7fb969cb4acdaff07c2428835ac72edc8d5db0ff
│     - JLLSource GNUMake_jll  sha1:2e2c3137676fc4eba8f19a6d29e460958d17cfbd
│     - JLLSource Libtool_jll  sha1:ad97640a7b5f4ac2b43640739c4b1d3aba6ef401
│     - JLLSource M4_jll  sha1:071130900095248610f9d42f7b9047d78d073264
│     - JLLSource Ninja_jll  sha1:1f9322f3e16f9ffaf03e32fc68f0c0e760b0bf57
│     - JLLSource Patchelf_jll  sha1:e87753be5c1a24405679f1fc974ed5b21ad235f6
│     - JLLSource Perl_jll  sha1:07c4e02273090f8cbe6b272c7b59cb62c732619e
│     - JLLSource Python_jll  sha1:9587861c4becb10739a51ed598743e3df578f330
│     - JLLSource patch_jll  sha1:f11306dcb47232e182bad68054de9d58d6ae4312
│     - JLLSource patchutils_jll  sha1:3a5f15175566d7f5b5fe8eb28209b5ff1ebe8a47
│     - JLLSource CURL_jll  sha1:5853d1de75bf9862f6c21c887c724e966925107c
│     - JLLSource Git_jll  sha1:c89a70239a8350aa9b9cd211723ee55e765a9da5
│     - JLLSource rsync_jll  sha1:a2cd62df467b3dc631144f6ad3aeb1e53bcbf916
│     - JLLSource MozillaCACerts_jll  sha1:669a7ce2060d13d27b9eb8628293143223401415
│     - JLLSource Tar_jll  sha1:c3a2a8b1326850f05e8c3df6a7305902d8319b13
│     - JLLSource Gzip_jll  sha1:8529081ed272fe664e6f443aad17e9f556429879
│     - JLLSource Bzip2_jll  sha1:85d6b3c7d19cb820d9426d7c9ed0a581998da2b2
│     - JLLSource unzip_jll  sha1:a07d565f19435ec706153d73656f7f6e571996d8
│     - JLLSource Zstd_jll  sha1:9ecc08626722c3a0c44f5d686deb815100ad90a7
│     - JLLSource XZ_jll  sha1:2e4a13dabe6042122a014e3377e78e48ee0c3284
│     - JLLSource Zlib_jll  sha1:3e5d79fad08b74b404fbcd65f4a08e7be4fddf38
│     - JLLSource Vim_jll  sha1:49237b707e236f2744121a9e5cf4f5d8c4c50ee3
│     - JLLSource strace_jll  sha1:aaee4e4c4e6fe05bc97d14c93ab918039a51b8f9
│     - JLLSource libtree_jll  sha1:d17dd460992baf9d552dbd9d80590abac8e87709
│     - JLLSource ripgrep_jll  sha1:d67e5231677e9b301405e755df33d9bfee373f3f
│     - JLLSource CompilerSupportLibraries_jll  sha1:ae79294c12d14270c41e713ef01d8eb81b3bf11c
│   /opt/target-aarch64-linux-gnu = sha1:49679d5b1d11fd6f38eb4d5b6300f03d454c9fb8
│     - GeneratedSource: wrappers sha1:f813e5e426d3c27600070a83463b921ed9538590
│     - GeneratedSource: wrappers sha1:b314c42581af715c6aafafcb31ca300983fd4939
│     - JLLSource Binutils_jll gcc sha1:f4909c7aac7cb4ff36721b11fbab51f5ec89d7b2
│     - JLLSource LinuxKernelHeaders_jll gcc/aarch64-linux-gnu/usr sha1:aa6c30fedeae9eb76ecb973552be25af6f9166b7
│     - JLLSource Glibc_jll gcc/aarch64-linux-gnu sha1:d569fe16f62743af8827bc2195aa0e1ee29ac101
│     - JLLSource GCC_jll gcc sha1:9135e6a48ea24ed3d4bfaf82248b1e3989bf3f72
│     - JLLSource GCC_support_libraries_jll gcc sha1:fb8379c58b375ef8cdc65b4c64c93fa6a80ba79d
│     - JLLSource GCC_crt_objects_jll gcc sha1:9d1f3b2d2fcc2841f092656b9c368c092f93ce4e
│     - JLLSource libstdcxx_jll gcc sha1:dc8638083d3f446fa010285ab8fffcb04de0d360
│   /usr/local = sha1:da39a3ee5e6b4b0d3255bfef95601890afd80709
│   /usr/share/licenses = sha1:d2d5d79765fa352588f9fc23b2abfef1a5d0fb96
│     - DirectorySource:  sha1:c356bf9f9da20681cd510e2ae79a7e30941b6261
│   /workspace/destdir/target-aarch64-linux-gnu = sha1:da39a3ee5e6b4b0d3255bfef95601890afd80709
│   /workspace/metadir = sha1:091bf082e48cbb7ce5a24f701eeacc6a117df8c9
│     - GeneratedSource:  sha1:693ad3f9fb2974038857fa03f1fb6338f068db9e
│   /workspace/scripts = sha1:a7189afd9cd7aa875783487b074364ffa0a276ed
│     - DirectorySource:  sha1:dbeb610a5ce1290d66c3340ff123041d079df083
│   /workspace/srcdir = sha1:da39a3ee5e6b4b0d3255bfef95601890afd80709
│ [environment]
│   BinaryBuilder2 v1.2.2 = sha1:fc730fd71fcc6996072126b5056b28a235b3cb28
│   BinaryBuilderAuditor v0.3.0 = sha1:6e06ec871d08017cf16402e743f91a4e2807c24b
│   BinaryBuilderGitUtils v0.3.0 = sha1:9fe8fe2a6fec7bcbf47cdca0e3a6189989ff5f4a
│   BinaryBuilderPlatformExtensions v0.2.1 = sha1:0932b3529a238dc2db243b16c170b93d197345cf
│   BinaryBuilderProducts v0.3.0 = sha1:909099b068360e9edca71294f212a44080455ba3
│   BinaryBuilderSources v0.2.5 = sha1:51e7fd808de0cb6ec9e256d9b468d4728d23eb99
│   BinaryBuilderToolchains v0.3.4 = sha1:864a849652194a89fc00ad173392b66386d716ec
│   JLLGenerator v0.5.2 = sha1:a6c22056b4f70a3024f47adf625f790622cf5bf1
│   JLLPrefixes v0.4.2 = sha1:ffa37008d2c195492c50fad49e18906b524c3552
│   KeywordArgumentExtraction v1.2.0 = sha1:4131dc24111f7e6708381b6194452df6e611239f
│   LazyJLLWrappers v1.2.1 = sha1:e6ee0a34be8d06343ad0c72cfeddd4c1b5d8f0cf
│   MultiHashParsing v0.2.1 = sha1:ff1ccf39c899dbad78cf5dadb9d8f55e6405fdc7
│   Sandbox v2.1.4 = sha1:2ae8f3cc0a6c40ad2e283a0147e065c21480e51a
│   ScratchSpaceGarbageCollector v0.1.2 = sha1:9671df55bab8965e27397e40ccc71f81ecb4ddc2
│   TreeArchival v0.2.0 = sha1:f13cb32318ba8fa878ab174e40f68ba875fe134a
└ @ BinaryBuilder2 /media/share/dev/BinaryBuilder2/src/build_api/BuildConfig.jl:289
sha1:22094feb0ff157d2b9da3673094104aa9538b7b1
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
│   host: aarch64-linux-gnu-target_libc+glibc-target_os+linux-target_arch+aarch64
│   target: aarch64-linux-gnu-target_libc+glibc-target_os+linux-target_arch+aarch64
│ [source_trees]
│   /opt/host-aarch64-linux-gnu = sha1:345439351f0b414937facb57a089cafa86265434
│     - GeneratedSource: wrappers sha1:50d3349f37e70c5afea24df916b5ccda46d4686a
│     - GeneratedSource: wrappers sha1:29ac0578502558d5588c5852490360daa930ab1d
│     - JLLSource Binutils_jll gcc sha1:f4909c7aac7cb4ff36721b11fbab51f5ec89d7b2
│     - JLLSource LinuxKernelHeaders_jll gcc/aarch64-linux-gnu/usr sha1:aa6c30fedeae9eb76ecb973552be25af6f9166b7
│     - JLLSource Glibc_jll gcc/aarch64-linux-gnu sha1:d569fe16f62743af8827bc2195aa0e1ee29ac101
│     - JLLSource GCC_jll gcc sha1:9135e6a48ea24ed3d4bfaf82248b1e3989bf3f72
│     - JLLSource GCC_support_libraries_jll gcc sha1:fb8379c58b375ef8cdc65b4c64c93fa6a80ba79d
│     - JLLSource GCC_crt_objects_jll gcc sha1:9d1f3b2d2fcc2841f092656b9c368c092f93ce4e
│     - JLLSource libstdcxx_jll gcc sha1:dc8638083d3f446fa010285ab8fffcb04de0d360
│   /opt/host-tools = sha1:a99b8f8ac8873e38db58d88a841a347c6ac6aa84
│     - GeneratedSource: etc/certs sha1:8528365da6b8dbe06c1d18059e7579fae48a628f
│     - GeneratedSource: wrappers sha1:ef2d319bfb84a499bfa6f3683b240c5d3f6a9a93
│     - JLLSource automake_jll  sha1:0473257b95998d068e017f28d493c91104b2401a
│     - JLLSource autoconf_jll  sha1:e6bf4dc3edb532a45199ebebb690994fb77bab03
│     - JLLSource Bison_jll  sha1:45114dd3d9a0e32f6a88ab7d09b54764d9772507
│     - JLLSource Ccache_jll  sha1:429af3de201dbce885b8a9977151ac262d1d9d08
│     - JLLSource file_jll  sha1:767774b8baf3ce5b7914b848902988d9d8699e74
│     - JLLSource flex_jll  sha1:9313ac5d8d5bfffa5e4d746d0c20bed007a3de0a
│     - JLLSource gawk_jll  sha1:7fb969cb4acdaff07c2428835ac72edc8d5db0ff
│     - JLLSource GNUMake_jll  sha1:2e2c3137676fc4eba8f19a6d29e460958d17cfbd
│     - JLLSource Libtool_jll  sha1:ad97640a7b5f4ac2b43640739c4b1d3aba6ef401
│     - JLLSource M4_jll  sha1:071130900095248610f9d42f7b9047d78d073264
│     - JLLSource Ninja_jll  sha1:1f9322f3e16f9ffaf03e32fc68f0c0e760b0bf57
│     - JLLSource Patchelf_jll  sha1:e87753be5c1a24405679f1fc974ed5b21ad235f6
│     - JLLSource Perl_jll  sha1:07c4e02273090f8cbe6b272c7b59cb62c732619e
│     - JLLSource Python_jll  sha1:9587861c4becb10739a51ed598743e3df578f330
│     - JLLSource patch_jll  sha1:f11306dcb47232e182bad68054de9d58d6ae4312
│     - JLLSource patchutils_jll  sha1:3a5f15175566d7f5b5fe8eb28209b5ff1ebe8a47
│     - JLLSource CURL_jll  sha1:5853d1de75bf9862f6c21c887c724e966925107c
│     - JLLSource Git_jll  sha1:c89a70239a8350aa9b9cd211723ee55e765a9da5
│     - JLLSource rsync_jll  sha1:a2cd62df467b3dc631144f6ad3aeb1e53bcbf916
│     - JLLSource MozillaCACerts_jll  sha1:669a7ce2060d13d27b9eb8628293143223401415
│     - JLLSource Tar_jll  sha1:c3a2a8b1326850f05e8c3df6a7305902d8319b13
│     - JLLSource Gzip_jll  sha1:8529081ed272fe664e6f443aad17e9f556429879
│     - JLLSource Bzip2_jll  sha1:85d6b3c7d19cb820d9426d7c9ed0a581998da2b2
│     - JLLSource unzip_jll  sha1:a07d565f19435ec706153d73656f7f6e571996d8
│     - JLLSource Zstd_jll  sha1:9ecc08626722c3a0c44f5d686deb815100ad90a7
│     - JLLSource XZ_jll  sha1:2e4a13dabe6042122a014e3377e78e48ee0c3284
│     - JLLSource Zlib_jll  sha1:3e5d79fad08b74b404fbcd65f4a08e7be4fddf38
│     - JLLSource Vim_jll  sha1:49237b707e236f2744121a9e5cf4f5d8c4c50ee3
│     - JLLSource strace_jll  sha1:aaee4e4c4e6fe05bc97d14c93ab918039a51b8f9
│     - JLLSource libtree_jll  sha1:d17dd460992baf9d552dbd9d80590abac8e87709
│     - JLLSource ripgrep_jll  sha1:d67e5231677e9b301405e755df33d9bfee373f3f
│     - JLLSource CompilerSupportLibraries_jll  sha1:ae79294c12d14270c41e713ef01d8eb81b3bf11c
│   /opt/target-aarch64-linux-gnu = sha1:49679d5b1d11fd6f38eb4d5b6300f03d454c9fb8
│     - GeneratedSource: wrappers sha1:f813e5e426d3c27600070a83463b921ed9538590
│     - GeneratedSource: wrappers sha1:b314c42581af715c6aafafcb31ca300983fd4939
│     - JLLSource Binutils_jll gcc sha1:f4909c7aac7cb4ff36721b11fbab51f5ec89d7b2
│     - JLLSource LinuxKernelHeaders_jll gcc/aarch64-linux-gnu/usr sha1:aa6c30fedeae9eb76ecb973552be25af6f9166b7
│     - JLLSource Glibc_jll gcc/aarch64-linux-gnu sha1:d569fe16f62743af8827bc2195aa0e1ee29ac101
│     - JLLSource GCC_jll gcc sha1:9135e6a48ea24ed3d4bfaf82248b1e3989bf3f72
│     - JLLSource GCC_support_libraries_jll gcc sha1:fb8379c58b375ef8cdc65b4c64c93fa6a80ba79d
│     - JLLSource GCC_crt_objects_jll gcc sha1:9d1f3b2d2fcc2841f092656b9c368c092f93ce4e
│     - JLLSource libstdcxx_jll gcc sha1:dc8638083d3f446fa010285ab8fffcb04de0d360
│   /usr/local = sha1:da39a3ee5e6b4b0d3255bfef95601890afd80709
│   /usr/share/licenses = sha1:d2d5d79765fa352588f9fc23b2abfef1a5d0fb96
│     - DirectorySource:  sha1:c356bf9f9da20681cd510e2ae79a7e30941b6261
│   /workspace/destdir/target-aarch64-linux-gnu = sha1:da39a3ee5e6b4b0d3255bfef95601890afd80709
│   /workspace/metadir = sha1:091bf082e48cbb7ce5a24f701eeacc6a117df8c9
│     - GeneratedSource:  sha1:693ad3f9fb2974038857fa03f1fb6338f068db9e
│   /workspace/scripts = sha1:a7189afd9cd7aa875783487b074364ffa0a276ed
│     - DirectorySource:  sha1:dbeb610a5ce1290d66c3340ff123041d079df083
│   /workspace/srcdir = sha1:da39a3ee5e6b4b0d3255bfef95601890afd80709
│ [environment]
│   BinaryBuilder2 v1.2.2 = sha1:fc730fd71fcc6996072126b5056b28a235b3cb28
│   BinaryBuilderAuditor v0.3.0 = sha1:6e06ec871d08017cf16402e743f91a4e2807c24b
│   BinaryBuilderGitUtils v0.3.0 = sha1:9fe8fe2a6fec7bcbf47cdca0e3a6189989ff5f4a
│   BinaryBuilderPlatformExtensions v0.2.1 = sha1:0932b3529a238dc2db243b16c170b93d197345cf
│   BinaryBuilderProducts v0.3.0 = sha1:909099b068360e9edca71294f212a44080455ba3
│   BinaryBuilderSources v0.2.5 = sha1:51e7fd808de0cb6ec9e256d9b468d4728d23eb99
│   BinaryBuilderToolchains v0.3.4 = sha1:864a849652194a89fc00ad173392b66386d716ec
│   JLLGenerator v0.5.2 = sha1:a6c22056b4f70a3024f47adf625f790622cf5bf1
│   JLLPrefixes v0.4.2 = sha1:ffa37008d2c195492c50fad49e18906b524c3552
│   KeywordArgumentExtraction v1.2.0 = sha1:4131dc24111f7e6708381b6194452df6e611239f
│   LazyJLLWrappers v1.2.1 = sha1:e6ee0a34be8d06343ad0c72cfeddd4c1b5d8f0cf
│   MultiHashParsing v0.2.1 = sha1:ff1ccf39c899dbad78cf5dadb9d8f55e6405fdc7
│   Sandbox v2.1.4 = sha1:2ae8f3cc0a6c40ad2e283a0147e065c21480e51a
│   ScratchSpaceGarbageCollector v0.1.2 = sha1:9671df55bab8965e27397e40ccc71f81ecb4ddc2
│   TreeArchival v0.2.0 = sha1:f13cb32318ba8fa878ab174e40f68ba875fe134a
└ @ BinaryBuilder2 /media/share/dev/BinaryBuilder2/src/build_api/BuildConfig.jl:289
┌ Debug: ExtractConfig hash buffer:
│ [extraction_metadata]
│   build_hash = sha1:fd633e730dc47f012582f48b44393503f45257aa
│   script_hash = sha1:da39a3ee5e6b4b0d3255bfef95601890afd80709
│ [products]
│   libfoo = ["libfoo"]
└ @ BinaryBuilder2 /media/share/dev/BinaryBuilder2/src/build_api/ExtractConfig.jl:112
sha1:e53042b52d7a3e7371da37a12e14aba39ce9258d
```


## Future work

* It would be nice to not load _everything_ into memory at boot, and instead only look things up when necessary.  Otherwise, I could imagine this getting slightly unwieldy in the future, for large `BuildCache`s.
* We should come up with a good default heuristic for when to call `prune!(bc)`.
* When hacking on BB2 itself, the `BuildCache` is all but useless, because of the `[environment]` section of the `spec_hash(::BuildConfig)` changing every time.  It would be nice if the `BuildCache` was either more granular (e.g. only depended on certain functions within BB2?  Is such a thing possible?)
