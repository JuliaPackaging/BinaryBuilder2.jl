using BinaryBuilder2

host = Platform(arch(HostPlatform()), "linux")
parsed_args = BinaryBuilder2.parse_build_tarballs_args(ARGS)
if !haskey(parsed_args, :universe_name)
    parsed_args[:universe_name] = "GCCBootstrap-$(triplet(host))"
end
meta = BuildMeta(;parsed_args...)
BinaryBuilder2.reset_timeline!(meta.universe)

# We start by building CrosstoolNG; to do so, we need Zlib, Ncurses and Readline.
# We use whatever C compiler BB2 already has in order to perform this initial
# step, and we target _only_ the current host architecture.
ctng_target = Platform(arch(HostPlatform()), "linux")
ctng_meta = BuildMeta(;target_list=[ctng_target], parsed_args...)

# Build dependencies of `CrosstoolNG`
@info("Building CrosstoolNG dependencies...")
run_build_tarballs(ctng_meta, "Zlib/build_tarballs.jl")
run_build_tarballs(ctng_meta, "Ncurses/build_tarballs.jl")
run_build_tarballs(ctng_meta, "Readline/build_tarballs.jl")

# Build `CrosstoolNG` itself
@info("Building CrosstoolNG...")
run_build_tarballs(ctng_meta, "CrosstoolNG/build_tarballs.jl")

# Build GCCBootstrap, which we will then use to build our Glibc, Binutils, GCC, etc...
@info("Building GCCBootstrap...")
run_build_tarballs(meta, "GCCBootstrap/build_tarballs.jl")

GCC_TOOLS=[
    "Zlib", # Build Zlib again, this time targeting everything

    # Platform header/library bundles
    "LinuxKernelHeaders",
    "macOSSDK",
    "Mingw",
    "Musl",
    "Glibc",

    # Binutils
    "CCTools",
    "Binutils",
    # The big kahuna
    "GCC",
]
for tool in GCC_TOOLS
    @info("Building $(tool)")
    run_build_tarballs(meta, "$(tool)/build_tarballs.jl")
end

# Next, build `clang`, then use it to compile `compiler_rt` and `libcxx`
LLVM_TOOLS=[
    "clang",
    "compiler_rt",
    "libcxx",
]
for tool in LLVM_TOOLS
    @info("Building $(tool)")
    run_build_tarballs(meta, "LLVM/$(tool).jl")
end
