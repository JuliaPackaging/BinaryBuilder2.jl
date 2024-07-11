using BinaryBuilder2

# We will build for Linux for the current host
host_linux = Platform(arch(HostPlatform()), "linux")

build_tarballs(;
    src_name = "CrosstoolNG",
    src_version = v"1.25.0",
    sources = [
        ArchiveSource("http://crosstool-ng.org/download/crosstool-ng/crosstool-ng-1.25.0.tar.xz",
                        "68162f342243cd4189ed7c1f4e3bb1302caa3f2cbbf8331879bd01fe06c60cd3"),
        DirectorySource(joinpath(@__DIR__, "./bundled")),
    ],
    target_dependencies = [
        JLLSource("Ncurses_jll"),
        JLLSource("Zlib_jll"),
    ],
    script = raw"""
    cd ${WORKSPACE}/srcdir/crosstool-ng*/

    # Eventually, it'd be nice to provide these via JLLs.
    apt update
    apt install -y texinfo help2man

    # Copy in our extra patches for all packages
    for package in ${WORKSPACE}/srcdir/patches/*; do
        package="$(basename "${package}")"
        for version in ${WORKSPACE}/srcdir/patches/${package}/*; do
            version="$(basename "${version}")"
            if [ ! -d packages/${package}/${version} ]; then
                continue
            fi
            cp -v ${WORKSPACE}/srcdir/patches/${package}/${version}/* packages/${package}/${version}/
        done
    done

    # Build crosstool-ng
    # The extra CFLAGS here are because the `kconfig/` directory of `crosstool-ng` doesn't
    # pay attention to the actual location of `ncurses`, it just directly looks for `panel.h`
    CFLAGS="-I${includedir}/ncursesw" ./configure --prefix=${prefix}
    make -j${nproc} V=1
    make -j${nproc} install

    # Create wrapper script for `ct-ng` that automatically sets environment variables
    # to make it relocatable, otherwise it uses baked-in absolute paths. :(
    mv ${bindir}/ct-ng ${bindir}/ct-ng-real
    cat >${bindir}/ct-ng <<-'EOF'
    #!/bin/bash

    SCRIPT_DIR=$( cd -- "$( dirname -- "${BASH_SOURCE[0]}" )" &> /dev/null && pwd )
    MAKE_ARGS=(
        CT_LIB_DIR="$(dirname ${SCRIPT_DIR})/share/crosstool-ng"
        CT_LIBEXEC_DIR="$(dirname ${SCRIPT_DIR})/libexec/crosstool-ng"
        CT_DOC_DIR="$(dirname ${SCRIPT_DIR})/share/doc/crosstool-ng"
    )
    make -rf "${SCRIPT_DIR}/ct-ng-real" "$@" "${MAKE_ARGS[@]}"
    EOF
    chmod +x ${bindir}/ct-ng
    """,
    platforms = [host_linux],
    products = [
        ExecutableProduct("ct-ng", :ct_ng),
    ],
)
