using BinaryBuilder2

meta = BinaryBuilder2.get_default_meta()
host_platforms = [
    Platform("x86_64", "linux"),
    Platform("aarch64", "linux"),
]
mac_platforms = [
    Platform("x86_64", "macos"),
    Platform("aarch64", "macos"),
]
target_platforms = [CrossPlatform(host => target) for host in host_platforms, target in mac_platforms][:]

tblgen_package = build_tarballs(;
    src_name = "tblgen",
    src_version = v"1300.6.5",
    sources = [
        GitSource("https://github.com/tpoechtrager/apple-libtapi",
                  "b8c5ac40267aa5f6004dd38cc2b2cd84f2d9d555"),
    ],
    script = raw"""
    TAPIDIR="${WORKSPACE}/srcdir/apple-libtapi"
    install_license ${TAPIDIR}/LICENSE.*
    mkcd ${TAPIDIR}/build
    ${HOST_CMAKE} ${TAPIDIR}/src/llvm \
        -G "Ninja" \
        -DLLVM_TARGETS_TO_BUILD:STRING=host \
        -DCMAKE_BUILD_TYPE=RELEASE \
        -DLLVM_ENABLE_PROJECTS="clang;llvm" \
        -DCMAKE_CROSSCOMPILING=False \
        -DLLVM_INCLUDE_TESTS=OFF \
        -DLLVM_INCLUDE_BENCHMARKS=OFF \
        -DCMAKE_INSTALL_PREFIX=${prefix}
    ninja llvm-tblgen clang-tblgen
    mkdir -p ${bindir}
    cp bin/*-tblgen ${bindir}/
    """,
    platforms = [BinaryBuilder2.default_host()],
    products = [
        ExecutableProduct("llvm-tblgen", :llvm_tblgen),
        ExecutableProduct("clang-tblgen", :clang_tblgen),
        #ExecutableProduct("llvm-config", :llvm_config),
    ],
    host_dependencies = [JLLSource("Python_jll")],
    target_dependencies = [JLLSource("Zlib_jll")],
    meta,
    # Don't package this JLL, we're just using this to get the `tblgen_source` below.
    package_jll = false,
)
tblgen_source = ExtractResultSource(only(tblgen_package.config.named_extractions["tblgen"]))

build_tarballs(;
    src_name = "libtapi",
    src_version = v"1300.6.5",
    sources = [
        GitSource("https://github.com/tpoechtrager/apple-libtapi",
                  "b8c5ac40267aa5f6004dd38cc2b2cd84f2d9d555"),
    ],
    script = raw"""
    apt update && apt install -y gdb vim
    TAPIDIR="${WORKSPACE}/srcdir/apple-libtapi"
    install_license ${TAPIDIR}/LICENSE.*
    mkcd ${TAPIDIR}/build

    cmake ${TAPIDIR}/src/llvm \
        -G "Ninja" \
        -DCMAKE_CXX_FLAGS="-I${TAPIDIR}/src/llvm/projects/clang/include -I${TAPIDIR}/build/projects/clang/include" \
        -DLLVM_ENABLE_PROJECTS="tapi;clang" \
        -DLLVM_INCLUDE_TESTS=OFF \
        -DLLVM_INCLUDE_BENCHMARKS=OFF \
        -DCMAKE_BUILD_TYPE=RELEASE \
        -DCMAKE_INSTALL_PREFIX=${prefix} \
        -DLLVM_TABLEGEN=${host_prefix}/bin/llvm-tblgen \
        -DCLANG_TABLEGEN=${host_prefix}/bin/clang-tblgen
    
        #-DCROSS_TOOLCHAIN_FLAGS_NATIVE="-DCMAKE_TOOLCHAIN_FILE=${CMAKE_HOST_TOOLCHAIN};-DLLVM_INCLUDE_TESTS=OFF;-DLLVM_INCLUDE_BENCHMARKS=OFF"
    ninja install-libtapi install-tapi-headers
    """,
    platforms = host_platforms,
    products = [
        LibraryProduct("libtapi", :libtapi),
    ],
    host_dependencies = [JLLSource("Python_jll"), JLLSource("Zlib_jll"), tblgen_source],
    target_dependencies = [JLLSource("Zlib_jll")],
    meta,
)

using BinaryBuilder2: BuildTargetSpec
function cctools_spec_generator(host, platform)
    return [
        BuildTargetSpec(
            "build",
            CrossPlatform(host => host),
            [CToolchain(), CMakeToolchain(), HostToolsToolchain()],
            [], #[JLLSource("Python_jll")],
            Set([:host]),
        ),
        BuildTargetSpec(
            "host",
            CrossPlatform(host => platform.host),
            [CToolchain(;vendor=:clang), CMakeToolchain()],
            [JLLSource("libtapi_jll"), JLLSource("Zlib_jll")],
            Set([:default]),
        ),
        BuildTargetSpec(
            "target",
            CrossPlatform(host => platform.target),
            [], #CToolchain(;vendor=:bootstrap)],
            [],
            Set{Symbol}(),
        ),
    ]
end


build_tarballs(;
    src_name = "CCTools",
    src_version = v"986",
    sources = [
        GitSource("https://github.com/tpoechtrager/cctools-port",
                  "2a3e1c2a6ff54a30f898b70cfb9ba1692a55fad7"),
    ],
    script = raw"""
    cd ${WORKSPACE}/srcdir/cctools-port/cctools
    ./configure --prefix=${prefix} --target=${target} \
                         --with-libtapi=${host_prefix}
    make -j${nproc}
    make -j${nproc} install

    # Install license
    install_license ${WORKSPACE}/srcdir/musl-*/COPYRIGHT
    """,
    platforms = target_platforms,
    products = [
        LibraryProduct(["usr/lib/libc"], :libc),
    ],
    spec_generator = cctools_spec_generator,
    meta,
)
