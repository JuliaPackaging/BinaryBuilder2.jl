using BinaryBuilder2

build_tarballs(;
    src_name = "Mingw",
    src_version = v"11.0.1",
    sources = [
        ArchiveSource("https://sourceforge.net/projects/mingw-w64/files/mingw-w64/mingw-w64-release/mingw-w64-v11.0.1.tar.bz2",
                      "3f66bce069ee8bed7439a1a13da7cb91a5e67ea6170f21317ac7f5794625ee10"),
    ],
    script = raw"""
    cd ${WORKSPACE}/srcdir/mingw-*/

    # Install licenses
    install_license ${WORKSPACE}/srcdir/mingw-*/COPYING
    install_license ${WORKSPACE}/srcdir/mingw-*/COPYING.*/*.txt

    # Install headers
    mkdir -p ${WORKSPACE}/srcdir/mingw_headers
    cd ${WORKSPACE}/srcdir/mingw_headers
    ${WORKSPACE}/srcdir/mingw-*/mingw-w64-headers/configure \
        --prefix=${prefix}/usr \
        --enable-sdk=no \
        --build=${MACHTYPE} \
        --host=${target}
    make install

    # Build CRT
    mkdir -p ${WORKSPACE}/srcdir/mingw_crt_build
    cd ${WORKSPACE}/srcdir/mingw_crt_build
    MINGW_CONF_ARGS=()

    # If we're building a 32-bit build of mingw, add `--disable-lib64`
    if [[ "${nbits}" == 32 ]]; then
        MINGW_CONF_ARGS+=( --disable-lib64 )
    else
        MINGW_CONF_ARGS+=( --disable-lib32 )
    fi

    ${WORKSPACE}/srcdir/mingw-*/mingw-w64-crt/configure \
        --prefix=${prefix}/usr \
        --build=${MACHTYPE} \
        --host=${target} \
        "${MINGW_CONF_ARGS[@]}"
    make
    make install


    # Build winpthreads
    mkdir -p ${WORKSPACE}/srcdir/mingw_winpthreads_build
    cd ${WORKSPACE}/srcdir/mingw_winpthreads_build
    ${WORKSPACE}/srcdir/mingw-*/mingw-w64-libraries/winpthreads/configure \
        --prefix=${prefix}/usr \
        --build=${MACHTYPE} \
        --host=${target} \
        --enable-static \
        --enable-shared

    make
    make install
    mv ${prefix}/usr/* ${prefix}/
    rmdir ${prefix}/usr
    """,
    products = [
        FileProduct(["lib/libmsvcrt.a"], :libmsvcrt_a),
    ],
    # We're only building for the host, since this is a bootstrap
    platforms = [
        Platform("x86_64", "windows"),
        Platform("i686", "windows"),
    ],
    host_toolchains = [CToolchain(;vendor=:bootstrap), HostToolsToolchain()],
    target_toolchains = [CToolchain(;vendor=:bootstrap)],
)
