using BinaryBuilder2

# Re-use these 
include(joinpath(@__DIR__, "..", "..", "test", "build_recipes", "Readline.jl"))
include(joinpath(@__DIR__, "..", "..", "test", "build_recipes", "Ncurses.jl"))
include(joinpath(@__DIR__, "..", "..", "test", "build_recipes", "Zlib.jl"))
include(joinpath(@__DIR__, "crosstool_ng.jl"))
include(joinpath(@__DIR__, "gcc_bootstrap.jl"))

host = Platform(arch(HostPlatform()), "linux")
meta = BuildMeta(;
    universe_name="GCCBoostrap-$(triplet(host))",
    deploy_org="staticfloat",
    debug_modes=["build-error", "extract-error"],
    verbose=true,
)

# First, build the dependencies for crosstool-ng.
# Right now, this is _required_, because we need the `JLL.toml` files to exist for these
# dependencies in order to properly build `crosstool-ng`.
zlib_build_tarballs(meta, [host])
ncurses_build_tarballs(meta, [host])
readline_build_tarballs(meta, [host])
# Next, crosstool-ng
crosstool_ng_build_tarballs(meta, [host])

# Now that we have crosstool-ng built for our host, let's build a GCCBootstrap,
# also for our host, targeting many different targets!
targets = [
    CrossPlatform(host => Platform("x86_64", "linux")),
    CrossPlatform(host => Platform("i686", "linux")),
    CrossPlatform(host => Platform("aarch64", "linux")),
    CrossPlatform(host => Platform("armv7l", "linux")),
    CrossPlatform(host => Platform("ppc64le", "linux")),
]
gcc_bootstrap_build_tarballs(meta, targets)
