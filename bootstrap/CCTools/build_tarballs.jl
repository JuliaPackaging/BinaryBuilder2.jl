using BinaryBuilder2, Pkg

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

build_tarballs(;
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
    target_dependencies = [
        JLLSource(
            "Zlib_jll";
            repo=Pkg.Types.GitRepo(
                rev="bb2/GCC",
                source="https://github.com/staticfloat/Zlib_jll.jl"
            ),
        ),
    ],
    meta,
    # Don't package this JLL, we're just using this to get the `tblgen_source` below.
    package_jll = false,
)
tblgen_source = ExtractResultSource(BinaryBuilder2.get_extract_result(meta, "tblgen"))

build_tarballs(;
    src_name = "libtapi",
    src_version = v"1300.6.5",
    sources = [
        GitSource("https://github.com/tpoechtrager/apple-libtapi",
                  "b8c5ac40267aa5f6004dd38cc2b2cd84f2d9d555"),
    ],
    script = raw"""
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
    host_dependencies = [JLLSource("Python_jll"), tblgen_source],
    target_dependencies = [
        JLLSource(
            "Zlib_jll";
            repo=Pkg.Types.GitRepo(
                rev="bb2/GCC",
                source="https://github.com/staticfloat/Zlib_jll.jl"
            ),
        ),
    ],
    meta,
)

using BinaryBuilder2: BuildTargetSpec
function cctools_build_spec_generator(host, platform)
    return [
        BuildTargetSpec(
            "build",
            CrossPlatform(host => host),
            [CToolchain(;vendor=:clang_bootstrap), CMakeToolchain(), HostToolsToolchain()],
            [], #[JLLSource("Python_jll")],
            Set([:host]),
        ),
        BuildTargetSpec(
            "host",
            CrossPlatform(host => platform.host),
            [CToolchain(;vendor=:clang_bootstrap), CMakeToolchain()],
            [
                JLLSource("libtapi_jll"),
                JLLSource(
                    "Zlib_jll";
                    # TODO: Drop this once `Zlib_jll` on `General` is built by BB2.
                    repo=Pkg.Types.GitRepo(
                        rev="bb2/GCC",
                        source="https://github.com/staticfloat/Zlib_jll.jl"
                    ),
                ),
            ],
            Set([:default]),
        ),
        BuildTargetSpec(
            "target",
            CrossPlatform(host => platform.target),
            [],
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
        DirectorySource("./patches"; target="patches"),
    ],
    script = raw"""
    cd ${WORKSPACE}/srcdir/cctools-port/cctools

    for patch in ${WORKSPACE}/srcdir/patches/*.patch; do
        atomic_patch -p2 ${patch}
    done

    install_license ./APPLE_LICENSE
    install_license ./COPYING
    
    # Disable uname wrapper, because it makes LLVM build confused
    rm -f $(which uname)

    ./configure --prefix=${prefix} \
                --build=${build} \
                --host=${host} \
                --target=${target} \
                --with-libtapi=${host_prefix} \
                --disable-lto-support
    make -j${nproc}
    make -j${nproc} install

    # Install license
    """,
    platforms = target_platforms,
    products = [
        ExecutableProduct(raw"${target}-ld", :ld),
        ExecutableProduct(raw"${target}-lipo", :lipo),
        ExecutableProduct(raw"${target}-install_name_tool", :install_name_tool),
    ],
    build_spec_generator = cctools_build_spec_generator,
    meta,
)
