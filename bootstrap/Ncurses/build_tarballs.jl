using BinaryBuilder2

host_linux = Platform(arch(HostPlatform()), "linux")
build_tarballs(;
    src_name = "Ncurses",
    src_version = v"6.4",
    sources = [
        ArchiveSource("https://ftp.gnu.org/pub/gnu/ncurses/ncurses-6.4.tar.gz",
                      "6931283d9ac87c5073f30b6290c4c75f21632bb4fc3603ac8100812bed248159"),
    ],
    script = raw"""
    cd $WORKSPACE/srcdir/ncurses-*/

    ./configure --prefix=${prefix} --build=${MACHTYPE} --host=${target} \
        --with-shared \
        --disable-static \
        --without-manpages \
        --with-normal \
        --without-debug \
        --without-ada \
        --without-cxx-binding \
        --enable-widec \
        --disable-rpath \
        --enable-colorfgbg \
        --enable-ext-colors \
        --enable-ext-mouse \
        --enable-warnings \
        --enable-assertions \
        --enable-database \
        --without-tests
    make -j${nproc}
    make install

    # Remove duplicates that don't work on case-insensitive filesystems
    rm -rf ${prefix}/share/terminfo

    # Install pc files and fool packages looking for non-wide-character ncurses
    for lib in ncurses form panel menu; do
        ln -vs "lib${lib}w.${dlext}" "${libdir}/lib${lib}.${dlext}"
    done
    """,
    products = [
        LibraryProduct(["libform", "libform6"], :libform),
        LibraryProduct(["libmenu", "libmenu6"], :libmenu),
        LibraryProduct(["libncurses", "libncurses6"], :libncurses),
        LibraryProduct(["libpanel", "libpanel6"], :libpanel),
    ],
    # We're only building for the host, since this is a bootstrap
    platforms = [host_linux],
)
