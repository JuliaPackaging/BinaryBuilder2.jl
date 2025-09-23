using BinaryBuilder2, Pkg
using BinaryBuilder2: BuildTargetSpec, gcc_platform, get_target_spec_by_name

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
    v"9.4.0" => [
        ArchiveSource("https://mirrors.kernel.org/gnu/gcc/gcc-9.4.0/gcc-9.4.0.tar.xz",
                      "c95da32f440378d7751dd95533186f7fc05ceb4fb65eb5b85234e6299eb9838e"),
        ArchiveSource("https://mirrors.kernel.org/gnu/mpfr/mpfr-4.0.2.tar.xz",
                      "1d3be708604eae0e42d578ba93b390c2a145f17743a744d8f3f8c2ad5855a38a";
                      target="gcc-9.4.0"),
        ArchiveSource("https://mirrors.kernel.org/gnu/mpc/mpc-1.1.0.tar.gz",
                      "6985c538143c1208dcb1ac42cedad6ff52e267b47e5f970183a3e75125b43c2e";
                      target="gcc-9.4.0"),
        ArchiveSource("https://gcc.gnu.org/pub/gcc/infrastructure/isl-0.18.tar.bz2",
                      "6b8b0fd7f81d0a957beb3679c81bbb34ccc7568d5682844d8924424a0dadcb1b";
                      target="gcc-9.4.0"),
        ArchiveSource("https://mirrors.kernel.org/gnu/gmp/gmp-6.1.2.tar.xz",
                      "87b565e89a9a684fe4ebeeddb8399dce2599f9c9049854ca8c0dfbdea0e21912";
                      target="gcc-9.4.0"),
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
    v"14.2.0" => [
        ArchiveSource("https://mirrors.kernel.org/gnu/gcc/gcc-14.2.0/gcc-14.2.0.tar.xz",
                      "a7b39bc69cbf9e25826c5a60ab26477001f7c08d85cec04bc0e29cabed6f3cc9"),
        ArchiveSource("https://mirrors.kernel.org/gnu/mpfr/mpfr-4.1.0.tar.xz",
                      "0c98a3f1732ff6ca4ea690552079da9c597872d30e96ec28414ee23c95558a7f",
                      target="gcc-14.2.0"),
        ArchiveSource("https://mirrors.kernel.org/gnu/mpc/mpc-1.2.1.tar.gz",
                      "17503d2c395dfcf106b622dc142683c1199431d095367c6aacba6eec30340459",
                      target="gcc-14.2.0"),
        ArchiveSource("https://gcc.gnu.org/pub/gcc/infrastructure/isl-0.24.tar.bz2",
                      "fcf78dd9656c10eb8cf9fbd5f59a0b6b01386205fe1934b3b287a0a1898145c0",
                      target="gcc-14.2.0"),
        ArchiveSource("https://mirrors.kernel.org/gnu/gmp/gmp-6.2.1.tar.xz",
                      "fd4829912cddd12f84181c3451cc752be224643e87fac497b69edddadc49b4f2",
                      target="gcc-14.2.0"),
    ],
)


