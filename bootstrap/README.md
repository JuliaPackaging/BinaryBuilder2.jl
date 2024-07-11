# bootstrap

This is like a mini [Yggdrasil](https://github.com/JuliaPackaging/Yggdrasil), but only for recipes required to build our compiler JLLs from scratch.
In particular, we vendor in anything needed to build `GCCBootstrap_jll` and `ClangBootstrap_jll`.
There may be some duplication between this subtree and Yggdrasil, especially in the early days, when not much is being built with BB2 on Yggdrasil.
In time, we expect the gap to close, and Yggdrasil to be able to serve as the host for almost everything (and perhaps even everything, in time).

## Running a bootstrap

Since BB2 is quite new, some dependencies are not packaged properly for consumption by BB2, and we must build them from scratch.
We will make use of BB2's `Universes` facility to stage multiple builds and deploy them in a synchronized fashion.
If you do not have `CrosstoolNG` packaged for your host architecture, let us begin by building it with an existing BB2 installation:

```
target="$(julia -e 'using Base.BinaryPlatforms; print(arch(HostPlatform()))')-linux-gnu"
UNIVERSE="GCCBootstrap-${target}"
DEPLOY="<github user>"
FLAGS=( "--universe=${UNIVERSE}" "--deploy=${DEPLOY}" "--verbose" "--debug=error" )
# If Crosstool_NG does not exist for your host, use the following:
julia --project bootstrap/Zlib/build_tarballs.jl "${FLAGS[@]}"
julia --project bootstrap/Ncurses/build_tarballs.jl "${FLAGS[@]}"
julia --project bootstrap/Readline/build_tarballs.jl "${FLAGS[@]}"
julia --project bootstrap/CrosstoolNG/build_tarballs.jl "${FLAGS[@]}"
```

Next, build `GCCBootstrap` for that host, but targeting all the targets that CrosstoolNG supports:
```
julia --project bootstrap/GCCBootstrap/build_tarballs.jl "${FLAGS[@]}"
```

**TODO**: Here, we would do `ClangBootstrap` as well, but that has not been built yet.

Once we have our bootstrap shards, let's use our bootstrap C toolchain to build our _actual_ C toolchain, starting with linux kernel headers, Glibc, and Binutils:


