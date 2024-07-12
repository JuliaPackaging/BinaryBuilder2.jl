using BinaryBuilder2, Pkg
using BinaryBuilder2: BuildTargetSpec, gcc_platform

meta = BinaryBuilder2.get_default_meta()

# Since we can build a variety of GCC versions, track them and their hashes here.
# We download GCC, MPFR, MPC, ISL and GMP.
const gcc_version_sources = Dict{VersionNumber,Vector}(
    v"4.8.5" => [
        ArchiveSource("https://mirrors.kernel.org/gnu/gcc/gcc-4.8.5/gcc-4.8.5.tar.bz2",
                      "22fb1e7e0f68a63cee631d85b20461d1ea6bda162f03096350e38c8d427ecf23";
                      target="gcc"),
        ArchiveSource("https://mirrors.kernel.org/gnu/mpfr/mpfr-2.4.2.tar.xz",
                      "d7271bbfbc9ddf387d3919df8318cd7192c67b232919bfa1cb3202d07843da1b";
                      target="gcc/mpfr"),
        ArchiveSource("https://gcc.gnu.org/pub/gcc/infrastructure/mpc-0.8.1.tar.gz",
                      "e664603757251fd8a352848276497a4c79b7f8b21fd8aedd5cc0598a38fee3e4";
                      target="gcc/mpc"),
        ArchiveSource("https://mirrors.kernel.org/gnu/gmp/gmp-4.3.2.tar.bz2",
                      "936162c0312886c21581002b79932829aa048cfaf9937c6265aeaa14f1cd1775";
                      target="gcc/gmp"),
    ],
    v"5.2.0" => [
        ArchiveSource("https://mirrors.kernel.org/gnu/gcc/gcc-5.2.0/gcc-5.2.0.tar.bz2",
                      "5f835b04b5f7dd4f4d2dc96190ec1621b8d89f2dc6f638f9f8bc1b1014ba8cad"),
        ArchiveSource("https://mirrors.kernel.org/gnu/mpfr/mpfr-2.4.2.tar.xz",
                      "d7271bbfbc9ddf387d3919df8318cd7192c67b232919bfa1cb3202d07843da1b"),
        ArchiveSource("https://gcc.gnu.org/pub/gcc/infrastructure/mpc-0.8.1.tar.gz",
                      "e664603757251fd8a352848276497a4c79b7f8b21fd8aedd5cc0598a38fee3e4"),
        ArchiveSource("https://mirrors.kernel.org/gnu/gmp/gmp-4.3.2.tar.bz2",
                      "936162c0312886c21581002b79932829aa048cfaf9937c6265aeaa14f1cd1775"),
        ArchiveSource("https://gcc.gnu.org/pub/gcc/infrastructure/isl-0.14.tar.bz2",
                      "7e3c02ff52f8540f6a85534f54158968417fd676001651c8289c705bd0228f36"),
    ],
    v"6.1.0" => [
        ArchiveSource("https://mirrors.kernel.org/gnu/gcc/gcc-6.1.0/gcc-6.1.0.tar.bz2",
                      "09c4c85cabebb971b1de732a0219609f93fc0af5f86f6e437fd8d7f832f1a351"),
        ArchiveSource("https://mirrors.kernel.org/gnu/mpfr/mpfr-2.4.2.tar.xz",
                      "d7271bbfbc9ddf387d3919df8318cd7192c67b232919bfa1cb3202d07843da1b"),
        ArchiveSource("https://gcc.gnu.org/pub/gcc/infrastructure/mpc-0.8.1.tar.gz",
                      "e664603757251fd8a352848276497a4c79b7f8b21fd8aedd5cc0598a38fee3e4"),
        ArchiveSource("https://mirrors.kernel.org/gnu/gmp/gmp-4.3.2.tar.bz2",
                      "936162c0312886c21581002b79932829aa048cfaf9937c6265aeaa14f1cd1775"),
        ArchiveSource("https://gcc.gnu.org/pub/gcc/infrastructure/isl-0.15.tar.bz2",
                      "8ceebbf4d9a81afa2b4449113cee4b7cb14a687d7a549a963deb5e2a41458b6b"),
    ],
    v"7.1.0" => [
        ArchiveSource("https://mirrors.kernel.org/gnu/gcc/gcc-7.1.0/gcc-7.1.0.tar.bz2",
                      "8a8136c235f64c6fef69cac0d73a46a1a09bb250776a050aec8f9fc880bebc17"),
        ArchiveSource("https://mirrors.kernel.org/gnu/mpfr/mpfr-3.1.4.tar.xz",
                      "761413b16d749c53e2bfd2b1dfaa3b027b0e793e404b90b5fbaeef60af6517f5"),
        ArchiveSource("https://mirrors.kernel.org/gnu/mpc/mpc-1.0.3.tar.gz",
                      "617decc6ea09889fb08ede330917a00b16809b8db88c29c31bfbb49cbf88ecc3"),
        ArchiveSource("https://gcc.gnu.org/pub/gcc/infrastructure/isl-0.16.1.tar.bz2",
                      "412538bb65c799ac98e17e8cfcdacbb257a57362acfaaff254b0fcae970126d2"),
        ArchiveSource("https://mirrors.kernel.org/gnu/gmp/gmp-6.1.0.tar.xz",
                      "68dadacce515b0f8a54f510edf07c1b636492bcdb8e8d54c56eb216225d16989"),
    ],
    v"8.1.0" => [
        ArchiveSource("https://mirrors.kernel.org/gnu/gcc/gcc-8.1.0/gcc-8.1.0.tar.xz",
                      "1d1866f992626e61349a1ccd0b8d5253816222cdc13390dcfaa74b093aa2b153"),
        ArchiveSource("https://mirrors.kernel.org/gnu/mpfr/mpfr-4.0.1.tar.xz",
                      "67874a60826303ee2fb6affc6dc0ddd3e749e9bfcb4c8655e3953d0458a6e16e"),
        ArchiveSource("https://mirrors.kernel.org/gnu/mpc/mpc-1.1.0.tar.gz",
                      "6985c538143c1208dcb1ac42cedad6ff52e267b47e5f970183a3e75125b43c2e"),
        ArchiveSource("https://gcc.gnu.org/pub/gcc/infrastructure/isl-0.18.tar.bz2",
                      "6b8b0fd7f81d0a957beb3679c81bbb34ccc7568d5682844d8924424a0dadcb1b"),
        ArchiveSource("https://mirrors.kernel.org/gnu/gmp/gmp-6.1.2.tar.xz",
                      "87b565e89a9a684fe4ebeeddb8399dce2599f9c9049854ca8c0dfbdea0e21912"),
    ],
    v"9.1.0" => [
        ArchiveSource("https://mirrors.kernel.org/gnu/gcc/gcc-9.1.0/gcc-9.1.0.tar.xz",
                      "79a66834e96a6050d8fe78db2c3b32fb285b230b855d0a66288235bc04b327a0"),
        ArchiveSource("https://mirrors.kernel.org/gnu/mpfr/mpfr-4.0.2.tar.xz",
                      "1d3be708604eae0e42d578ba93b390c2a145f17743a744d8f3f8c2ad5855a38a";
                      target="gcc-9.1.0"),
        ArchiveSource("https://mirrors.kernel.org/gnu/mpc/mpc-1.1.0.tar.gz",
                      "6985c538143c1208dcb1ac42cedad6ff52e267b47e5f970183a3e75125b43c2e";
                      target="gcc-9.1.0"),
        ArchiveSource("https://gcc.gnu.org/pub/gcc/infrastructure/isl-0.18.tar.bz2",
                      "6b8b0fd7f81d0a957beb3679c81bbb34ccc7568d5682844d8924424a0dadcb1b";
                      target="gcc-9.1.0"),
        ArchiveSource("https://mirrors.kernel.org/gnu/gmp/gmp-6.1.2.tar.xz",
                      "87b565e89a9a684fe4ebeeddb8399dce2599f9c9049854ca8c0dfbdea0e21912";
                      target="gcc-9.1.0"),
    ],
    v"10.2.0" => [
        ArchiveSource("https://mirrors.kernel.org/gnu/gcc/gcc-10.2.0/gcc-10.2.0.tar.xz",
                      "b8dd4368bb9c7f0b98188317ee0254dd8cc99d1e3a18d0ff146c855fe16c1d8c"),
        ArchiveSource("https://mirrors.kernel.org/gnu/mpfr/mpfr-4.0.2.tar.xz",
                      "1d3be708604eae0e42d578ba93b390c2a145f17743a744d8f3f8c2ad5855a38a"),
        ArchiveSource("https://mirrors.kernel.org/gnu/mpc/mpc-1.1.0.tar.gz",
                      "6985c538143c1208dcb1ac42cedad6ff52e267b47e5f970183a3e75125b43c2e"),
        ArchiveSource("https://gcc.gnu.org/pub/gcc/infrastructure/isl-0.18.tar.bz2",
                      "6b8b0fd7f81d0a957beb3679c81bbb34ccc7568d5682844d8924424a0dadcb1b"),
        ArchiveSource("https://mirrors.kernel.org/gnu/gmp/gmp-6.1.2.tar.xz",
                      "87b565e89a9a684fe4ebeeddb8399dce2599f9c9049854ca8c0dfbdea0e21912"),
    ],
    v"11.1.0" => [
        ArchiveSource("https://mirrors.kernel.org/gnu/gcc/gcc-11.1.0/gcc-11.1.0.tar.xz",
                      "4c4a6fb8a8396059241c2e674b85b351c26a5d678274007f076957afa1cc9ddf"),
        ArchiveSource("https://mirrors.kernel.org/gnu/mpfr/mpfr-4.0.2.tar.xz",
                      "1d3be708604eae0e42d578ba93b390c2a145f17743a744d8f3f8c2ad5855a38a"),
        ArchiveSource("https://mirrors.kernel.org/gnu/mpc/mpc-1.1.0.tar.gz",
                      "6985c538143c1208dcb1ac42cedad6ff52e267b47e5f970183a3e75125b43c2e"),
        ArchiveSource("https://gcc.gnu.org/pub/gcc/infrastructure/isl-0.18.tar.bz2",
                      "6b8b0fd7f81d0a957beb3679c81bbb34ccc7568d5682844d8924424a0dadcb1b"),
        ArchiveSource("https://mirrors.kernel.org/gnu/gmp/gmp-6.1.2.tar.xz",
                      "87b565e89a9a684fe4ebeeddb8399dce2599f9c9049854ca8c0dfbdea0e21912"),
    ],
    v"14.1.0" => [
        ArchiveSource("https://mirrors.kernel.org/gnu/gcc/gcc-14.1.0/gcc-14.1.0.tar.xz",
                      "e283c654987afe3de9d8080bc0bd79534b5ca0d681a73a11ff2b5d3767426840"),
        ArchiveSource("https://mirrors.kernel.org/gnu/mpfr/mpfr-4.1.0.tar.xz",
                      "0c98a3f1732ff6ca4ea690552079da9c597872d30e96ec28414ee23c95558a7f",
                      target="gcc-14.1.0"),
        ArchiveSource("https://mirrors.kernel.org/gnu/mpc/mpc-1.2.1.tar.gz",
                      "17503d2c395dfcf106b622dc142683c1199431d095367c6aacba6eec30340459",
                      target="gcc-14.1.0"),
        ArchiveSource("https://gcc.gnu.org/pub/gcc/infrastructure/isl-0.24.tar.bz2",
                      "fcf78dd9656c10eb8cf9fbd5f59a0b6b01386205fe1934b3b287a0a1898145c0",
                      target="gcc-14.1.0"),
        ArchiveSource("https://mirrors.kernel.org/gnu/gmp/gmp-6.2.1.tar.xz",
                      "fd4829912cddd12f84181c3451cc752be224643e87fac497b69edddadc49b4f2",
                      target="gcc-14.1.0"),
    ],
)


