using BinaryBuilder2

host = Platform(arch(HostPlatform()), "linux")
parsed_args = BinaryBuilder2.parse_build_tarballs_args(ARGS)
if !haskey(parsed_args, :universe_name)
    parsed_args[:universe_name] = "GCCBootstrap-$(triplet(host))"
end
meta = BuildMeta(;parsed_args...)
BinaryBuilder2.reset_timeline!(meta.universe)

# Build dependencies of `CrosstoolNG`
run_build_tarballs(meta, "Zlib/build_tarballs.jl")
run_build_tarballs(meta, "Ncurses/build_tarballs.jl")
run_build_tarballs(meta, "Readline/build_tarballs.jl")

# Build `CrosstoolNG` itself
run_build_tarballs(meta, "CrosstoolNG/build_tarballs.jl")

# Build GCCBootstrap_jll
run_build_tarballs(meta, "GCCBootstrap/build_tarballs.jl")
