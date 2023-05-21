using BB2, Artifacts

name = "GCCBootstrap"
version = v"9.4.0"

# Build a native compiler right now
host = Platform("x86_64", "linux")
target = Platform("riscv64", "linux")

# Collection of sources required to complete build
sources = [
    # crosstool-ng will provide the build script
    GitSource("https://github.com/crosstool-ng/crosstool-ng.git",
                      "a8cef5773ef1961d26d334175d96758006625561"),

    # We provide some configs for crostool-ng
    DirectorySource(joinpath(@__DIR__, "./bundled")),

    # crosstool-ng can download the files, but we'd rather download them ourselves
    FileSource("http://mirrors.kernel.org/gnu/gcc/gcc-12.3.0/gcc-12.3.0.tar.xz",
               "949a5d4f99e786421a93b532b22ffab5578de7321369975b91aec97adfda8c3b"),
    FileSource("https://mirrors.kernel.org/gnu/mpfr/mpfr-4.1.0.tar.xz",
               "0c98a3f1732ff6ca4ea690552079da9c597872d30e96ec28414ee23c95558a7f"),
    FileSource("https://mirrors.kernel.org/gnu/mpc/mpc-1.2.1.tar.gz",
               "17503d2c395dfcf106b622dc142683c1199431d095367c6aacba6eec30340459"),
    FileSource("https://libisl.sourceforge.io/isl-0.26.tar.xz",
               "a0b5cb06d24f9fa9e77b55fabbe9a3c94a336190345c2555f9915bb38e976504"),
    FileSource("https://mirrors.kernel.org/gnu/gmp/gmp-6.2.1.tar.xz",
               "fd4829912cddd12f84181c3451cc752be224643e87fac497b69edddadc49b4f2"),
    FileSource("http://mirrors.kernel.org/pub/linux/kernel/v5.x/linux-5.15.108.tar.xz",
               "8beb69ada46f1cbca2f4cf901ec078846035c1cd925d9471422f65aff74243ba"),
    FileSource("https://mirrors.kernel.org/gnu/glibc/glibc-2.36.tar.xz",
               "1c959fea240906226062cb4b1e7ebce71a9f0e3c0836c09e7e3423d434fcfe75"),
    FileSource("https://github.com/madler/zlib/archive/refs/tags/v1.2.13.tar.gz",
               "1525952a0a567581792613a9723333d7f8cc20b87a81f920fb8bc7e3f2251428"; target="zlib-1.2.13.tar.gz"),
    FileSource("http://mirrors.kernel.org/gnu/ncurses/ncurses-6.4.tar.gz",
               "6931283d9ac87c5073f30b6290c4c75f21632bb4fc3603ac8100812bed248159"),
    FileSource("http://mirrors.kernel.org/gnu/libiconv/libiconv-1.16.tar.gz",
               "e6a1b1b589654277ee790cce3734f07876ac4ccfaecbee8afa0b649cf529cc04"),
    FileSource("http://mirrors.kernel.org/gnu/gettext/gettext-0.21.tar.xz",
               "d20fcbb537e02dcf1383197ba05bd0734ef7bf5db06bdb241eb69b7d16b73192"),
    FileSource("http://mirrors.kernel.org/gnu/binutils/binutils-2.40.tar.xz",
               "0f8a4c272d7f17f369ded10a4aca28b8e304828e95526da482b0ccc4dfc9d8e1"),
]

dependencies = AbstractSource[]

# Bash recipe for building across all platforms
script = raw"""
cd ${WORKSPACE}/srcdir/crosstool-ng*/

# These tools will help us to bootstrap
apt update
apt install -y texinfo unzip help2man

# Copy in our extra patches for all packages
for package in ${WORKSPACE}/srcdir/patches/*; do
    package="$(basename "${package}")"
    for version in ${WORKSPACE}/srcdir/patches/${package}/*; do
        version="$(basename "${version}")"
        if [ ! -d packages/${package}/${version} ]; then
            continue
        fi
        cp -v ${WORKSPACE}/srcdir/patches/${package}/${version}/* packages/${package}/${version}/
    done
done

# Disable some checks that ct-ng performs
export CT_ALLOW_BUILD_AS_ROOT_SURE=1

# Build crosstool-ng for the current host
# Tell it to look inside of `ncursesw` to find `panel.h` and friends
CFLAGS="-I/usr/local/include/ncursesw" ./configure --enable-local
make -j${nproc}

# Generate the appropriate crosstool-ng config file for our current target
${WORKSPACE}/srcdir/gen_config.sh > .config
cat .config

# This takes our stripped-down config and fills out all the other options
./ct-ng upgradeconfig

# Unset some things that BB automatically inserts into the environment,
# but which crosstool-ng rightfully complains about.
for TOOL in CC CXX LD AS AR FC OBJCOPY OBJDUMP RANLIB STRIP LIPO MESON NM READELF; do
    unset "${TOOL}" "BUILD_${TOOL}" "${TOOL}_BUILD" "${TOOL}_FOR_BUILD" "HOST${TOOL}"
done

# Do the actual build!
./ct-ng build

# Fix case-insensitivity problems in netfilter headers
# if [[ "${target}" == *linux* ]]; then
#     NF="${prefix}/${target}/sysroot/usr/include/linux/netfilter"
#     for NAME in CONNMARK DSCP MARK RATEEST TCPMSS; do
#         mv "${NF}/xt_${NAME}.h" "${NF}/xt_${NAME}_.h"
#     done
#     for NAME in ECN TTL; do
#         mv "${NF}_ipv4/ipt_${NAME}.h" "${NF}_ipv4/ipt_${NAME}_.h"
#     done
#     mv "${NF}_ipv6/ip6t_HL.h" "${NF}_ipv6/ip6t_HL_.h"
# fi

# Move licenses to the right spot
mkdir -p /tmp/GCCBootstrap
mv ${prefix}/share/licenses/* /tmp/GCCBootstrap
mv /tmp/GCCBootstrap ${prefix}/share/licenses/

[[ -f "${bindir}/${target}-gcc" ]]
"""

host_dependencies = [
    JLLSource("Ncurses_jll", host),
    JLLSource("Zlib_jll", host),
]

# Customize the toolchains that are provided here
toolchains = BB2.default_toolchains(CrossPlatform(host, target), [
    # We require make v4.3, rather than the latest.
    JLLSource("GNUMake_jll", host; version=BB2.VersionSpec("4.3")),
]; host_only=true)

meta = BuildMeta()
build_config = BuildConfig(
    name,
    version,
    sources,
    dependencies,
    host_dependencies,
    script,
    target;
    toolchains,
)
build_result = build!(meta, build_config)
runshell(build_result)

# extract_config = ExtractConfig(
#     build_result,
#     raw"""
#     extract ${prefix}/**
#     """,
#     BB2.AbstractProduct[],
# )
# extract_result = extract!(meta, extract_config)
# @info("Build complete", artifact=artifact_path(extract_result.artifact))
# display(extract_result.config.to)