script = raw"""
cd ${WORKSPACE}/srcdir

apt update
apt install -y vim

# Figure out the GCC version from the directory name
gcc_version="$(echo gcc-* | cut -d- -f2)"

# Update configure scripts for all projects
#update_configure_scripts --reconf

# Force everything to default to cross compiling; this avoids differences
# in behavior between when we target our own triplet
for f in $(find . -name configure); do
    sed -i.bak -e 's&cross_compiling=no&cross_compiling=yes&g' "${f}"
    sed -i.bak -e 's&is_cross_compiler=no&is_cross_compiler=yes&g' "${f}"
done

# Initialize GCC_CONF_ARGS
GCC_CONF_ARGS=()

## Architecture-dependent arguments
# Choose a default arch, and on arm*hf targets, pass `--with-float=hard` explicitly
if [[ "${target}" == arm*hf ]]; then
    # We choose the armv6 arch by default for compatibility
    GCC_CONF_ARGS+=( --with-float=hard --with-arch=armv6 --with-fpu=vfp )
elif [[ "${target}" == x86_64* ]]; then
    GCC_CONF_ARGS+=( --with-arch=x86-64 )
elif [[ "${target}" == i686* ]]; then
    GCC_CONF_ARGS+=( --with-arch=pentium4 )
fi

## OS-dependent arguments
# On musl targets, disable a bunch of things we don't want
if [[ "${target}" == *-musl* ]]; then
    GCC_CONF_ARGS+=( --disable-libssp --disable-libmpx --disable-libmudflap )
    GCC_CONF_ARGS+=( --disable-libsanitizer --disable-symvers )
    export libat_cv_have_ifunc=no
    export ac_cv_have_decl__builtin_ffs=yes

elif [[ "${target}" == *-mingw* ]]; then
    # On mingw, we need to explicitly set the windres code page to 1, otherwise windres segfaults
    export CPPFLAGS="${CPPFLAGS} -DCP_ACP=1"

    # On mingw override native system header directories
    GCC_CONF_ARGS+=( --with-native-system-header-dir=/include )

    # On mingw, we need to explicitly enable openmp
    GCC_CONF_ARGS+=( --enable-libgomp )

    # We also need to symlink our lib directory specially
    #ln -s sys-root/lib ${sysroot}/lib

elif [[ "${target}" == *-darwin* ]]; then
    # GCC doesn't turn LTO on by default for some reason.
    GCC_CONF_ARGS+=( --enable-lto --enable-plugin )

    # On darwin, cilk doesn't build on 5.X-7.X.  :(
    export enable_libcilkrts=no

    # GCC doesn't know how to use availability macros properly, so tell it not to use functions
    # that are available only starting in later macOS versions such as `clock_gettime` or `mkostemp`
    export ac_cv_func_clock_gettime=no
    export ac_cv_func_mkostemp=no
fi

# Get rid of version numbers at the end of GCC deps
cd $WORKSPACE/srcdir/gcc-*/
for proj in mpfr mpc isl gmp; do
    if [[ -d $(echo ${proj}-*) ]]; then
        echo "Moving $(echo ${proj}-*) -> ${proj}"
        mv ${proj}-* ${proj}
    fi
done

# Do not run fixincludes except on Darwin
# if [[ ${target} != *-darwin* ]]; then
#     sed -i 's@\./fixinc\.sh@-c true@' gcc/Makefile.in
# fi

# Apply all gcc patches, if any exist
if compgen -G "${WORKSPACE}/srcdir/patches/gcc-*.patch" > /dev/null; then
    for p in ${WORKSPACE}/srcdir/patches/gcc-*.patch; do
        atomic_patch -p1 "${p}"
    done
fi

# Build in separate directory
mkdir -p $WORKSPACE/srcdir/gcc_build
cd $WORKSPACE/srcdir/gcc_build

# Force `make` to use `/bin/true` instead of `makeinfo` so that we don't
# die while failing to build docs.
MAKEVARS=( MAKEINFO=true )

for TOOL in CC CXX AS AR NM LD RANLIB; do
    BUILD_NAME="BUILD_${TOOL}"
    export ${TOOL}_FOR_BUILD=${!BUILD_NAME}
    TARGET_NAME="TARGET_${TOOL}"
    export ${TOOL}_FOR_TARGET=${!TARGET_NAME}

    # These target tool autodetections do not work
    export ac_cv_path_${TOOL}_FOR_TARGET=${!TARGET_NAME}
done

# Make sure the tools that GCC itself wants to use ("ld", "as", "dysmutil") are available
# not just as "host-ld" or "host-as", etc... Otherwise, the `collect2` we generate looks
# for these names.  This lovely mess of bash results in `--with-ld=x86_64-linux-gnu-ld`
for TOOL in LD AS DSYMUTIL; do
    if [[ -n "${!TOOL:-}" ]]; then
        tool="$(tr '[:upper:]' '[:lower:]' <<<"${TOOL}")"
        GCC_CONF_ARGS+=( --with-${tool}="$(which "${target}-${tool}")" )
    fi
done

$WORKSPACE/srcdir/gcc-*/configure \
    --prefix="${host_prefix}" \
    --build="${build}" \
    --host="${host}" \
    --target="${target}" \
    --disable-multilib \
    --disable-werror \
    --disable-bootstrap \
    --enable-threads=posix \
    --enable-languages=c,c++ \
    --with-build-sysroot="${host_prefix}/${target}" \
    --with-sysroot="${host_prefix}/${target}" \
    --program-prefix="${target}-" \
    ${GCC_CONF_ARGS[@]}

## Build, build, build!
make -j${nproc} "${MAKEVARS[@]}"
make install "${MAKEVARS[@]}"

# Remove misleading libtool archives
rm -f ${prefix}/${target}/lib*/*.la

# Remove heavy doc directories
rm -rf ${prefix}/share/man
"""

