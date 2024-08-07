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
    CONFIGURE_FLAGS=()
    MAKE_FLAGS=()
    if [[ ${target} == *mingw* ]]; then
        CONFIGURE_FLAGS+=( --sharedlibdir=${bindir} )
        MAKE_FLAGS+=( SHAREDLIB=libz.dll SHAREDLIBM=libz-1.dll SHAREDLIBV=libz-1.2.11.dll LDSHAREDLIBC= )
    fi
    
    ./configure --prefix=${prefix} "${CONFIGURE_FLAGS[@]}"
    make install -j${nproc} "${MAKE_FLAGS[@]}"
    """,
    products = [
        LibraryProduct("libz", :libz),
    ],
    host_toolchains = [CToolchain(;vendor=:bootstrap), HostToolsToolchain()],
    target_toolchains = [CToolchain(;vendor=:bootstrap)],
    platforms = [
        Platform("x86_64", "linux"),
        Platform("i686", "linux"),
        Platform("aarch64", "linux"),
        Platform("armv6l", "linux"),
        Platform("armv7l", "linux"),
        Platform("powerpc64le", "linux"),

        Platform("x86_64", "linux"; libc="musl"),
        Platform("i686", "linux"; libc="musl"),
        Platform("aarch64", "linux"; libc="musl"),
        Platform("armv6l", "linux"; libc="musl"),
        Platform("armv7l", "linux"; libc="musl"),

        Platform("x86_64", "windows"),
        Platform("i686", "windows"),
    ],
)
