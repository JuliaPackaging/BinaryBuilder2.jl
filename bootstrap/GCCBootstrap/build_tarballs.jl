using BinaryBuilder2, Pkg

host = Platform(arch(HostPlatform()), "linux")
# The platforms we build for are themselves CrossPlatforms
platforms = [
    # Glibc linuces
    CrossPlatform(host => Platform("x86_64", "linux")),
    CrossPlatform(host => Platform("i686", "linux")),
    CrossPlatform(host => Platform("aarch64", "linux")),
    CrossPlatform(host => Platform("armv6l", "linux")),
    CrossPlatform(host => Platform("armv7l", "linux")),
    CrossPlatform(host => Platform("ppc64le", "linux")),

    # musl linuces
    CrossPlatform(host => Platform("x86_64", "linux"; libc="musl")),
    CrossPlatform(host => Platform("i686", "linux"; libc="musl")),
    CrossPlatform(host => Platform("aarch64", "linux"; libc="musl")),
    CrossPlatform(host => Platform("armv6l", "linux"; libc="musl")),
    CrossPlatform(host => Platform("armv7l", "linux"; libc="musl")),

    # Windows platforms
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
    src_version = v"14.2.0",
    sources = [
        # crosstool-ng can download the files, but we'd rather download them ourselves
        FileSource("http://mirrors.kernel.org/gnu/gcc/gcc-14.2.0/gcc-14.2.0.tar.xz",
            "a7b39bc69cbf9e25826c5a60ab26477001f7c08d85cec04bc0e29cabed6f3cc9"),
        FileSource("https://mirrors.kernel.org/gnu/mpfr/mpfr-4.2.1.tar.xz",
            "277807353a6726978996945af13e52829e3abd7a9a5b7fb2793894e18f1fcbb2"),
        FileSource("https://mirrors.kernel.org/gnu/mpc/mpc-1.3.1.tar.gz",
            "ab642492f5cf882b74aa0cb730cd410a81edcdbec895183ce930e706c1c759b8"),
        FileSource("https://libisl.sourceforge.io/isl-0.26.tar.xz",
            "a0b5cb06d24f9fa9e77b55fabbe9a3c94a336190345c2555f9915bb38e976504"),
        FileSource("https://mirrors.kernel.org/gnu/gmp/gmp-6.3.0.tar.xz",
            "a3c2b80201b89e68616f4ad30bc66aee4927c3ce50e33929ca819d5c43538898"),
        FileSource("http://mirrors.kernel.org/pub/linux/kernel/v4.x/linux-4.1.49.tar.xz",
            "ff2e0ea5c536650aef64447c3aaa49c1a25e8f1db4ec4f7da700d3176f512ba8"),
        FileSource("https://mirrors.kernel.org/gnu/glibc/glibc-2.17.tar.xz",
            "6914e337401e0e0ade23694e1b2c52a5f09e4eda3270c67e7c3ba93a89b5b23e"),
        FileSource("https://mirrors.kernel.org/gnu/glibc/glibc-2.19.tar.xz",
            "2d3997f588401ea095a0b27227b1d50cdfdd416236f6567b564549d3b46ea2a2"),
        FileSource("https://musl.libc.org/releases/musl-1.2.5.tar.gz",
            "a9a118bbe84d8764da0ea0d28b3ab3fae8477fc7e4085d90102b8596fc7c75e4"),
        FileSource("https://sourceforge.net/projects/mingw-w64/files/mingw-w64/mingw-w64-release/mingw-w64-v12.0.0.tar.bz2",
            "cc41898aac4b6e8dd5cffd7331b9d9515b912df4420a3a612b5ea2955bbeed2f"),
        FileSource("https://github.com/madler/zlib/archive/refs/tags/v1.3.1.tar.gz",
            "17e88863f3600672ab49182f217281b6fc4d3c762bde361935e436a95214d05c"; target="zlib-1.3.1.tar.gz"),
        FileSource("https://github.com/facebook/zstd/releases/download/v1.5.6/zstd-1.5.6.tar.gz",
            "8c29e06cf42aacc1eafc4077ae2ec6c6fcb96a626157e0593d5e82a34fd403c1"),
        FileSource("http://mirrors.kernel.org/gnu/ncurses/ncurses-6.4.tar.gz",
            "6931283d9ac87c5073f30b6290c4c75f21632bb4fc3603ac8100812bed248159"),
        FileSource("http://mirrors.kernel.org/gnu/libiconv/libiconv-1.16.tar.gz",
            "e6a1b1b589654277ee790cce3734f07876ac4ccfaecbee8afa0b649cf529cc04"),
        FileSource("http://mirrors.kernel.org/gnu/gettext/gettext-0.23.1.tar.xz",
            "c1f97a72a7385b7e71dd07b5fea6cdaf12c9b88b564976b23bd8c11857af2970"),
        FileSource("http://mirrors.kernel.org/gnu/binutils/binutils-2.29.1.tar.xz",
            "e7010a46969f9d3e53b650a518663f98a5dde3c3ae21b7d71e5e6803bc36b577"),
        FileSource("http://mirrors.kernel.org/gnu/binutils/binutils-2.43.1.tar.xz",
            "13f74202a3c4c51118b797a39ea4200d3f6cfbe224da6d1d95bb938480132dfd"),
        DirectorySource(joinpath(@__DIR__, "./bundled"))
    ],
    host_dependencies = [
        # This is not registered yet, so we just use one that I pushed up
        JLLSource(
            "CrosstoolNG_jll",
            host;
            uuid = Base.UUID("86569e53-7a4c-551c-9ab0-bc1131c15cd4"),
            repo = Pkg.Types.GitRepo(
                source="https://github.com/staticfloat/CrosstoolNG_jll.jl",
                rev="main",
            ),
        ),
    ],
    script = raw"""
    cd ${WORKSPACE}/srcdir/

    # We purposefully do not use our toolchain here (although we could)
    # to make the point that this recipe does not require a functioning CToolchain.
    apt update && apt install -y build-essential || true

    # We don't need the `LD_LIBRARY_PATH` that is set for the CSL libs
    unset LD_LIBRARY_PATH

    # Generate the appropriate crosstool-ng config file for our current target
    ${WORKSPACE}/srcdir/gen_config.sh > .config

    # This takes our stripped-down config and fills out all the other options
    ct-ng upgradeconfig

    # Disable some checks that ct-ng performs
    export CT_ALLOW_BUILD_AS_ROOT_SURE=1

    # Do the actual build!
    ct-ng build

    # Fix case-insensitivity problems in netfilter headers
    # This code is duplicated in the `LinuxKernelHeaders` recipe,
    # since this JLL contains them too.
    GCC_TARGET=$(basename $(compgen -G ${host_bindir}/*-gcc))
    GCC_TARGET=${GCC_TARGET%*-gcc}
    if [[ "${target}" == *linux* ]]; then
        NF="${host_prefix}/${GCC_TARGET}/sysroot/usr/include/linux/netfilter"
        for NAME in CONNMARK DSCP MARK RATEEST TCPMSS; do
            mv "${NF}/xt_${NAME}.h" "${NF}/xt_${NAME}_.h"
        done
        for NAME in ECN TTL; do
            mv "${NF}_ipv4/ipt_${NAME}.h" "${NF}_ipv4/ipt_${NAME}_.h"
        done
        mv "${NF}_ipv6/ip6t_HL.h" "${NF}_ipv6/ip6t_HL_.h"
    fi

    # Parent all the installed licenses under `GCCBootstrap`
    mkdir -p ${prefix}/share/GCCBootstrap_licenses
    mv ${prefix}/share/licenses/* ${prefix}/share/GCCBootstrap_licenses/
    mv ${prefix}/share/GCCBootstrap_licenses ${prefix}/share/licenses/GCCBootstrap
    """,
    platforms,
    products,
    host,
    # No target toolchains, only the host one, and for that one, only tools like `make`.
    host_toolchains = [HostToolsToolchain()],
    target_toolchains = [],
)
