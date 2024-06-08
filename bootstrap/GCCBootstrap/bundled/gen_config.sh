#!/bin/bash

set -euo pipefail

# Start with things that are always true
cat <<-EOF
CT_CONFIG_VERSION=4

# Always build GCC v9.X
CT_GCC_V_9=y

# Disable progress bar, it fills up our logs:
CT_LOG_PROGRESS_BAR=n

# If something goes wrong, this can be helpful to watch it all scroll by
#CT_LOG_LEVEL_MAX="ALL"
#CT_LOG_ALL=y

# We use some experimental features, just enable them for all
CT_EXPERIMENTAL=y

# Explicitly claim the '--build' triplet, so there's no confusion
CT_BUILD="${MACHTYPE}"

# Tell ct-ng to not remove our prefix... this really confused me, as the
# build would finish, but the resultant artifact was empty, because it
# would have cleared out the symlink to the target-specific prefix. Orz.
CT_PREFIX_DIR="${prefix}"
CT_PREFIX_DIR_RO=n
CT_RM_RF_PREFIX_DIR=n

# Don't download any tarballs; we should have taken care of that already
CT_FORBID_DOWNLOAD=y
CT_LOCAL_TARBALLS_DIR="${WORKSPACE}/srcdir"

# We always want to build g++
CT_CC_LANG_CXX=y
EOF

# Handle OS stuff
case "${target}" in
    *linux*)
        cat <<-EOF
# We're building against linux, and always use an older kernel
# version so that we are maximally compatible.
CT_KERNEL_LINUX=y
CT_LINUX_V_4_1=y

# We don't like the 'unknown' for Linux
CT_OMIT_TARGET_VENDOR=y
CT_TARGET_VENDOR=
EOF
        ;;
    *mingw*)
        cat <<-EOF
CT_TARGET_VENDOR="w64"
CT_KERNEL_WINDOWS=y
EOF
        ;;
    *)
        echo "Unhandled OS '${target}'" >&2
        exit 1
        ;;
esac

# Handle arch stuff
case "${target}" in
    arm*)
        echo "CT_ARCH_ARM=y"
        echo "CT_ARCH_FLOAT_HW=y"
        if [[ "${bb_full_target}" == armv6l* ]]; then
            echo "CT_ARCH_ARCH=\"armv6+fp\""
        elif [[ "${bb_full_target}" == armv7l* ]]; then
            echo "CT_ARCH_ARCH=\"armv7-a+fp\""
        else
            echo "ERROR: Unknown arm microarchitecture in ${bb_full_target}!" >&2
            exit 1
        fi
        ;;
    aarch64*)
        echo "CT_ARCH_ARM=y"
        echo "CT_ARCH_64=y"
        ;;
    i686*)
        echo "CT_ARCH_X86=y"
        echo "CT_ARCH_ARCH=\"pentium4\""
        ;;
    x86_64*)
        echo "CT_ARCH_X86=y"
        echo "CT_ARCH_64=y"
        echo "CT_ARCH_ARCH=\"x86-64\""
        ;;
    powerpc64le*)
        echo "CT_ARCH_POWERPC=y"
        echo "CT_ARCH_LE=y"
        echo "CT_ARCH_64=y"
        ;;
    riscv64*)
        echo "CT_ARCH_RISCV=y"
        echo "CT_ARCH_64=y"
        echo "CT_ARCH_USE_MMU=y"
        echo "CT_ARCH_ARCH=\"rv64imafdc\""
        echo "CT_ARCH_ABI=\"lp64d\""
        echo "CT_ARCH_TUNE=\"sifive-7-series\""
        ;;
    *)
        echo "ERROR: Unhandled arch '${target}'" >&2
        exit 1
esac

# Handle libc stuff
case "${target}" in
    *gnu*)
        if [[ "${target}" == x86_64* ]] || [[ "${target}" == i686* ]] || [[ "${target}" == powerpc64le* ]]; then
            echo "CT_GLIBC_V_2_17=y"
        else
            echo "CT_GLIBC_V_2_19=y"
        fi
        ;;
    *musl*)
        echo "CT_LIBC_MUSL=y"
        echo "CT_MUSL_v_1_2_2=y"
        ;;
    *mingw*)
        echo "CT_LIBC_MINGW_W64=y"
        echo "CT_THREADS_POSIX=y"
        echo "CT_MINGW_W64_V_V9_0=y"
        ;;
    *)
        echo "ERROR: Unhandled libc '${target}'" >&2
        exit 1
        ;;
esac
