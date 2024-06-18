using BinaryBuilder2

host_linux = Platform(arch(HostPlatform()), "linux")
build_tarballs(;
    src_name = "Zlib",
    src_version = v"1.3.1",
    sources = [
        # use Git source because zlib has a track record of deleting release tarballs of old versions
        GitSource("https://github.com/madler/zlib.git",
                  "51b7f2abdade71cd9bb0e7a373ef2610ec6f9daf"),
    ],
    script = raw"""
    cd $WORKSPACE/srcdir/zlib*
    ./configure --prefix=${prefix}
    make install -j${nproc}
    """,
    products = [
        LibraryProduct("libz", :libz),
    ],
    # We're only building for the host here, as this is part of bootstrap
    platforms = [host_linux],
)
