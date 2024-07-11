using BinaryBuilder2

# First, we need all the information we had from the previous example:

meta = BinaryBuilder2.get_default_meta()
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
    extract_scripts = Dict(
        "Zlib" => "extract \${shlibdir}/*",
        "all" => "extract \${prefix}/*",
    ),

    # TODO: remove these lines once the GCC builds are all working
    meta,
    target_toolchains = [CToolchain(;vendor=:bootstrap)],
    host_toolchains = [CToolchain(;vendor=:bootstrap), HostToolsToolchain()],
)