script = raw"""
cd ${WORKSPACE}/srcdir

# Figure out the GCC version from the directory name
gcc_version="$(echo gcc-* | cut -d- -f2)"
if [[ "${target}" != *mingw* ]] && [[ "${target}" != *darwin* ]]; then
    lib64="lib${target_nbits%32}"
else
    lib64="lib"
fi

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
    GCC_CONF_ARGS+=( --disable-libsanitizer --disable-symvers --enable-clocale=generic )
    export libat_cv_have_ifunc=no
    export ac_cv_have_decl__builtin_ffs=yes

elif [[ "${target}" == *-mingw* ]]; then
    # On mingw, we need to explicitly enable openmp
    GCC_CONF_ARGS+=( --enable-libgomp )

    # Mingw just always looks in `mingw/` instead of `usr/`, so we symlink it:
    mkdir -p ${host_prefix}/${target}
    ln -s . ${target_prefix}/${target}/mingw

    # Go ahead and do this for 
    if [[ "${host}" == *-mingw-* ]]; then
        ln -s . ${host_prefix}/${target}/mingw
    fi

elif [[ "${target}" == *-darwin* ]]; then
    # GCC doesn't turn LTO on by default for some reason.
    GCC_CONF_ARGS+=( --enable-lto --enable-plugin )

    # On darwin, cilk doesn't build on 5.X-7.X.  :(
    export enable_libcilkrts=no

    # GCC doesn't know how to use availability macros properly, so tell it not to use functions
    # that are available only starting in later macOS versions such as `clock_gettime` or `mkostemp`
    export ac_cv_func_clock_gettime=no
    export ac_cv_func_mkostemp=no

    # Force GCC to use its own libiconv, don't use Apple's
    ICONV_PATHS=(
        /opt/target-*
        ${target_prefix}
    )
    if [[ "${host}" == *-darwin* ]]; then
        ICONV_PATHS+=( /opt/host-* )
    fi
    find ${ICONV_PATHS[@]} -name iconv.h -o -name libiconv\* | xargs rm -fv

elif [[ "${target}" == *-freebsd* ]]; then
    # If we don't already have a version number, add one
    if [[ "${target}" == *-freebsd ]]; then
        target_suffix="${FREEBSD_TARGET_SDK}"
    fi
fi

# Get rid of version numbers at the end of GCC deps
cd $WORKSPACE/srcdir/gcc-*/
for proj in mpfr mpc isl gmp; do
    if [[ -d $(echo ${proj}-*) ]]; then
        echo "Moving $(echo ${proj}-*) -> ${proj}"
        mv ${proj}-* ${proj}
    fi
done

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

for TOOL in CC CPP CXX AS AR NM LD RANLIB; do
    unset "${TOOL}"
    BUILD_NAME="BUILD_${TOOL}"
    export ${TOOL}_FOR_BUILD=${!BUILD_NAME}
    TARGET_NAME="TARGET_${TOOL}"
    if [[ -v "${TARGET_NAME}" ]]; then
        export ${TOOL}_FOR_TARGET=${!TARGET_NAME}

        # These target tool autodetections do not work
        export ac_cv_path_${TOOL}_FOR_TARGET=${!TARGET_NAME}
    fi
done

# libcc1 fails with an error about `-rdynamic` unless we define this
if [[ -v "NM_FOR_TARGET" ]]; then
    export gcc_cv_nm="${NM_FOR_TARGET}"
fi

# Make sure the tools that GCC itself wants to use ("ld", "as", "dysmutil") are available
# not just as "host-ld" or "host-as", etc... Otherwise, the `collect2` we generate looks
# for these names.  This lovely mess of bash results in `--with-ld=x86_64-linux-gnu-ld`
for TOOL in LD AS DSYMUTIL; do
    if [[ -v "TARGET_${TOOL}" ]]; then
        tool="$(tr '[:upper:]' '[:lower:]' <<<"${TOOL}")"
        GCC_CONF_ARGS+=( --with-${tool}="$(which "${target}-${tool}")" )
    fi
done
# It's critical that the above makes a mapping for `--with-ld`, so just assert that
# it does, here and now, rather than wasting everyone's time later:
[[ "${GCC_CONF_ARGS[@]}" == *--with-ld=* ]]
[[ "${GCC_CONF_ARGS[@]}" == *--with-as=* ]]

$WORKSPACE/srcdir/gcc-*/configure \
    --prefix="${host_prefix}" \
    --build="${build}" \
    --host="${host}" \
    --target="${target}${target_suffix:-}" \
    --disable-multilib \
    --disable-bootstrap \
    --disable-werror \
    --enable-threads=posix \
    --enable-languages=c,c++ \
    --with-build-sysroot="${target_prefix}/${target}" \
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

# Install licenses
install_license ${WORKSPACE}/srcdir/gcc-*/COPYING*
"""

