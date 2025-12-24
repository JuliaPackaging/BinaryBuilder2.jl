using BinaryBuilder2

meta = BinaryBuilder2.get_default_meta()
platforms = [
    Platform("x86_64", "freebsd"; os_version="14.1"),
    Platform("aarch64", "freebsd"; os_version="14.1"),
]

# Build the tarballs, and possibly a `build.jl` as well.
build_tarballs(;
    src_name = "FreeBSDSysroot",
    src_version = v"14.1",
    sources = [
        # We can't use `ArchiveSource` here, because it trips Tar.jl's attack detection: ("Tarball contains hardlink with non-existent target")
        FileSource("http://ftp-archive.freebsd.org/pub/FreeBSD-Archive/old-releases/arm64/14.1-RELEASE/base.txz",
                      "sha256:b25830252e0dce0161004a5b69a159cbbd92d5e92ae362b06158dbb3f2568d32";
                      target="freebsd-aarch64.tar.xz"),
        FileSource("http://ftp-archive.freebsd.org/pub/FreeBSD-Archive/old-releases/amd64/14.1-RELEASE/base.txz",
                      "sha256:bb451694e8435e646b5ff7ddc5e94d5c6c9649f125837a34b2a2dd419732f347";
                      target="freebsd-x86_64.tar.xz"),
    ],
    script = raw"""
    TARBALL_NAME="freebsd-$(echo "${target}" | cut -d- -f1).tar.xz"

    FILES_TO_EXTRACT=(
        # Extract headers
        ./usr/include

        # Extract crt*.o
        ./usr/lib/Scrt1.o
        ./usr/lib/crti.o
        ./usr/lib/crtbeginS.o
        ./usr/lib/crtendS.o
        ./usr/lib/crtn.o
        ./usr/lib/crtbegin.o
        ./usr/lib/crtend.o
        ./usr/lib/crtbeginT.o
        ./usr/lib/gcrt1.o
        ./usr/lib/crt1.o

        # Compiler runtimes
        # ./usr/lib/libcompiler_rt.a
        # ./usr/lib/libgcc.a
        # ./usr/lib/libgcc_s.so
        # ./usr/lib/libgcc_eh.a
        # ./lib/libgcc_s.so.1
        # ./usr/lib/libc++.so
        # ./usr/lib/libc++.a
        # ./usr/lib/libc++experimental.a
        # ./lib/libc++.so.1
        # ./usr/lib/libcxxrt.a
        # ./usr/lib/libcxxrt.so
        # ./lib/libcxxrt.so.1

        # We're only going to extract certain libraries that are required to bootstrap GCC/Clang:
        # libc
        ./lib/libc.so.7
        ./usr/lib/libc.so
        ./usr/lib/libc_nonshared.a

        # libdl
        ./usr/lib/libdl.so.1
        ./usr/lib/libdl.so

        # libm
        ./lib/libm.so.5
        ./usr/lib/libm.so
        
        # libthr
        ./lib/libthr.so.3
        ./usr/lib/libthr.so

        # libpthread
        ./usr/lib/libpthread.so
        ./usr/lib/libpthread.a
    )

    tar -C ${prefix} -xJf "${TARBALL_NAME}" "${FILES_TO_EXTRACT[@]}"

    # Clean up headers that we're going to deploy from JLLs we build
    # libc++
    rm -rf ${prefix}/usr/include/c++

    # libunwind
    rm -rf ${prefix}/usr/include/__libunwind_config.h
    rm -rf ${prefix}/usr/include/unwind_arm_ehabi.h
    rm -rf ${prefix}/usr/include/libunwind.h

    # zlib
    rm -rf ${prefix}/usr/include/zconf.h
    rm -rf ${prefix}/usr/include/zlib.h

    # Extract license
    tar -xJf "${TARBALL_NAME}" ./COPYRIGHT
    install_license COPYRIGHT
    """,
    platforms,
    products = [
        FileProduct("usr/include/unistd.h", :unistd_h),
    ],
    host_toolchains = [HostToolsToolchain()],
    target_toolchains = [],
    meta,
)
