jll = JLLInfo(;
    name = "SuiteSparse",
    version = v"7.2.0+1",
    artifacts = [
        JLLArtifactInfo(;
            src_version = v"7.2.0+1",
            deps = [
                JLLPackageDependency(
                    "libblastrampoline_jll",
                    Base.UUID("8e850b90-86db-534c-a0d3-1478176c7d93"),
                    "5.4.0",
                ),
            ],
            sources = [],
            platform = Platform("aarch64", "macos"; ),
            name = "SuiteSparse",
            treehash = "8a12b0606590424b57db06f7b111abfb483fc366",
            download_sources = [
                JLLArtifactSource(
                    "https://github.com/JuliaBinaryWrappers/SuiteSparse_jll.jl/releases/download/SuiteSparse-v7.2.0+1/SuiteSparse.v7.2.0.aarch64-apple-darwin.tar.gz",
                    "d0caed10f94f8931e6772a946d583a3d411451ad0e68daf9c01086306e8c4854",
                ),
            ],
            products = [
                JLLLibraryProduct(
                    :libamd,
                    "lib/libamd.3.0.4.dylib",
                    [
                        JLLLibraryDep(nothing, :libsuitesparseconfig),
                    ],
                    [:RTLD_LAZY, :RTLD_DEEPBIND],
                ),
                JLLLibraryProduct(
                    :libbtf,
                    "lib/libbtf.2.0.4.dylib",
                    [
                        JLLLibraryDep(nothing, :libsuitesparseconfig),
                    ],
                    [:RTLD_LAZY, :RTLD_DEEPBIND],
                ),
                JLLLibraryProduct(
                    :libcamd,
                    "lib/libcamd.3.0.4.dylib",
                    [
                        JLLLibraryDep(nothing, :libsuitesparseconfig),
                    ],
                    [:RTLD_LAZY, :RTLD_DEEPBIND],
                ),
                JLLLibraryProduct(
                    :libccolamd,
                    "lib/libccolamd.3.0.4.dylib",
                    [
                        JLLLibraryDep(nothing, :libsuitesparseconfig),
                    ],
                    [:RTLD_LAZY, :RTLD_DEEPBIND],
                ),
                JLLLibraryProduct(
                    :libcholmod,
                    "lib/libcholmod.4.0.4.dylib",
                    [
                        JLLLibraryDep(nothing, :libsuitesparseconfig),
                        JLLLibraryDep(nothing, :libcolamd),
                        JLLLibraryDep(nothing, :libccolamd),
                        JLLLibraryDep(nothing, :libcamd),
                        JLLLibraryDep(nothing, :libamd),
                        JLLLibraryDep(:libblastrampoline_jll, :libblastrampoline),
                    ],
                    [:RTLD_LAZY, :RTLD_DEEPBIND],
                ),
                JLLLibraryProduct(
                    :libcolamd,
                    "lib/libcolamd.3.0.4.dylib",
                    [
                        JLLLibraryDep(nothing, :libsuitesparseconfig),
                    ],
                    [:RTLD_LAZY, :RTLD_DEEPBIND],
                ),
                JLLLibraryProduct(
                    :libklu,
                    "lib/libklu.2.0.4.dylib",
                    [
                        JLLLibraryDep(nothing, :libsuitesparseconfig),
                        JLLLibraryDep(nothing, :libamd),
                        JLLLibraryDep(nothing, :libcolamd),
                        JLLLibraryDep(nothing, :libbtf),
                    ],
                    [:RTLD_LAZY, :RTLD_DEEPBIND],
                ),
                JLLLibraryProduct(
                    :libldl,
                    "lib/libldl.3.0.4.dylib",
                    [
                        JLLLibraryDep(nothing, :libsuitesparseconfig),
                    ],
                    [:RTLD_LAZY, :RTLD_DEEPBIND],
                ),
                JLLLibraryProduct(
                    :librbio,
                    "lib/librbio.4.0.0.dylib",
                    [
                        JLLLibraryDep(nothing, :libsuitesparseconfig),
                    ],
                    [:RTLD_LAZY, :RTLD_DEEPBIND],
                ),
                JLLLibraryProduct(
                    :libspqr,
                    "lib/libspqr.4.0.0.dylib",
                    [
                        JLLLibraryDep(nothing, :libsuitesparseconfig),
                        JLLLibraryDep(nothing, :libamd),
                        JLLLibraryDep(nothing, :libcamd),
                        JLLLibraryDep(nothing, :libcholmod),
                        JLLLibraryDep(:libblastrampoline_jll, :libblastrampoline),
                    ],
                    [:RTLD_LAZY, :RTLD_DEEPBIND],
                ),
                JLLLibraryProduct(
                    :libsuitesparseconfig,
                    "lib/libsuitesparseconfig.7.1.0.dylib",
                    [],
                    [:RTLD_LAZY, :RTLD_DEEPBIND],
                ),
                JLLLibraryProduct(
                    :libumfpack,
                    "lib/libumfpack.6.1.1.dylib",
                    [
                        JLLLibraryDep(nothing, :libsuitesparseconfig),
                        JLLLibraryDep(:libblastrampoline_jll, :libblastrampoline),
                        JLLLibraryDep(nothing, :libcholmod),
                        JLLLibraryDep(nothing, :libamd),
                    ],
                    [:RTLD_LAZY, :RTLD_DEEPBIND],
                ),
            ]
        ),

        JLLArtifactInfo(;
            src_version = v"7.2.0+1",
            deps = [
                JLLPackageDependency(
                    "libblastrampoline_jll",
                    Base.UUID("8e850b90-86db-534c-a0d3-1478176c7d93"),
                    "5.4.0",
                ),
            ],
            sources = [],
            platform = Platform("aarch64", "linux"; libc = "glibc"),
            name = "SuiteSparse",
            treehash = "71b9a24526921e4b969d81bcfae2081cac269bc7",
            download_sources = [
                JLLArtifactSource(
                    "https://github.com/JuliaBinaryWrappers/SuiteSparse_jll.jl/releases/download/SuiteSparse-v7.2.0+1/SuiteSparse.v7.2.0.aarch64-linux-gnu.tar.gz",
                    "4a56d71cf66a84ee5806e0ce2c026aa5dc7c56cc1ae92eba49197ab99f7d7637",
                ),
            ],
            products = [
                JLLLibraryProduct(
                    :libamd,
                    "lib/libamd.so",
                    [
                        JLLLibraryDep(nothing, :libsuitesparseconfig),
                    ],
                    [:RTLD_LAZY, :RTLD_DEEPBIND],
                ),
                JLLLibraryProduct(
                    :libbtf,
                    "lib/libbtf.so",
                    [
                        JLLLibraryDep(nothing, :libsuitesparseconfig),
                    ],
                    [:RTLD_LAZY, :RTLD_DEEPBIND],
                ),
                JLLLibraryProduct(
                    :libcamd,
                    "lib/libcamd.so",
                    [
                        JLLLibraryDep(nothing, :libsuitesparseconfig),
                    ],
                    [:RTLD_LAZY, :RTLD_DEEPBIND],
                ),
                JLLLibraryProduct(
                    :libccolamd,
                    "lib/libccolamd.so",
                    [
                        JLLLibraryDep(nothing, :libsuitesparseconfig),
                    ],
                    [:RTLD_LAZY, :RTLD_DEEPBIND],
                ),
                JLLLibraryProduct(
                    :libcholmod,
                    "lib/libcholmod.so",
                    [
                        JLLLibraryDep(nothing, :libsuitesparseconfig),
                        JLLLibraryDep(nothing, :libcolamd),
                        JLLLibraryDep(nothing, :libccolamd),
                        JLLLibraryDep(nothing, :libcamd),
                        JLLLibraryDep(nothing, :libamd),
                        JLLLibraryDep(:libblastrampoline_jll, :libblastrampoline),
                    ],
                    [:RTLD_LAZY, :RTLD_DEEPBIND],
                ),
                JLLLibraryProduct(
                    :libcolamd,
                    "lib/libcolamd.so",
                    [
                        JLLLibraryDep(nothing, :libsuitesparseconfig),
                    ],
                    [:RTLD_LAZY, :RTLD_DEEPBIND],
                ),
                JLLLibraryProduct(
                    :libklu,
                    "lib/libklu.so",
                    [
                        JLLLibraryDep(nothing, :libsuitesparseconfig),
                        JLLLibraryDep(nothing, :libamd),
                        JLLLibraryDep(nothing, :libcolamd),
                        JLLLibraryDep(nothing, :libbtf),
                    ],
                    [:RTLD_LAZY, :RTLD_DEEPBIND],
                ),
                JLLLibraryProduct(
                    :libldl,
                    "lib/libldl.so",
                    [
                        JLLLibraryDep(nothing, :libsuitesparseconfig),
                    ],
                    [:RTLD_LAZY, :RTLD_DEEPBIND],
                ),
                JLLLibraryProduct(
                    :librbio,
                    "lib/librbio.so",
                    [
                        JLLLibraryDep(nothing, :libsuitesparseconfig),
                    ],
                    [:RTLD_LAZY, :RTLD_DEEPBIND],
                ),
                JLLLibraryProduct(
                    :libspqr,
                    "lib/libspqr.so",
                    [
                        JLLLibraryDep(nothing, :libsuitesparseconfig),
                        JLLLibraryDep(nothing, :libamd),
                        JLLLibraryDep(nothing, :libcamd),
                        JLLLibraryDep(nothing, :libcholmod),
                        JLLLibraryDep(:libblastrampoline_jll, :libblastrampoline),
                    ],
                    [:RTLD_LAZY, :RTLD_DEEPBIND],
                ),
                JLLLibraryProduct(
                    :libsuitesparseconfig,
                    "lib/libsuitesparseconfig.so",
                    [],
                    [:RTLD_LAZY, :RTLD_DEEPBIND],
                ),
                JLLLibraryProduct(
                    :libumfpack,
                    "lib/libumfpack.so",
                    [
                        JLLLibraryDep(nothing, :libsuitesparseconfig),
                        JLLLibraryDep(:libblastrampoline_jll, :libblastrampoline),
                        JLLLibraryDep(nothing, :libcholmod),
                        JLLLibraryDep(nothing, :libamd),
                    ],
                    [:RTLD_LAZY, :RTLD_DEEPBIND],
                ),
            ]
        ),

        JLLArtifactInfo(;
            src_version = v"7.2.0+1",
            deps = [
                JLLPackageDependency(
                    "libblastrampoline_jll",
                    Base.UUID("8e850b90-86db-534c-a0d3-1478176c7d93"),
                    "5.4.0",
                ),
            ],
            sources = [],
            platform = Platform("aarch64", "linux"; libc = "musl"),
            name = "SuiteSparse",
            treehash = "ebc1d355856c9efde9b0cef5971f20ba9e87fd8a",
            download_sources = [
                JLLArtifactSource(
                    "https://github.com/JuliaBinaryWrappers/SuiteSparse_jll.jl/releases/download/SuiteSparse-v7.2.0+1/SuiteSparse.v7.2.0.aarch64-linux-musl.tar.gz",
                    "633c254762899e8aebce2c7517f7da4b82c7aaadcba14b86efe632cd5f31f3e6",
                ),
            ],
            products = [
                JLLLibraryProduct(
                    :libamd,
                    "lib/libamd.so",
                    [
                        JLLLibraryDep(nothing, :libsuitesparseconfig),
                    ],
                    [:RTLD_LAZY, :RTLD_DEEPBIND],
                ),
                JLLLibraryProduct(
                    :libbtf,
                    "lib/libbtf.so",
                    [
                        JLLLibraryDep(nothing, :libsuitesparseconfig),
                    ],
                    [:RTLD_LAZY, :RTLD_DEEPBIND],
                ),
                JLLLibraryProduct(
                    :libcamd,
                    "lib/libcamd.so",
                    [
                        JLLLibraryDep(nothing, :libsuitesparseconfig),
                    ],
                    [:RTLD_LAZY, :RTLD_DEEPBIND],
                ),
                JLLLibraryProduct(
                    :libccolamd,
                    "lib/libccolamd.so",
                    [
                        JLLLibraryDep(nothing, :libsuitesparseconfig),
                    ],
                    [:RTLD_LAZY, :RTLD_DEEPBIND],
                ),
                JLLLibraryProduct(
                    :libcholmod,
                    "lib/libcholmod.so",
                    [
                        JLLLibraryDep(nothing, :libsuitesparseconfig),
                        JLLLibraryDep(nothing, :libcolamd),
                        JLLLibraryDep(nothing, :libccolamd),
                        JLLLibraryDep(nothing, :libcamd),
                        JLLLibraryDep(nothing, :libamd),
                        JLLLibraryDep(:libblastrampoline_jll, :libblastrampoline),
                    ],
                    [:RTLD_LAZY, :RTLD_DEEPBIND],
                ),
                JLLLibraryProduct(
                    :libcolamd,
                    "lib/libcolamd.so",
                    [
                        JLLLibraryDep(nothing, :libsuitesparseconfig),
                    ],
                    [:RTLD_LAZY, :RTLD_DEEPBIND],
                ),
                JLLLibraryProduct(
                    :libklu,
                    "lib/libklu.so",
                    [
                        JLLLibraryDep(nothing, :libsuitesparseconfig),
                        JLLLibraryDep(nothing, :libamd),
                        JLLLibraryDep(nothing, :libcolamd),
                        JLLLibraryDep(nothing, :libbtf),
                    ],
                    [:RTLD_LAZY, :RTLD_DEEPBIND],
                ),
                JLLLibraryProduct(
                    :libldl,
                    "lib/libldl.so",
                    [
                        JLLLibraryDep(nothing, :libsuitesparseconfig),
                    ],
                    [:RTLD_LAZY, :RTLD_DEEPBIND],
                ),
                JLLLibraryProduct(
                    :librbio,
                    "lib/librbio.so",
                    [
                        JLLLibraryDep(nothing, :libsuitesparseconfig),
                    ],
                    [:RTLD_LAZY, :RTLD_DEEPBIND],
                ),
                JLLLibraryProduct(
                    :libspqr,
                    "lib/libspqr.so",
                    [
                        JLLLibraryDep(nothing, :libsuitesparseconfig),
                        JLLLibraryDep(nothing, :libamd),
                        JLLLibraryDep(nothing, :libcamd),
                        JLLLibraryDep(nothing, :libcholmod),
                        JLLLibraryDep(:libblastrampoline_jll, :libblastrampoline),
                    ],
                    [:RTLD_LAZY, :RTLD_DEEPBIND],
                ),
                JLLLibraryProduct(
                    :libsuitesparseconfig,
                    "lib/libsuitesparseconfig.so",
                    [],
                    [:RTLD_LAZY, :RTLD_DEEPBIND],
                ),
                JLLLibraryProduct(
                    :libumfpack,
                    "lib/libumfpack.so",
                    [
                        JLLLibraryDep(nothing, :libsuitesparseconfig),
                        JLLLibraryDep(:libblastrampoline_jll, :libblastrampoline),
                        JLLLibraryDep(nothing, :libcholmod),
                        JLLLibraryDep(nothing, :libamd),
                    ],
                    [:RTLD_LAZY, :RTLD_DEEPBIND],
                ),
            ]
        ),

        JLLArtifactInfo(;
            src_version = v"7.2.0+1",
            deps = [
                JLLPackageDependency(
                    "libblastrampoline_jll",
                    Base.UUID("8e850b90-86db-534c-a0d3-1478176c7d93"),
                    "5.4.0",
                ),
            ],
            sources = [],
            platform = Platform("armv6l", "linux"; call_abi = "eabihf", libc = "glibc"),
            name = "SuiteSparse",
            treehash = "3c70b51e115f6610fcdaa686a7a3e2dfc2a4ac56",
            download_sources = [
                JLLArtifactSource(
                    "https://github.com/JuliaBinaryWrappers/SuiteSparse_jll.jl/releases/download/SuiteSparse-v7.2.0+1/SuiteSparse.v7.2.0.armv6l-linux-gnueabihf.tar.gz",
                    "9723c8df60ce669322c856a1ed836a99319ca8865e040692fe3fd9328546f127",
                ),
            ],
            products = [
                JLLLibraryProduct(
                    :libamd,
                    "lib/libamd.so",
                    [
                        JLLLibraryDep(nothing, :libsuitesparseconfig),
                    ],
                    [:RTLD_LAZY, :RTLD_DEEPBIND],
                ),
                JLLLibraryProduct(
                    :libbtf,
                    "lib/libbtf.so",
                    [
                        JLLLibraryDep(nothing, :libsuitesparseconfig),
                    ],
                    [:RTLD_LAZY, :RTLD_DEEPBIND],
                ),
                JLLLibraryProduct(
                    :libcamd,
                    "lib/libcamd.so",
                    [
                        JLLLibraryDep(nothing, :libsuitesparseconfig),
                    ],
                    [:RTLD_LAZY, :RTLD_DEEPBIND],
                ),
                JLLLibraryProduct(
                    :libccolamd,
                    "lib/libccolamd.so",
                    [
                        JLLLibraryDep(nothing, :libsuitesparseconfig),
                    ],
                    [:RTLD_LAZY, :RTLD_DEEPBIND],
                ),
                JLLLibraryProduct(
                    :libcholmod,
                    "lib/libcholmod.so",
                    [
                        JLLLibraryDep(nothing, :libsuitesparseconfig),
                        JLLLibraryDep(nothing, :libcolamd),
                        JLLLibraryDep(nothing, :libccolamd),
                        JLLLibraryDep(nothing, :libcamd),
                        JLLLibraryDep(nothing, :libamd),
                        JLLLibraryDep(:libblastrampoline_jll, :libblastrampoline),
                    ],
                    [:RTLD_LAZY, :RTLD_DEEPBIND],
                ),
                JLLLibraryProduct(
                    :libcolamd,
                    "lib/libcolamd.so",
                    [
                        JLLLibraryDep(nothing, :libsuitesparseconfig),
                    ],
                    [:RTLD_LAZY, :RTLD_DEEPBIND],
                ),
                JLLLibraryProduct(
                    :libklu,
                    "lib/libklu.so",
                    [
                        JLLLibraryDep(nothing, :libsuitesparseconfig),
                        JLLLibraryDep(nothing, :libamd),
                        JLLLibraryDep(nothing, :libcolamd),
                        JLLLibraryDep(nothing, :libbtf),
                    ],
                    [:RTLD_LAZY, :RTLD_DEEPBIND],
                ),
                JLLLibraryProduct(
                    :libldl,
                    "lib/libldl.so",
                    [
                        JLLLibraryDep(nothing, :libsuitesparseconfig),
                    ],
                    [:RTLD_LAZY, :RTLD_DEEPBIND],
                ),
                JLLLibraryProduct(
                    :librbio,
                    "lib/librbio.so",
                    [
                        JLLLibraryDep(nothing, :libsuitesparseconfig),
                    ],
                    [:RTLD_LAZY, :RTLD_DEEPBIND],
                ),
                JLLLibraryProduct(
                    :libspqr,
                    "lib/libspqr.so",
                    [
                        JLLLibraryDep(nothing, :libsuitesparseconfig),
                        JLLLibraryDep(nothing, :libamd),
                        JLLLibraryDep(nothing, :libcamd),
                        JLLLibraryDep(nothing, :libcholmod),
                        JLLLibraryDep(:libblastrampoline_jll, :libblastrampoline),
                    ],
                    [:RTLD_LAZY, :RTLD_DEEPBIND],
                ),
                JLLLibraryProduct(
                    :libsuitesparseconfig,
                    "lib/libsuitesparseconfig.so",
                    [],
                    [:RTLD_LAZY, :RTLD_DEEPBIND],
                ),
                JLLLibraryProduct(
                    :libumfpack,
                    "lib/libumfpack.so",
                    [
                        JLLLibraryDep(nothing, :libsuitesparseconfig),
                        JLLLibraryDep(:libblastrampoline_jll, :libblastrampoline),
                        JLLLibraryDep(nothing, :libcholmod),
                        JLLLibraryDep(nothing, :libamd),
                    ],
                    [:RTLD_LAZY, :RTLD_DEEPBIND],
                ),
            ]
        ),

        JLLArtifactInfo(;
            src_version = v"7.2.0+1",
            deps = [
                JLLPackageDependency(
                    "libblastrampoline_jll",
                    Base.UUID("8e850b90-86db-534c-a0d3-1478176c7d93"),
                    "5.4.0",
                ),
            ],
            sources = [],
            platform = Platform("armv6l", "linux"; call_abi = "eabihf", libc = "musl"),
            name = "SuiteSparse",
            treehash = "384da13f523185583ef52b7001fa8b7a31a9845c",
            download_sources = [
                JLLArtifactSource(
                    "https://github.com/JuliaBinaryWrappers/SuiteSparse_jll.jl/releases/download/SuiteSparse-v7.2.0+1/SuiteSparse.v7.2.0.armv6l-linux-musleabihf.tar.gz",
                    "4b32e2b9818b6cdf6bc977dbbfe7a11f70232f3be9754a3b4e8e2fcc71b6891c",
                ),
            ],
            products = [
                JLLLibraryProduct(
                    :libamd,
                    "lib/libamd.so",
                    [
                        JLLLibraryDep(nothing, :libsuitesparseconfig),
                    ],
                    [:RTLD_LAZY, :RTLD_DEEPBIND],
                ),
                JLLLibraryProduct(
                    :libbtf,
                    "lib/libbtf.so",
                    [
                        JLLLibraryDep(nothing, :libsuitesparseconfig),
                    ],
                    [:RTLD_LAZY, :RTLD_DEEPBIND],
                ),
                JLLLibraryProduct(
                    :libcamd,
                    "lib/libcamd.so",
                    [
                        JLLLibraryDep(nothing, :libsuitesparseconfig),
                    ],
                    [:RTLD_LAZY, :RTLD_DEEPBIND],
                ),
                JLLLibraryProduct(
                    :libccolamd,
                    "lib/libccolamd.so",
                    [
                        JLLLibraryDep(nothing, :libsuitesparseconfig),
                    ],
                    [:RTLD_LAZY, :RTLD_DEEPBIND],
                ),
                JLLLibraryProduct(
                    :libcholmod,
                    "lib/libcholmod.so",
                    [
                        JLLLibraryDep(nothing, :libsuitesparseconfig),
                        JLLLibraryDep(nothing, :libcolamd),
                        JLLLibraryDep(nothing, :libccolamd),
                        JLLLibraryDep(nothing, :libcamd),
                        JLLLibraryDep(nothing, :libamd),
                        JLLLibraryDep(:libblastrampoline_jll, :libblastrampoline),
                    ],
                    [:RTLD_LAZY, :RTLD_DEEPBIND],
                ),
                JLLLibraryProduct(
                    :libcolamd,
                    "lib/libcolamd.so",
                    [
                        JLLLibraryDep(nothing, :libsuitesparseconfig),
                    ],
                    [:RTLD_LAZY, :RTLD_DEEPBIND],
                ),
                JLLLibraryProduct(
                    :libklu,
                    "lib/libklu.so",
                    [
                        JLLLibraryDep(nothing, :libsuitesparseconfig),
                        JLLLibraryDep(nothing, :libamd),
                        JLLLibraryDep(nothing, :libcolamd),
                        JLLLibraryDep(nothing, :libbtf),
                    ],
                    [:RTLD_LAZY, :RTLD_DEEPBIND],
                ),
                JLLLibraryProduct(
                    :libldl,
                    "lib/libldl.so",
                    [
                        JLLLibraryDep(nothing, :libsuitesparseconfig),
                    ],
                    [:RTLD_LAZY, :RTLD_DEEPBIND],
                ),
                JLLLibraryProduct(
                    :librbio,
                    "lib/librbio.so",
                    [
                        JLLLibraryDep(nothing, :libsuitesparseconfig),
                    ],
                    [:RTLD_LAZY, :RTLD_DEEPBIND],
                ),
                JLLLibraryProduct(
                    :libspqr,
                    "lib/libspqr.so",
                    [
                        JLLLibraryDep(nothing, :libsuitesparseconfig),
                        JLLLibraryDep(nothing, :libamd),
                        JLLLibraryDep(nothing, :libcamd),
                        JLLLibraryDep(nothing, :libcholmod),
                        JLLLibraryDep(:libblastrampoline_jll, :libblastrampoline),
                    ],
                    [:RTLD_LAZY, :RTLD_DEEPBIND],
                ),
                JLLLibraryProduct(
                    :libsuitesparseconfig,
                    "lib/libsuitesparseconfig.so",
                    [],
                    [:RTLD_LAZY, :RTLD_DEEPBIND],
                ),
                JLLLibraryProduct(
                    :libumfpack,
                    "lib/libumfpack.so",
                    [
                        JLLLibraryDep(nothing, :libsuitesparseconfig),
                        JLLLibraryDep(:libblastrampoline_jll, :libblastrampoline),
                        JLLLibraryDep(nothing, :libcholmod),
                        JLLLibraryDep(nothing, :libamd),
                    ],
                    [:RTLD_LAZY, :RTLD_DEEPBIND],
                ),
            ]
        ),

        JLLArtifactInfo(;
            src_version = v"7.2.0+1",
            deps = [
                JLLPackageDependency(
                    "libblastrampoline_jll",
                    Base.UUID("8e850b90-86db-534c-a0d3-1478176c7d93"),
                    "5.4.0",
                ),
            ],
            sources = [],
            platform = Platform("armv7l", "linux"; call_abi = "eabihf", libc = "glibc"),
            name = "SuiteSparse",
            treehash = "6677c3d4c51e18ebdb50f4081fccbeb060fe1b43",
            download_sources = [
                JLLArtifactSource(
                    "https://github.com/JuliaBinaryWrappers/SuiteSparse_jll.jl/releases/download/SuiteSparse-v7.2.0+1/SuiteSparse.v7.2.0.armv7l-linux-gnueabihf.tar.gz",
                    "0ce63c50815098b4352d535a849cc72e53fa7027a36124f18f347f48c3377211",
                ),
            ],
            products = [
                JLLLibraryProduct(
                    :libamd,
                    "lib/libamd.so",
                    [
                        JLLLibraryDep(nothing, :libsuitesparseconfig),
                    ],
                    [:RTLD_LAZY, :RTLD_DEEPBIND],
                ),
                JLLLibraryProduct(
                    :libbtf,
                    "lib/libbtf.so",
                    [
                        JLLLibraryDep(nothing, :libsuitesparseconfig),
                    ],
                    [:RTLD_LAZY, :RTLD_DEEPBIND],
                ),
                JLLLibraryProduct(
                    :libcamd,
                    "lib/libcamd.so",
                    [
                        JLLLibraryDep(nothing, :libsuitesparseconfig),
                    ],
                    [:RTLD_LAZY, :RTLD_DEEPBIND],
                ),
                JLLLibraryProduct(
                    :libccolamd,
                    "lib/libccolamd.so",
                    [
                        JLLLibraryDep(nothing, :libsuitesparseconfig),
                    ],
                    [:RTLD_LAZY, :RTLD_DEEPBIND],
                ),
                JLLLibraryProduct(
                    :libcholmod,
                    "lib/libcholmod.so",
                    [
                        JLLLibraryDep(nothing, :libsuitesparseconfig),
                        JLLLibraryDep(nothing, :libcolamd),
                        JLLLibraryDep(nothing, :libccolamd),
                        JLLLibraryDep(nothing, :libcamd),
                        JLLLibraryDep(nothing, :libamd),
                        JLLLibraryDep(:libblastrampoline_jll, :libblastrampoline),
                    ],
                    [:RTLD_LAZY, :RTLD_DEEPBIND],
                ),
                JLLLibraryProduct(
                    :libcolamd,
                    "lib/libcolamd.so",
                    [
                        JLLLibraryDep(nothing, :libsuitesparseconfig),
                    ],
                    [:RTLD_LAZY, :RTLD_DEEPBIND],
                ),
                JLLLibraryProduct(
                    :libklu,
                    "lib/libklu.so",
                    [
                        JLLLibraryDep(nothing, :libsuitesparseconfig),
                        JLLLibraryDep(nothing, :libamd),
                        JLLLibraryDep(nothing, :libcolamd),
                        JLLLibraryDep(nothing, :libbtf),
                    ],
                    [:RTLD_LAZY, :RTLD_DEEPBIND],
                ),
                JLLLibraryProduct(
                    :libldl,
                    "lib/libldl.so",
                    [
                        JLLLibraryDep(nothing, :libsuitesparseconfig),
                    ],
                    [:RTLD_LAZY, :RTLD_DEEPBIND],
                ),
                JLLLibraryProduct(
                    :librbio,
                    "lib/librbio.so",
                    [
                        JLLLibraryDep(nothing, :libsuitesparseconfig),
                    ],
                    [:RTLD_LAZY, :RTLD_DEEPBIND],
                ),
                JLLLibraryProduct(
                    :libspqr,
                    "lib/libspqr.so",
                    [
                        JLLLibraryDep(nothing, :libsuitesparseconfig),
                        JLLLibraryDep(nothing, :libamd),
                        JLLLibraryDep(nothing, :libcamd),
                        JLLLibraryDep(nothing, :libcholmod),
                        JLLLibraryDep(:libblastrampoline_jll, :libblastrampoline),
                    ],
                    [:RTLD_LAZY, :RTLD_DEEPBIND],
                ),
                JLLLibraryProduct(
                    :libsuitesparseconfig,
                    "lib/libsuitesparseconfig.so",
                    [],
                    [:RTLD_LAZY, :RTLD_DEEPBIND],
                ),
                JLLLibraryProduct(
                    :libumfpack,
                    "lib/libumfpack.so",
                    [
                        JLLLibraryDep(nothing, :libsuitesparseconfig),
                        JLLLibraryDep(:libblastrampoline_jll, :libblastrampoline),
                        JLLLibraryDep(nothing, :libcholmod),
                        JLLLibraryDep(nothing, :libamd),
                    ],
                    [:RTLD_LAZY, :RTLD_DEEPBIND],
                ),
            ]
        ),

        JLLArtifactInfo(;
            src_version = v"7.2.0+1",
            deps = [
                JLLPackageDependency(
                    "libblastrampoline_jll",
                    Base.UUID("8e850b90-86db-534c-a0d3-1478176c7d93"),
                    "5.4.0",
                ),
            ],
            sources = [],
            platform = Platform("armv7l", "linux"; call_abi = "eabihf", libc = "musl"),
            name = "SuiteSparse",
            treehash = "2995605c5d4ac886535be0b07fc0d8e63aa49ac8",
            download_sources = [
                JLLArtifactSource(
                    "https://github.com/JuliaBinaryWrappers/SuiteSparse_jll.jl/releases/download/SuiteSparse-v7.2.0+1/SuiteSparse.v7.2.0.armv7l-linux-musleabihf.tar.gz",
                    "34a6314f9075e9d789d25a9b5bca7c34d6d28c477102f4fbf1a93e9ad4715de7",
                ),
            ],
            products = [
                JLLLibraryProduct(
                    :libamd,
                    "lib/libamd.so",
                    [
                        JLLLibraryDep(nothing, :libsuitesparseconfig),
                    ],
                    [:RTLD_LAZY, :RTLD_DEEPBIND],
                ),
                JLLLibraryProduct(
                    :libbtf,
                    "lib/libbtf.so",
                    [
                        JLLLibraryDep(nothing, :libsuitesparseconfig),
                    ],
                    [:RTLD_LAZY, :RTLD_DEEPBIND],
                ),
                JLLLibraryProduct(
                    :libcamd,
                    "lib/libcamd.so",
                    [
                        JLLLibraryDep(nothing, :libsuitesparseconfig),
                    ],
                    [:RTLD_LAZY, :RTLD_DEEPBIND],
                ),
                JLLLibraryProduct(
                    :libccolamd,
                    "lib/libccolamd.so",
                    [
                        JLLLibraryDep(nothing, :libsuitesparseconfig),
                    ],
                    [:RTLD_LAZY, :RTLD_DEEPBIND],
                ),
                JLLLibraryProduct(
                    :libcholmod,
                    "lib/libcholmod.so",
                    [
                        JLLLibraryDep(nothing, :libsuitesparseconfig),
                        JLLLibraryDep(nothing, :libcolamd),
                        JLLLibraryDep(nothing, :libccolamd),
                        JLLLibraryDep(nothing, :libcamd),
                        JLLLibraryDep(nothing, :libamd),
                        JLLLibraryDep(:libblastrampoline_jll, :libblastrampoline),
                    ],
                    [:RTLD_LAZY, :RTLD_DEEPBIND],
                ),
                JLLLibraryProduct(
                    :libcolamd,
                    "lib/libcolamd.so",
                    [
                        JLLLibraryDep(nothing, :libsuitesparseconfig),
                    ],
                    [:RTLD_LAZY, :RTLD_DEEPBIND],
                ),
                JLLLibraryProduct(
                    :libklu,
                    "lib/libklu.so",
                    [
                        JLLLibraryDep(nothing, :libsuitesparseconfig),
                        JLLLibraryDep(nothing, :libamd),
                        JLLLibraryDep(nothing, :libcolamd),
                        JLLLibraryDep(nothing, :libbtf),
                    ],
                    [:RTLD_LAZY, :RTLD_DEEPBIND],
                ),
                JLLLibraryProduct(
                    :libldl,
                    "lib/libldl.so",
                    [
                        JLLLibraryDep(nothing, :libsuitesparseconfig),
                    ],
                    [:RTLD_LAZY, :RTLD_DEEPBIND],
                ),
                JLLLibraryProduct(
                    :librbio,
                    "lib/librbio.so",
                    [
                        JLLLibraryDep(nothing, :libsuitesparseconfig),
                    ],
                    [:RTLD_LAZY, :RTLD_DEEPBIND],
                ),
                JLLLibraryProduct(
                    :libspqr,
                    "lib/libspqr.so",
                    [
                        JLLLibraryDep(nothing, :libsuitesparseconfig),
                        JLLLibraryDep(nothing, :libamd),
                        JLLLibraryDep(nothing, :libcamd),
                        JLLLibraryDep(nothing, :libcholmod),
                        JLLLibraryDep(:libblastrampoline_jll, :libblastrampoline),
                    ],
                    [:RTLD_LAZY, :RTLD_DEEPBIND],
                ),
                JLLLibraryProduct(
                    :libsuitesparseconfig,
                    "lib/libsuitesparseconfig.so",
                    [],
                    [:RTLD_LAZY, :RTLD_DEEPBIND],
                ),
                JLLLibraryProduct(
                    :libumfpack,
                    "lib/libumfpack.so",
                    [
                        JLLLibraryDep(nothing, :libsuitesparseconfig),
                        JLLLibraryDep(:libblastrampoline_jll, :libblastrampoline),
                        JLLLibraryDep(nothing, :libcholmod),
                        JLLLibraryDep(nothing, :libamd),
                    ],
                    [:RTLD_LAZY, :RTLD_DEEPBIND],
                ),
            ]
        ),

        JLLArtifactInfo(;
            src_version = v"7.2.0+1",
            deps = [
                JLLPackageDependency(
                    "libblastrampoline_jll",
                    Base.UUID("8e850b90-86db-534c-a0d3-1478176c7d93"),
                    "5.4.0",
                ),
            ],
            sources = [],
            platform = Platform("i686", "linux"; libc = "glibc"),
            name = "SuiteSparse",
            treehash = "bc44cb09261ee7ce9a40e3769685724ebea00051",
            download_sources = [
                JLLArtifactSource(
                    "https://github.com/JuliaBinaryWrappers/SuiteSparse_jll.jl/releases/download/SuiteSparse-v7.2.0+1/SuiteSparse.v7.2.0.i686-linux-gnu.tar.gz",
                    "a7b183b9b86ee0a5777e520d3178e42c3a8a528e58f2a5d345f66124ea8b0dea",
                ),
            ],
            products = [
                JLLLibraryProduct(
                    :libamd,
                    "lib/libamd.so",
                    [
                        JLLLibraryDep(nothing, :libsuitesparseconfig),
                    ],
                    [:RTLD_LAZY, :RTLD_DEEPBIND],
                ),
                JLLLibraryProduct(
                    :libbtf,
                    "lib/libbtf.so",
                    [
                        JLLLibraryDep(nothing, :libsuitesparseconfig),
                    ],
                    [:RTLD_LAZY, :RTLD_DEEPBIND],
                ),
                JLLLibraryProduct(
                    :libcamd,
                    "lib/libcamd.so",
                    [
                        JLLLibraryDep(nothing, :libsuitesparseconfig),
                    ],
                    [:RTLD_LAZY, :RTLD_DEEPBIND],
                ),
                JLLLibraryProduct(
                    :libccolamd,
                    "lib/libccolamd.so",
                    [
                        JLLLibraryDep(nothing, :libsuitesparseconfig),
                    ],
                    [:RTLD_LAZY, :RTLD_DEEPBIND],
                ),
                JLLLibraryProduct(
                    :libcholmod,
                    "lib/libcholmod.so",
                    [
                        JLLLibraryDep(nothing, :libsuitesparseconfig),
                        JLLLibraryDep(nothing, :libcolamd),
                        JLLLibraryDep(nothing, :libccolamd),
                        JLLLibraryDep(nothing, :libcamd),
                        JLLLibraryDep(nothing, :libamd),
                        JLLLibraryDep(:libblastrampoline_jll, :libblastrampoline),
                    ],
                    [:RTLD_LAZY, :RTLD_DEEPBIND],
                ),
                JLLLibraryProduct(
                    :libcolamd,
                    "lib/libcolamd.so",
                    [
                        JLLLibraryDep(nothing, :libsuitesparseconfig),
                    ],
                    [:RTLD_LAZY, :RTLD_DEEPBIND],
                ),
                JLLLibraryProduct(
                    :libklu,
                    "lib/libklu.so",
                    [
                        JLLLibraryDep(nothing, :libsuitesparseconfig),
                        JLLLibraryDep(nothing, :libamd),
                        JLLLibraryDep(nothing, :libcolamd),
                        JLLLibraryDep(nothing, :libbtf),
                    ],
                    [:RTLD_LAZY, :RTLD_DEEPBIND],
                ),
                JLLLibraryProduct(
                    :libldl,
                    "lib/libldl.so",
                    [
                        JLLLibraryDep(nothing, :libsuitesparseconfig),
                    ],
                    [:RTLD_LAZY, :RTLD_DEEPBIND],
                ),
                JLLLibraryProduct(
                    :librbio,
                    "lib/librbio.so",
                    [
                        JLLLibraryDep(nothing, :libsuitesparseconfig),
                    ],
                    [:RTLD_LAZY, :RTLD_DEEPBIND],
                ),
                JLLLibraryProduct(
                    :libspqr,
                    "lib/libspqr.so",
                    [
                        JLLLibraryDep(nothing, :libsuitesparseconfig),
                        JLLLibraryDep(nothing, :libamd),
                        JLLLibraryDep(nothing, :libcamd),
                        JLLLibraryDep(nothing, :libcholmod),
                        JLLLibraryDep(:libblastrampoline_jll, :libblastrampoline),
                    ],
                    [:RTLD_LAZY, :RTLD_DEEPBIND],
                ),
                JLLLibraryProduct(
                    :libsuitesparseconfig,
                    "lib/libsuitesparseconfig.so",
                    [],
                    [:RTLD_LAZY, :RTLD_DEEPBIND],
                ),
                JLLLibraryProduct(
                    :libumfpack,
                    "lib/libumfpack.so",
                    [
                        JLLLibraryDep(nothing, :libsuitesparseconfig),
                        JLLLibraryDep(:libblastrampoline_jll, :libblastrampoline),
                        JLLLibraryDep(nothing, :libcholmod),
                        JLLLibraryDep(nothing, :libamd),
                    ],
                    [:RTLD_LAZY, :RTLD_DEEPBIND],
                ),
            ]
        ),

        JLLArtifactInfo(;
            src_version = v"7.2.0+1",
            deps = [
                JLLPackageDependency(
                    "libblastrampoline_jll",
                    Base.UUID("8e850b90-86db-534c-a0d3-1478176c7d93"),
                    "5.4.0",
                ),
            ],
            sources = [],
            platform = Platform("i686", "linux"; libc = "musl"),
            name = "SuiteSparse",
            treehash = "693263287c7f3e233e965dc8aa5b1e63642ec9ac",
            download_sources = [
                JLLArtifactSource(
                    "https://github.com/JuliaBinaryWrappers/SuiteSparse_jll.jl/releases/download/SuiteSparse-v7.2.0+1/SuiteSparse.v7.2.0.i686-linux-musl.tar.gz",
                    "6c597b3ddb27d963de52a001072e41e1b5b1f8fe4e2c1c28e6c2a48f47760800",
                ),
            ],
            products = [
                JLLLibraryProduct(
                    :libamd,
                    "lib/libamd.so",
                    [
                        JLLLibraryDep(nothing, :libsuitesparseconfig),
                    ],
                    [:RTLD_LAZY, :RTLD_DEEPBIND],
                ),
                JLLLibraryProduct(
                    :libbtf,
                    "lib/libbtf.so",
                    [
                        JLLLibraryDep(nothing, :libsuitesparseconfig),
                    ],
                    [:RTLD_LAZY, :RTLD_DEEPBIND],
                ),
                JLLLibraryProduct(
                    :libcamd,
                    "lib/libcamd.so",
                    [
                        JLLLibraryDep(nothing, :libsuitesparseconfig),
                    ],
                    [:RTLD_LAZY, :RTLD_DEEPBIND],
                ),
                JLLLibraryProduct(
                    :libccolamd,
                    "lib/libccolamd.so",
                    [
                        JLLLibraryDep(nothing, :libsuitesparseconfig),
                    ],
                    [:RTLD_LAZY, :RTLD_DEEPBIND],
                ),
                JLLLibraryProduct(
                    :libcholmod,
                    "lib/libcholmod.so",
                    [
                        JLLLibraryDep(nothing, :libsuitesparseconfig),
                        JLLLibraryDep(nothing, :libcolamd),
                        JLLLibraryDep(nothing, :libccolamd),
                        JLLLibraryDep(nothing, :libcamd),
                        JLLLibraryDep(nothing, :libamd),
                        JLLLibraryDep(:libblastrampoline_jll, :libblastrampoline),
                    ],
                    [:RTLD_LAZY, :RTLD_DEEPBIND],
                ),
                JLLLibraryProduct(
                    :libcolamd,
                    "lib/libcolamd.so",
                    [
                        JLLLibraryDep(nothing, :libsuitesparseconfig),
                    ],
                    [:RTLD_LAZY, :RTLD_DEEPBIND],
                ),
                JLLLibraryProduct(
                    :libklu,
                    "lib/libklu.so",
                    [
                        JLLLibraryDep(nothing, :libsuitesparseconfig),
                        JLLLibraryDep(nothing, :libamd),
                        JLLLibraryDep(nothing, :libcolamd),
                        JLLLibraryDep(nothing, :libbtf),
                    ],
                    [:RTLD_LAZY, :RTLD_DEEPBIND],
                ),
                JLLLibraryProduct(
                    :libldl,
                    "lib/libldl.so",
                    [
                        JLLLibraryDep(nothing, :libsuitesparseconfig),
                    ],
                    [:RTLD_LAZY, :RTLD_DEEPBIND],
                ),
                JLLLibraryProduct(
                    :librbio,
                    "lib/librbio.so",
                    [
                        JLLLibraryDep(nothing, :libsuitesparseconfig),
                    ],
                    [:RTLD_LAZY, :RTLD_DEEPBIND],
                ),
                JLLLibraryProduct(
                    :libspqr,
                    "lib/libspqr.so",
                    [
                        JLLLibraryDep(nothing, :libsuitesparseconfig),
                        JLLLibraryDep(nothing, :libamd),
                        JLLLibraryDep(nothing, :libcamd),
                        JLLLibraryDep(nothing, :libcholmod),
                        JLLLibraryDep(:libblastrampoline_jll, :libblastrampoline),
                    ],
                    [:RTLD_LAZY, :RTLD_DEEPBIND],
                ),
                JLLLibraryProduct(
                    :libsuitesparseconfig,
                    "lib/libsuitesparseconfig.so",
                    [],
                    [:RTLD_LAZY, :RTLD_DEEPBIND],
                ),
                JLLLibraryProduct(
                    :libumfpack,
                    "lib/libumfpack.so",
                    [
                        JLLLibraryDep(nothing, :libsuitesparseconfig),
                        JLLLibraryDep(:libblastrampoline_jll, :libblastrampoline),
                        JLLLibraryDep(nothing, :libcholmod),
                        JLLLibraryDep(nothing, :libamd),
                    ],
                    [:RTLD_LAZY, :RTLD_DEEPBIND],
                ),
            ]
        ),

        JLLArtifactInfo(;
            src_version = v"7.2.0+1",
            deps = [
                JLLPackageDependency(
                    "libblastrampoline_jll",
                    Base.UUID("8e850b90-86db-534c-a0d3-1478176c7d93"),
                    "5.4.0",
                ),
            ],
            sources = [],
            platform = Platform("i686", "windows"; ),
            name = "SuiteSparse",
            treehash = "d807ad48e83734199c48c8292a4fd4ddcb322409",
            download_sources = [
                JLLArtifactSource(
                    "https://github.com/JuliaBinaryWrappers/SuiteSparse_jll.jl/releases/download/SuiteSparse-v7.2.0+1/SuiteSparse.v7.2.0.i686-w64-mingw32.tar.gz",
                    "afbdcf81e02f1df4b903c8fc0776804e37ca72d1d41ee1c99ac7a7024c26dca0",
                ),
            ],
            products = [
                JLLLibraryProduct(
                    :libamd,
                    "bin\\libamd.dll",
                    [
                        JLLLibraryDep(nothing, :libsuitesparseconfig),
                    ],
                    [:RTLD_LAZY, :RTLD_DEEPBIND],
                ),
                JLLLibraryProduct(
                    :libbtf,
                    "bin\\libbtf.dll",
                    [
                        JLLLibraryDep(nothing, :libsuitesparseconfig),
                    ],
                    [:RTLD_LAZY, :RTLD_DEEPBIND],
                ),
                JLLLibraryProduct(
                    :libcamd,
                    "bin\\libcamd.dll",
                    [
                        JLLLibraryDep(nothing, :libsuitesparseconfig),
                    ],
                    [:RTLD_LAZY, :RTLD_DEEPBIND],
                ),
                JLLLibraryProduct(
                    :libccolamd,
                    "bin\\libccolamd.dll",
                    [
                        JLLLibraryDep(nothing, :libsuitesparseconfig),
                    ],
                    [:RTLD_LAZY, :RTLD_DEEPBIND],
                ),
                JLLLibraryProduct(
                    :libcholmod,
                    "bin\\libcholmod.dll",
                    [
                        JLLLibraryDep(nothing, :libsuitesparseconfig),
                        JLLLibraryDep(nothing, :libcolamd),
                        JLLLibraryDep(nothing, :libccolamd),
                        JLLLibraryDep(nothing, :libcamd),
                        JLLLibraryDep(nothing, :libamd),
                        JLLLibraryDep(:libblastrampoline_jll, :libblastrampoline),
                    ],
                    [:RTLD_LAZY, :RTLD_DEEPBIND],
                ),
                JLLLibraryProduct(
                    :libcolamd,
                    "bin\\libcolamd.dll",
                    [
                        JLLLibraryDep(nothing, :libsuitesparseconfig),
                    ],
                    [:RTLD_LAZY, :RTLD_DEEPBIND],
                ),
                JLLLibraryProduct(
                    :libklu,
                    "bin\\libklu.dll",
                    [
                        JLLLibraryDep(nothing, :libsuitesparseconfig),
                        JLLLibraryDep(nothing, :libamd),
                        JLLLibraryDep(nothing, :libcolamd),
                        JLLLibraryDep(nothing, :libbtf),
                    ],
                    [:RTLD_LAZY, :RTLD_DEEPBIND],
                ),
                JLLLibraryProduct(
                    :libldl,
                    "bin\\libldl.dll",
                    [
                        JLLLibraryDep(nothing, :libsuitesparseconfig),
                    ],
                    [:RTLD_LAZY, :RTLD_DEEPBIND],
                ),
                JLLLibraryProduct(
                    :librbio,
                    "bin\\librbio.dll",
                    [
                        JLLLibraryDep(nothing, :libsuitesparseconfig),
                    ],
                    [:RTLD_LAZY, :RTLD_DEEPBIND],
                ),
                JLLLibraryProduct(
                    :libspqr,
                    "bin\\libspqr.dll",
                    [
                        JLLLibraryDep(nothing, :libsuitesparseconfig),
                        JLLLibraryDep(nothing, :libamd),
                        JLLLibraryDep(nothing, :libcamd),
                        JLLLibraryDep(nothing, :libcholmod),
                        JLLLibraryDep(:libblastrampoline_jll, :libblastrampoline),
                    ],
                    [:RTLD_LAZY, :RTLD_DEEPBIND],
                ),
                JLLLibraryProduct(
                    :libsuitesparseconfig,
                    "bin\\libsuitesparseconfig.dll",
                    [],
                    [:RTLD_LAZY, :RTLD_DEEPBIND],
                ),
                JLLLibraryProduct(
                    :libumfpack,
                    "bin\\libumfpack.dll",
                    [
                        JLLLibraryDep(nothing, :libsuitesparseconfig),
                        JLLLibraryDep(:libblastrampoline_jll, :libblastrampoline),
                        JLLLibraryDep(nothing, :libcholmod),
                        JLLLibraryDep(nothing, :libamd),
                    ],
                    [:RTLD_LAZY, :RTLD_DEEPBIND],
                ),
            ]
        ),

        JLLArtifactInfo(;
            src_version = v"7.2.0+1",
            deps = [
                JLLPackageDependency(
                    "libblastrampoline_jll",
                    Base.UUID("8e850b90-86db-534c-a0d3-1478176c7d93"),
                    "5.4.0",
                ),
            ],
            sources = [],
            platform = Platform("powerpc64le", "linux"; libc = "glibc"),
            name = "SuiteSparse",
            treehash = "3726451ab62e3f4ad5ad5e348f32f391806c884d",
            download_sources = [
                JLLArtifactSource(
                    "https://github.com/JuliaBinaryWrappers/SuiteSparse_jll.jl/releases/download/SuiteSparse-v7.2.0+1/SuiteSparse.v7.2.0.powerpc64le-linux-gnu.tar.gz",
                    "1bf533a8de562d10b731fcad02508f4790d7fae7517d2eb97eb97910cbc1e53a",
                ),
            ],
            products = [
                JLLLibraryProduct(
                    :libamd,
                    "lib/libamd.so",
                    [
                        JLLLibraryDep(nothing, :libsuitesparseconfig),
                    ],
                    [:RTLD_LAZY, :RTLD_DEEPBIND],
                ),
                JLLLibraryProduct(
                    :libbtf,
                    "lib/libbtf.so",
                    [
                        JLLLibraryDep(nothing, :libsuitesparseconfig),
                    ],
                    [:RTLD_LAZY, :RTLD_DEEPBIND],
                ),
                JLLLibraryProduct(
                    :libcamd,
                    "lib/libcamd.so",
                    [
                        JLLLibraryDep(nothing, :libsuitesparseconfig),
                    ],
                    [:RTLD_LAZY, :RTLD_DEEPBIND],
                ),
                JLLLibraryProduct(
                    :libccolamd,
                    "lib/libccolamd.so",
                    [
                        JLLLibraryDep(nothing, :libsuitesparseconfig),
                    ],
                    [:RTLD_LAZY, :RTLD_DEEPBIND],
                ),
                JLLLibraryProduct(
                    :libcholmod,
                    "lib/libcholmod.so",
                    [
                        JLLLibraryDep(nothing, :libsuitesparseconfig),
                        JLLLibraryDep(nothing, :libcolamd),
                        JLLLibraryDep(nothing, :libccolamd),
                        JLLLibraryDep(nothing, :libcamd),
                        JLLLibraryDep(nothing, :libamd),
                        JLLLibraryDep(:libblastrampoline_jll, :libblastrampoline),
                    ],
                    [:RTLD_LAZY, :RTLD_DEEPBIND],
                ),
                JLLLibraryProduct(
                    :libcolamd,
                    "lib/libcolamd.so",
                    [
                        JLLLibraryDep(nothing, :libsuitesparseconfig),
                    ],
                    [:RTLD_LAZY, :RTLD_DEEPBIND],
                ),
                JLLLibraryProduct(
                    :libklu,
                    "lib/libklu.so",
                    [
                        JLLLibraryDep(nothing, :libsuitesparseconfig),
                        JLLLibraryDep(nothing, :libamd),
                        JLLLibraryDep(nothing, :libcolamd),
                        JLLLibraryDep(nothing, :libbtf),
                    ],
                    [:RTLD_LAZY, :RTLD_DEEPBIND],
                ),
                JLLLibraryProduct(
                    :libldl,
                    "lib/libldl.so",
                    [
                        JLLLibraryDep(nothing, :libsuitesparseconfig),
                    ],
                    [:RTLD_LAZY, :RTLD_DEEPBIND],
                ),
                JLLLibraryProduct(
                    :librbio,
                    "lib/librbio.so",
                    [
                        JLLLibraryDep(nothing, :libsuitesparseconfig),
                    ],
                    [:RTLD_LAZY, :RTLD_DEEPBIND],
                ),
                JLLLibraryProduct(
                    :libspqr,
                    "lib/libspqr.so",
                    [
                        JLLLibraryDep(nothing, :libsuitesparseconfig),
                        JLLLibraryDep(nothing, :libamd),
                        JLLLibraryDep(nothing, :libcamd),
                        JLLLibraryDep(nothing, :libcholmod),
                        JLLLibraryDep(:libblastrampoline_jll, :libblastrampoline),
                    ],
                    [:RTLD_LAZY, :RTLD_DEEPBIND],
                ),
                JLLLibraryProduct(
                    :libsuitesparseconfig,
                    "lib/libsuitesparseconfig.so",
                    [],
                    [:RTLD_LAZY, :RTLD_DEEPBIND],
                ),
                JLLLibraryProduct(
                    :libumfpack,
                    "lib/libumfpack.so",
                    [
                        JLLLibraryDep(nothing, :libsuitesparseconfig),
                        JLLLibraryDep(:libblastrampoline_jll, :libblastrampoline),
                        JLLLibraryDep(nothing, :libcholmod),
                        JLLLibraryDep(nothing, :libamd),
                    ],
                    [:RTLD_LAZY, :RTLD_DEEPBIND],
                ),
            ]
        ),

        JLLArtifactInfo(;
            src_version = v"7.2.0+1",
            deps = [
                JLLPackageDependency(
                    "libblastrampoline_jll",
                    Base.UUID("8e850b90-86db-534c-a0d3-1478176c7d93"),
                    "5.4.0",
                ),
            ],
            sources = [],
            platform = Platform("x86_64", "macos"; ),
            name = "SuiteSparse",
            treehash = "a7f3e578d721fec758c2988adf91f7f1b765cbc9",
            download_sources = [
                JLLArtifactSource(
                    "https://github.com/JuliaBinaryWrappers/SuiteSparse_jll.jl/releases/download/SuiteSparse-v7.2.0+1/SuiteSparse.v7.2.0.x86_64-apple-darwin.tar.gz",
                    "c458728c58d1403f61c8758806088e2aec5a74a7823f4a5168cee2740dd5a62d",
                ),
            ],
            products = [
                JLLLibraryProduct(
                    :libamd,
                    "lib/libamd.3.0.4.dylib",
                    [
                        JLLLibraryDep(nothing, :libsuitesparseconfig),
                    ],
                    [:RTLD_LAZY, :RTLD_DEEPBIND],
                ),
                JLLLibraryProduct(
                    :libbtf,
                    "lib/libbtf.2.0.4.dylib",
                    [
                        JLLLibraryDep(nothing, :libsuitesparseconfig),
                    ],
                    [:RTLD_LAZY, :RTLD_DEEPBIND],
                ),
                JLLLibraryProduct(
                    :libcamd,
                    "lib/libcamd.3.0.4.dylib",
                    [
                        JLLLibraryDep(nothing, :libsuitesparseconfig),
                    ],
                    [:RTLD_LAZY, :RTLD_DEEPBIND],
                ),
                JLLLibraryProduct(
                    :libccolamd,
                    "lib/libccolamd.3.0.4.dylib",
                    [
                        JLLLibraryDep(nothing, :libsuitesparseconfig),
                    ],
                    [:RTLD_LAZY, :RTLD_DEEPBIND],
                ),
                JLLLibraryProduct(
                    :libcholmod,
                    "lib/libcholmod.4.0.4.dylib",
                    [
                        JLLLibraryDep(nothing, :libsuitesparseconfig),
                        JLLLibraryDep(nothing, :libcolamd),
                        JLLLibraryDep(nothing, :libccolamd),
                        JLLLibraryDep(nothing, :libcamd),
                        JLLLibraryDep(nothing, :libamd),
                        JLLLibraryDep(:libblastrampoline_jll, :libblastrampoline),
                    ],
                    [:RTLD_LAZY, :RTLD_DEEPBIND],
                ),
                JLLLibraryProduct(
                    :libcolamd,
                    "lib/libcolamd.3.0.4.dylib",
                    [
                        JLLLibraryDep(nothing, :libsuitesparseconfig),
                    ],
                    [:RTLD_LAZY, :RTLD_DEEPBIND],
                ),
                JLLLibraryProduct(
                    :libklu,
                    "lib/libklu.2.0.4.dylib",
                    [
                        JLLLibraryDep(nothing, :libsuitesparseconfig),
                        JLLLibraryDep(nothing, :libamd),
                        JLLLibraryDep(nothing, :libcolamd),
                        JLLLibraryDep(nothing, :libbtf),
                    ],
                    [:RTLD_LAZY, :RTLD_DEEPBIND],
                ),
                JLLLibraryProduct(
                    :libldl,
                    "lib/libldl.3.0.4.dylib",
                    [
                        JLLLibraryDep(nothing, :libsuitesparseconfig),
                    ],
                    [:RTLD_LAZY, :RTLD_DEEPBIND],
                ),
                JLLLibraryProduct(
                    :librbio,
                    "lib/librbio.4.0.0.dylib",
                    [
                        JLLLibraryDep(nothing, :libsuitesparseconfig),
                    ],
                    [:RTLD_LAZY, :RTLD_DEEPBIND],
                ),
                JLLLibraryProduct(
                    :libspqr,
                    "lib/libspqr.4.0.0.dylib",
                    [
                        JLLLibraryDep(nothing, :libsuitesparseconfig),
                        JLLLibraryDep(nothing, :libamd),
                        JLLLibraryDep(nothing, :libcamd),
                        JLLLibraryDep(nothing, :libcholmod),
                        JLLLibraryDep(:libblastrampoline_jll, :libblastrampoline),
                    ],
                    [:RTLD_LAZY, :RTLD_DEEPBIND],
                ),
                JLLLibraryProduct(
                    :libsuitesparseconfig,
                    "lib/libsuitesparseconfig.7.1.0.dylib",
                    [],
                    [:RTLD_LAZY, :RTLD_DEEPBIND],
                ),
                JLLLibraryProduct(
                    :libumfpack,
                    "lib/libumfpack.6.1.1.dylib",
                    [
                        JLLLibraryDep(nothing, :libsuitesparseconfig),
                        JLLLibraryDep(:libblastrampoline_jll, :libblastrampoline),
                        JLLLibraryDep(nothing, :libcholmod),
                        JLLLibraryDep(nothing, :libamd),
                    ],
                    [:RTLD_LAZY, :RTLD_DEEPBIND],
                ),
            ]
        ),

        JLLArtifactInfo(;
            src_version = v"7.2.0+1",
            deps = [
                JLLPackageDependency(
                    "libblastrampoline_jll",
                    Base.UUID("8e850b90-86db-534c-a0d3-1478176c7d93"),
                    "5.4.0",
                ),
            ],
            sources = [],
            platform = Platform("x86_64", "linux"; libc = "glibc"),
            name = "SuiteSparse",
            treehash = "d4f6a49d4aa41c303cae0f5dfbd663bbb0463245",
            download_sources = [
                JLLArtifactSource(
                    "https://github.com/JuliaBinaryWrappers/SuiteSparse_jll.jl/releases/download/SuiteSparse-v7.2.0+1/SuiteSparse.v7.2.0.x86_64-linux-gnu.tar.gz",
                    "bbe82b3d2e3983781bfa0a83c5c292923addd1515164b14cdf63ee93ea2341aa",
                ),
            ],
            products = [
                JLLLibraryProduct(
                    :libamd,
                    "lib/libamd.so",
                    [
                        JLLLibraryDep(nothing, :libsuitesparseconfig),
                    ],
                    [:RTLD_LAZY, :RTLD_DEEPBIND],
                ),
                JLLLibraryProduct(
                    :libbtf,
                    "lib/libbtf.so",
                    [
                        JLLLibraryDep(nothing, :libsuitesparseconfig),
                    ],
                    [:RTLD_LAZY, :RTLD_DEEPBIND],
                ),
                JLLLibraryProduct(
                    :libcamd,
                    "lib/libcamd.so",
                    [
                        JLLLibraryDep(nothing, :libsuitesparseconfig),
                    ],
                    [:RTLD_LAZY, :RTLD_DEEPBIND],
                ),
                JLLLibraryProduct(
                    :libccolamd,
                    "lib/libccolamd.so",
                    [
                        JLLLibraryDep(nothing, :libsuitesparseconfig),
                    ],
                    [:RTLD_LAZY, :RTLD_DEEPBIND],
                ),
                JLLLibraryProduct(
                    :libcholmod,
                    "lib/libcholmod.so",
                    [
                        JLLLibraryDep(nothing, :libsuitesparseconfig),
                        JLLLibraryDep(nothing, :libcolamd),
                        JLLLibraryDep(nothing, :libccolamd),
                        JLLLibraryDep(nothing, :libcamd),
                        JLLLibraryDep(nothing, :libamd),
                        JLLLibraryDep(:libblastrampoline_jll, :libblastrampoline),
                    ],
                    [:RTLD_LAZY, :RTLD_DEEPBIND],
                ),
                JLLLibraryProduct(
                    :libcolamd,
                    "lib/libcolamd.so",
                    [
                        JLLLibraryDep(nothing, :libsuitesparseconfig),
                    ],
                    [:RTLD_LAZY, :RTLD_DEEPBIND],
                ),
                JLLLibraryProduct(
                    :libklu,
                    "lib/libklu.so",
                    [
                        JLLLibraryDep(nothing, :libsuitesparseconfig),
                        JLLLibraryDep(nothing, :libamd),
                        JLLLibraryDep(nothing, :libcolamd),
                        JLLLibraryDep(nothing, :libbtf),
                    ],
                    [:RTLD_LAZY, :RTLD_DEEPBIND],
                ),
                JLLLibraryProduct(
                    :libldl,
                    "lib/libldl.so",
                    [
                        JLLLibraryDep(nothing, :libsuitesparseconfig),
                    ],
                    [:RTLD_LAZY, :RTLD_DEEPBIND],
                ),
                JLLLibraryProduct(
                    :librbio,
                    "lib/librbio.so",
                    [
                        JLLLibraryDep(nothing, :libsuitesparseconfig),
                    ],
                    [:RTLD_LAZY, :RTLD_DEEPBIND],
                ),
                JLLLibraryProduct(
                    :libspqr,
                    "lib/libspqr.so",
                    [
                        JLLLibraryDep(nothing, :libsuitesparseconfig),
                        JLLLibraryDep(nothing, :libamd),
                        JLLLibraryDep(nothing, :libcamd),
                        JLLLibraryDep(nothing, :libcholmod),
                        JLLLibraryDep(:libblastrampoline_jll, :libblastrampoline),
                    ],
                    [:RTLD_LAZY, :RTLD_DEEPBIND],
                ),
                JLLLibraryProduct(
                    :libsuitesparseconfig,
                    "lib/libsuitesparseconfig.so",
                    [],
                    [:RTLD_LAZY, :RTLD_DEEPBIND],
                ),
                JLLLibraryProduct(
                    :libumfpack,
                    "lib/libumfpack.so",
                    [
                        JLLLibraryDep(nothing, :libsuitesparseconfig),
                        JLLLibraryDep(:libblastrampoline_jll, :libblastrampoline),
                        JLLLibraryDep(nothing, :libcholmod),
                        JLLLibraryDep(nothing, :libamd),
                    ],
                    [:RTLD_LAZY, :RTLD_DEEPBIND],
                ),
            ]
        ),

        JLLArtifactInfo(;
            src_version = v"7.2.0+1",
            deps = [
                JLLPackageDependency(
                    "libblastrampoline_jll",
                    Base.UUID("8e850b90-86db-534c-a0d3-1478176c7d93"),
                    "5.4.0",
                ),
            ],
            sources = [],
            platform = Platform("x86_64", "linux"; libc = "glibc", sanitize = "memory"),
            name = "SuiteSparse",
            treehash = "23e0f02c0b7d2a7dba23f0ecf401aca264d3c15c",
            download_sources = [
                JLLArtifactSource(
                    "https://github.com/JuliaBinaryWrappers/SuiteSparse_jll.jl/releases/download/SuiteSparse-v7.2.0+1/SuiteSparse.v7.2.0.x86_64-linux-gnu-sanitize+memory.tar.gz",
                    "4a5f661a0e932916ce6cc9c79b2b56ca966300e56493d803aa7b9c98ce26b277",
                ),
            ],
            products = [
                JLLLibraryProduct(
                    :libamd,
                    "lib/libamd.so",
                    [
                        JLLLibraryDep(nothing, :libsuitesparseconfig),
                    ],
                    [:RTLD_LAZY, :RTLD_DEEPBIND],
                ),
                JLLLibraryProduct(
                    :libbtf,
                    "lib/libbtf.so",
                    [
                        JLLLibraryDep(nothing, :libsuitesparseconfig),
                    ],
                    [:RTLD_LAZY, :RTLD_DEEPBIND],
                ),
                JLLLibraryProduct(
                    :libcamd,
                    "lib/libcamd.so",
                    [
                        JLLLibraryDep(nothing, :libsuitesparseconfig),
                    ],
                    [:RTLD_LAZY, :RTLD_DEEPBIND],
                ),
                JLLLibraryProduct(
                    :libccolamd,
                    "lib/libccolamd.so",
                    [
                        JLLLibraryDep(nothing, :libsuitesparseconfig),
                    ],
                    [:RTLD_LAZY, :RTLD_DEEPBIND],
                ),
                JLLLibraryProduct(
                    :libcholmod,
                    "lib/libcholmod.so",
                    [
                        JLLLibraryDep(nothing, :libsuitesparseconfig),
                        JLLLibraryDep(nothing, :libcolamd),
                        JLLLibraryDep(nothing, :libccolamd),
                        JLLLibraryDep(nothing, :libcamd),
                        JLLLibraryDep(nothing, :libamd),
                        JLLLibraryDep(:libblastrampoline_jll, :libblastrampoline),
                    ],
                    [:RTLD_LAZY, :RTLD_DEEPBIND],
                ),
                JLLLibraryProduct(
                    :libcolamd,
                    "lib/libcolamd.so",
                    [
                        JLLLibraryDep(nothing, :libsuitesparseconfig),
                    ],
                    [:RTLD_LAZY, :RTLD_DEEPBIND],
                ),
                JLLLibraryProduct(
                    :libklu,
                    "lib/libklu.so",
                    [
                        JLLLibraryDep(nothing, :libsuitesparseconfig),
                        JLLLibraryDep(nothing, :libamd),
                        JLLLibraryDep(nothing, :libcolamd),
                        JLLLibraryDep(nothing, :libbtf),
                    ],
                    [:RTLD_LAZY, :RTLD_DEEPBIND],
                ),
                JLLLibraryProduct(
                    :libldl,
                    "lib/libldl.so",
                    [
                        JLLLibraryDep(nothing, :libsuitesparseconfig),
                    ],
                    [:RTLD_LAZY, :RTLD_DEEPBIND],
                ),
                JLLLibraryProduct(
                    :librbio,
                    "lib/librbio.so",
                    [
                        JLLLibraryDep(nothing, :libsuitesparseconfig),
                    ],
                    [:RTLD_LAZY, :RTLD_DEEPBIND],
                ),
                JLLLibraryProduct(
                    :libspqr,
                    "lib/libspqr.so",
                    [
                        JLLLibraryDep(nothing, :libsuitesparseconfig),
                        JLLLibraryDep(nothing, :libamd),
                        JLLLibraryDep(nothing, :libcamd),
                        JLLLibraryDep(nothing, :libcholmod),
                        JLLLibraryDep(:libblastrampoline_jll, :libblastrampoline),
                    ],
                    [:RTLD_LAZY, :RTLD_DEEPBIND],
                ),
                JLLLibraryProduct(
                    :libsuitesparseconfig,
                    "lib/libsuitesparseconfig.so",
                    [],
                    [:RTLD_LAZY, :RTLD_DEEPBIND],
                ),
                JLLLibraryProduct(
                    :libumfpack,
                    "lib/libumfpack.so",
                    [
                        JLLLibraryDep(nothing, :libsuitesparseconfig),
                        JLLLibraryDep(:libblastrampoline_jll, :libblastrampoline),
                        JLLLibraryDep(nothing, :libcholmod),
                        JLLLibraryDep(nothing, :libamd),
                    ],
                    [:RTLD_LAZY, :RTLD_DEEPBIND],
                ),
            ]
        ),

        JLLArtifactInfo(;
            src_version = v"7.2.0+1",
            deps = [
                JLLPackageDependency(
                    "libblastrampoline_jll",
                    Base.UUID("8e850b90-86db-534c-a0d3-1478176c7d93"),
                    "5.4.0",
                ),
            ],
            sources = [],
            platform = Platform("x86_64", "linux"; libc = "musl"),
            name = "SuiteSparse",
            treehash = "24119a6212d43f4962c5c2d0a5eccf667ed5cd69",
            download_sources = [
                JLLArtifactSource(
                    "https://github.com/JuliaBinaryWrappers/SuiteSparse_jll.jl/releases/download/SuiteSparse-v7.2.0+1/SuiteSparse.v7.2.0.x86_64-linux-musl.tar.gz",
                    "88fcc9a14f7c8b1993908a9cf9d6cab4c55247faed535f8928dc95ecff9372b6",
                ),
            ],
            products = [
                JLLLibraryProduct(
                    :libamd,
                    "lib/libamd.so",
                    [
                        JLLLibraryDep(nothing, :libsuitesparseconfig),
                    ],
                    [:RTLD_LAZY, :RTLD_DEEPBIND],
                ),
                JLLLibraryProduct(
                    :libbtf,
                    "lib/libbtf.so",
                    [
                        JLLLibraryDep(nothing, :libsuitesparseconfig),
                    ],
                    [:RTLD_LAZY, :RTLD_DEEPBIND],
                ),
                JLLLibraryProduct(
                    :libcamd,
                    "lib/libcamd.so",
                    [
                        JLLLibraryDep(nothing, :libsuitesparseconfig),
                    ],
                    [:RTLD_LAZY, :RTLD_DEEPBIND],
                ),
                JLLLibraryProduct(
                    :libccolamd,
                    "lib/libccolamd.so",
                    [
                        JLLLibraryDep(nothing, :libsuitesparseconfig),
                    ],
                    [:RTLD_LAZY, :RTLD_DEEPBIND],
                ),
                JLLLibraryProduct(
                    :libcholmod,
                    "lib/libcholmod.so",
                    [
                        JLLLibraryDep(nothing, :libsuitesparseconfig),
                        JLLLibraryDep(nothing, :libcolamd),
                        JLLLibraryDep(nothing, :libccolamd),
                        JLLLibraryDep(nothing, :libcamd),
                        JLLLibraryDep(nothing, :libamd),
                        JLLLibraryDep(:libblastrampoline_jll, :libblastrampoline),
                    ],
                    [:RTLD_LAZY, :RTLD_DEEPBIND],
                ),
                JLLLibraryProduct(
                    :libcolamd,
                    "lib/libcolamd.so",
                    [
                        JLLLibraryDep(nothing, :libsuitesparseconfig),
                    ],
                    [:RTLD_LAZY, :RTLD_DEEPBIND],
                ),
                JLLLibraryProduct(
                    :libklu,
                    "lib/libklu.so",
                    [
                        JLLLibraryDep(nothing, :libsuitesparseconfig),
                        JLLLibraryDep(nothing, :libamd),
                        JLLLibraryDep(nothing, :libcolamd),
                        JLLLibraryDep(nothing, :libbtf),
                    ],
                    [:RTLD_LAZY, :RTLD_DEEPBIND],
                ),
                JLLLibraryProduct(
                    :libldl,
                    "lib/libldl.so",
                    [
                        JLLLibraryDep(nothing, :libsuitesparseconfig),
                    ],
                    [:RTLD_LAZY, :RTLD_DEEPBIND],
                ),
                JLLLibraryProduct(
                    :librbio,
                    "lib/librbio.so",
                    [
                        JLLLibraryDep(nothing, :libsuitesparseconfig),
                    ],
                    [:RTLD_LAZY, :RTLD_DEEPBIND],
                ),
                JLLLibraryProduct(
                    :libspqr,
                    "lib/libspqr.so",
                    [
                        JLLLibraryDep(nothing, :libsuitesparseconfig),
                        JLLLibraryDep(nothing, :libamd),
                        JLLLibraryDep(nothing, :libcamd),
                        JLLLibraryDep(nothing, :libcholmod),
                        JLLLibraryDep(:libblastrampoline_jll, :libblastrampoline),
                    ],
                    [:RTLD_LAZY, :RTLD_DEEPBIND],
                ),
                JLLLibraryProduct(
                    :libsuitesparseconfig,
                    "lib/libsuitesparseconfig.so",
                    [],
                    [:RTLD_LAZY, :RTLD_DEEPBIND],
                ),
                JLLLibraryProduct(
                    :libumfpack,
                    "lib/libumfpack.so",
                    [
                        JLLLibraryDep(nothing, :libsuitesparseconfig),
                        JLLLibraryDep(:libblastrampoline_jll, :libblastrampoline),
                        JLLLibraryDep(nothing, :libcholmod),
                        JLLLibraryDep(nothing, :libamd),
                    ],
                    [:RTLD_LAZY, :RTLD_DEEPBIND],
                ),
            ]
        ),

        JLLArtifactInfo(;
            src_version = v"7.2.0+1",
            deps = [
                JLLPackageDependency(
                    "libblastrampoline_jll",
                    Base.UUID("8e850b90-86db-534c-a0d3-1478176c7d93"),
                    "5.4.0",
                ),
            ],
            sources = [],
            platform = Platform("x86_64", "freebsd"; ),
            name = "SuiteSparse",
            treehash = "fe4ced0a06144ab901913546358f7eb09e844e51",
            download_sources = [
                JLLArtifactSource(
                    "https://github.com/JuliaBinaryWrappers/SuiteSparse_jll.jl/releases/download/SuiteSparse-v7.2.0+1/SuiteSparse.v7.2.0.x86_64-unknown-freebsd.tar.gz",
                    "dd8c1af1711a24a79950370a2b83d21698a4cc6533578824be359250e208233e",
                ),
            ],
            products = [
                JLLLibraryProduct(
                    :libamd,
                    "lib/libamd.so",
                    [
                        JLLLibraryDep(nothing, :libsuitesparseconfig),
                    ],
                    [:RTLD_LAZY, :RTLD_DEEPBIND],
                ),
                JLLLibraryProduct(
                    :libbtf,
                    "lib/libbtf.so",
                    [
                        JLLLibraryDep(nothing, :libsuitesparseconfig),
                    ],
                    [:RTLD_LAZY, :RTLD_DEEPBIND],
                ),
                JLLLibraryProduct(
                    :libcamd,
                    "lib/libcamd.so",
                    [
                        JLLLibraryDep(nothing, :libsuitesparseconfig),
                    ],
                    [:RTLD_LAZY, :RTLD_DEEPBIND],
                ),
                JLLLibraryProduct(
                    :libccolamd,
                    "lib/libccolamd.so",
                    [
                        JLLLibraryDep(nothing, :libsuitesparseconfig),
                    ],
                    [:RTLD_LAZY, :RTLD_DEEPBIND],
                ),
                JLLLibraryProduct(
                    :libcholmod,
                    "lib/libcholmod.so",
                    [
                        JLLLibraryDep(nothing, :libsuitesparseconfig),
                        JLLLibraryDep(nothing, :libcolamd),
                        JLLLibraryDep(nothing, :libccolamd),
                        JLLLibraryDep(nothing, :libcamd),
                        JLLLibraryDep(nothing, :libamd),
                        JLLLibraryDep(:libblastrampoline_jll, :libblastrampoline),
                    ],
                    [:RTLD_LAZY, :RTLD_DEEPBIND],
                ),
                JLLLibraryProduct(
                    :libcolamd,
                    "lib/libcolamd.so",
                    [
                        JLLLibraryDep(nothing, :libsuitesparseconfig),
                    ],
                    [:RTLD_LAZY, :RTLD_DEEPBIND],
                ),
                JLLLibraryProduct(
                    :libklu,
                    "lib/libklu.so",
                    [
                        JLLLibraryDep(nothing, :libsuitesparseconfig),
                        JLLLibraryDep(nothing, :libamd),
                        JLLLibraryDep(nothing, :libcolamd),
                        JLLLibraryDep(nothing, :libbtf),
                    ],
                    [:RTLD_LAZY, :RTLD_DEEPBIND],
                ),
                JLLLibraryProduct(
                    :libldl,
                    "lib/libldl.so",
                    [
                        JLLLibraryDep(nothing, :libsuitesparseconfig),
                    ],
                    [:RTLD_LAZY, :RTLD_DEEPBIND],
                ),
                JLLLibraryProduct(
                    :librbio,
                    "lib/librbio.so",
                    [
                        JLLLibraryDep(nothing, :libsuitesparseconfig),
                    ],
                    [:RTLD_LAZY, :RTLD_DEEPBIND],
                ),
                JLLLibraryProduct(
                    :libspqr,
                    "lib/libspqr.so",
                    [
                        JLLLibraryDep(nothing, :libsuitesparseconfig),
                        JLLLibraryDep(nothing, :libamd),
                        JLLLibraryDep(nothing, :libcamd),
                        JLLLibraryDep(nothing, :libcholmod),
                        JLLLibraryDep(:libblastrampoline_jll, :libblastrampoline),
                    ],
                    [:RTLD_LAZY, :RTLD_DEEPBIND],
                ),
                JLLLibraryProduct(
                    :libsuitesparseconfig,
                    "lib/libsuitesparseconfig.so",
                    [],
                    [:RTLD_LAZY, :RTLD_DEEPBIND],
                ),
                JLLLibraryProduct(
                    :libumfpack,
                    "lib/libumfpack.so",
                    [
                        JLLLibraryDep(nothing, :libsuitesparseconfig),
                        JLLLibraryDep(:libblastrampoline_jll, :libblastrampoline),
                        JLLLibraryDep(nothing, :libcholmod),
                        JLLLibraryDep(nothing, :libamd),
                    ],
                    [:RTLD_LAZY, :RTLD_DEEPBIND],
                ),
            ]
        ),

        JLLArtifactInfo(;
            src_version = v"7.2.0+1",
            deps = [
                JLLPackageDependency(
                    "libblastrampoline_jll",
                    Base.UUID("8e850b90-86db-534c-a0d3-1478176c7d93"),
                    "5.4.0",
                ),
            ],
            sources = [],
            platform = Platform("x86_64", "windows"; ),
            name = "SuiteSparse",
            treehash = "d9305ffe3e6d14a5b8cf43204bfcf35d13929c79",
            download_sources = [
                JLLArtifactSource(
                    "https://github.com/JuliaBinaryWrappers/SuiteSparse_jll.jl/releases/download/SuiteSparse-v7.2.0+1/SuiteSparse.v7.2.0.x86_64-w64-mingw32.tar.gz",
                    "1dfd33b089991ae50562b6fe583e2edea51fe347f88d0d88cceb9f49cd38a5a2",
                ),
            ],
            products = [
                JLLLibraryProduct(
                    :libamd,
                    "bin\\libamd.dll",
                    [
                        JLLLibraryDep(nothing, :libsuitesparseconfig),
                    ],
                    [:RTLD_LAZY, :RTLD_DEEPBIND],
                ),
                JLLLibraryProduct(
                    :libbtf,
                    "bin\\libbtf.dll",
                    [
                        JLLLibraryDep(nothing, :libsuitesparseconfig),
                    ],
                    [:RTLD_LAZY, :RTLD_DEEPBIND],
                ),
                JLLLibraryProduct(
                    :libcamd,
                    "bin\\libcamd.dll",
                    [
                        JLLLibraryDep(nothing, :libsuitesparseconfig),
                    ],
                    [:RTLD_LAZY, :RTLD_DEEPBIND],
                ),
                JLLLibraryProduct(
                    :libccolamd,
                    "bin\\libccolamd.dll",
                    [
                        JLLLibraryDep(nothing, :libsuitesparseconfig),
                    ],
                    [:RTLD_LAZY, :RTLD_DEEPBIND],
                ),
                JLLLibraryProduct(
                    :libcholmod,
                    "bin\\libcholmod.dll",
                    [
                        JLLLibraryDep(nothing, :libsuitesparseconfig),
                        JLLLibraryDep(nothing, :libcolamd),
                        JLLLibraryDep(nothing, :libccolamd),
                        JLLLibraryDep(nothing, :libcamd),
                        JLLLibraryDep(nothing, :libamd),
                        JLLLibraryDep(:libblastrampoline_jll, :libblastrampoline),
                    ],
                    [:RTLD_LAZY, :RTLD_DEEPBIND],
                ),
                JLLLibraryProduct(
                    :libcolamd,
                    "bin\\libcolamd.dll",
                    [
                        JLLLibraryDep(nothing, :libsuitesparseconfig),
                    ],
                    [:RTLD_LAZY, :RTLD_DEEPBIND],
                ),
                JLLLibraryProduct(
                    :libklu,
                    "bin\\libklu.dll",
                    [
                        JLLLibraryDep(nothing, :libsuitesparseconfig),
                        JLLLibraryDep(nothing, :libamd),
                        JLLLibraryDep(nothing, :libcolamd),
                        JLLLibraryDep(nothing, :libbtf),
                    ],
                    [:RTLD_LAZY, :RTLD_DEEPBIND],
                ),
                JLLLibraryProduct(
                    :libldl,
                    "bin\\libldl.dll",
                    [
                        JLLLibraryDep(nothing, :libsuitesparseconfig),
                    ],
                    [:RTLD_LAZY, :RTLD_DEEPBIND],
                ),
                JLLLibraryProduct(
                    :librbio,
                    "bin\\librbio.dll",
                    [
                        JLLLibraryDep(nothing, :libsuitesparseconfig),
                    ],
                    [:RTLD_LAZY, :RTLD_DEEPBIND],
                ),
                JLLLibraryProduct(
                    :libspqr,
                    "bin\\libspqr.dll",
                    [
                        JLLLibraryDep(nothing, :libsuitesparseconfig),
                        JLLLibraryDep(nothing, :libamd),
                        JLLLibraryDep(nothing, :libcamd),
                        JLLLibraryDep(nothing, :libcholmod),
                        JLLLibraryDep(:libblastrampoline_jll, :libblastrampoline),
                    ],
                    [:RTLD_LAZY, :RTLD_DEEPBIND],
                ),
                JLLLibraryProduct(
                    :libsuitesparseconfig,
                    "bin\\libsuitesparseconfig.dll",
                    [],
                    [:RTLD_LAZY, :RTLD_DEEPBIND],
                ),
                JLLLibraryProduct(
                    :libumfpack,
                    "bin\\libumfpack.dll",
                    [
                        JLLLibraryDep(nothing, :libsuitesparseconfig),
                        JLLLibraryDep(:libblastrampoline_jll, :libblastrampoline),
                        JLLLibraryDep(nothing, :libcholmod),
                        JLLLibraryDep(nothing, :libamd),
                    ],
                    [:RTLD_LAZY, :RTLD_DEEPBIND],
                ),
            ]
        ),

    ]
)

