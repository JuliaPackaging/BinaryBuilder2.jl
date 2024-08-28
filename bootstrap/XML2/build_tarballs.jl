using BinaryBuilder2

host_linux = Platform(arch(HostPlatform()), "linux")
build_tarballs(;
    src_name = "XML2",
    src_version = v"2.13.1",
    sources = [
        ArchiveSource("https://download.gnome.org/sources/libxml2/2.13/libxml2-2.13.1.tar.xz",
                      "25239263dc37f5f55a5393eff27b35f0b7d9ea4b2a7653310598ea8299e3b741"),
    ],
    script = raw"""
    cd ${WORKSPACE}/srcdir/libxml2-*

    apt update
    apt install -y vim

    ./configure --prefix=${prefix} --build=${MACHTYPE} --host=${target} \
        --without-python \
        --disable-static
    make -j${nproc}
    make install

    # Remove heavy doc directories
    rm -r ${prefix}/share/{doc/libxml2,man}
    """,
    products = [
        LibraryProduct("libxml2", :libxml2),
    ],
    # We only need this for our host platforms
    platforms = [
        Platform("x86_64", "linux"),
        Platform("aarch64", "linux"),
    ],
)
