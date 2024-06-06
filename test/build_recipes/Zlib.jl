function zlib_build_tarballs(meta, platforms)
    return build_tarballs(
        "Zlib",
        v"1.3.1",
        [
            # use Git source because zlib has a track record of deleting release tarballs of old versions
            GitSource("https://github.com/madler/zlib.git",
                      "51b7f2abdade71cd9bb0e7a373ef2610ec6f9daf"),
        ],
        [],
        [],
        raw"""
        cd $WORKSPACE/srcdir/zlib*
        ./configure --prefix=${prefix}
        make install -j${nproc}
        """,
        platforms,
        [
            LibraryProduct("libz", :libz),
        ];
        meta,
    )
end
