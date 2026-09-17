High-priority list:
 - Add rust/go/fortran compilers for all platforms
 - Add Binutils `--enable-compressed-debug-sections=all`: https://github.com/JuliaLang/julia/pull/45631#issuecomment-1529628736
 - Fix sandbox docker/podman backend with overlays
   - docker run --security-opt apparmor:unconfined --cap-add=sys_admin -ti -v $(pwd)/mount_test:/mount_test -v storage:/storage alpine
   - podman run --cap-add=sys_admin -ti -v $(pwd)/mount_test:/mount_test -v storage:/storage alpine
   - mkdir -p /storage/upper /storage/work /tmp/merged; mount -t overlay overlay -o lowerdir=/mount_test,upperdir=/storage/upper,workdir=/storage/work /tmp/merged

- Expand GCCBootstrap for Windows
  - Add patches for long file support (https://gcc.gnu.org/bugzilla/show_bug.cgi?id=107974)
- Finish implementation of `DepotCompactor.jl` to save disk space on Yggdrasil
  - Create torture-test-suite to run a bunch of builds in parallel on a new depot, to make sure that we can share resources properly
- Copy over as many tests as possible from BB.jl and BBB.jl
- Build `-debug` variants, deploy them in a JLL, show how to override preferences to switch to them.
  - This should be doable with separate `extract!()` steps, perhaps?
  - Integrate with `.pkg` hooks for `select_artifacts.jl` to get them at `Pkg.add()` time?
- Do `strace` example, where we have statically-linked binaries so we don't need the `libc` tag.

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