function gcc_extract_spec_generator(build::BuildConfig, platform::AbstractPlatform)
    gcc_crt_object_names = ["libgcc.a"]
    if Sys.isapple(platform.target)
        append!(gcc_crt_object_names, ["crttms.o", "crt3.o"])
    else
        append!(gcc_crt_object_names, ["crtbegin.o", "crtend.o"])
    end
    gcc_crt_object_products = [
        FileProduct([string(raw"lib/gcc/${target}/${gcc_version}/", name)],
                    Symbol(replace(name, "." => "_"))) for name in gcc_crt_object_names
    ]
    return Dict(
        "libstdcxx" => ExtractSpec(
            raw"""
            extract ${prefix}/${target}/include
            extract ${prefix}/${target}/${lib64}/libstdc++*
            """,
            [
                FileProduct([raw"${target}/include/c++/${gcc_version}/iostream"], :iostream),
                FileProduct([raw"${target}/${lib64}/libstdc++.a"], :libstdcxx_a),
                LibraryProduct([raw"${target}/${lib64}/libstdc++"], :libstdcxx),
            ],
            get_target_spec_by_name(build, "host");
            platform = platform.target,
        ),
        "GCC_support_libraries" => ExtractSpec(
            raw"""
            extract ${prefix}/${target}/${lib64}
            # Remove `libstdc++`, as that was extracted in `libstdcxx`
            rm -f ${extract_dir}/${target}/${lib64}/libstdc++*
            """,
            [
                LibraryProduct([
                        raw"${target}/${lib64}/libgcc_s",
                        # Special windows naming of libgcc_s
                        raw"${target}/${lib64}/libgcc_s_seh",
                        raw"${target}/${lib64}/libgcc_s_sjlj",
                    ],
                    :libgcc_s
                ),
            ],
            get_target_spec_by_name(build, "host");
            platform = platform.target,
        ),
        "GCC_crt_objects" => ExtractSpec(
            raw"""
            extract ${prefix}/lib/gcc/${target}/${gcc_version}
            """,
            gcc_crt_object_products,
            get_target_spec_by_name(build, "host");
            platform = platform.target,
        ),
        "GCC" => ExtractSpec(
            raw"""
            # Remove things already extracted elsewhere
            extract ${prefix}/**
            rm -rf ${extract_dir}/${target}/include
            rm -rf ${extract_dir}/${target}/${lib64}
            rm -rf ${extract_dir}/lib/gcc
            """,
            [
                ExecutableProduct("\${target}-gcc", :gcc),
                ExecutableProduct("\${target}-g++", :gxx),
            ],
            get_target_spec_by_name(build, "host");
            platform,
        ),
    )
end
gcc_extraction_map = Dict(
    "libstdcxx" => ["libstdcxx"],
    "GCC_support_libraries" => ["GCC_support_libraries"],
    "GCC_crt_objects" => ["GCC_crt_objects"],
    # We explicitly do not depend on the above libraries, because they are `target`
    # and not cross-platform, thus do not get installed at the same time in JLLPrefixes.
    "GCC" => ["GCC"],
)

# Build for these host platforms
host_platforms = [
    Platform("x86_64", "linux"),
    Platform("aarch64", "linux"),
]

# Build for all supported target platforms
target_platforms = [
    Platform("x86_64", "linux"),
    Platform("i686", "linux"),
    Platform("aarch64", "linux"),
    Platform("armv6l", "linux"),
    Platform("armv7l", "linux"),
    Platform("powerpc64le", "linux"),

    Platform("x86_64", "linux"; libc="musl"),
    Platform("i686", "linux"; libc="musl"),
    Platform("aarch64", "linux"; libc="musl"),
    Platform("armv6l", "linux"; libc="musl"),
    Platform("armv7l", "linux"; libc="musl"),

    Platform("x86_64", "windows"),
    Platform("i686", "windows"),

    Platform("x86_64", "macos"),
    Platform("aarch64", "macos"),
]

