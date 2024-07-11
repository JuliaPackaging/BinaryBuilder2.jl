using BinaryBuilder2

host = Platform(arch(HostPlatform()), "linux")
glibc_version_sources = Dict{VersionNumber,Vector}(
    #=
    v"2.12.2" => [
        ArchiveSource("https://mirrors.kernel.org/gnu/glibc/glibc-2.12.2.tar.xz",
                        "0eb4fdf7301a59d3822194f20a2782858955291dd93be264b8b8d4d56f87203f"),
    ],
    =#
    v"2.17" => [
        ArchiveSource("https://mirrors.kernel.org/gnu/glibc/glibc-2.17.tar.xz",
                        "6914e337401e0e0ade23694e1b2c52a5f09e4eda3270c67e7c3ba93a89b5b23e"),
    ],
    v"2.19" => [
        ArchiveSource("https://mirrors.kernel.org/gnu/glibc/glibc-2.19.tar.xz",
                        "2d3997f588401ea095a0b27227b1d50cdfdd416236f6567b564549d3b46ea2a2"),
    ],
)

linarch(arch) = Platform(arch, "linux")
glibc_version_platforms = Dict{VersionNumber,Vector}(
    v"2.12.2" => linarch.(["x86_64", "i686"]),
    v"2.17" => linarch.(["x86_64", "i686", "powerpc64le"]),
    v"2.19" => linarch.(["x86_64", "i686", "armv7l", "armv6l", "aarch64", "powerpc64le"]),
)

script = raw"""
cd ${WORKSPACE}/srcdir/glibc-*/

# Some things need /lib64, others just need /lib
case ${target} in
    x86_64*)
        lib64=lib64
        ;;
    aarch64*)
        lib64=lib64
        ;;
    ppc64*)
        lib64=lib64
        ;;
    *)
        lib64=lib
        ;;
esac

# Update configure scripts to work well with `musl`
update_configure_scripts

for p in ${WORKSPACE}/srcdir/patches/glibc-*.patch; do
    atomic_patch -p1 ${p}
done

# Various configure overrides
GLIBC_CONFIGURE_OVERRIDES=( libc_cv_forced_unwind=yes libc_cv_c_cleanup=yes BUILD_CC=${HOSTCC} )

# We have problems with libssp on ppc64le
if [[ ${target} == powerpc64le-* ]]; then
    GLIBC_CONFIGURE_OVERRIDES+=( libc_cv_ssp=no libc_cv_ssp_strong=no )
fi

# Always use `/lib`, no more `/lib64`
GLIBC_CONFIGURE_OVERRIDES+=( libc_cv_slibdir=/lib libdir="/lib" )

rm -rf ${WORKSPACE}/srcdir/glibc_build
mkdir -p ${WORKSPACE}/srcdir/glibc_build
cd ${WORKSPACE}/srcdir/glibc_build
${WORKSPACE}/srcdir/glibc-*/configure \
    --prefix=/usr \
    --build=${MACHTYPE} \
    --host=${target} \
    --disable-multilib \
    --disable-werror \
    ${GLIBC_CONFIGURE_OVERRIDES[@]}

make -j${nproc}
make install install_root="${prefix}"

# Copy our `crt*.o` files over (useful for bootstrapping GCC)
csu_libdir="${prefix}/lib"
cp csu/crt1.o csu/crti.o csu/crtn.o ${csu_libdir}/

# fix bad linker scripts
sed -i -e "s& /lib/& ./&g" "${csu_libdir}/libc.so"
sed -i -e "s& /lib/& ./&g" "${csu_libdir}/libpthread.so"

# Many Glibc versions place binaries in strange locations, this seems to be a build system bug
if [[ -d ${prefix}/${prefix} ]]; then
    mv -v ${prefix}/${prefix}/* ${prefix}/
    # Remove the empty directories
    rm -rf ${prefix}/workspace
fi
"""

# For each version
meta = BinaryBuilder2.get_default_meta()
for version in keys(glibc_version_sources)
    build_tarballs(;
        src_name = "Glibc",
        src_version = version,
        sources = [
            glibc_version_sources[version]...,
            # We've got a bevvy of patches for Glibc, include them in.
            DirectorySource("./patches-v$(version)"; follow_symlinks=true, target="patches"),
        ],
        script,
        platforms = glibc_version_platforms[version],
        products = [
            # We use the versioned filenames here, because the `.so` files are linker scripts
            # and ObjectFile can't handle those, sadly.
            LibraryProduct("lib/libc-$(version.major).$(version.minor)", :libc),
            LibraryProduct("lib/libdl-$(version.major).$(version.minor)", :libld),
            LibraryProduct("lib/libm-$(version.major).$(version.minor)", :libm),
            LibraryProduct("lib/libpthread-$(version.major).$(version.minor)", :libpthread),
            LibraryProduct("lib/librt-$(version.major).$(version.minor)", :librt),
        ],
        host_toolchains = [CToolchain(;vendor=:bootstrap), HostToolsToolchain()],
        target_toolchains = [CToolchain(;vendor=:bootstrap)],
        meta,
    )
end
