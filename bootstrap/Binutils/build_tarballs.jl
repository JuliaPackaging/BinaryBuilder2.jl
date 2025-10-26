using BinaryBuilder2, Pkg

# `--bootstrap` causes us to only build `host => target` binutils for everything
# This does not require a target C toolchain.
bootstrap_mode = false
if "--bootstrap" ∈ ARGS
    bootstrap_mode = true
    filter!(x -> x != "--bootstrap", ARGS)
end

script = raw"""
cd ${WORKSPACE}/srcdir/binutils-*/

# Update configure scripts and apply patches
update_configure_scripts
for p in ${WORKSPACE}/srcdir/patches/binutils-*.patch; do
    atomic_patch -p1 "${p}"
done

# Map `BUILD_CC` to `CC_FOR_BUILD`, etc...
BUILD_ENVS=( $(env | grep "^BUILD_" | cut -d'=' -f1) )
for BUILD_ENV in "${BUILD_ENVS[@]}"; do
    ENV="${BUILD_ENV#BUILD_}"
    export "${ENV}_FOR_BUILD=${!BUILD_ENV}"
done

./configure --prefix=${host_prefix} \
    --build=${build} \
    --host=${host} \
    --target=${target} \
    --with-sysroot=${host_prefix}/${target} \
    --disable-multilib \
    --program-prefix="${target}-" \
    --disable-werror \
    --enable-new-dtags \
    --enable-deterministic-archives \
    --disable-gprofng

# Force `make` to use `/bin/true` instead of `makeinfo` so that we don't
# die while failing to build docs.
MAKEVARS=( MAKEINFO=true )

# Fix "error: conflicting types for 'libintl_gettextparse'" that occurs
# because when cross-compiling, a different version of libintl is used
# and bison fails to regenerate `plural.c` from `plural.y`
# X-ref: https://sourceware.org/bugzilla/show_bug.cgi?id=22941
touch intl/plural.c

make -j${nproc} ${MAKEVARS[@]}
make install ${MAKEVARS[@]}
"""

if bootstrap_mode
    host_platforms = [
        Platform(arch(HostPlatform()), "linux")
    ]
else
    # Build for these host platforms
    host_platforms = [
        Platform("x86_64", "linux"),
        Platform("aarch64", "linux"),
    ]
end

# Build for all supported target platforms, except for macOS, which uses cctools, not binutils :(
target_platforms = supported_platforms(CToolchain)
target_platforms = filter(!Sys.isapple, target_platforms)

platforms = vec([
    # Build cross-binutils from `host => target`
    CrossPlatform(host, target) for host in host_platforms, target in target_platforms
])

if !bootstrap_mode
    # Build native binutils for all targets as well
    append!(platforms, [CrossPlatform(target, target) for target in target_platforms if target ∉ host_platforms])
end

tool_names = [
    :ar, :as, :ld, :nm, :objcopy, :objdump, :ranlib, :readelf, :strings, :binutils_strip,
]

products = []
for varname in tool_names
    # Special-case troublesome variable names for our executable products
    if varname == :binutils_strip
        tool_name = "strip"
    else
        tool_name = string(varname)
    end
    push!(products, ExecutableProduct("\${bindir}/\${target}-$(tool_name)", varname))
end

extra_kwargs = Dict(:target_toolchains => [])
if !bootstrap_mode
    extra_kwargs[:target_toolchains] = [CToolchain(;vendor=:gcc_bootstrap)]
end

build_tarballs(;
    src_name = "Binutils",
    src_version = v"2.41",
    sources = [
        ArchiveSource("https://ftp.wayne.edu/gnu/binutils/binutils-2.41.tar.xz",
                      "ae9a5789e23459e59606e6714723f2d3ffc31c03174191ef0d015bdf06007450"),
        # We've got a bevvy of patches for Binutils, include them in.
        DirectorySource("./patches-v2.41.0"; follow_symlinks=true, target="patches"),
    ],
    target_dependencies = [
        JLLSource(
            "Zlib_jll";
            # TODO: Drop this once `Zlib_jll` on `General` is built by BB2.
            repo=Pkg.Types.GitRepo(
                rev="bb2/GCCBootstrap-x86_64-linux-gnu",
                source="https://github.com/staticfloat/Zlib_jll.jl"
            ),
        ),
    ],
    script,
    platforms,
    products,
    host_toolchains = [CToolchain(;vendor=:gcc_bootstrap), HostToolsToolchain()],
    extra_kwargs...,
)
