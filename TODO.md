High-priority list:
 - Replace general registry rebasing with a separate registry that gets added as a "patch registry" of General!
   - Teach universes to pull down General registry from fork, scan registered JLLs and build map of buildcache hashes to JLL versions.
     - JLLGenerator needs to encode build hashes.
       - Top-level BB hash, for quick-reject
       - Top-level package hash (all extract hashes combined)
     - at top of build_tarballs() calculate package hash, check with buildcache for matching JLL version.
   - Don't use git registries until we're ready to register into them
 - Auto-remove extractions that exist in dependencies
 - Fix sandbox docker with overlays
   - docker run --security-opt apparmor:unconfined --cap-add=sys_admin -ti -v $(pwd)/mount_test:/mount_test -v storage:/storage alpine
   - podman run --cap-add=sys_admin -ti -v $(pwd)/mount_test:/mount_test -v storage:/storage alpine
   - mkdir -p /storage/upper /storage/work /tmp/merged; mount -t overlay overlay -o lowerdir=/mount_test,upperdir=/storage/upper,workdir=/storage/work /tmp/merged


- Add Binutils 2.28 (first version with `--push-state`?)
  - `--enable-compressed-debug-sections=all`: https://github.com/JuliaLang/julia/pull/45631#issuecomment-1529628736
- Create enormous bootstrapping script to build everything to ensure it's all working.
  - GCCBootstrap
  - Binutils
  - GCC
  - ClangBootstrap
  - Clang
  - Libcxx, etc...
- Add ability to specify an `on_load_callback` definition, then link to it from the `LibraryProduct`.
- Expand GCCBootstrap for Windows
  - Ensure that we have the patches for long file support (https://gcc.gnu.org/bugzilla/show_bug.cgi?id=107974)
- Build GCC <-> Glibc baked header diff tarballs
  - Build easy "diff/core" packaging utility to analyze a set of outputs for
    shared content and create a `FooCore_jll` and `FooXYZ_jll` set of artifacts
- Make universes more resilient to interruption, e.g.
  - expected package `Zlib_jll [83775a58]` to exist at path `/home/sabae/.julia/scratchspaces/12aac903-9f7c-5d81-afc2-d9565ea332af/universes/GCCBoostrap/dev/Zlib_jll`
- Finish implementation of `DepotCompactor.jl` to save disk space on Yggdrasil
  - Create torture-test-suite to run a bunch of builds in parallel on a new depot, to make sure that we can share resources properly
- Create mappings from all old style syntax to new style
  - `build_tarballs()` -> `BuildMeta()`, `BuildConfig()`, `build()`, `extract()`, `package()`, etc...
  - `compilers = [:c]` => `toolchains = [CToolchain()]`.
  - `HostBuildDependency()` => `JLLDependency` with appropriate platforms
- Copy over as many tests as possible from BB.jl and BBB.jl
- Build `-debug` variants, deploy them in a JLL, show how to override preferences to switch to them.
  - This should be doable with separate `extract!()` steps, perhaps?
  - Integrate with `.pkg` hooks for `select_artifacts.jl` to get them at `Pkg.add()` time?
- Do `strace` example, where we have statically-linked binaries so we don't need the `libc` tag.
- Remove `src_version` from BuildConfig and JLLs?

Features I'd like but I'm not prioritizing:
- Create testing github org and deploy to it during CI tests.
- LRU cache of specific size for `downloads` folder
- Progress bars for _everything_
  - JLL downloads
  - Source tarball unpacking
  - Auditing
- Automatic apk/apt caching server for Yggdrasil
  - Perhaps it'd be better to just have a transparent SQUID proxy to cache _every_ large HTTP request?
  - Could be another good buildkite plugin