function gcc_platforms(version::VersionNumber)
    platforms = vcat(
        # Build cross-gcc from `host => target`
        (CrossPlatform(host, target) for host in host_platforms, target in target_platforms if host != target)...,
        # Build native gcc for all targets as well
        (CrossPlatform(target, target) for target in target_platforms)...,
    )
    # aarch64-apple-darwin can't be targeted by GCC versions before
    # Iain Sandoe's legendary porting effort.
    if version < v"12"
        filter!(p -> !(os(p) == "macos" && arch(p) == "aarch64"), platforms)
    end
    return platforms
end

function gcc_build_spec_generator(host, platform)
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

    if os(platform.target) == "linux" && libc(platform.target) == "glibc"
        if arch(platform.target) ∈ ("x86_64", "i686", "powerpc64le")
            # v2.17
            glibc_repo = Pkg.Types.GitRepo(
                rev="2f33ece6d34f813332ff277ffaea52b075f1af67",
                source="https://github.com/staticfloat/Glibc_jll.jl"
            )
        else
            # v2.19
            glibc_repo = Pkg.Types.GitRepo(
                rev="a3d1c4ed6e676a47c4659aeecc8f396a2233757d",
                source="https://github.com/staticfloat/Glibc_jll.jl"
            )
        end

        push!(target_sources, JLLSource(
            "Glibc_jll",
            platform.target;
            repo=glibc_repo,
            target=target_str,
        ))
    elseif os(platform.target) == "linux" &&  libc(platform.target) == "musl"
        push!(target_sources, JLLSource(
            "Musl_jll",
            platform.target;
            repo=Pkg.Types.GitRepo(
                rev="827bfab690e1cab77b4d48e1a250c8acd3547443",
                source="https://github.com/staticfloat/Musl_jll.jl"
            ),
            target=target_str,
        ))
    elseif os(platform.target) == "windows"
        push!(target_sources, JLLSource(
            "Mingw_jll",
            platform.target;
            repo=Pkg.Types.GitRepo(
                rev="bb2/GCCBootstrap",
                source="https://github.com/staticfloat/Mingw_jll.jl"
            ),
            target=target_str,
        ))
    elseif os(platform.target) == "macos"
        push!(target_sources, JLLSource(
            "macOSSDK_jll",
            platform.target;
            uuid=Base.UUID("52f8e75f-aed1-5264-b4c9-b8da5a6d5365"),
            repo=Pkg.Types.GitRepo(
                rev="main",
                source="https://github.com/staticfloat/macOSSDK_jll.jl"
            ),
            target=target_str,
        ))
    elseif os(platform.target) == "freebsd"
        push!(target_sources, JLLSource(
            "FreeBSDSysroot_jll",
            platform.target;
            uuid=Base.UUID("671a10c0-f9bf-59ae-b52a-dff4adda89ae"),
            repo=Pkg.Types.GitRepo(
                source="https://github.com/staticfloat/FreeBSDSysroot_jll.jl",
                rev="main",
            ),
            target=target_str,
        ))
    else
        throw(ArgumentError("Don't know how to install libc sources for $(triplet(platform.target))"))
    end

    return [
        BuildTargetSpec(
            "build",
            CrossPlatform(host => host),
            [CToolchain(; vendor=:gcc_bootstrap, lock_microarchitecture), HostToolsToolchain()],
            [],
            Set([:host]),
        ),
        BuildTargetSpec(
            "host",
            CrossPlatform(host => platform.host),
            [CToolchain(; vendor=:gcc_bootstrap, lock_microarchitecture)],
            [],
            Set([:default]),
        ),
        BuildTargetSpec(
            "target",
            CrossPlatform(host => platform.target),
            [CToolchain(; vendor=:gcc_bootstrap, lock_microarchitecture)],
            target_sources,
            Set([]),
        ),
    ]
end
