using BinaryBuilder2, Pkg

host_linux = Platform(arch(HostPlatform()), "linux")
build_tarballs(;
    src_name = "Readline",
    src_version = v"8.3",
    sources = [
        ArchiveSource("https://ftp.wayne.edu/gnu/readline/readline-8.3.tar.gz",
                      "fe5383204467828cd495ee8d1d3c037a7eba1389c22bc6a041f627976f9061cc"),
    ],
    target_dependencies = [
        JLLSource(
            "Ncurses_jll",
            repo=Pkg.Types.GitRepo(
                rev="bb2/GCCBootstrap",
                source="https://github.com/staticfloat/Ncurses_jll.jl",
            ),
        ),
    ],
    script = raw"""
    cd $WORKSPACE/srcdir/readline-*/
    export CPPFLAGS="-I${includedir}"
    ./configure --prefix=${prefix} --build=${MACHTYPE} --host=${target} --with-curses

    # Must include `SHLIBS_LIBS` override here because for SOME REASON readline
    # doesn't properly `-lncurses` when building its shared libraries?!
    make -j${nproc} SHLIB_LIBS="-lncurses"
    make install
    """,
    products = [
        LibraryProduct(["libhistory", "libhistory8"], :libhistory),
        LibraryProduct(["libreadline", "libreadline8"], :libreadline),
    ],
    platforms = supported_platforms(),
)
