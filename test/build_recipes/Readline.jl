function readline_build_tarballs(meta, platforms; fail_build::Bool = false, fail_extract::Bool = false, kwargs...)
    return build_tarballs(
        "Readline",
        v"8.2",
        [
            ArchiveSource("https://ftp.gnu.org/gnu/readline/readline-8.2.tar.gz",
                          "3feb7171f16a84ee82ca18a36d7b9be109a52c04f492a053331d7d1095007c35"),
            FileSource("https://ftp.gnu.org/gnu/readline/readline-8.2-patches/readline82-001",
                       "bbf97f1ec40a929edab5aa81998c1e2ef435436c597754916e6a5868f273aff7"),
        ],
        [JLLSource("Ncurses_jll")],
        [],
        fail_build ? "false" : raw"""
        cd $WORKSPACE/srcdir/readline-*/

        atomic_patch -p0 ${WORKSPACE}/srcdir/readline82-001
        export CPPFLAGS="-I${includedir}"
        ./configure --prefix=${prefix} --build=${MACHTYPE} --host=${target} --with-curses

        # Must include `SHLIBS_LIBS` override here because for SOME REASON readline
        # doesn't properly `-lncurses` when building its shared libraries?!
        make -j${nproc} SHLIB_LIBS="-lncurses"
        make install
        """,
        platforms,
        [
            LibraryProduct(["libhistory", "libhistory8"], :libhistory),
            LibraryProduct(["libreadline", "libreadline8"], :libreadline),
        ];
        extract_script = fail_extract ? "false" : "extract \${prefix}/*",
        meta,
        kwargs...,
    )
end