# Build for these host platforms
host_platforms = [
    Platform("x86_64", "linux"),
    Platform("aarch64", "linux"),
]

# Build for all supported target platforms
target_platforms = supported_platforms(;experimental=true)

# Only glibc linux for now
target_platforms = filter(p -> libc(p) == "glibc", target_platforms)

platforms = vcat(
    # Build cross-gcc from `host => target`
    (CrossPlatform(host, target) for host in host_platforms, target in target_platforms if host != target)...,
    # Build native gcc for all targets as well
    (CrossPlatform(target, target) for target in target_platforms)...,
)

function gcc_spec_generator(host, platform)
    target_str = triplet(gcc_platform(platform.target))
    lock_microarchitecture = false

    target_sources = []
    if os(platform.target) == "linux"
        push!(target_sources, JLLSource(
            "LinuxKernelHeaders_jll",
            platform.target;
            repo=Pkg.Types.GitRepo(
                rev="bb2/GCC",
                source="https://github.com/staticfloat/LinuxKernelHeaders_jll.jl"
            ),
            target=joinpath(target_str, "usr"),
        ))
    end

    if libc(platform.target) == "glibc"
        if arch(platform.target) ∈ ("x86_64", "i686", "powerpc64le")
            # v2.17
            glibc_repo = Pkg.Types.GitRepo(
                rev="1ae9e1bdd75523bf0f027a9a740888ee6aad22ac",
                source="https://github.com/staticfloat/Glibc_jll.jl"
            )
        else
            # v2.19
            glibc_repo = Pkg.Types.GitRepo(
                rev="d436c3277e9bce583bcc5c469849fc9809bf86e9",
                source="https://github.com/staticfloat/Glibc_jll.jl"
            )
        end

        push!(target_sources, JLLSource(
            "Glibc_jll",
            platform.target;
            repo=glibc_repo,
            target=target_str,
        ))
    elseif libc(platform.target) == "musl"
        push!(target_sources, JLLSource(
            "Musl_jll",
            platform.target;
            repo=Pkg.Types.GitRepo(
                rev="bb2/GCC",
                source="https://github.com/staticfloat/Musl_jll.jl"
            ),
            target=target_str,
        ))
    end

    return [
        BuildTargetSpec(
            "build",
            CrossPlatform(host => host),
            [CToolchain(; vendor=:bootstrap, lock_microarchitecture), HostToolsToolchain()],
            [],
            Set([:host]),
        ),
        BuildTargetSpec(
            "host",
            CrossPlatform(host => platform.host),
            [CToolchain(; vendor=:bootstrap, lock_microarchitecture)],
            target_sources,
            Set([:default]),
        ),
        BuildTargetSpec(
            "target",
            CrossPlatform(host => platform.target),
            [CToolchain(; vendor=:bootstrap, lock_microarchitecture)],
            [],
            Set{Symbol}(),
        ),
    ]
end
