using BinaryBuilder2

host = Platform(arch(HostPlatform()), "linux")
meta = BuildMeta(;
    universe_name="GCCBoostrap-$(triplet(host))",
    deploy_org="staticfloat",
    debug_modes=["build-error", "extract-error"],
    verbose=true,
)

# If we're building for a new host, we need to build `CrosstoolNG_jll` first.
# To do so, you need to build `Zlib`, `Ncurses`, `Readline`, and then `CrosstoolNG`.
# We don't do this anymore, because Elliot deployed a `CrosstoolNG_jll` to his github.
#=
include(joinpath(@__DIR__, "..", "..", "test", "build_recipes", "Readline.jl"))
include(joinpath(@__DIR__, "..", "..", "test", "build_recipes", "Ncurses.jl"))
include(joinpath(@__DIR__, "..", "..", "test", "build_recipes", "Zlib.jl"))
include(joinpath(@__DIR__, "crosstool_ng.jl"))

zlib_build_tarballs(meta, [host])
ncurses_build_tarballs(meta, [host])
readline_build_tarballs(meta, [host])
# Next, crosstool-ng
crosstool_ng_build_tarballs(meta, [host])
=#

include(joinpath(@__DIR__, "gcc_bootstrap.jl"))

# Now that we have crosstool-ng built for our host, let's build a GCCBootstrap,
# also for our host, targeting many different targets!
targets = [
    CrossPlatform(host => Platform("x86_64", "linux")),
    CrossPlatform(host => Platform("i686", "linux")),
    CrossPlatform(host => Platform("aarch64", "linux")),
    CrossPlatform(host => Platform("armv7l", "linux")),
    CrossPlatform(host => Platform("ppc64le", "linux")),
    CrossPlatform(host => Platform("x86_64", "windows")),
    CrossPlatform(host => Platform("i686", "windows")),
]
gcc_bootstrap_build_tarballs(meta, targets)
