function ncurses_build_tarballs(meta, platforms)
    return build_tarballs(
        "Ncurses",
        v"6.4",
        [
            ArchiveSource("https://ftp.gnu.org/pub/gnu/ncurses/ncurses-6.4.tar.gz",
                          "6931283d9ac87c5073f30b6290c4c75f21632bb4fc3603ac8100812bed248159"),
        ],
        [JLLSource("Readline_jll")],
        AbstractSource[],
        raw"""
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
        """,
        platforms,
        [
            LibraryProduct(["libform", "libform6"], :libform),
            LibraryProduct(["libmenu", "libmenu6"], :libmenu),
            LibraryProduct(["libncurses", "libncurses6"], :libncurses),
            LibraryProduct(["libpanel", "libpanel6"], :libpanel),
        ];
        meta,
    )
end
