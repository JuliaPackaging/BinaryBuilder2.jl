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
    mkcd build

    $CMAKE -DCMAKE_INSTALL_PREFIX=${prefix} \
        -DCMAKE_BUILD_TYPE=Release \
        -DUNIX=true \
        -DCMAKE_POSITION_INDEPENDENT_CODE=ON \
        ..
    
    make install -j${nproc}
    install_license ../README
    """,
    products = [
        LibraryProduct("libz", :libz),
    ],
    host_toolchains = [CToolchain(;vendor=:gcc_bootstrap), HostToolsToolchain(), CMakeToolchain()],
    target_toolchains = [CToolchain(;vendor=:gcc_bootstrap), CMakeToolchain()],
    platforms = supported_platforms(),
)
