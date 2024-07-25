using BinaryBuilder2

host = Platform(arch(HostPlatform()), "linux")
musl_version_sources = Dict{VersionNumber,Vector}(
    v"1.1.24" => [
        ArchiveSource("https://musl.libc.org/releases/musl-1.1.24.tar.gz",
                      "1370c9a812b2cf2a7d92802510cca0058cc37e66a7bedd70051f0a34015022a3"),
    ],
    v"1.2.5" => [
        ArchiveSource("https://musl.libc.org/releases/musl-1.2.5.tar.gz",
                      "a9a118bbe84d8764da0ea0d28b3ab3fae8477fc7e4085d90102b8596fc7c75e4"),
    ],
)

name = "Musl"
version = v"1.1.24"

# Bash recipe for building across all platforms
script = raw"""
mkdir ${WORKSPACE}/srcdir/musl_build
cd ${WORKSPACE}/srcdir/musl_build
musl_arch()
{
    case "${target}" in
        i686*)
            echo i386 ;;
        arm*)
            echo armhf ;;
        *)
            echo ${target%%-*} ;;
    esac
}

# Force an SONAME with a version number
export LDFLAGS="-Wl,-soname,libc.musl-$(musl_arch).so.1"
${WORKSPACE}/srcdir/musl-*/configure --prefix=/usr \
    --build=${MACHTYPE} \
    --host=${target} \
    --disable-multilib \
    --disable-werror \
    --enable-optimize \
    --enable-debug \
    --disable-gcc-wrapper

make -j${nproc}
make install DESTDIR="${prefix}"

# Fix wrong symlink in `lib`
ln -sfv ../usr/lib/libc.so ${prefix}/lib/ld-musl-$(musl_arch).so.1
ln -sfv libc.so ${prefix}/usr/lib/libc.musl-$(musl_arch).so.1
"""

# For each version, build it!
meta = BinaryBuilder2.get_default_meta()
for version in keys(musl_version_sources)
    build_tarballs(;
        src_name = "Musl",
        src_version = version,
        sources = musl_version_sources[version],
        script,
        platforms = filter(p -> libc(p) == "musl", supported_platforms()),
        products = [
            LibraryProduct(["usr/lib/libc"], :libc),
        ],
        host_toolchains = [CToolchain(;vendor=:bootstrap), HostToolsToolchain()],
        target_toolchains = [CToolchain(;vendor=:bootstrap)],
        meta,
    )
end
