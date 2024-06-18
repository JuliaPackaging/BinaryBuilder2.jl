using BinaryBuilder2

host = Platform(arch(HostPlatform()), "linux")
# The platforms we build for are themselves CrossPlatforms
platforms = [
    CrossPlatform(host => Platform("x86_64", "linux")),
    CrossPlatform(host => Platform("i686", "linux")),
    CrossPlatform(host => Platform("aarch64", "linux")),
    CrossPlatform(host => Platform("armv7l", "linux")),
    CrossPlatform(host => Platform("ppc64le", "linux")),
    CrossPlatform(host => Platform("x86_64", "windows")),
    CrossPlatform(host => Platform("i686", "windows")),
]

products = []
# For the bootstrap JLL, we contain within ourselves GCC and Binutils
tool_names = [
    # Binutils executables
    :ar, :as, :ld, :nm, :objcopy, :objdump, :ranlib, :readelf, :strings, :binutils_strip,
    # GCC executables
    :cc, :gcc, :cpp, :gxx, :gcc,
]

for varname in tool_names
    # Special-case troublesome variable names for our executable products
    if varname == :gxx
        tool_name = "g++"
    elseif varname == :binutils_strip
        tool_name = "strip"
    else
        tool_name = string(varname)
    end
    push!(products, ExecutableProduct("\${bindir}/\${GCC_TARGET}-$(tool_name)", varname))
end

