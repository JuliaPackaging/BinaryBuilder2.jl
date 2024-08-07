using BinaryBuilder2

meta = BinaryBuilder2.get_default_meta()
src_name = "LinuxKernelHeaders"
src_version = v"6.9.5"
linarch(arch) = Platform(arch, "linux")
platforms = [
    Platform("x86_64", "linux"),
    Platform("i686", "linux"),
    Platform("armv7l", "linux"),
    Platform("armv6l", "linux"),
    Platform("aarch64", "linux"),
    Platform("powerpc64le", "linux"),

    Platform("x86_64", "linux"; libc="musl"),
    Platform("i686", "linux"; libc="musl"),
    Platform("armv7l", "linux"; libc="musl"),
    Platform("armv6l", "linux"; libc="musl"),
    Platform("aarch64", "linux"; libc="musl"),
]

# Build the tarballs, and possibly a `build.jl` as well.
build_tarballs(;
    src_name = "LinuxKernelHeaders",
    src_version = v"6.9.5",
    sources = [
        ArchiveSource("https://mirrors.edge.kernel.org/pub/linux/kernel/v$(src_version.major).x/linux-$(src_version).tar.xz",
                      "a51fb4ab5003a6149bd9bf4c18c9b1f0f4945c272549095ab154b9d1052f95b1"),
    ],
    script = raw"""
    ## Function to take in a target such as `aarch64-linux-gnu`` and spit out a
    ## linux kernel arch like "arm64".
    target_to_linux_arch()
    {
        case "$1" in
            arm*)
                echo "arm"
                ;;
            aarch64*)
                echo "arm64"
                ;;
            powerpc*)
                echo "powerpc"
                ;;
            i686*)
                echo "x86"
                ;;
            x86*)
                echo "x86"
                ;;
        esac
    }

    # Install kernel headers
    cd $WORKSPACE/srcdir/linux-*/

    # The kernel make system can't deal with spaces (for things like ccache) very well
    KERNEL_FLAGS=( "ARCH=$(target_to_linux_arch ${target})" "HOSTCC=${HOSTCC}" "-j${nproc}" )
    make ${KERNEL_FLAGS[@]} mrproper V=1
    make ${KERNEL_FLAGS[@]} INSTALL_HDR_PATH=${prefix} V=1 headers_install

    # Move case-sensitivity issues, breaking netfilter without a patch
    NF="${prefix}/include/linux/netfilter"
    for NAME in CONNMARK DSCP MARK RATEEST TCPMSS; do
        mv "${NF}/xt_${NAME}.h" "${NF}/xt_${NAME}_.h"
    done    

    for NAME in ECN TTL; do
        mv "${NF}_ipv4/ipt_${NAME}.h" "${NF}_ipv4/ipt_${NAME}_.h"
    done
    mv "${NF}_ipv6/ip6t_HL.h" "${NF}_ipv6/ip6t_HL_.h"
    """,
    platforms,
    # Note that while we place the products directly into `${prefix}`, when using these
    # headers with Glibc_jll, GCC_jll, etc... you will most likely want to mount these
    # headers at `${compiler_prefix}/${encoded_target}`.
    products = [
        FileProduct("\${includedir}/linux/limits.h", :limits_h),
    ],
    host_toolchains = [CToolchain(;vendor=:bootstrap), HostToolsToolchain()],
    target_toolchains = [CToolchain(;vendor=:bootstrap)],
    meta,
)
