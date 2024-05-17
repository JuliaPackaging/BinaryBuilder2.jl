function readline_build_tarballs(meta, platforms; fail_build::Bool = false, fail_extract::Bool = false)
    return build_tarballs(
        "Readline",
        v"8.1",
        [
            ArchiveSource("https://ftp.gnu.org/gnu/readline/readline-8.1.tar.gz",
                          "f8ceb4ee131e3232226a17f51b164afc46cd0b9e6cef344be87c65962cb82b02"),
            FileSource("https://ftp.gnu.org/gnu/readline/readline-8.1-patches/readline81-001",
                       "682a465a68633650565c43d59f0b8cdf149c13a874682d3c20cb4af6709b9144"),
        ],
        # No target or host dependencies
        AbstractSource[],
        AbstractSource[],
        fail_build ? "false" : raw"""
        cd $WORKSPACE/srcdir/readline-*/

        export CPPFLAGS="-I${includedir}"
        ./configure --prefix=${prefix} --build=${MACHTYPE} --host=${target} --with-curses
        make -j${nproc}
        make install
        """,
        platforms,
        [
            LibraryProduct(["libhistory", "libhistory8"], :libhistory),
            LibraryProduct(["libreadline", "libreadline8"], :libreadline),
        ];
        extract_script = fail_extract ? "false" : "extract \${prefix}/*",
        meta,
    )
end