build_tarballs(;
    src_name = "GCCBootstrap",
    src_version = v"9.4.0",
    sources = [
        # crosstool-ng can download the files, but we'd rather download them ourselves
        FileSource("http://mirrors.kernel.org/gnu/gcc/gcc-9.4.0/gcc-9.4.0.tar.xz",
            "c95da32f440378d7751dd95533186f7fc05ceb4fb65eb5b85234e6299eb9838e"),
        FileSource("https://mirrors.kernel.org/gnu/mpfr/mpfr-4.1.0.tar.xz",
            "0c98a3f1732ff6ca4ea690552079da9c597872d30e96ec28414ee23c95558a7f"),
        FileSource("https://mirrors.kernel.org/gnu/mpc/mpc-1.2.1.tar.gz",
            "17503d2c395dfcf106b622dc142683c1199431d095367c6aacba6eec30340459"),
        FileSource("https://gcc.gnu.org/pub/gcc/infrastructure/isl-0.24.tar.bz2",
            "fcf78dd9656c10eb8cf9fbd5f59a0b6b01386205fe1934b3b287a0a1898145c0"),
        FileSource("https://mirrors.kernel.org/gnu/gmp/gmp-6.2.1.tar.xz",
            "fd4829912cddd12f84181c3451cc752be224643e87fac497b69edddadc49b4f2"),
        FileSource("http://mirrors.kernel.org/pub/linux/kernel/v4.x/linux-4.1.49.tar.xz",
            "ff2e0ea5c536650aef64447c3aaa49c1a25e8f1db4ec4f7da700d3176f512ba8"),
        FileSource("https://mirrors.kernel.org/gnu/glibc/glibc-2.17.tar.xz",
            "6914e337401e0e0ade23694e1b2c52a5f09e4eda3270c67e7c3ba93a89b5b23e"),
        FileSource("https://mirrors.kernel.org/gnu/glibc/glibc-2.19.tar.xz",
            "2d3997f588401ea095a0b27227b1d50cdfdd416236f6567b564549d3b46ea2a2"),
        FileSource("https://musl.libc.org/releases/musl-1.2.2.tar.gz",
            "9b969322012d796dc23dda27a35866034fa67d8fb67e0e2c45c913c3d43219dd"),
        FileSource("https://sourceforge.net/projects/mingw-w64/files/mingw-w64/mingw-w64-release/mingw-w64-v9.0.0.tar.bz2",
            "1929b94b402f5ff4d7d37a9fe88daa9cc55515a6134805c104d1794ae22a4181"),
        FileSource("https://github.com/madler/zlib/archive/refs/tags/v1.2.12.tar.gz",
            "d8688496ea40fb61787500e863cc63c9afcbc524468cedeb478068924eb54932"; target="zlib-1.2.12.tar.gz"),
        FileSource("http://mirrors.kernel.org/gnu/ncurses/ncurses-6.2.tar.gz",
            "30306e0c76e0f9f1f0de987cf1c82a5c21e1ce6568b9227f7da5b71cbea86c9d"),
        FileSource("http://mirrors.kernel.org/gnu/libiconv/libiconv-1.16.tar.gz",
            "e6a1b1b589654277ee790cce3734f07876ac4ccfaecbee8afa0b649cf529cc04"),
        FileSource("http://mirrors.kernel.org/gnu/gettext/gettext-0.21.tar.xz",
            "d20fcbb537e02dcf1383197ba05bd0734ef7bf5db06bdb241eb69b7d16b73192"),
        FileSource("http://mirrors.kernel.org/gnu/binutils/binutils-2.29.1.tar.xz",
            "e7010a46969f9d3e53b650a518663f98a5dde3c3ae21b7d71e5e6803bc36b577"),
        FileSource("http://mirrors.kernel.org/gnu/binutils/binutils-2.38.tar.xz",
            "e316477a914f567eccc34d5d29785b8b0f5a10208d36bbacedcc39048ecfe024"),
        DirectorySource(joinpath(@__DIR__, "./bundled"))
    ],
    # This is not fully registered yet, it should have been
    # built as part of this universe earlier on in our bootstrap
    host_dependencies = [
        JLLSource("CrosstoolNG_jll"),
    ],
    script = raw"""
    cd ${WORKSPACE}/srcdir/

    # We purposefully do not use our toolchain here (although we could)
    # to make the point that this recipe does not require a functioning CToolchain.
    apt update && apt install -y build-essential || true

    # Generate the appropriate crosstool-ng config file for our current target
    ${WORKSPACE}/srcdir/gen_config.sh > .config

    # This takes our stripped-down config and fills out all the other options
    ct-ng upgradeconfig

    # Unset some things that BB automatically inserts into the environment,
    # but which crosstool-ng rightfully complains about.
    for TOOL in CC CXX LD AS AR FC OBJCOPY OBJDUMP RANLIB STRIP LIPO MESON NM READELF; do
        unset "${TOOL}" "HOST${TOOL}"
    done

    # Disable some checks that ct-ng performs
    export CT_ALLOW_BUILD_AS_ROOT_SURE=1

    # Do the actual build!
    hostcc_env ct-ng build

    # Fix case-insensitivity problems in netfilter headers
    if [[ "${target}" == *linux* ]]; then
        NF="${prefix}/${target}/sysroot/usr/include/linux/netfilter"
        for NAME in CONNMARK DSCP MARK RATEEST TCPMSS; do
            mv "${NF}/xt_${NAME}.h" "${NF}/xt_${NAME}_.h"
        done
        for NAME in ECN TTL; do
            mv "${NF}_ipv4/ipt_${NAME}.h" "${NF}_ipv4/ipt_${NAME}_.h"
        done
        mv "${NF}_ipv6/ip6t_HL.h" "${NF}_ipv6/ip6t_HL_.h"
    fi

    # Get GCC's target tuple
    GCC_TARGET=$(basename $(compgen -G ${bindir}/*-gcc))
    GCC_TARGET=${GCC_TARGET%*-gcc}
    """,
    platforms,
    products;
    toolchains=[
        HostToolsToolchain(
            host,
            [
                # We require make v4.3, rather than the latest, because GCC's build system
                # falls into an infinite loop with `make v4.4+`.
                JLLSource("GNUMake_jll", host; version=BinaryBuilder2.VersionSpec("4.3")),
            ],
        ),
    ],
    host,
)
