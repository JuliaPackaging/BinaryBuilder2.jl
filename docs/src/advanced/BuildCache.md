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
    # Pin the platform rather than using `native_linux`, so that the expected
    # output below (which contains platform-specific prefixes, ordering and
    # hashes) is the same no matter which machine runs the doctests.
    doc_platform = Platform("aarch64", "linux")
    bts = apply_spec_plan(spec_plan, doc_platform, doc_platform)
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
│   host: aarch64-linux-gnu-target_arch+aarch64-target_libc+glibc-target_os+linux
│   target: aarch64-linux-gnu-target_arch+aarch64-target_libc+glibc-target_os+linux
│ [source_trees]
│   /opt/host-aarch64-linux-gnu = sha1:558b97151e26ad8329ed4a7e099a75e7ccf01ed2
│     - GeneratedSource: wrappers sha1:85b6f63e39dab7aa8fe0cce7a3d5baa1d52c7c76
│     - GeneratedSource: wrappers sha1:0bf1fd170d5d0ec906551e91639563283ea1d001
│     - JLLSource Binutils_jll gcc sha1:265ac0fca2dc65da2ffaa6a5ad20d6d16d1623df
│     - JLLSource LinuxKernelHeaders_jll gcc/aarch64-linux-gnu/usr sha1:9dc8b93248cd24d5e4ea90c01856a6553e69ba22
│     - JLLSource Glibc_jll gcc/aarch64-linux-gnu sha1:f48edfeeb834732af7cea2caec502b42e6519b2d
│     - JLLSource GCC_jll gcc sha1:d74cb5b93fcac07759ac3bdde8f450668e877940
│     - JLLSource GCC_support_libraries_jll gcc sha1:262d7535a798070bd1bc3cb791ee9cf4e6838cdb
│     - JLLSource GCC_crt_objects_jll gcc sha1:43f8c8448210e34e95e9b91cf9e607240c9d7ee3
│     - JLLSource libstdcxx_jll gcc sha1:b66b45d43925f9375efef1be896935d2a6fc11aa
│     - JLLSource pkgconf_jll pkgconf sha1:08ebecab56e453db55392f9451fdf2ab9bdda249
│   /opt/host-tools = sha1:c7e46419b2552566abb367aca3e7dd712ff8fbba
│     - GeneratedSource: etc/certs sha1:c5652e051531eb0a6c2f4766ee6136907f3a9e27
│     - GeneratedSource: wrappers sha1:0bbde73922fc56d829f527124aaba7e03ed00825
│     - GeneratedSource: etc/loader sha1:ebb0fba8300d88f7087189c8c471d2bb02e93eef
│     - JLLSource automake_jll  sha1:51f43e63b741f003fa924a4d82f5aecb36c974f1
│     - JLLSource autoconf_jll  sha1:46425db7398509605de27fc93c5f9de656f596ed
│     - JLLSource Bison_jll  sha1:1f9a9127381c8bad8e336b2acc051cd5b7acebd6
│     - JLLSource Ccache_jll  sha1:636724fb4417b4bc8dfb7a6ce5c0b9bf3660db52
│     - JLLSource file_jll  sha1:e9c7c64915f3a298af037615521b3ac257335205
│     - JLLSource flex_jll  sha1:c9106fe2b6d3592434cbd4bf5ce7a612080bf4dd
│     - JLLSource gawk_jll  sha1:a2f7c5157a69052bf7d3aa502912acb1ffa2706b
│     - JLLSource GNUMake_jll  sha1:bf24c81bf1ed3788b02b69b8a6dbc115cafd1ca5
│     - JLLSource Libtool_jll  sha1:15c2c3fe8ba35d0cf45cad9d213cba3b8c5b43f9
│     - JLLSource M4_jll  sha1:7132a68b4489e7e053bc11e555d59de61519c40d
│     - JLLSource Ninja_jll  sha1:d41359c208bf73f19a237566e8d85384394e9e3f
│     - JLLSource Patchelf_jll  sha1:4f4c0358f487cb52099967863aca531ac4bb9b3a
│     - JLLSource Perl_jll  sha1:b69ed0df1d3a32ca7e180eb6374ee303026dcbff
│     - JLLSource Python_jll  sha1:59a95a14ea3ba5a0a597cc99d068c991844061ba
│     - JLLSource patch_jll  sha1:f2408be1f9a680760d4f94684e3b9f1cfdfccf92
│     - JLLSource patchutils_jll  sha1:8f3517d3e3fdfc03359330d577bfe8cf65b81ede
│     - JLLSource CURL_jll  sha1:408cd2f6a207a93bb29ded87cc938bbf35685439
│     - JLLSource Git_jll  sha1:99a55980528b5aaf7164a486c94bfbcee6e7ff69
│     - JLLSource rsync_jll  sha1:3b319377f338dd181c0e61278d26286834a8097f
│     - JLLSource MozillaCACerts_jll  sha1:f45b029ddf86c0b0b9e46a78120d12e7d5069389
│     - JLLSource Tar_jll  sha1:9c18aed62be69b2de24816be4c21c916836f73a9
│     - JLLSource Gzip_jll  sha1:ba902da9069feaef5777fe8dd0d94c21eb77fdae
│     - JLLSource Bzip2_jll  sha1:b9eaf073d757bd442839dd5208d54c91dd40ccb5
│     - JLLSource unzip_jll  sha1:68d208e1bbc25a1ca436002fdbf074b56c859a00
│     - JLLSource Zstd_jll  sha1:5f03ee0aa248f9a8b88065f0f398787c14e5a590
│     - JLLSource XZ_jll  sha1:dfa4e39ecdb0ab663b1a0844ea5399f62425e857
│     - JLLSource Zlib_jll  sha1:f155c5fd788123618c464ccf54ecf3e724781c54
│     - JLLSource Vim_jll  sha1:b85c043ca176690025ed896e7d09d8b654e7766a
│     - JLLSource strace_jll  sha1:e4d5efc4349341e4aec534c109a39a85b8ddcb74
│     - JLLSource libtree_jll  sha1:31b5758e11ec188ea824c6e8028e72bdec520f74
│     - JLLSource ripgrep_jll  sha1:af8985028c1f1d0ec073ee81226b3db43dd6c439
│     - JLLSource libstdcxx_jll runtime sha1:1e8c06932a70d97dcc9ebbfbf672837c7bd0260b
│     - JLLSource GCC_support_libraries_jll runtime sha1:f989d3f5b7dd4db0b199013b0872b2c07c27eab8
│   /opt/target-aarch64-linux-gnu = sha1:b9c4a8b63e7ededde072c4ef0464288e24815318
│     - GeneratedSource: wrappers sha1:8f7cd737ff168d78373469edb0cf07e0e5e2a44c
│     - GeneratedSource: wrappers sha1:b2e500f186890ca4b13ea8634c2b9287a90d2499
│     - JLLSource Binutils_jll gcc sha1:265ac0fca2dc65da2ffaa6a5ad20d6d16d1623df
│     - JLLSource LinuxKernelHeaders_jll gcc/aarch64-linux-gnu/usr sha1:9dc8b93248cd24d5e4ea90c01856a6553e69ba22
│     - JLLSource Glibc_jll gcc/aarch64-linux-gnu sha1:f48edfeeb834732af7cea2caec502b42e6519b2d
│     - JLLSource GCC_jll gcc sha1:d74cb5b93fcac07759ac3bdde8f450668e877940
│     - JLLSource GCC_support_libraries_jll gcc sha1:262d7535a798070bd1bc3cb791ee9cf4e6838cdb
│     - JLLSource GCC_crt_objects_jll gcc sha1:43f8c8448210e34e95e9b91cf9e607240c9d7ee3
│     - JLLSource libstdcxx_jll gcc sha1:b66b45d43925f9375efef1be896935d2a6fc11aa
│     - JLLSource pkgconf_jll pkgconf sha1:08ebecab56e453db55392f9451fdf2ab9bdda249
│   /usr/local = sha1:da39a3ee5e6b4b0d3255bfef95601890afd80709
│   /usr/share/licenses = sha1:d2d5d79765fa352588f9fc23b2abfef1a5d0fb96
│     - DirectorySource:  sha1:c356bf9f9da20681cd510e2ae79a7e30941b6261
│   /workspace/destdir/target-aarch64-linux-gnu = sha1:da39a3ee5e6b4b0d3255bfef95601890afd80709
│   /workspace/metadir = sha1:aaa0d245ac10b10ab94373170dd0c03d7701832c
│     - GeneratedSource:  sha1:8530abbcee8051b560872b79c9201c9d9aea53da
│   /workspace/scripts = sha1:a7189afd9cd7aa875783487b074364ffa0a276ed
│     - DirectorySource:  sha1:dbeb610a5ce1290d66c3340ff123041d079df083
│   /workspace/srcdir = sha1:da39a3ee5e6b4b0d3255bfef95601890afd80709
│ [environment]
│   BinaryBuilder2 v1.4.4 = sha1:6d290be9244057f54318ca86b63d20992320aa57
│   BinaryBuilderAuditor v0.4.7 = sha1:cfe5b11125ad337abee50df6622064bb0ac3721d
│   BinaryBuilderGitUtils v0.3.0 = sha1:9fe8fe2a6fec7bcbf47cdca0e3a6189989ff5f4a
│   BinaryBuilderPlatformExtensions v0.2.2 = sha1:bebe0418f40164ff08d191b85cc55c6db1c1168a
│   BinaryBuilderProducts v0.4.0 = sha1:d51596bd9cc8bb0935cb8f33c80b79ce8bdd17ee
│   BinaryBuilderSources v0.3.6 = sha1:cd2720a0f8f0b3011c52f062be951ff326a5f776
│   BinaryBuilderToolchains v0.5.0 = sha1:642f70c6b149fc191e7b44844c4b6670160b3ec2
│   JLLGenerator v0.6.0 = sha1:5e510be2e08fc91283c414abefb108c481901294
│   JLLPrefixes v0.4.3 = sha1:64570d6b5f41521d8c7899b9c050d76a03f4528a
│   KeywordArgumentExtraction v1.2.0 = sha1:4131dc24111f7e6708381b6194452df6e611239f
│   LazyJLLWrappers v1.2.7 = sha1:ad57e8d126ed98ec169e1a710c5dd9e04d298c1d
│   MultiHashParsing v0.2.2 = sha1:0476b43f1f3c55ade6bf70609530991ddb4c2c89
│   Sandbox v2.3.0 = sha1:5759ba67d24e88176a84c23bb47bac5395a23765
│   ScratchSpaceGarbageCollector v0.1.2 = sha1:9671df55bab8965e27397e40ccc71f81ecb4ddc2
│   TreeArchival v0.2.0 = sha1:f13cb32318ba8fa878ab174e40f68ba875fe134a
└ @ BinaryBuilder2 ~/src/experiments/BB2-compiler-toolchains-transfer/worktrees/BinaryBuilder2.jl-ldconfig-dropin/src/build_api/BuildConfig.jl:290
sha1:70763ef1f5e90f97dc2c29d226088d7196d84abe
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
│   host: aarch64-linux-gnu-target_arch+aarch64-target_libc+glibc-target_os+linux
│   target: aarch64-linux-gnu-target_arch+aarch64-target_libc+glibc-target_os+linux
│ [source_trees]
│   /opt/host-aarch64-linux-gnu = sha1:558b97151e26ad8329ed4a7e099a75e7ccf01ed2
│     - GeneratedSource: wrappers sha1:85b6f63e39dab7aa8fe0cce7a3d5baa1d52c7c76
│     - GeneratedSource: wrappers sha1:0bf1fd170d5d0ec906551e91639563283ea1d001
│     - JLLSource Binutils_jll gcc sha1:265ac0fca2dc65da2ffaa6a5ad20d6d16d1623df
│     - JLLSource LinuxKernelHeaders_jll gcc/aarch64-linux-gnu/usr sha1:9dc8b93248cd24d5e4ea90c01856a6553e69ba22
│     - JLLSource Glibc_jll gcc/aarch64-linux-gnu sha1:f48edfeeb834732af7cea2caec502b42e6519b2d
│     - JLLSource GCC_jll gcc sha1:d74cb5b93fcac07759ac3bdde8f450668e877940
│     - JLLSource GCC_support_libraries_jll gcc sha1:262d7535a798070bd1bc3cb791ee9cf4e6838cdb
│     - JLLSource GCC_crt_objects_jll gcc sha1:43f8c8448210e34e95e9b91cf9e607240c9d7ee3
│     - JLLSource libstdcxx_jll gcc sha1:b66b45d43925f9375efef1be896935d2a6fc11aa
│     - JLLSource pkgconf_jll pkgconf sha1:08ebecab56e453db55392f9451fdf2ab9bdda249
│   /opt/host-tools = sha1:c7e46419b2552566abb367aca3e7dd712ff8fbba
│     - GeneratedSource: etc/certs sha1:c5652e051531eb0a6c2f4766ee6136907f3a9e27
│     - GeneratedSource: wrappers sha1:0bbde73922fc56d829f527124aaba7e03ed00825
│     - GeneratedSource: etc/loader sha1:ebb0fba8300d88f7087189c8c471d2bb02e93eef
│     - JLLSource automake_jll  sha1:51f43e63b741f003fa924a4d82f5aecb36c974f1
│     - JLLSource autoconf_jll  sha1:46425db7398509605de27fc93c5f9de656f596ed
│     - JLLSource Bison_jll  sha1:1f9a9127381c8bad8e336b2acc051cd5b7acebd6
│     - JLLSource Ccache_jll  sha1:636724fb4417b4bc8dfb7a6ce5c0b9bf3660db52
│     - JLLSource file_jll  sha1:e9c7c64915f3a298af037615521b3ac257335205
│     - JLLSource flex_jll  sha1:c9106fe2b6d3592434cbd4bf5ce7a612080bf4dd
│     - JLLSource gawk_jll  sha1:a2f7c5157a69052bf7d3aa502912acb1ffa2706b
│     - JLLSource GNUMake_jll  sha1:bf24c81bf1ed3788b02b69b8a6dbc115cafd1ca5
│     - JLLSource Libtool_jll  sha1:15c2c3fe8ba35d0cf45cad9d213cba3b8c5b43f9
│     - JLLSource M4_jll  sha1:7132a68b4489e7e053bc11e555d59de61519c40d
│     - JLLSource Ninja_jll  sha1:d41359c208bf73f19a237566e8d85384394e9e3f
│     - JLLSource Patchelf_jll  sha1:4f4c0358f487cb52099967863aca531ac4bb9b3a
│     - JLLSource Perl_jll  sha1:b69ed0df1d3a32ca7e180eb6374ee303026dcbff
│     - JLLSource Python_jll  sha1:59a95a14ea3ba5a0a597cc99d068c991844061ba
│     - JLLSource patch_jll  sha1:f2408be1f9a680760d4f94684e3b9f1cfdfccf92
│     - JLLSource patchutils_jll  sha1:8f3517d3e3fdfc03359330d577bfe8cf65b81ede
│     - JLLSource CURL_jll  sha1:408cd2f6a207a93bb29ded87cc938bbf35685439
│     - JLLSource Git_jll  sha1:99a55980528b5aaf7164a486c94bfbcee6e7ff69
│     - JLLSource rsync_jll  sha1:3b319377f338dd181c0e61278d26286834a8097f
│     - JLLSource MozillaCACerts_jll  sha1:f45b029ddf86c0b0b9e46a78120d12e7d5069389
│     - JLLSource Tar_jll  sha1:9c18aed62be69b2de24816be4c21c916836f73a9
│     - JLLSource Gzip_jll  sha1:ba902da9069feaef5777fe8dd0d94c21eb77fdae
│     - JLLSource Bzip2_jll  sha1:b9eaf073d757bd442839dd5208d54c91dd40ccb5
│     - JLLSource unzip_jll  sha1:68d208e1bbc25a1ca436002fdbf074b56c859a00
│     - JLLSource Zstd_jll  sha1:5f03ee0aa248f9a8b88065f0f398787c14e5a590
│     - JLLSource XZ_jll  sha1:dfa4e39ecdb0ab663b1a0844ea5399f62425e857
│     - JLLSource Zlib_jll  sha1:f155c5fd788123618c464ccf54ecf3e724781c54
│     - JLLSource Vim_jll  sha1:b85c043ca176690025ed896e7d09d8b654e7766a
│     - JLLSource strace_jll  sha1:e4d5efc4349341e4aec534c109a39a85b8ddcb74
│     - JLLSource libtree_jll  sha1:31b5758e11ec188ea824c6e8028e72bdec520f74
│     - JLLSource ripgrep_jll  sha1:af8985028c1f1d0ec073ee81226b3db43dd6c439
│     - JLLSource libstdcxx_jll runtime sha1:1e8c06932a70d97dcc9ebbfbf672837c7bd0260b
│     - JLLSource GCC_support_libraries_jll runtime sha1:f989d3f5b7dd4db0b199013b0872b2c07c27eab8
│   /opt/target-aarch64-linux-gnu = sha1:b9c4a8b63e7ededde072c4ef0464288e24815318
│     - GeneratedSource: wrappers sha1:8f7cd737ff168d78373469edb0cf07e0e5e2a44c
│     - GeneratedSource: wrappers sha1:b2e500f186890ca4b13ea8634c2b9287a90d2499
│     - JLLSource Binutils_jll gcc sha1:265ac0fca2dc65da2ffaa6a5ad20d6d16d1623df
│     - JLLSource LinuxKernelHeaders_jll gcc/aarch64-linux-gnu/usr sha1:9dc8b93248cd24d5e4ea90c01856a6553e69ba22
│     - JLLSource Glibc_jll gcc/aarch64-linux-gnu sha1:f48edfeeb834732af7cea2caec502b42e6519b2d
│     - JLLSource GCC_jll gcc sha1:d74cb5b93fcac07759ac3bdde8f450668e877940
│     - JLLSource GCC_support_libraries_jll gcc sha1:262d7535a798070bd1bc3cb791ee9cf4e6838cdb
│     - JLLSource GCC_crt_objects_jll gcc sha1:43f8c8448210e34e95e9b91cf9e607240c9d7ee3
│     - JLLSource libstdcxx_jll gcc sha1:b66b45d43925f9375efef1be896935d2a6fc11aa
│     - JLLSource pkgconf_jll pkgconf sha1:08ebecab56e453db55392f9451fdf2ab9bdda249
│   /usr/local = sha1:da39a3ee5e6b4b0d3255bfef95601890afd80709
│   /usr/share/licenses = sha1:d2d5d79765fa352588f9fc23b2abfef1a5d0fb96
│     - DirectorySource:  sha1:c356bf9f9da20681cd510e2ae79a7e30941b6261
│   /workspace/destdir/target-aarch64-linux-gnu = sha1:da39a3ee5e6b4b0d3255bfef95601890afd80709
│   /workspace/metadir = sha1:aaa0d245ac10b10ab94373170dd0c03d7701832c
│     - GeneratedSource:  sha1:8530abbcee8051b560872b79c9201c9d9aea53da
│   /workspace/scripts = sha1:a7189afd9cd7aa875783487b074364ffa0a276ed
│     - DirectorySource:  sha1:dbeb610a5ce1290d66c3340ff123041d079df083
│   /workspace/srcdir = sha1:da39a3ee5e6b4b0d3255bfef95601890afd80709
│ [environment]
│   BinaryBuilder2 v1.4.4 = sha1:6d290be9244057f54318ca86b63d20992320aa57
│   BinaryBuilderAuditor v0.4.7 = sha1:cfe5b11125ad337abee50df6622064bb0ac3721d
│   BinaryBuilderGitUtils v0.3.0 = sha1:9fe8fe2a6fec7bcbf47cdca0e3a6189989ff5f4a
│   BinaryBuilderPlatformExtensions v0.2.2 = sha1:bebe0418f40164ff08d191b85cc55c6db1c1168a
│   BinaryBuilderProducts v0.4.0 = sha1:d51596bd9cc8bb0935cb8f33c80b79ce8bdd17ee
│   BinaryBuilderSources v0.3.6 = sha1:cd2720a0f8f0b3011c52f062be951ff326a5f776
│   BinaryBuilderToolchains v0.5.0 = sha1:642f70c6b149fc191e7b44844c4b6670160b3ec2
│   JLLGenerator v0.6.0 = sha1:5e510be2e08fc91283c414abefb108c481901294
│   JLLPrefixes v0.4.3 = sha1:64570d6b5f41521d8c7899b9c050d76a03f4528a
│   KeywordArgumentExtraction v1.2.0 = sha1:4131dc24111f7e6708381b6194452df6e611239f
│   LazyJLLWrappers v1.2.7 = sha1:ad57e8d126ed98ec169e1a710c5dd9e04d298c1d
│   MultiHashParsing v0.2.2 = sha1:0476b43f1f3c55ade6bf70609530991ddb4c2c89
│   Sandbox v2.3.0 = sha1:5759ba67d24e88176a84c23bb47bac5395a23765
│   ScratchSpaceGarbageCollector v0.1.2 = sha1:9671df55bab8965e27397e40ccc71f81ecb4ddc2
│   TreeArchival v0.2.0 = sha1:f13cb32318ba8fa878ab174e40f68ba875fe134a
└ @ BinaryBuilder2 ~/src/experiments/BB2-compiler-toolchains-transfer/worktrees/BinaryBuilder2.jl-ldconfig-dropin/src/build_api/BuildConfig.jl:290
┌ Debug: ExtractConfig hash buffer:
│ [extraction_metadata]
│   build_hash = sha1:70763ef1f5e90f97dc2c29d226088d7196d84abe
│   script_hash = sha1:da39a3ee5e6b4b0d3255bfef95601890afd80709
│ [products]
│   libfoo = ["libfoo"]
└ @ BinaryBuilder2 ~/src/experiments/BB2-compiler-toolchains-transfer/worktrees/BinaryBuilder2.jl-ldconfig-dropin/src/build_api/ExtractConfig.jl:141
sha1:9ee4849d5ba56938a7c0b8297f187b7612b5054f
```


## Future work

* It would be nice to not load _everything_ into memory at boot, and instead only look things up when necessary.  Otherwise, I could imagine this getting slightly unwieldy in the future, for large `BuildCache`s.
* We should come up with a good default heuristic for when to call `prune!(bc)`.
* When hacking on BB2 itself, the `BuildCache` is all but useless, because of the `[environment]` section of the `spec_hash(::BuildConfig)` changing every time.  It would be nice if the `BuildCache` was either more granular (e.g. only depended on certain functions within BB2?  Is such a thing possible?)
