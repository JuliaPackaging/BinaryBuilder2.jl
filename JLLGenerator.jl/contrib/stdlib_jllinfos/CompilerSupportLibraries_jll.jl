jll = JLLInfo(;
    name = "CompilerSupportLibraries",
    version = v"1.0.5+1",
    artifacts = [
        JLLArtifactInfo(;
            src_version = v"1.0.5+1",
            deps = [],
            sources = [],
            platform = Platform("aarch64", "macos"; libgfortran_version = "5.0.0"),
            name = "default",
            treehash = "f9547d56705c03a6e887a01aeb0f0b6b030b7060",
            download_sources = [
                JLLArtifactSource(
                    "https://github.com/JuliaBinaryWrappers/CompilerSupportLibraries_jll.jl/releases/download/CompilerSupportLibraries-v1.0.5+1/CompilerSupportLibraries.v1.0.5.aarch64-apple-darwin-libgfortran5.tar.gz",
                    "c7d0330a55d3b32fbe1b6f73c43e9b9d6649f23b6d9034efd5e107b1d537ab53",
                ),
            ],
            products = [
                JLLLibraryProduct(
                    :libatomic,
                    "lib/libatomic.1.dylib",
                    [],
                    [:RTLD_LAZY, :RTLD_DEEPBIND],
                ),
                JLLLibraryProduct(
                    :libgcc_s,
                    "lib/libgcc_s.1.1.dylib",
                    [],
                    [:RTLD_LAZY, :RTLD_DEEPBIND],
                ),
                JLLLibraryProduct(
                    :libgfortran,
                    "lib/libgfortran.5.dylib",
                    [
                        JLLLibraryDep(nothing, :libgcc_s),
                        JLLLibraryDep(nothing, :libquadmath)
                    ],
                    [:RTLD_LAZY, :RTLD_DEEPBIND],
                ),
                JLLLibraryProduct(
                    :libgomp,
                    "lib/libgomp.1.dylib",
                    [],
                    [:RTLD_LAZY, :RTLD_DEEPBIND],
                ),
                JLLLibraryProduct(
                    :libssp,
                    "lib/libssp.0.dylib",
                    [],
                    [:RTLD_LAZY, :RTLD_DEEPBIND],
                ),
                JLLLibraryProduct(
                    :libstdcxx,
                    "lib/libstdc++.6.dylib",
                    [
                        JLLLibraryDep(nothing, :libgcc_s),
                    ],
                    [:RTLD_LAZY, :RTLD_DEEPBIND],
                ),
                JLLLibraryProduct(
                    :libquadmath,
                    "lib/libquadmath.6.dylib",
                    [],
                    [:RTLD_LAZY, :RTLD_DEEPBIND],
                ),
            ]
        ),

        JLLArtifactInfo(;
            src_version = v"1.0.5+1",
            deps = [],
            sources = [],
            platform = Platform("aarch64", "linux"; libgfortran_version = "3.0.0", libc = "glibc"),
            name = "default",
            treehash = "07367ce08b712728c6f409cede2b62a1cc409111",
            download_sources = [
                JLLArtifactSource(
                    "https://github.com/JuliaBinaryWrappers/CompilerSupportLibraries_jll.jl/releases/download/CompilerSupportLibraries-v1.0.5+1/CompilerSupportLibraries.v1.0.5.aarch64-linux-gnu-libgfortran3.tar.gz",
                    "9aab3427fcf68217d7ebeffbc6e216dca2ba791b641cccf7ae0ddc8b823c5298",
                ),
            ],
            products = [
                JLLLibraryProduct(
                    :libgcc_s,
                    "lib/libgcc_s.so",
                    [],
                    [:RTLD_LAZY, :RTLD_DEEPBIND],
                ),
                JLLLibraryProduct(
                    :libgfortran,
                    "lib/libgfortran.so",
                    [
                        JLLLibraryDep(nothing, :libgcc_s),
                        JLLLibraryDep(nothing, :libquadmath)
                    ],
                    [:RTLD_LAZY, :RTLD_DEEPBIND],
                ),
                JLLLibraryProduct(
                    :libgomp,
                    "lib/libgomp.so",
                    [],
                    [:RTLD_LAZY, :RTLD_DEEPBIND],
                ),
                JLLLibraryProduct(
                    :libssp,
                    "lib/libssp.so",
                    [],
                    [:RTLD_LAZY, :RTLD_DEEPBIND],
                ),
                JLLLibraryProduct(
                    :libstdcxx,
                    "lib/libstdc++.so",
                    [
                        JLLLibraryDep(nothing, :libgcc_s),
                    ],
                    [:RTLD_LAZY, :RTLD_DEEPBIND],
                ),
                JLLLibraryProduct(
                    :libquadmath,
                    "lib/libquadmath.so",
                    [],
                    [:RTLD_LAZY, :RTLD_DEEPBIND],
                ),
            ]
        ),

        JLLArtifactInfo(;
            src_version = v"1.0.5+1",
            deps = [],
            sources = [],
            platform = Platform("aarch64", "linux"; libgfortran_version = "4.0.0", libc = "glibc"),
            name = "default",
            treehash = "f03cdda9ec6cef33775d1c041a66d7e2a8b231c8",
            download_sources = [
                JLLArtifactSource(
                    "https://github.com/JuliaBinaryWrappers/CompilerSupportLibraries_jll.jl/releases/download/CompilerSupportLibraries-v1.0.5+1/CompilerSupportLibraries.v1.0.5.aarch64-linux-gnu-libgfortran4.tar.gz",
                    "822a694923ffe1214c46c929bb495c5d187d1bcb4d7e11dc4d8d0f3dd9c03da2",
                ),
            ],
            products = [
                JLLLibraryProduct(
                    :libatomic,
                    "lib/libatomic.so",
                    [],
                    [:RTLD_LAZY, :RTLD_DEEPBIND],
                ),
                JLLLibraryProduct(
                    :libgcc_s,
                    "lib/libgcc_s.so",
                    [],
                    [:RTLD_LAZY, :RTLD_DEEPBIND],
                ),
                JLLLibraryProduct(
                    :libgfortran,
                    "lib/libgfortran.so",
                    [
                        JLLLibraryDep(nothing, :libgcc_s),
                        JLLLibraryDep(nothing, :libquadmath)
                    ],
                    [:RTLD_LAZY, :RTLD_DEEPBIND],
                ),
                JLLLibraryProduct(
                    :libgomp,
                    "lib/libgomp.so",
                    [],
                    [:RTLD_LAZY, :RTLD_DEEPBIND],
                ),
                JLLLibraryProduct(
                    :libssp,
                    "lib/libssp.so",
                    [],
                    [:RTLD_LAZY, :RTLD_DEEPBIND],
                ),
                JLLLibraryProduct(
                    :libstdcxx,
                    "lib/libstdc++.so",
                    [
                        JLLLibraryDep(nothing, :libgcc_s),
                    ],
                    [:RTLD_LAZY, :RTLD_DEEPBIND],
                ),
                JLLLibraryProduct(
                    :libquadmath,
                    "lib/libquadmath.so",
                    [],
                    [:RTLD_LAZY, :RTLD_DEEPBIND],
                ),
            ]
        ),

        JLLArtifactInfo(;
            src_version = v"1.0.5+1",
            deps = [],
            sources = [],
            platform = Platform("aarch64", "linux"; libgfortran_version = "5.0.0", libc = "glibc"),
            name = "default",
            treehash = "8e8ba762012703e5cacb641ae7776bf8b3dccf1f",
            download_sources = [
                JLLArtifactSource(
                    "https://github.com/JuliaBinaryWrappers/CompilerSupportLibraries_jll.jl/releases/download/CompilerSupportLibraries-v1.0.5+1/CompilerSupportLibraries.v1.0.5.aarch64-linux-gnu-libgfortran5.tar.gz",
                    "6927f19dc3aaaeca5a064b3aa9498f50d09b00af5f7947961ac92f7384236695",
                ),
            ],
            products = [
                JLLLibraryProduct(
                    :libatomic,
                    "lib/libatomic.so",
                    [],
                    [:RTLD_LAZY, :RTLD_DEEPBIND],
                ),
                JLLLibraryProduct(
                    :libgcc_s,
                    "lib/libgcc_s.so.1",
                    [],
                    [:RTLD_LAZY, :RTLD_DEEPBIND],
                ),
                JLLLibraryProduct(
                    :libgfortran,
                    "lib/libgfortran.so",
                    [
                        JLLLibraryDep(nothing, :libgcc_s),
                        JLLLibraryDep(nothing, :libquadmath)
                    ],
                    [:RTLD_LAZY, :RTLD_DEEPBIND],
                ),
                JLLLibraryProduct(
                    :libgomp,
                    "lib/libgomp.so",
                    [],
                    [:RTLD_LAZY, :RTLD_DEEPBIND],
                ),
                JLLLibraryProduct(
                    :libssp,
                    "lib/libssp.so",
                    [],
                    [:RTLD_LAZY, :RTLD_DEEPBIND],
                ),
                JLLLibraryProduct(
                    :libstdcxx,
                    "lib/libstdc++.so",
                    [
                        JLLLibraryDep(nothing, :libgcc_s),
                    ],
                    [:RTLD_LAZY, :RTLD_DEEPBIND],
                ),
                JLLLibraryProduct(
                    :libquadmath,
                    "lib/libquadmath.so",
                    [],
                    [:RTLD_LAZY, :RTLD_DEEPBIND],
                ),
            ]
        ),

        JLLArtifactInfo(;
            src_version = v"1.0.5+1",
            deps = [],
            sources = [],
            platform = Platform("aarch64", "linux"; libgfortran_version = "3.0.0", libc = "musl"),
            name = "default",
            treehash = "0fb87bd5bbd72fdf4d5bd91633cb3849cee11d09",
            download_sources = [
                JLLArtifactSource(
                    "https://github.com/JuliaBinaryWrappers/CompilerSupportLibraries_jll.jl/releases/download/CompilerSupportLibraries-v1.0.5+1/CompilerSupportLibraries.v1.0.5.aarch64-linux-musl-libgfortran3.tar.gz",
                    "4f7e7de5a43cab303c7a435cf59dcc22895e63508f2811945aa00513ae04992f",
                ),
            ],
            products = [
                JLLLibraryProduct(
                    :libgcc_s,
                    "lib/libgcc_s.so",
                    [],
                    [:RTLD_LAZY, :RTLD_DEEPBIND],
                ),
                JLLLibraryProduct(
                    :libgfortran,
                    "lib/libgfortran.so",
                    [
                        JLLLibraryDep(nothing, :libgcc_s),
                        JLLLibraryDep(nothing, :libquadmath)
                    ],
                    [:RTLD_LAZY, :RTLD_DEEPBIND],
                ),
                JLLLibraryProduct(
                    :libgomp,
                    "lib/libgomp.so",
                    [],
                    [:RTLD_LAZY, :RTLD_DEEPBIND],
                ),
                JLLLibraryProduct(
                    :libstdcxx,
                    "lib/libstdc++.so",
                    [
                        JLLLibraryDep(nothing, :libgcc_s),
                    ],
                    [:RTLD_LAZY, :RTLD_DEEPBIND],
                ),
                JLLLibraryProduct(
                    :libquadmath,
                    "lib/libquadmath.so",
                    [],
                    [:RTLD_LAZY, :RTLD_DEEPBIND],
                ),
            ]
        ),

        JLLArtifactInfo(;
            src_version = v"1.0.5+1",
            deps = [],
            sources = [],
            platform = Platform("aarch64", "linux"; libgfortran_version = "4.0.0", libc = "musl"),
            name = "default",
            treehash = "165dc4dc524f971743345d1adaffa16315654ddf",
            download_sources = [
                JLLArtifactSource(
                    "https://github.com/JuliaBinaryWrappers/CompilerSupportLibraries_jll.jl/releases/download/CompilerSupportLibraries-v1.0.5+1/CompilerSupportLibraries.v1.0.5.aarch64-linux-musl-libgfortran4.tar.gz",
                    "6e054df3cd3222a1860e295a78795e8ad63bd8f3b8320db5d9cd733be86c0006",
                ),
            ],
            products = [
                JLLLibraryProduct(
                    :libatomic,
                    "lib/libatomic.so",
                    [],
                    [:RTLD_LAZY, :RTLD_DEEPBIND],
                ),
                JLLLibraryProduct(
                    :libgcc_s,
                    "lib/libgcc_s.so",
                    [],
                    [:RTLD_LAZY, :RTLD_DEEPBIND],
                ),
                JLLLibraryProduct(
                    :libgfortran,
                    "lib/libgfortran.so",
                    [
                        JLLLibraryDep(nothing, :libgcc_s),
                        JLLLibraryDep(nothing, :libquadmath)
                    ],
                    [:RTLD_LAZY, :RTLD_DEEPBIND],
                ),
                JLLLibraryProduct(
                    :libgomp,
                    "lib/libgomp.so",
                    [],
                    [:RTLD_LAZY, :RTLD_DEEPBIND],
                ),
                JLLLibraryProduct(
                    :libstdcxx,
                    "lib/libstdc++.so",
                    [
                        JLLLibraryDep(nothing, :libgcc_s),
                    ],
                    [:RTLD_LAZY, :RTLD_DEEPBIND],
                ),
                JLLLibraryProduct(
                    :libquadmath,
                    "lib/libquadmath.so",
                    [],
                    [:RTLD_LAZY, :RTLD_DEEPBIND],
                ),
            ]
        ),

        JLLArtifactInfo(;
            src_version = v"1.0.5+1",
            deps = [],
            sources = [],
            platform = Platform("aarch64", "linux"; libgfortran_version = "5.0.0", libc = "musl"),
            name = "default",
            treehash = "ebd8ede84f0551a3b1cf43c9c8689c0c224dfbc2",
            download_sources = [
                JLLArtifactSource(
                    "https://github.com/JuliaBinaryWrappers/CompilerSupportLibraries_jll.jl/releases/download/CompilerSupportLibraries-v1.0.5+1/CompilerSupportLibraries.v1.0.5.aarch64-linux-musl-libgfortran5.tar.gz",
                    "11bd7dfb194ea256f12c3eda0a5101a92dfaf60b68298fa15ca99ba5fc799bcd",
                ),
            ],
            products = [
                JLLLibraryProduct(
                    :libatomic,
                    "lib/libatomic.so",
                    [],
                    [:RTLD_LAZY, :RTLD_DEEPBIND],
                ),
                JLLLibraryProduct(
                    :libgcc_s,
                    "lib/libgcc_s.so.1",
                    [],
                    [:RTLD_LAZY, :RTLD_DEEPBIND],
                ),
                JLLLibraryProduct(
                    :libgfortran,
                    "lib/libgfortran.so",
                    [
                        JLLLibraryDep(nothing, :libgcc_s),
                        JLLLibraryDep(nothing, :libquadmath)
                    ],
                    [:RTLD_LAZY, :RTLD_DEEPBIND],
                ),
                JLLLibraryProduct(
                    :libgomp,
                    "lib/libgomp.so",
                    [],
                    [:RTLD_LAZY, :RTLD_DEEPBIND],
                ),
                JLLLibraryProduct(
                    :libstdcxx,
                    "lib/libstdc++.so",
                    [
                        JLLLibraryDep(nothing, :libgcc_s),
                    ],
                    [:RTLD_LAZY, :RTLD_DEEPBIND],
                ),
                JLLLibraryProduct(
                    :libquadmath,
                    "lib/libquadmath.so",
                    [],
                    [:RTLD_LAZY, :RTLD_DEEPBIND],
                ),
            ]
        ),

        JLLArtifactInfo(;
            src_version = v"1.0.5+1",
            deps = [],
            sources = [],
            platform = Platform("armv6l", "linux"; libgfortran_version = "3.0.0", call_abi = "eabihf", libc = "glibc"),
            name = "default",
            treehash = "34d3f5e147532a5d21b1eac23684da7fe8cf0ace",
            download_sources = [
                JLLArtifactSource(
                    "https://github.com/JuliaBinaryWrappers/CompilerSupportLibraries_jll.jl/releases/download/CompilerSupportLibraries-v1.0.5+1/CompilerSupportLibraries.v1.0.5.armv6l-linux-gnueabihf-libgfortran3.tar.gz",
                    "5d39a9d5dc51c637ece643699b75ee48a0afb198c6fd9102a04c10c3640ad4fe",
                ),
            ],
            products = [
                JLLLibraryProduct(
                    :libatomic,
                    "lib/libatomic.so",
                    [],
                    [:RTLD_LAZY, :RTLD_DEEPBIND],
                ),
                JLLLibraryProduct(
                    :libgcc_s,
                    "lib/libgcc_s.so.1",
                    [],
                    [:RTLD_LAZY, :RTLD_DEEPBIND],
                ),
                JLLLibraryProduct(
                    :libgfortran,
                    "lib/libgfortran.so",
                    [
                        JLLLibraryDep(nothing, :libgcc_s),
                        JLLLibraryDep(nothing, :libquadmath)
                    ],
                    [:RTLD_LAZY, :RTLD_DEEPBIND],
                ),
                JLLLibraryProduct(
                    :libgomp,
                    "lib/libgomp.so",
                    [],
                    [:RTLD_LAZY, :RTLD_DEEPBIND],
                ),
                JLLLibraryProduct(
                    :libssp,
                    "lib/libssp.so",
                    [],
                    [:RTLD_LAZY, :RTLD_DEEPBIND],
                ),
                JLLLibraryProduct(
                    :libstdcxx,
                    "lib/libstdc++.so",
                    [
                        JLLLibraryDep(nothing, :libgcc_s),
                    ],
                    [:RTLD_LAZY, :RTLD_DEEPBIND],
                ),
                JLLLibraryProduct(
                    :libquadmath,
                    "lib/libquadmath.so",
                    [],
                    [:RTLD_LAZY, :RTLD_DEEPBIND],
                ),
            ]
        ),

        JLLArtifactInfo(;
            src_version = v"1.0.5+1",
            deps = [],
            sources = [],
            platform = Platform("armv6l", "linux"; libgfortran_version = "4.0.0", call_abi = "eabihf", libc = "glibc"),
            name = "default",
            treehash = "5e53206751e1e82da943e31903553390d1a0f6db",
            download_sources = [
                JLLArtifactSource(
                    "https://github.com/JuliaBinaryWrappers/CompilerSupportLibraries_jll.jl/releases/download/CompilerSupportLibraries-v1.0.5+1/CompilerSupportLibraries.v1.0.5.armv6l-linux-gnueabihf-libgfortran4.tar.gz",
                    "64e6fde622961608010982587de46a1970d5a55678b83a7de003fa9e3125a955",
                ),
            ],
            products = [
                JLLLibraryProduct(
                    :libatomic,
                    "lib/libatomic.so",
                    [],
                    [:RTLD_LAZY, :RTLD_DEEPBIND],
                ),
                JLLLibraryProduct(
                    :libgcc_s,
                    "lib/libgcc_s.so.1",
                    [],
                    [:RTLD_LAZY, :RTLD_DEEPBIND],
                ),
                JLLLibraryProduct(
                    :libgfortran,
                    "lib/libgfortran.so",
                    [
                        JLLLibraryDep(nothing, :libgcc_s),
                        JLLLibraryDep(nothing, :libquadmath)
                    ],
                    [:RTLD_LAZY, :RTLD_DEEPBIND],
                ),
                JLLLibraryProduct(
                    :libgomp,
                    "lib/libgomp.so",
                    [],
                    [:RTLD_LAZY, :RTLD_DEEPBIND],
                ),
                JLLLibraryProduct(
                    :libssp,
                    "lib/libssp.so",
                    [],
                    [:RTLD_LAZY, :RTLD_DEEPBIND],
                ),
                JLLLibraryProduct(
                    :libstdcxx,
                    "lib/libstdc++.so",
                    [
                        JLLLibraryDep(nothing, :libgcc_s),
                    ],
                    [:RTLD_LAZY, :RTLD_DEEPBIND],
                ),
                JLLLibraryProduct(
                    :libquadmath,
                    "lib/libquadmath.so",
                    [],
                    [:RTLD_LAZY, :RTLD_DEEPBIND],
                ),
            ]
        ),

        JLLArtifactInfo(;
            src_version = v"1.0.5+1",
            deps = [],
            sources = [],
            platform = Platform("armv6l", "linux"; libgfortran_version = "5.0.0", call_abi = "eabihf", libc = "glibc"),
            name = "default",
            treehash = "f11a091fb4502ae0026494d19752a0797034d096",
            download_sources = [
                JLLArtifactSource(
                    "https://github.com/JuliaBinaryWrappers/CompilerSupportLibraries_jll.jl/releases/download/CompilerSupportLibraries-v1.0.5+1/CompilerSupportLibraries.v1.0.5.armv6l-linux-gnueabihf-libgfortran5.tar.gz",
                    "2d3492244bdbd59a7fcde087555037340eecbe0d2d82904f5b07503db38f6abd",
                ),
            ],
            products = [
                JLLLibraryProduct(
                    :libatomic,
                    "lib/libatomic.so",
                    [],
                    [:RTLD_LAZY, :RTLD_DEEPBIND],
                ),
                JLLLibraryProduct(
                    :libgcc_s,
                    "lib/libgcc_s.so.1",
                    [],
                    [:RTLD_LAZY, :RTLD_DEEPBIND],
                ),
                JLLLibraryProduct(
                    :libgfortran,
                    "lib/libgfortran.so",
                    [
                        JLLLibraryDep(nothing, :libgcc_s),
                        JLLLibraryDep(nothing, :libquadmath)
                    ],
                    [:RTLD_LAZY, :RTLD_DEEPBIND],
                ),
                JLLLibraryProduct(
                    :libgomp,
                    "lib/libgomp.so",
                    [],
                    [:RTLD_LAZY, :RTLD_DEEPBIND],
                ),
                JLLLibraryProduct(
                    :libssp,
                    "lib/libssp.so",
                    [],
                    [:RTLD_LAZY, :RTLD_DEEPBIND],
                ),
                JLLLibraryProduct(
                    :libstdcxx,
                    "lib/libstdc++.so",
                    [
                        JLLLibraryDep(nothing, :libgcc_s),
                    ],
                    [:RTLD_LAZY, :RTLD_DEEPBIND],
                ),
                JLLLibraryProduct(
                    :libquadmath,
                    "lib/libquadmath.so",
                    [],
                    [:RTLD_LAZY, :RTLD_DEEPBIND],
                ),
            ]
        ),

        JLLArtifactInfo(;
            src_version = v"1.0.5+1",
            deps = [],
            sources = [],
            platform = Platform("armv6l", "linux"; libgfortran_version = "3.0.0", call_abi = "eabihf", libc = "musl"),
            name = "default",
            treehash = "75b85f7a799b832084dd9df223fdc8298a3f8fd1",
            download_sources = [
                JLLArtifactSource(
                    "https://github.com/JuliaBinaryWrappers/CompilerSupportLibraries_jll.jl/releases/download/CompilerSupportLibraries-v1.0.5+1/CompilerSupportLibraries.v1.0.5.armv6l-linux-musleabihf-libgfortran3.tar.gz",
                    "5ae6aec1b15bfb69435cda6ab5dd32216cce86237b38153fc1e8dda8fb26c1bc",
                ),
            ],
            products = [
                JLLLibraryProduct(
                    :libatomic,
                    "lib/libatomic.so",
                    [],
                    [:RTLD_LAZY, :RTLD_DEEPBIND],
                ),
                JLLLibraryProduct(
                    :libgcc_s,
                    "lib/libgcc_s.so.1",
                    [],
                    [:RTLD_LAZY, :RTLD_DEEPBIND],
                ),
                JLLLibraryProduct(
                    :libgfortran,
                    "lib/libgfortran.so",
                    [
                        JLLLibraryDep(nothing, :libgcc_s),
                        JLLLibraryDep(nothing, :libquadmath)
                    ],
                    [:RTLD_LAZY, :RTLD_DEEPBIND],
                ),
                JLLLibraryProduct(
                    :libgomp,
                    "lib/libgomp.so",
                    [],
                    [:RTLD_LAZY, :RTLD_DEEPBIND],
                ),
                JLLLibraryProduct(
                    :libstdcxx,
                    "lib/libstdc++.so",
                    [
                        JLLLibraryDep(nothing, :libgcc_s),
                    ],
                    [:RTLD_LAZY, :RTLD_DEEPBIND],
                ),
                JLLLibraryProduct(
                    :libquadmath,
                    "lib/libquadmath.so",
                    [],
                    [:RTLD_LAZY, :RTLD_DEEPBIND],
                ),
            ]
        ),

        JLLArtifactInfo(;
            src_version = v"1.0.5+1",
            deps = [],
            sources = [],
            platform = Platform("armv6l", "linux"; libgfortran_version = "4.0.0", call_abi = "eabihf", libc = "musl"),
            name = "default",
            treehash = "56c37e4d7d9d1966154922477e9ae50a8e92880f",
            download_sources = [
                JLLArtifactSource(
                    "https://github.com/JuliaBinaryWrappers/CompilerSupportLibraries_jll.jl/releases/download/CompilerSupportLibraries-v1.0.5+1/CompilerSupportLibraries.v1.0.5.armv6l-linux-musleabihf-libgfortran4.tar.gz",
                    "9219b9b0af4615b13a0ac7b0fed7f5a09e414cebf69852861619db46fdeeecd9",
                ),
            ],
            products = [
                JLLLibraryProduct(
                    :libatomic,
                    "lib/libatomic.so",
                    [],
                    [:RTLD_LAZY, :RTLD_DEEPBIND],
                ),
                JLLLibraryProduct(
                    :libgcc_s,
                    "lib/libgcc_s.so.1",
                    [],
                    [:RTLD_LAZY, :RTLD_DEEPBIND],
                ),
                JLLLibraryProduct(
                    :libgfortran,
                    "lib/libgfortran.so",
                    [
                        JLLLibraryDep(nothing, :libgcc_s),
                        JLLLibraryDep(nothing, :libquadmath)
                    ],
                    [:RTLD_LAZY, :RTLD_DEEPBIND],
                ),
                JLLLibraryProduct(
                    :libgomp,
                    "lib/libgomp.so",
                    [],
                    [:RTLD_LAZY, :RTLD_DEEPBIND],
                ),
                JLLLibraryProduct(
                    :libstdcxx,
                    "lib/libstdc++.so",
                    [
                        JLLLibraryDep(nothing, :libgcc_s),
                    ],
                    [:RTLD_LAZY, :RTLD_DEEPBIND],
                ),
                JLLLibraryProduct(
                    :libquadmath,
                    "lib/libquadmath.so",
                    [],
                    [:RTLD_LAZY, :RTLD_DEEPBIND],
                ),
            ]
        ),

        JLLArtifactInfo(;
            src_version = v"1.0.5+1",
            deps = [],
            sources = [],
            platform = Platform("armv6l", "linux"; libgfortran_version = "5.0.0", call_abi = "eabihf", libc = "musl"),
            name = "default",
            treehash = "1fb18c2b9ee3527b1044141bc8bce17ac89172ed",
            download_sources = [
                JLLArtifactSource(
                    "https://github.com/JuliaBinaryWrappers/CompilerSupportLibraries_jll.jl/releases/download/CompilerSupportLibraries-v1.0.5+1/CompilerSupportLibraries.v1.0.5.armv6l-linux-musleabihf-libgfortran5.tar.gz",
                    "b89f6dbd73449a99a1dac4377f3e8faecb8bad1d32ae4f06c03f9435b1d7006e",
                ),
            ],
            products = [
                JLLLibraryProduct(
                    :libatomic,
                    "lib/libatomic.so",
                    [],
                    [:RTLD_LAZY, :RTLD_DEEPBIND],
                ),
                JLLLibraryProduct(
                    :libgcc_s,
                    "lib/libgcc_s.so.1",
                    [],
                    [:RTLD_LAZY, :RTLD_DEEPBIND],
                ),
                JLLLibraryProduct(
                    :libgfortran,
                    "lib/libgfortran.so",
                    [
                        JLLLibraryDep(nothing, :libgcc_s),
                        JLLLibraryDep(nothing, :libquadmath)
                    ],
                    [:RTLD_LAZY, :RTLD_DEEPBIND],
                ),
                JLLLibraryProduct(
                    :libgomp,
                    "lib/libgomp.so",
                    [],
                    [:RTLD_LAZY, :RTLD_DEEPBIND],
                ),
                JLLLibraryProduct(
                    :libstdcxx,
                    "lib/libstdc++.so",
                    [
                        JLLLibraryDep(nothing, :libgcc_s),
                    ],
                    [:RTLD_LAZY, :RTLD_DEEPBIND],
                ),
                JLLLibraryProduct(
                    :libquadmath,
                    "lib/libquadmath.so",
                    [],
                    [:RTLD_LAZY, :RTLD_DEEPBIND],
                ),
            ]
        ),

        JLLArtifactInfo(;
            src_version = v"1.0.5+1",
            deps = [],
            sources = [],
            platform = Platform("armv7l", "linux"; libgfortran_version = "3.0.0", call_abi = "eabihf", libc = "glibc"),
            name = "default",
            treehash = "34d3f5e147532a5d21b1eac23684da7fe8cf0ace",
            download_sources = [
                JLLArtifactSource(
                    "https://github.com/JuliaBinaryWrappers/CompilerSupportLibraries_jll.jl/releases/download/CompilerSupportLibraries-v1.0.5+1/CompilerSupportLibraries.v1.0.5.armv7l-linux-gnueabihf-libgfortran3.tar.gz",
                    "5d39a9d5dc51c637ece643699b75ee48a0afb198c6fd9102a04c10c3640ad4fe",
                ),
            ],
            products = [
                JLLLibraryProduct(
                    :libatomic,
                    "lib/libatomic.so",
                    [],
                    [:RTLD_LAZY, :RTLD_DEEPBIND],
                ),
                JLLLibraryProduct(
                    :libgcc_s,
                    "lib/libgcc_s.so.1",
                    [],
                    [:RTLD_LAZY, :RTLD_DEEPBIND],
                ),
                JLLLibraryProduct(
                    :libgfortran,
                    "lib/libgfortran.so",
                    [
                        JLLLibraryDep(nothing, :libgcc_s),
                        JLLLibraryDep(nothing, :libquadmath)
                    ],
                    [:RTLD_LAZY, :RTLD_DEEPBIND],
                ),
                JLLLibraryProduct(
                    :libgomp,
                    "lib/libgomp.so",
                    [],
                    [:RTLD_LAZY, :RTLD_DEEPBIND],
                ),
                JLLLibraryProduct(
                    :libssp,
                    "lib/libssp.so",
                    [],
                    [:RTLD_LAZY, :RTLD_DEEPBIND],
                ),
                JLLLibraryProduct(
                    :libstdcxx,
                    "lib/libstdc++.so",
                    [
                        JLLLibraryDep(nothing, :libgcc_s),
                    ],
                    [:RTLD_LAZY, :RTLD_DEEPBIND],
                ),
                JLLLibraryProduct(
                    :libquadmath,
                    "lib/libquadmath.so",
                    [],
                    [:RTLD_LAZY, :RTLD_DEEPBIND],
                ),
            ]
        ),

        JLLArtifactInfo(;
            src_version = v"1.0.5+1",
            deps = [],
            sources = [],
            platform = Platform("armv7l", "linux"; libgfortran_version = "4.0.0", call_abi = "eabihf", libc = "glibc"),
            name = "default",
            treehash = "5e53206751e1e82da943e31903553390d1a0f6db",
            download_sources = [
                JLLArtifactSource(
                    "https://github.com/JuliaBinaryWrappers/CompilerSupportLibraries_jll.jl/releases/download/CompilerSupportLibraries-v1.0.5+1/CompilerSupportLibraries.v1.0.5.armv7l-linux-gnueabihf-libgfortran4.tar.gz",
                    "64e6fde622961608010982587de46a1970d5a55678b83a7de003fa9e3125a955",
                ),
            ],
            products = [
                JLLLibraryProduct(
                    :libatomic,
                    "lib/libatomic.so",
                    [],
                    [:RTLD_LAZY, :RTLD_DEEPBIND],
                ),
                JLLLibraryProduct(
                    :libgcc_s,
                    "lib/libgcc_s.so.1",
                    [],
                    [:RTLD_LAZY, :RTLD_DEEPBIND],
                ),
                JLLLibraryProduct(
                    :libgfortran,
                    "lib/libgfortran.so",
                    [
                        JLLLibraryDep(nothing, :libgcc_s),
                        JLLLibraryDep(nothing, :libquadmath)
                    ],
                    [:RTLD_LAZY, :RTLD_DEEPBIND],
                ),
                JLLLibraryProduct(
                    :libgomp,
                    "lib/libgomp.so",
                    [],
                    [:RTLD_LAZY, :RTLD_DEEPBIND],
                ),
                JLLLibraryProduct(
                    :libssp,
                    "lib/libssp.so",
                    [],
                    [:RTLD_LAZY, :RTLD_DEEPBIND],
                ),
                JLLLibraryProduct(
                    :libstdcxx,
                    "lib/libstdc++.so",
                    [
                        JLLLibraryDep(nothing, :libgcc_s),
                    ],
                    [:RTLD_LAZY, :RTLD_DEEPBIND],
                ),
                JLLLibraryProduct(
                    :libquadmath,
                    "lib/libquadmath.so",
                    [],
                    [:RTLD_LAZY, :RTLD_DEEPBIND],
                ),
            ]
        ),

        JLLArtifactInfo(;
            src_version = v"1.0.5+1",
            deps = [],
            sources = [],
            platform = Platform("armv7l", "linux"; libgfortran_version = "5.0.0", call_abi = "eabihf", libc = "glibc"),
            name = "default",
            treehash = "f11a091fb4502ae0026494d19752a0797034d096",
            download_sources = [
                JLLArtifactSource(
                    "https://github.com/JuliaBinaryWrappers/CompilerSupportLibraries_jll.jl/releases/download/CompilerSupportLibraries-v1.0.5+1/CompilerSupportLibraries.v1.0.5.armv7l-linux-gnueabihf-libgfortran5.tar.gz",
                    "2d3492244bdbd59a7fcde087555037340eecbe0d2d82904f5b07503db38f6abd",
                ),
            ],
            products = [
                JLLLibraryProduct(
                    :libatomic,
                    "lib/libatomic.so",
                    [],
                    [:RTLD_LAZY, :RTLD_DEEPBIND],
                ),
                JLLLibraryProduct(
                    :libgcc_s,
                    "lib/libgcc_s.so.1",
                    [],
                    [:RTLD_LAZY, :RTLD_DEEPBIND],
                ),
                JLLLibraryProduct(
                    :libgfortran,
                    "lib/libgfortran.so",
                    [
                        JLLLibraryDep(nothing, :libgcc_s),
                        JLLLibraryDep(nothing, :libquadmath)
                    ],
                    [:RTLD_LAZY, :RTLD_DEEPBIND],
                ),
                JLLLibraryProduct(
                    :libgomp,
                    "lib/libgomp.so",
                    [],
                    [:RTLD_LAZY, :RTLD_DEEPBIND],
                ),
                JLLLibraryProduct(
                    :libssp,
                    "lib/libssp.so",
                    [],
                    [:RTLD_LAZY, :RTLD_DEEPBIND],
                ),
                JLLLibraryProduct(
                    :libstdcxx,
                    "lib/libstdc++.so",
                    [
                        JLLLibraryDep(nothing, :libgcc_s),
                    ],
                    [:RTLD_LAZY, :RTLD_DEEPBIND],
                ),
                JLLLibraryProduct(
                    :libquadmath,
                    "lib/libquadmath.so",
                    [],
                    [:RTLD_LAZY, :RTLD_DEEPBIND],
                ),
            ]
        ),

        JLLArtifactInfo(;
            src_version = v"1.0.5+1",
            deps = [],
            sources = [],
            platform = Platform("armv7l", "linux"; libgfortran_version = "3.0.0", call_abi = "eabihf", libc = "musl"),
            name = "default",
            treehash = "75b85f7a799b832084dd9df223fdc8298a3f8fd1",
            download_sources = [
                JLLArtifactSource(
                    "https://github.com/JuliaBinaryWrappers/CompilerSupportLibraries_jll.jl/releases/download/CompilerSupportLibraries-v1.0.5+1/CompilerSupportLibraries.v1.0.5.armv7l-linux-musleabihf-libgfortran3.tar.gz",
                    "5ae6aec1b15bfb69435cda6ab5dd32216cce86237b38153fc1e8dda8fb26c1bc",
                ),
            ],
            products = [
                JLLLibraryProduct(
                    :libatomic,
                    "lib/libatomic.so",
                    [],
                    [:RTLD_LAZY, :RTLD_DEEPBIND],
                ),
                JLLLibraryProduct(
                    :libgcc_s,
                    "lib/libgcc_s.so.1",
                    [],
                    [:RTLD_LAZY, :RTLD_DEEPBIND],
                ),
                JLLLibraryProduct(
                    :libgfortran,
                    "lib/libgfortran.so",
                    [
                        JLLLibraryDep(nothing, :libgcc_s),
                        JLLLibraryDep(nothing, :libquadmath)
                    ],
                    [:RTLD_LAZY, :RTLD_DEEPBIND],
                ),
                JLLLibraryProduct(
                    :libgomp,
                    "lib/libgomp.so",
                    [],
                    [:RTLD_LAZY, :RTLD_DEEPBIND],
                ),
                JLLLibraryProduct(
                    :libstdcxx,
                    "lib/libstdc++.so",
                    [
                        JLLLibraryDep(nothing, :libgcc_s),
                    ],
                    [:RTLD_LAZY, :RTLD_DEEPBIND],
                ),
                JLLLibraryProduct(
                    :libquadmath,
                    "lib/libquadmath.so",
                    [],
                    [:RTLD_LAZY, :RTLD_DEEPBIND],
                ),
            ]
        ),

        JLLArtifactInfo(;
            src_version = v"1.0.5+1",
            deps = [],
            sources = [],
            platform = Platform("armv7l", "linux"; libgfortran_version = "4.0.0", call_abi = "eabihf", libc = "musl"),
            name = "default",
            treehash = "56c37e4d7d9d1966154922477e9ae50a8e92880f",
            download_sources = [
                JLLArtifactSource(
                    "https://github.com/JuliaBinaryWrappers/CompilerSupportLibraries_jll.jl/releases/download/CompilerSupportLibraries-v1.0.5+1/CompilerSupportLibraries.v1.0.5.armv7l-linux-musleabihf-libgfortran4.tar.gz",
                    "9219b9b0af4615b13a0ac7b0fed7f5a09e414cebf69852861619db46fdeeecd9",
                ),
            ],
            products = [
                JLLLibraryProduct(
                    :libatomic,
                    "lib/libatomic.so",
                    [],
                    [:RTLD_LAZY, :RTLD_DEEPBIND],
                ),
                JLLLibraryProduct(
                    :libgcc_s,
                    "lib/libgcc_s.so.1",
                    [],
                    [:RTLD_LAZY, :RTLD_DEEPBIND],
                ),
                JLLLibraryProduct(
                    :libgfortran,
                    "lib/libgfortran.so",
                    [
                        JLLLibraryDep(nothing, :libgcc_s),
                        JLLLibraryDep(nothing, :libquadmath)
                    ],
                    [:RTLD_LAZY, :RTLD_DEEPBIND],
                ),
                JLLLibraryProduct(
                    :libgomp,
                    "lib/libgomp.so",
                    [],
                    [:RTLD_LAZY, :RTLD_DEEPBIND],
                ),
                JLLLibraryProduct(
                    :libstdcxx,
                    "lib/libstdc++.so",
                    [
                        JLLLibraryDep(nothing, :libgcc_s),
                    ],
                    [:RTLD_LAZY, :RTLD_DEEPBIND],
                ),
                JLLLibraryProduct(
                    :libquadmath,
                    "lib/libquadmath.so",
                    [],
                    [:RTLD_LAZY, :RTLD_DEEPBIND],
                ),
            ]
        ),

        JLLArtifactInfo(;
            src_version = v"1.0.5+1",
            deps = [],
            sources = [],
            platform = Platform("armv7l", "linux"; libgfortran_version = "5.0.0", call_abi = "eabihf", libc = "musl"),
            name = "default",
            treehash = "1fb18c2b9ee3527b1044141bc8bce17ac89172ed",
            download_sources = [
                JLLArtifactSource(
                    "https://github.com/JuliaBinaryWrappers/CompilerSupportLibraries_jll.jl/releases/download/CompilerSupportLibraries-v1.0.5+1/CompilerSupportLibraries.v1.0.5.armv7l-linux-musleabihf-libgfortran5.tar.gz",
                    "b89f6dbd73449a99a1dac4377f3e8faecb8bad1d32ae4f06c03f9435b1d7006e",
                ),
            ],
            products = [
                JLLLibraryProduct(
                    :libatomic,
                    "lib/libatomic.so",
                    [],
                    [:RTLD_LAZY, :RTLD_DEEPBIND],
                ),
                JLLLibraryProduct(
                    :libgcc_s,
                    "lib/libgcc_s.so.1",
                    [],
                    [:RTLD_LAZY, :RTLD_DEEPBIND],
                ),
                JLLLibraryProduct(
                    :libgfortran,
                    "lib/libgfortran.so",
                    [
                        JLLLibraryDep(nothing, :libgcc_s),
                        JLLLibraryDep(nothing, :libquadmath)
                    ],
                    [:RTLD_LAZY, :RTLD_DEEPBIND],
                ),
                JLLLibraryProduct(
                    :libgomp,
                    "lib/libgomp.so",
                    [],
                    [:RTLD_LAZY, :RTLD_DEEPBIND],
                ),
                JLLLibraryProduct(
                    :libstdcxx,
                    "lib/libstdc++.so",
                    [
                        JLLLibraryDep(nothing, :libgcc_s),
                    ],
                    [:RTLD_LAZY, :RTLD_DEEPBIND],
                ),
                JLLLibraryProduct(
                    :libquadmath,
                    "lib/libquadmath.so",
                    [],
                    [:RTLD_LAZY, :RTLD_DEEPBIND],
                ),
            ]
        ),

        JLLArtifactInfo(;
            src_version = v"1.0.5+1",
            deps = [],
            sources = [],
            platform = Platform("i686", "linux"; libgfortran_version = "3.0.0", libc = "glibc"),
            name = "default",
            treehash = "e462389dcbe3386fd8e87b223f9a5e9c009a00c5",
            download_sources = [
                JLLArtifactSource(
                    "https://github.com/JuliaBinaryWrappers/CompilerSupportLibraries_jll.jl/releases/download/CompilerSupportLibraries-v1.0.5+1/CompilerSupportLibraries.v1.0.5.i686-linux-gnu-libgfortran3.tar.gz",
                    "00957a41b398f11d7ac57cf97864c73c1e64b18c3536280b175abefbbfc34208",
                ),
            ],
            products = [
                JLLLibraryProduct(
                    :libatomic,
                    "lib/libatomic.so",
                    [],
                    [:RTLD_LAZY, :RTLD_DEEPBIND],
                ),
                JLLLibraryProduct(
                    :libgcc_s,
                    "lib/libgcc_s.so.1",
                    [],
                    [:RTLD_LAZY, :RTLD_DEEPBIND],
                ),
                JLLLibraryProduct(
                    :libgfortran,
                    "lib/libgfortran.so",
                    [
                        JLLLibraryDep(nothing, :libgcc_s),
                        JLLLibraryDep(nothing, :libquadmath)
                    ],
                    [:RTLD_LAZY, :RTLD_DEEPBIND],
                ),
                JLLLibraryProduct(
                    :libgomp,
                    "lib/libgomp.so",
                    [],
                    [:RTLD_LAZY, :RTLD_DEEPBIND],
                ),
                JLLLibraryProduct(
                    :libssp,
                    "lib/libssp.so",
                    [],
                    [:RTLD_LAZY, :RTLD_DEEPBIND],
                ),
                JLLLibraryProduct(
                    :libstdcxx,
                    "lib/libstdc++.so",
                    [
                        JLLLibraryDep(nothing, :libgcc_s),
                    ],
                    [:RTLD_LAZY, :RTLD_DEEPBIND],
                ),
                JLLLibraryProduct(
                    :libquadmath,
                    "lib/libquadmath.so",
                    [],
                    [:RTLD_LAZY, :RTLD_DEEPBIND],
                ),
            ]
        ),

        JLLArtifactInfo(;
            src_version = v"1.0.5+1",
            deps = [],
            sources = [],
            platform = Platform("i686", "linux"; libgfortran_version = "4.0.0", libc = "glibc"),
            name = "default",
            treehash = "557781bb71df5d843f884e6cba537967a0c88252",
            download_sources = [
                JLLArtifactSource(
                    "https://github.com/JuliaBinaryWrappers/CompilerSupportLibraries_jll.jl/releases/download/CompilerSupportLibraries-v1.0.5+1/CompilerSupportLibraries.v1.0.5.i686-linux-gnu-libgfortran4.tar.gz",
                    "e53e3dd0e875b353c8982381915c297a456840d897d62a9040d718536c0da084",
                ),
            ],
            products = [
                JLLLibraryProduct(
                    :libatomic,
                    "lib/libatomic.so",
                    [],
                    [:RTLD_LAZY, :RTLD_DEEPBIND],
                ),
                JLLLibraryProduct(
                    :libgcc_s,
                    "lib/libgcc_s.so.1",
                    [],
                    [:RTLD_LAZY, :RTLD_DEEPBIND],
                ),
                JLLLibraryProduct(
                    :libgfortran,
                    "lib/libgfortran.so",
                    [
                        JLLLibraryDep(nothing, :libgcc_s),
                        JLLLibraryDep(nothing, :libquadmath)
                    ],
                    [:RTLD_LAZY, :RTLD_DEEPBIND],
                ),
                JLLLibraryProduct(
                    :libgomp,
                    "lib/libgomp.so",
                    [],
                    [:RTLD_LAZY, :RTLD_DEEPBIND],
                ),
                JLLLibraryProduct(
                    :libssp,
                    "lib/libssp.so",
                    [],
                    [:RTLD_LAZY, :RTLD_DEEPBIND],
                ),
                JLLLibraryProduct(
                    :libstdcxx,
                    "lib/libstdc++.so",
                    [
                        JLLLibraryDep(nothing, :libgcc_s),
                    ],
                    [:RTLD_LAZY, :RTLD_DEEPBIND],
                ),
                JLLLibraryProduct(
                    :libquadmath,
                    "lib/libquadmath.so",
                    [],
                    [:RTLD_LAZY, :RTLD_DEEPBIND],
                ),
            ]
        ),

        JLLArtifactInfo(;
            src_version = v"1.0.5+1",
            deps = [],
            sources = [],
            platform = Platform("i686", "linux"; libgfortran_version = "5.0.0", libc = "glibc"),
            name = "default",
            treehash = "d8648bef77326fab1952b8ac696882ee2a303a81",
            download_sources = [
                JLLArtifactSource(
                    "https://github.com/JuliaBinaryWrappers/CompilerSupportLibraries_jll.jl/releases/download/CompilerSupportLibraries-v1.0.5+1/CompilerSupportLibraries.v1.0.5.i686-linux-gnu-libgfortran5.tar.gz",
                    "550511ee0dc67e8fdde0c5cb8c56f8974d06c5ab50f0763c6f7a1e2af0000f70",
                ),
            ],
            products = [
                JLLLibraryProduct(
                    :libatomic,
                    "lib/libatomic.so",
                    [],
                    [:RTLD_LAZY, :RTLD_DEEPBIND],
                ),
                JLLLibraryProduct(
                    :libgcc_s,
                    "lib/libgcc_s.so.1",
                    [],
                    [:RTLD_LAZY, :RTLD_DEEPBIND],
                ),
                JLLLibraryProduct(
                    :libgfortran,
                    "lib/libgfortran.so",
                    [
                        JLLLibraryDep(nothing, :libgcc_s),
                        JLLLibraryDep(nothing, :libquadmath)
                    ],
                    [:RTLD_LAZY, :RTLD_DEEPBIND],
                ),
                JLLLibraryProduct(
                    :libgomp,
                    "lib/libgomp.so",
                    [],
                    [:RTLD_LAZY, :RTLD_DEEPBIND],
                ),
                JLLLibraryProduct(
                    :libssp,
                    "lib/libssp.so",
                    [],
                    [:RTLD_LAZY, :RTLD_DEEPBIND],
                ),
                JLLLibraryProduct(
                    :libstdcxx,
                    "lib/libstdc++.so",
                    [
                        JLLLibraryDep(nothing, :libgcc_s),
                    ],
                    [:RTLD_LAZY, :RTLD_DEEPBIND],
                ),
                JLLLibraryProduct(
                    :libquadmath,
                    "lib/libquadmath.so",
                    [],
                    [:RTLD_LAZY, :RTLD_DEEPBIND],
                ),
            ]
        ),

        JLLArtifactInfo(;
            src_version = v"1.0.5+1",
            deps = [],
            sources = [],
            platform = Platform("i686", "linux"; libgfortran_version = "3.0.0", libc = "musl"),
            name = "default",
            treehash = "69453857368f2f36663838413c04f9a1e8d19c1c",
            download_sources = [
                JLLArtifactSource(
                    "https://github.com/JuliaBinaryWrappers/CompilerSupportLibraries_jll.jl/releases/download/CompilerSupportLibraries-v1.0.5+1/CompilerSupportLibraries.v1.0.5.i686-linux-musl-libgfortran3.tar.gz",
                    "6c3016d5ef5633a4146552fccdca949355d7ecf4054bbea961a3d07430a4f3b5",
                ),
            ],
            products = [
                JLLLibraryProduct(
                    :libatomic,
                    "lib/libatomic.so",
                    [],
                    [:RTLD_LAZY, :RTLD_DEEPBIND],
                ),
                JLLLibraryProduct(
                    :libgcc_s,
                    "lib/libgcc_s.so.1",
                    [],
                    [:RTLD_LAZY, :RTLD_DEEPBIND],
                ),
                JLLLibraryProduct(
                    :libgfortran,
                    "lib/libgfortran.so",
                    [
                        JLLLibraryDep(nothing, :libgcc_s),
                        JLLLibraryDep(nothing, :libquadmath)
                    ],
                    [:RTLD_LAZY, :RTLD_DEEPBIND],
                ),
                JLLLibraryProduct(
                    :libgomp,
                    "lib/libgomp.so",
                    [],
                    [:RTLD_LAZY, :RTLD_DEEPBIND],
                ),
                JLLLibraryProduct(
                    :libstdcxx,
                    "lib/libstdc++.so",
                    [
                        JLLLibraryDep(nothing, :libgcc_s),
                    ],
                    [:RTLD_LAZY, :RTLD_DEEPBIND],
                ),
                JLLLibraryProduct(
                    :libquadmath,
                    "lib/libquadmath.so",
                    [],
                    [:RTLD_LAZY, :RTLD_DEEPBIND],
                ),
            ]
        ),

        JLLArtifactInfo(;
            src_version = v"1.0.5+1",
            deps = [],
            sources = [],
            platform = Platform("i686", "linux"; libgfortran_version = "4.0.0", libc = "musl"),
            name = "default",
            treehash = "a3e20ca71102075b672df91216d743857978d93a",
            download_sources = [
                JLLArtifactSource(
                    "https://github.com/JuliaBinaryWrappers/CompilerSupportLibraries_jll.jl/releases/download/CompilerSupportLibraries-v1.0.5+1/CompilerSupportLibraries.v1.0.5.i686-linux-musl-libgfortran4.tar.gz",
                    "a54d047d04ea432baa3c31b0c18a617af538722cc00a1d92f45d50fe1be82350",
                ),
            ],
            products = [
                JLLLibraryProduct(
                    :libatomic,
                    "lib/libatomic.so",
                    [],
                    [:RTLD_LAZY, :RTLD_DEEPBIND],
                ),
                JLLLibraryProduct(
                    :libgcc_s,
                    "lib/libgcc_s.so.1",
                    [],
                    [:RTLD_LAZY, :RTLD_DEEPBIND],
                ),
                JLLLibraryProduct(
                    :libgfortran,
                    "lib/libgfortran.so",
                    [
                        JLLLibraryDep(nothing, :libgcc_s),
                        JLLLibraryDep(nothing, :libquadmath)
                    ],
                    [:RTLD_LAZY, :RTLD_DEEPBIND],
                ),
                JLLLibraryProduct(
                    :libgomp,
                    "lib/libgomp.so",
                    [],
                    [:RTLD_LAZY, :RTLD_DEEPBIND],
                ),
                JLLLibraryProduct(
                    :libstdcxx,
                    "lib/libstdc++.so",
                    [
                        JLLLibraryDep(nothing, :libgcc_s),
                    ],
                    [:RTLD_LAZY, :RTLD_DEEPBIND],
                ),
                JLLLibraryProduct(
                    :libquadmath,
                    "lib/libquadmath.so",
                    [],
                    [:RTLD_LAZY, :RTLD_DEEPBIND],
                ),
            ]
        ),

        JLLArtifactInfo(;
            src_version = v"1.0.5+1",
            deps = [],
            sources = [],
            platform = Platform("i686", "linux"; libgfortran_version = "5.0.0", libc = "musl"),
            name = "default",
            treehash = "e7e13711690b88a11ae8a5dc372f7ce9cb7168ca",
            download_sources = [
                JLLArtifactSource(
                    "https://github.com/JuliaBinaryWrappers/CompilerSupportLibraries_jll.jl/releases/download/CompilerSupportLibraries-v1.0.5+1/CompilerSupportLibraries.v1.0.5.i686-linux-musl-libgfortran5.tar.gz",
                    "045b8c192cbded8ae5b9005deb40176d4223c3c0df44e576cadd8eeab37c53a2",
                ),
            ],
            products = [
                JLLLibraryProduct(
                    :libatomic,
                    "lib/libatomic.so",
                    [],
                    [:RTLD_LAZY, :RTLD_DEEPBIND],
                ),
                JLLLibraryProduct(
                    :libgcc_s,
                    "lib/libgcc_s.so.1",
                    [],
                    [:RTLD_LAZY, :RTLD_DEEPBIND],
                ),
                JLLLibraryProduct(
                    :libgfortran,
                    "lib/libgfortran.so",
                    [
                        JLLLibraryDep(nothing, :libgcc_s),
                        JLLLibraryDep(nothing, :libquadmath)
                    ],
                    [:RTLD_LAZY, :RTLD_DEEPBIND],
                ),
                JLLLibraryProduct(
                    :libgomp,
                    "lib/libgomp.so",
                    [],
                    [:RTLD_LAZY, :RTLD_DEEPBIND],
                ),
                JLLLibraryProduct(
                    :libstdcxx,
                    "lib/libstdc++.so",
                    [
                        JLLLibraryDep(nothing, :libgcc_s),
                    ],
                    [:RTLD_LAZY, :RTLD_DEEPBIND],
                ),
                JLLLibraryProduct(
                    :libquadmath,
                    "lib/libquadmath.so",
                    [],
                    [:RTLD_LAZY, :RTLD_DEEPBIND],
                ),
            ]
        ),

        JLLArtifactInfo(;
            src_version = v"1.0.5+1",
            deps = [],
            sources = [],
            platform = Platform("i686", "windows"; libgfortran_version = "3.0.0"),
            name = "default",
            treehash = "d5007ced365e2c3ab8876e8d257095ee7e85a7be",
            download_sources = [
                JLLArtifactSource(
                    "https://github.com/JuliaBinaryWrappers/CompilerSupportLibraries_jll.jl/releases/download/CompilerSupportLibraries-v1.0.5+1/CompilerSupportLibraries.v1.0.5.i686-w64-mingw32-libgfortran3.tar.gz",
                    "f98dc8398db9d66d42aa15c16f095a5b72df60a35618997267dfa31571b1f1c8",
                ),
            ],
            products = [
                JLLLibraryProduct(
                    :libgcc_s,
                    "bin\\libgcc_s_sjlj-1.dll",
                    [],
                    [:RTLD_LAZY, :RTLD_DEEPBIND],
                ),
                JLLLibraryProduct(
                    :libgfortran,
                    "bin\\libgfortran-3.dll",
                    [
                        JLLLibraryDep(nothing, :libgcc_s),
                        JLLLibraryDep(nothing, :libquadmath)
                    ],
                    [:RTLD_LAZY, :RTLD_DEEPBIND],
                ),
                JLLLibraryProduct(
                    :libgomp,
                    "bin\\libgomp-1.dll",
                    [],
                    [:RTLD_LAZY, :RTLD_DEEPBIND],
                ),
                JLLLibraryProduct(
                    :libssp,
                    "bin\\libssp-0.dll",
                    [],
                    [:RTLD_LAZY, :RTLD_DEEPBIND],
                ),
                JLLLibraryProduct(
                    :libstdcxx,
                    "bin\\libstdc++-6.dll",
                    [
                        JLLLibraryDep(nothing, :libgcc_s),
                    ],
                    [:RTLD_LAZY, :RTLD_DEEPBIND],
                ),
                JLLLibraryProduct(
                    :libquadmath,
                    "bin\\libquadmath.6.dll",
                    [],
                    [:RTLD_LAZY, :RTLD_DEEPBIND],
                ),
                JLLFileProduct(
                    :libgcc_a,
                    "lib\\libgcc.a",
                ),
                JLLFileProduct(
                    :libgcc_s_a,
                    "lib\\libgcc_s.a",
                ),
                JLLFileProduct(
                    :libmsvcrt_a,
                    "lib\\libmsvcrt.a",
                ),
                JLLFileProduct(
                    :libssp_dll_a,
                    "lib\\libssp.dll.a",
                ),
            ]
        ),

        JLLArtifactInfo(;
            src_version = v"1.0.5+1",
            deps = [],
            sources = [],
            platform = Platform("i686", "windows"; libgfortran_version = "4.0.0"),
            name = "default",
            treehash = "cdfd28f31ccdff8f26f23d36f5379ca85bbf3b5a",
            download_sources = [
                JLLArtifactSource(
                    "https://github.com/JuliaBinaryWrappers/CompilerSupportLibraries_jll.jl/releases/download/CompilerSupportLibraries-v1.0.5+1/CompilerSupportLibraries.v1.0.5.i686-w64-mingw32-libgfortran4.tar.gz",
                    "c799bc84619c56fcf994a3e6876073145d0d38d48831b45f16b2fa4cd58bb4b3",
                ),
            ],
            products = [
                JLLLibraryProduct(
                    :libatomic,
                    "bin\\libatomic-1.dll",
                    [],
                    [:RTLD_LAZY, :RTLD_DEEPBIND],
                ),
                JLLLibraryProduct(
                    :libgcc_s,
                    "bin\\libgcc_s_sjlj-1.dll",
                    [],
                    [:RTLD_LAZY, :RTLD_DEEPBIND],
                ),
                JLLLibraryProduct(
                    :libgfortran,
                    "bin\\libgfortran-4.dll",
                    [
                        JLLLibraryDep(nothing, :libgcc_s),
                        JLLLibraryDep(nothing, :libquadmath)
                    ],
                    [:RTLD_LAZY, :RTLD_DEEPBIND],
                ),
                JLLLibraryProduct(
                    :libgomp,
                    "bin\\libgomp-1.dll",
                    [],
                    [:RTLD_LAZY, :RTLD_DEEPBIND],
                ),
                JLLLibraryProduct(
                    :libssp,
                    "bin\\libssp-0.dll",
                    [],
                    [:RTLD_LAZY, :RTLD_DEEPBIND],
                ),
                JLLLibraryProduct(
                    :libstdcxx,
                    "bin\\libstdc++-6.dll",
                    [
                        JLLLibraryDep(nothing, :libgcc_s),
                    ],
                    [:RTLD_LAZY, :RTLD_DEEPBIND],
                ),
                JLLLibraryProduct(
                    :libquadmath,
                    "bin\\libquadmath.6.dll",
                    [],
                    [:RTLD_LAZY, :RTLD_DEEPBIND],
                ),
                JLLFileProduct(
                    :libgcc_a,
                    "lib\\libgcc.a",
                ),
                JLLFileProduct(
                    :libgcc_s_a,
                    "lib\\libgcc_s.a",
                ),
                JLLFileProduct(
                    :libmsvcrt_a,
                    "lib\\libmsvcrt.a",
                ),
                JLLFileProduct(
                    :libssp_dll_a,
                    "lib\\libssp.dll.a",
                ),
            ]
        ),

        JLLArtifactInfo(;
            src_version = v"1.0.5+1",
            deps = [],
            sources = [],
            platform = Platform("i686", "windows"; libgfortran_version = "5.0.0"),
            name = "default",
            treehash = "0b76f5573ea478f71309c965888bacee71e47231",
            download_sources = [
                JLLArtifactSource(
                    "https://github.com/JuliaBinaryWrappers/CompilerSupportLibraries_jll.jl/releases/download/CompilerSupportLibraries-v1.0.5+1/CompilerSupportLibraries.v1.0.5.i686-w64-mingw32-libgfortran5.tar.gz",
                    "a754b2b224807332a2f012ca4fe647c117b43dce462dbbecf2df1e231425847b",
                ),
            ],
            products = [
                JLLLibraryProduct(
                    :libatomic,
                    "bin\\libatomic-1.dll",
                    [],
                    [:RTLD_LAZY, :RTLD_DEEPBIND],
                ),
                JLLLibraryProduct(
                    :libgcc_s,
                    "bin\\libgcc_s_sjlj-1.dll",
                    [],
                    [:RTLD_LAZY, :RTLD_DEEPBIND],
                ),
                JLLLibraryProduct(
                    :libgfortran,
                    "bin\\libgfortran-5.dll",
                    [
                        JLLLibraryDep(nothing, :libgcc_s),
                        JLLLibraryDep(nothing, :libquadmath)
                    ],
                    [:RTLD_LAZY, :RTLD_DEEPBIND],
                ),
                JLLLibraryProduct(
                    :libgomp,
                    "bin\\libgomp-1.dll",
                    [],
                    [:RTLD_LAZY, :RTLD_DEEPBIND],
                ),
                JLLLibraryProduct(
                    :libssp,
                    "bin\\libssp-0.dll",
                    [],
                    [:RTLD_LAZY, :RTLD_DEEPBIND],
                ),
                JLLLibraryProduct(
                    :libstdcxx,
                    "bin\\libstdc++-6.dll",
                    [
                        JLLLibraryDep(nothing, :libgcc_s),
                    ],
                    [:RTLD_LAZY, :RTLD_DEEPBIND],
                ),
                JLLLibraryProduct(
                    :libquadmath,
                    "bin\\libquadmath.6.dll",
                    [],
                    [:RTLD_LAZY, :RTLD_DEEPBIND],
                ),
                JLLFileProduct(
                    :libgcc_a,
                    "lib\\libgcc.a",
                ),
                JLLFileProduct(
                    :libgcc_s_a,
                    "lib\\libgcc_s.a",
                ),
                JLLFileProduct(
                    :libmsvcrt_a,
                    "lib\\libmsvcrt.a",
                ),
                JLLFileProduct(
                    :libssp_dll_a,
                    "lib\\libssp.dll.a",
                ),
            ]
        ),

        JLLArtifactInfo(;
            src_version = v"1.0.5+1",
            deps = [],
            sources = [],
            platform = Platform("powerpc64le", "linux"; libgfortran_version = "3.0.0", libc = "glibc"),
            name = "default",
            treehash = "ac16bfc33a7ced0b93dc99058c26d00c74f18980",
            download_sources = [
                JLLArtifactSource(
                    "https://github.com/JuliaBinaryWrappers/CompilerSupportLibraries_jll.jl/releases/download/CompilerSupportLibraries-v1.0.5+1/CompilerSupportLibraries.v1.0.5.powerpc64le-linux-gnu-libgfortran3.tar.gz",
                    "fcfc67fe4cfb0815d13072d4f05c1fcbc0aea6a632f6f3b6c7ebced08b5341aa",
                ),
            ],
            products = [
                JLLLibraryProduct(
                    :libatomic,
                    "lib/libatomic.so",
                    [],
                    [:RTLD_LAZY, :RTLD_DEEPBIND],
                ),
                JLLLibraryProduct(
                    :libgcc_s,
                    "lib/libgcc_s.so.1",
                    [],
                    [:RTLD_LAZY, :RTLD_DEEPBIND],
                ),
                JLLLibraryProduct(
                    :libgfortran,
                    "lib/libgfortran.so",
                    [
                        JLLLibraryDep(nothing, :libgcc_s),
                        JLLLibraryDep(nothing, :libquadmath)
                    ],
                    [:RTLD_LAZY, :RTLD_DEEPBIND],
                ),
                JLLLibraryProduct(
                    :libgomp,
                    "lib/libgomp.so",
                    [],
                    [:RTLD_LAZY, :RTLD_DEEPBIND],
                ),
                JLLLibraryProduct(
                    :libssp,
                    "lib/libssp.so",
                    [],
                    [:RTLD_LAZY, :RTLD_DEEPBIND],
                ),
                JLLLibraryProduct(
                    :libstdcxx,
                    "lib/libstdc++.so",
                    [
                        JLLLibraryDep(nothing, :libgcc_s),
                    ],
                    [:RTLD_LAZY, :RTLD_DEEPBIND],
                ),
                JLLLibraryProduct(
                    :libquadmath,
                    "lib/libquadmath.so",
                    [],
                    [:RTLD_LAZY, :RTLD_DEEPBIND],
                ),
            ]
        ),

        JLLArtifactInfo(;
            src_version = v"1.0.5+1",
            deps = [],
            sources = [],
            platform = Platform("powerpc64le", "linux"; libgfortran_version = "4.0.0", libc = "glibc"),
            name = "default",
            treehash = "8ecbe141a2b8ea16526e3c4c4ef0780e5d2d73e7",
            download_sources = [
                JLLArtifactSource(
                    "https://github.com/JuliaBinaryWrappers/CompilerSupportLibraries_jll.jl/releases/download/CompilerSupportLibraries-v1.0.5+1/CompilerSupportLibraries.v1.0.5.powerpc64le-linux-gnu-libgfortran4.tar.gz",
                    "fb9c392ec18bf91c5740272249f8db0e49d9848834a30780966051bc6e430e45",
                ),
            ],
            products = [
                JLLLibraryProduct(
                    :libatomic,
                    "lib/libatomic.so",
                    [],
                    [:RTLD_LAZY, :RTLD_DEEPBIND],
                ),
                JLLLibraryProduct(
                    :libgcc_s,
                    "lib/libgcc_s.so.1",
                    [],
                    [:RTLD_LAZY, :RTLD_DEEPBIND],
                ),
                JLLLibraryProduct(
                    :libgfortran,
                    "lib/libgfortran.so",
                    [
                        JLLLibraryDep(nothing, :libgcc_s),
                        JLLLibraryDep(nothing, :libquadmath)
                    ],
                    [:RTLD_LAZY, :RTLD_DEEPBIND],
                ),
                JLLLibraryProduct(
                    :libgomp,
                    "lib/libgomp.so",
                    [],
                    [:RTLD_LAZY, :RTLD_DEEPBIND],
                ),
                JLLLibraryProduct(
                    :libssp,
                    "lib/libssp.so",
                    [],
                    [:RTLD_LAZY, :RTLD_DEEPBIND],
                ),
                JLLLibraryProduct(
                    :libstdcxx,
                    "lib/libstdc++.so",
                    [
                        JLLLibraryDep(nothing, :libgcc_s),
                    ],
                    [:RTLD_LAZY, :RTLD_DEEPBIND],
                ),
                JLLLibraryProduct(
                    :libquadmath,
                    "lib/libquadmath.so",
                    [],
                    [:RTLD_LAZY, :RTLD_DEEPBIND],
                ),
            ]
        ),

        JLLArtifactInfo(;
            src_version = v"1.0.5+1",
            deps = [],
            sources = [],
            platform = Platform("powerpc64le", "linux"; libgfortran_version = "5.0.0", libc = "glibc"),
            name = "default",
            treehash = "10ca78da9e90af0a49574eb1702eca85a25dddba",
            download_sources = [
                JLLArtifactSource(
                    "https://github.com/JuliaBinaryWrappers/CompilerSupportLibraries_jll.jl/releases/download/CompilerSupportLibraries-v1.0.5+1/CompilerSupportLibraries.v1.0.5.powerpc64le-linux-gnu-libgfortran5.tar.gz",
                    "bded0b18a2eb37ea6281c458bdf512d209d441d0992b36916eeb4d10b5909942",
                ),
            ],
            products = [
                JLLLibraryProduct(
                    :libatomic,
                    "lib/libatomic.so",
                    [],
                    [:RTLD_LAZY, :RTLD_DEEPBIND],
                ),
                JLLLibraryProduct(
                    :libgcc_s,
                    "lib/libgcc_s.so.1",
                    [],
                    [:RTLD_LAZY, :RTLD_DEEPBIND],
                ),
                JLLLibraryProduct(
                    :libgfortran,
                    "lib/libgfortran.so",
                    [
                        JLLLibraryDep(nothing, :libgcc_s),
                        JLLLibraryDep(nothing, :libquadmath)
                    ],
                    [:RTLD_LAZY, :RTLD_DEEPBIND],
                ),
                JLLLibraryProduct(
                    :libgomp,
                    "lib/libgomp.so",
                    [],
                    [:RTLD_LAZY, :RTLD_DEEPBIND],
                ),
                JLLLibraryProduct(
                    :libssp,
                    "lib/libssp.so",
                    [],
                    [:RTLD_LAZY, :RTLD_DEEPBIND],
                ),
                JLLLibraryProduct(
                    :libstdcxx,
                    "lib/libstdc++.so",
                    [
                        JLLLibraryDep(nothing, :libgcc_s),
                    ],
                    [:RTLD_LAZY, :RTLD_DEEPBIND],
                ),
                JLLLibraryProduct(
                    :libquadmath,
                    "lib/libquadmath.so",
                    [],
                    [:RTLD_LAZY, :RTLD_DEEPBIND],
                ),
            ]
        ),

        JLLArtifactInfo(;
            src_version = v"1.0.5+1",
            deps = [],
            sources = [],
            platform = Platform("x86_64", "macos"; libgfortran_version = "3.0.0"),
            name = "default",
            treehash = "3e845875edec511c5e75f635e7d4cb1b71fe527d",
            download_sources = [
                JLLArtifactSource(
                    "https://github.com/JuliaBinaryWrappers/CompilerSupportLibraries_jll.jl/releases/download/CompilerSupportLibraries-v1.0.5+1/CompilerSupportLibraries.v1.0.5.x86_64-apple-darwin-libgfortran3.tar.gz",
                    "20119774176f57bfb377309edbc89ed2423a5c0b43f18e68418ccd65a3d4647a",
                ),
            ],
            products = [
                JLLLibraryProduct(
                    :libatomic,
                    "lib/libatomic.1.dylib",
                    [],
                    [:RTLD_LAZY, :RTLD_DEEPBIND],
                ),
                JLLLibraryProduct(
                    :libgcc_s,
                    "lib/libgcc_s.1.1.dylib",
                    [],
                    [:RTLD_LAZY, :RTLD_DEEPBIND],
                ),
                JLLLibraryProduct(
                    :libgfortran,
                    "lib/libgfortran.3.dylib",
                    [
                        JLLLibraryDep(nothing, :libgcc_s),
                        JLLLibraryDep(nothing, :libquadmath)
                    ],
                    [:RTLD_LAZY, :RTLD_DEEPBIND],
                ),
                JLLLibraryProduct(
                    :libgomp,
                    "lib/libgomp.1.dylib",
                    [],
                    [:RTLD_LAZY, :RTLD_DEEPBIND],
                ),
                JLLLibraryProduct(
                    :libssp,
                    "lib/libssp.0.dylib",
                    [],
                    [:RTLD_LAZY, :RTLD_DEEPBIND],
                ),
                JLLLibraryProduct(
                    :libstdcxx,
                    "lib/libstdc++.6.dylib",
                    [
                        JLLLibraryDep(nothing, :libgcc_s),
                    ],
                    [:RTLD_LAZY, :RTLD_DEEPBIND],
                ),
                JLLLibraryProduct(
                    :libquadmath,
                    "lib/libquadmath.6.dylib",
                    [],
                    [:RTLD_LAZY, :RTLD_DEEPBIND],
                ),
            ]
        ),

        JLLArtifactInfo(;
            src_version = v"1.0.5+1",
            deps = [],
            sources = [],
            platform = Platform("x86_64", "macos"; libgfortran_version = "4.0.0"),
            name = "default",
            treehash = "52f7de768a6ffdff53b857938a08f7c8243b4aa7",
            download_sources = [
                JLLArtifactSource(
                    "https://github.com/JuliaBinaryWrappers/CompilerSupportLibraries_jll.jl/releases/download/CompilerSupportLibraries-v1.0.5+1/CompilerSupportLibraries.v1.0.5.x86_64-apple-darwin-libgfortran4.tar.gz",
                    "2b8df36350a0bb1a74db46f633013c63556edf963ec29813a58ac703f4dd49ca",
                ),
            ],
            products = [
                JLLLibraryProduct(
                    :libatomic,
                    "lib/libatomic.1.dylib",
                    [],
                    [:RTLD_LAZY, :RTLD_DEEPBIND],
                ),
                JLLLibraryProduct(
                    :libgcc_s,
                    "lib/libgcc_s.1.1.dylib",
                    [],
                    [:RTLD_LAZY, :RTLD_DEEPBIND],
                ),
                JLLLibraryProduct(
                    :libgfortran,
                    "lib/libgfortran.4.dylib",
                    [
                        JLLLibraryDep(nothing, :libgcc_s),
                        JLLLibraryDep(nothing, :libquadmath)
                    ],
                    [:RTLD_LAZY, :RTLD_DEEPBIND],
                ),
                JLLLibraryProduct(
                    :libgomp,
                    "lib/libgomp.1.dylib",
                    [],
                    [:RTLD_LAZY, :RTLD_DEEPBIND],
                ),
                JLLLibraryProduct(
                    :libssp,
                    "lib/libssp.0.dylib",
                    [],
                    [:RTLD_LAZY, :RTLD_DEEPBIND],
                ),
                JLLLibraryProduct(
                    :libstdcxx,
                    "lib/libstdc++.6.dylib",
                    [
                        JLLLibraryDep(nothing, :libgcc_s),
                    ],
                    [:RTLD_LAZY, :RTLD_DEEPBIND],
                ),
                JLLLibraryProduct(
                    :libquadmath,
                    "lib/libquadmath.6.dylib",
                    [],
                    [:RTLD_LAZY, :RTLD_DEEPBIND],
                ),
            ]
        ),

        JLLArtifactInfo(;
            src_version = v"1.0.5+1",
            deps = [],
            sources = [],
            platform = Platform("x86_64", "macos"; libgfortran_version = "5.0.0"),
            name = "default",
            treehash = "3b8127a3d5f3f59847cc9b4c4a7d9d0618e54667",
            download_sources = [
                JLLArtifactSource(
                    "https://github.com/JuliaBinaryWrappers/CompilerSupportLibraries_jll.jl/releases/download/CompilerSupportLibraries-v1.0.5+1/CompilerSupportLibraries.v1.0.5.x86_64-apple-darwin-libgfortran5.tar.gz",
                    "69d81257818a404cf4d53b0b6a3eb6317ade7f5902cca128df3b802f5147e04f",
                ),
            ],
            products = [
                JLLLibraryProduct(
                    :libatomic,
                    "lib/libatomic.1.dylib",
                    [],
                    [:RTLD_LAZY, :RTLD_DEEPBIND],
                ),
                JLLLibraryProduct(
                    :libgcc_s,
                    "lib/libgcc_s.1.1.dylib",
                    [],
                    [:RTLD_LAZY, :RTLD_DEEPBIND],
                ),
                JLLLibraryProduct(
                    :libgfortran,
                    "lib/libgfortran.5.dylib",
                    [
                        JLLLibraryDep(nothing, :libgcc_s),
                        JLLLibraryDep(nothing, :libquadmath)
                    ],
                    [:RTLD_LAZY, :RTLD_DEEPBIND],
                ),
                JLLLibraryProduct(
                    :libgomp,
                    "lib/libgomp.1.dylib",
                    [],
                    [:RTLD_LAZY, :RTLD_DEEPBIND],
                ),
                JLLLibraryProduct(
                    :libssp,
                    "lib/libssp.0.dylib",
                    [],
                    [:RTLD_LAZY, :RTLD_DEEPBIND],
                ),
                JLLLibraryProduct(
                    :libstdcxx,
                    "lib/libstdc++.6.dylib",
                    [
                        JLLLibraryDep(nothing, :libgcc_s),
                    ],
                    [:RTLD_LAZY, :RTLD_DEEPBIND],
                ),
                JLLLibraryProduct(
                    :libquadmath,
                    "lib/libquadmath.6.dylib",
                    [],
                    [:RTLD_LAZY, :RTLD_DEEPBIND],
                ),
            ]
        ),

        JLLArtifactInfo(;
            src_version = v"1.0.5+1",
            deps = [],
            sources = [],
            platform = Platform("x86_64", "linux"; libgfortran_version = "3.0.0", libc = "glibc"),
            name = "default",
            treehash = "6009eeab5f9d15182b3d77ee88da94c81474a1a8",
            download_sources = [
                JLLArtifactSource(
                    "https://github.com/JuliaBinaryWrappers/CompilerSupportLibraries_jll.jl/releases/download/CompilerSupportLibraries-v1.0.5+1/CompilerSupportLibraries.v1.0.5.x86_64-linux-gnu-libgfortran3.tar.gz",
                    "152d2b5f18728350090d157a5b26958026cd19532f0b2a760ee779e565744460",
                ),
            ],
            products = [
                JLLLibraryProduct(
                    :libatomic,
                    "lib/libatomic.so",
                    [],
                    [:RTLD_LAZY, :RTLD_DEEPBIND],
                ),
                JLLLibraryProduct(
                    :libgcc_s,
                    "lib/libgcc_s.so.1",
                    [],
                    [:RTLD_LAZY, :RTLD_DEEPBIND],
                ),
                JLLLibraryProduct(
                    :libgfortran,
                    "lib/libgfortran.so",
                    [
                        JLLLibraryDep(nothing, :libgcc_s),
                        JLLLibraryDep(nothing, :libquadmath)
                    ],
                    [:RTLD_LAZY, :RTLD_DEEPBIND],
                ),
                JLLLibraryProduct(
                    :libgomp,
                    "lib/libgomp.so",
                    [],
                    [:RTLD_LAZY, :RTLD_DEEPBIND],
                ),
                JLLLibraryProduct(
                    :libssp,
                    "lib/libssp.so",
                    [],
                    [:RTLD_LAZY, :RTLD_DEEPBIND],
                ),
                JLLLibraryProduct(
                    :libstdcxx,
                    "lib/libstdc++.so",
                    [
                        JLLLibraryDep(nothing, :libgcc_s),
                    ],
                    [:RTLD_LAZY, :RTLD_DEEPBIND],
                ),
                JLLLibraryProduct(
                    :libquadmath,
                    "lib/libquadmath.so",
                    [],
                    [:RTLD_LAZY, :RTLD_DEEPBIND],
                ),
            ]
        ),

        JLLArtifactInfo(;
            src_version = v"1.0.5+1",
            deps = [],
            sources = [],
            platform = Platform("x86_64", "linux"; libgfortran_version = "4.0.0", libc = "glibc"),
            name = "default",
            treehash = "5117b0f2b4d3d7c5c8f47b989ee37e57f5cdbdad",
            download_sources = [
                JLLArtifactSource(
                    "https://github.com/JuliaBinaryWrappers/CompilerSupportLibraries_jll.jl/releases/download/CompilerSupportLibraries-v1.0.5+1/CompilerSupportLibraries.v1.0.5.x86_64-linux-gnu-libgfortran4.tar.gz",
                    "19817245880ffc52fde582e0f375d23b63f7496778981a9e664058f9ecfa62a7",
                ),
            ],
            products = [
                JLLLibraryProduct(
                    :libatomic,
                    "lib/libatomic.so",
                    [],
                    [:RTLD_LAZY, :RTLD_DEEPBIND],
                ),
                JLLLibraryProduct(
                    :libgcc_s,
                    "lib/libgcc_s.so.1",
                    [],
                    [:RTLD_LAZY, :RTLD_DEEPBIND],
                ),
                JLLLibraryProduct(
                    :libgfortran,
                    "lib/libgfortran.so",
                    [
                        JLLLibraryDep(nothing, :libgcc_s),
                        JLLLibraryDep(nothing, :libquadmath)
                    ],
                    [:RTLD_LAZY, :RTLD_DEEPBIND],
                ),
                JLLLibraryProduct(
                    :libgomp,
                    "lib/libgomp.so",
                    [],
                    [:RTLD_LAZY, :RTLD_DEEPBIND],
                ),
                JLLLibraryProduct(
                    :libssp,
                    "lib/libssp.so",
                    [],
                    [:RTLD_LAZY, :RTLD_DEEPBIND],
                ),
                JLLLibraryProduct(
                    :libstdcxx,
                    "lib/libstdc++.so",
                    [
                        JLLLibraryDep(nothing, :libgcc_s),
                    ],
                    [:RTLD_LAZY, :RTLD_DEEPBIND],
                ),
                JLLLibraryProduct(
                    :libquadmath,
                    "lib/libquadmath.so",
                    [],
                    [:RTLD_LAZY, :RTLD_DEEPBIND],
                ),
            ]
        ),

        JLLArtifactInfo(;
            src_version = v"1.0.5+1",
            deps = [],
            sources = [],
            platform = Platform("x86_64", "linux"; libgfortran_version = "5.0.0", libc = "glibc"),
            name = "default",
            treehash = "1f4bd66f010c9bc98223169cf751de729024ef31",
            download_sources = [
                JLLArtifactSource(
                    "https://github.com/JuliaBinaryWrappers/CompilerSupportLibraries_jll.jl/releases/download/CompilerSupportLibraries-v1.0.5+1/CompilerSupportLibraries.v1.0.5.x86_64-linux-gnu-libgfortran5.tar.gz",
                    "f953a30a863457035ad9db091b9517f617b88e0a159b17d4a03f793723f85c3a",
                ),
            ],
            products = [
                JLLLibraryProduct(
                    :libatomic,
                    "lib/libatomic.so",
                    [],
                    [:RTLD_LAZY, :RTLD_DEEPBIND],
                ),
                JLLLibraryProduct(
                    :libgcc_s,
                    "lib/libgcc_s.so.1",
                    [],
                    [:RTLD_LAZY, :RTLD_DEEPBIND],
                ),
                JLLLibraryProduct(
                    :libgfortran,
                    "lib/libgfortran.so",
                    [
                        JLLLibraryDep(nothing, :libgcc_s),
                        JLLLibraryDep(nothing, :libquadmath)
                    ],
                    [:RTLD_LAZY, :RTLD_DEEPBIND],
                ),
                JLLLibraryProduct(
                    :libgomp,
                    "lib/libgomp.so",
                    [],
                    [:RTLD_LAZY, :RTLD_DEEPBIND],
                ),
                JLLLibraryProduct(
                    :libssp,
                    "lib/libssp.so",
                    [],
                    [:RTLD_LAZY, :RTLD_DEEPBIND],
                ),
                JLLLibraryProduct(
                    :libstdcxx,
                    "lib/libstdc++.so",
                    [
                        JLLLibraryDep(nothing, :libgcc_s),
                    ],
                    [:RTLD_LAZY, :RTLD_DEEPBIND],
                ),
                JLLLibraryProduct(
                    :libquadmath,
                    "lib/libquadmath.so",
                    [],
                    [:RTLD_LAZY, :RTLD_DEEPBIND],
                ),
            ]
        ),

        JLLArtifactInfo(;
            src_version = v"1.0.5+1",
            deps = [],
            sources = [],
            platform = Platform("x86_64", "linux"; libgfortran_version = "3.0.0", libc = "musl"),
            name = "default",
            treehash = "5b4263b70158ec85c1d5d8e99a007cb774c174ff",
            download_sources = [
                JLLArtifactSource(
                    "https://github.com/JuliaBinaryWrappers/CompilerSupportLibraries_jll.jl/releases/download/CompilerSupportLibraries-v1.0.5+1/CompilerSupportLibraries.v1.0.5.x86_64-linux-musl-libgfortran3.tar.gz",
                    "20a4d7d9c8de05f4de7247f40bf73696d1494d02872ff35642e612f702d05bd7",
                ),
            ],
            products = [
                JLLLibraryProduct(
                    :libatomic,
                    "lib/libatomic.so",
                    [],
                    [:RTLD_LAZY, :RTLD_DEEPBIND],
                ),
                JLLLibraryProduct(
                    :libgcc_s,
                    "lib/libgcc_s.so.1",
                    [],
                    [:RTLD_LAZY, :RTLD_DEEPBIND],
                ),
                JLLLibraryProduct(
                    :libgfortran,
                    "lib/libgfortran.so",
                    [
                        JLLLibraryDep(nothing, :libgcc_s),
                        JLLLibraryDep(nothing, :libquadmath)
                    ],
                    [:RTLD_LAZY, :RTLD_DEEPBIND],
                ),
                JLLLibraryProduct(
                    :libgomp,
                    "lib/libgomp.so",
                    [],
                    [:RTLD_LAZY, :RTLD_DEEPBIND],
                ),
                JLLLibraryProduct(
                    :libstdcxx,
                    "lib/libstdc++.so",
                    [
                        JLLLibraryDep(nothing, :libgcc_s),
                    ],
                    [:RTLD_LAZY, :RTLD_DEEPBIND],
                ),
                JLLLibraryProduct(
                    :libquadmath,
                    "lib/libquadmath.so",
                    [],
                    [:RTLD_LAZY, :RTLD_DEEPBIND],
                ),
            ]
        ),

        JLLArtifactInfo(;
            src_version = v"1.0.5+1",
            deps = [],
            sources = [],
            platform = Platform("x86_64", "linux"; libgfortran_version = "4.0.0", libc = "musl"),
            name = "default",
            treehash = "9eb9fc4f5e8c70dce84957143c624c567c4fd4e3",
            download_sources = [
                JLLArtifactSource(
                    "https://github.com/JuliaBinaryWrappers/CompilerSupportLibraries_jll.jl/releases/download/CompilerSupportLibraries-v1.0.5+1/CompilerSupportLibraries.v1.0.5.x86_64-linux-musl-libgfortran4.tar.gz",
                    "4646efbaac866e3027f6ed3bf7d6c8e8b916c1067392c325ee6340319be370ef",
                ),
            ],
            products = [
                JLLLibraryProduct(
                    :libatomic,
                    "lib/libatomic.so",
                    [],
                    [:RTLD_LAZY, :RTLD_DEEPBIND],
                ),
                JLLLibraryProduct(
                    :libgcc_s,
                    "lib/libgcc_s.so.1",
                    [],
                    [:RTLD_LAZY, :RTLD_DEEPBIND],
                ),
                JLLLibraryProduct(
                    :libgfortran,
                    "lib/libgfortran.so",
                    [
                        JLLLibraryDep(nothing, :libgcc_s),
                        JLLLibraryDep(nothing, :libquadmath)
                    ],
                    [:RTLD_LAZY, :RTLD_DEEPBIND],
                ),
                JLLLibraryProduct(
                    :libgomp,
                    "lib/libgomp.so",
                    [],
                    [:RTLD_LAZY, :RTLD_DEEPBIND],
                ),
                JLLLibraryProduct(
                    :libstdcxx,
                    "lib/libstdc++.so",
                    [
                        JLLLibraryDep(nothing, :libgcc_s),
                    ],
                    [:RTLD_LAZY, :RTLD_DEEPBIND],
                ),
                JLLLibraryProduct(
                    :libquadmath,
                    "lib/libquadmath.so",
                    [],
                    [:RTLD_LAZY, :RTLD_DEEPBIND],
                ),
            ]
        ),

        JLLArtifactInfo(;
            src_version = v"1.0.5+1",
            deps = [],
            sources = [],
            platform = Platform("x86_64", "linux"; libgfortran_version = "5.0.0", libc = "musl"),
            name = "default",
            treehash = "fd7c41553127e994ab85d0931ec3e3c1fd989d4b",
            download_sources = [
                JLLArtifactSource(
                    "https://github.com/JuliaBinaryWrappers/CompilerSupportLibraries_jll.jl/releases/download/CompilerSupportLibraries-v1.0.5+1/CompilerSupportLibraries.v1.0.5.x86_64-linux-musl-libgfortran5.tar.gz",
                    "5d284a38048738a7d14ff1e327af5da868556fa1b4f331ca10ed652cfd4e130b",
                ),
            ],
            products = [
                JLLLibraryProduct(
                    :libatomic,
                    "lib/libatomic.so",
                    [],
                    [:RTLD_LAZY, :RTLD_DEEPBIND],
                ),
                JLLLibraryProduct(
                    :libgcc_s,
                    "lib/libgcc_s.so.1",
                    [],
                    [:RTLD_LAZY, :RTLD_DEEPBIND],
                ),
                JLLLibraryProduct(
                    :libgfortran,
                    "lib/libgfortran.so",
                    [
                        JLLLibraryDep(nothing, :libgcc_s),
                        JLLLibraryDep(nothing, :libquadmath)
                    ],
                    [:RTLD_LAZY, :RTLD_DEEPBIND],
                ),
                JLLLibraryProduct(
                    :libgomp,
                    "lib/libgomp.so",
                    [],
                    [:RTLD_LAZY, :RTLD_DEEPBIND],
                ),
                JLLLibraryProduct(
                    :libstdcxx,
                    "lib/libstdc++.so",
                    [
                        JLLLibraryDep(nothing, :libgcc_s),
                    ],
                    [:RTLD_LAZY, :RTLD_DEEPBIND],
                ),
                JLLLibraryProduct(
                    :libquadmath,
                    "lib/libquadmath.so",
                    [],
                    [:RTLD_LAZY, :RTLD_DEEPBIND],
                ),
            ]
        ),

        JLLArtifactInfo(;
            src_version = v"1.0.5+1",
            deps = [],
            sources = [],
            platform = Platform("x86_64", "freebsd"; libgfortran_version = "3.0.0"),
            name = "default",
            treehash = "ad208afa825bc2852043c3819f492120b3b8fc84",
            download_sources = [
                JLLArtifactSource(
                    "https://github.com/JuliaBinaryWrappers/CompilerSupportLibraries_jll.jl/releases/download/CompilerSupportLibraries-v1.0.5+1/CompilerSupportLibraries.v1.0.5.x86_64-unknown-freebsd-libgfortran3.tar.gz",
                    "786a8efdd999932b26d70d45866f947183b192e19d5fb605a3fe0b26b6dcdb68",
                ),
            ],
            products = [
                JLLLibraryProduct(
                    :libatomic,
                    "lib/libatomic.so",
                    [],
                    [:RTLD_LAZY, :RTLD_DEEPBIND],
                ),
                JLLLibraryProduct(
                    :libgcc_s,
                    "lib/libgcc_s.so",
                    [],
                    [:RTLD_LAZY, :RTLD_DEEPBIND],
                ),
                JLLLibraryProduct(
                    :libgfortran,
                    "lib/libgfortran.so",
                    [
                        JLLLibraryDep(nothing, :libgcc_s),
                        JLLLibraryDep(nothing, :libquadmath)
                    ],
                    [:RTLD_LAZY, :RTLD_DEEPBIND],
                ),
                JLLLibraryProduct(
                    :libgomp,
                    "lib/libgomp.so",
                    [],
                    [:RTLD_LAZY, :RTLD_DEEPBIND],
                ),
                JLLLibraryProduct(
                    :libssp,
                    "lib/libssp.so",
                    [],
                    [:RTLD_LAZY, :RTLD_DEEPBIND],
                ),
                JLLLibraryProduct(
                    :libstdcxx,
                    "lib/libstdc++.so",
                    [
                        JLLLibraryDep(nothing, :libgcc_s),
                    ],
                    [:RTLD_LAZY, :RTLD_DEEPBIND],
                ),
                JLLLibraryProduct(
                    :libquadmath,
                    "lib/libquadmath.so",
                    [],
                    [:RTLD_LAZY, :RTLD_DEEPBIND],
                ),
            ]
        ),

        JLLArtifactInfo(;
            src_version = v"1.0.5+1",
            deps = [],
            sources = [],
            platform = Platform("x86_64", "freebsd"; libgfortran_version = "4.0.0"),
            name = "default",
            treehash = "39f6a2fd984c38d33d209117cc2b82b5e1c510a6",
            download_sources = [
                JLLArtifactSource(
                    "https://github.com/JuliaBinaryWrappers/CompilerSupportLibraries_jll.jl/releases/download/CompilerSupportLibraries-v1.0.5+1/CompilerSupportLibraries.v1.0.5.x86_64-unknown-freebsd-libgfortran4.tar.gz",
                    "c99d4cbde4c3c6b452abd92ffabef26f52044c99a68c4cdcca12756f9b9ae9e5",
                ),
            ],
            products = [
                JLLLibraryProduct(
                    :libatomic,
                    "lib/libatomic.so",
                    [],
                    [:RTLD_LAZY, :RTLD_DEEPBIND],
                ),
                JLLLibraryProduct(
                    :libgcc_s,
                    "lib/libgcc_s.so",
                    [],
                    [:RTLD_LAZY, :RTLD_DEEPBIND],
                ),
                JLLLibraryProduct(
                    :libgfortran,
                    "lib/libgfortran.so",
                    [
                        JLLLibraryDep(nothing, :libgcc_s),
                        JLLLibraryDep(nothing, :libquadmath)
                    ],
                    [:RTLD_LAZY, :RTLD_DEEPBIND],
                ),
                JLLLibraryProduct(
                    :libgomp,
                    "lib/libgomp.so",
                    [],
                    [:RTLD_LAZY, :RTLD_DEEPBIND],
                ),
                JLLLibraryProduct(
                    :libssp,
                    "lib/libssp.so",
                    [],
                    [:RTLD_LAZY, :RTLD_DEEPBIND],
                ),
                JLLLibraryProduct(
                    :libstdcxx,
                    "lib/libstdc++.so",
                    [
                        JLLLibraryDep(nothing, :libgcc_s),
                    ],
                    [:RTLD_LAZY, :RTLD_DEEPBIND],
                ),
                JLLLibraryProduct(
                    :libquadmath,
                    "lib/libquadmath.so",
                    [],
                    [:RTLD_LAZY, :RTLD_DEEPBIND],
                ),
            ]
        ),

        JLLArtifactInfo(;
            src_version = v"1.0.5+1",
            deps = [],
            sources = [],
            platform = Platform("x86_64", "freebsd"; libgfortran_version = "5.0.0"),
            name = "default",
            treehash = "8939fa01cad3bd36d3014e58f40c904e0a511df2",
            download_sources = [
                JLLArtifactSource(
                    "https://github.com/JuliaBinaryWrappers/CompilerSupportLibraries_jll.jl/releases/download/CompilerSupportLibraries-v1.0.5+1/CompilerSupportLibraries.v1.0.5.x86_64-unknown-freebsd-libgfortran5.tar.gz",
                    "d41bf8f528aea9705b73b25924ddbe408afb2333ea4507dd67546185d74ed453",
                ),
            ],
            products = [
                JLLLibraryProduct(
                    :libatomic,
                    "lib/libatomic.so",
                    [],
                    [:RTLD_LAZY, :RTLD_DEEPBIND],
                ),
                JLLLibraryProduct(
                    :libgcc_s,
                    "lib/libgcc_s.so",
                    [],
                    [:RTLD_LAZY, :RTLD_DEEPBIND],
                ),
                JLLLibraryProduct(
                    :libgfortran,
                    "lib/libgfortran.so",
                    [
                        JLLLibraryDep(nothing, :libgcc_s),
                        JLLLibraryDep(nothing, :libquadmath)
                    ],
                    [:RTLD_LAZY, :RTLD_DEEPBIND],
                ),
                JLLLibraryProduct(
                    :libgomp,
                    "lib/libgomp.so",
                    [],
                    [:RTLD_LAZY, :RTLD_DEEPBIND],
                ),
                JLLLibraryProduct(
                    :libssp,
                    "lib/libssp.so",
                    [],
                    [:RTLD_LAZY, :RTLD_DEEPBIND],
                ),
                JLLLibraryProduct(
                    :libstdcxx,
                    "lib/libstdc++.so",
                    [
                        JLLLibraryDep(nothing, :libgcc_s),
                    ],
                    [:RTLD_LAZY, :RTLD_DEEPBIND],
                ),
                JLLLibraryProduct(
                    :libquadmath,
                    "lib/libquadmath.so",
                    [],
                    [:RTLD_LAZY, :RTLD_DEEPBIND],
                ),
            ]
        ),

        JLLArtifactInfo(;
            src_version = v"1.0.5+1",
            deps = [],
            sources = [],
            platform = Platform("x86_64", "windows"; libgfortran_version = "3.0.0"),
            name = "default",
            treehash = "402de15efce092d3693b10cf676227b2f3207f0c",
            download_sources = [
                JLLArtifactSource(
                    "https://github.com/JuliaBinaryWrappers/CompilerSupportLibraries_jll.jl/releases/download/CompilerSupportLibraries-v1.0.5+1/CompilerSupportLibraries.v1.0.5.x86_64-w64-mingw32-libgfortran3.tar.gz",
                    "401498410ca8b626c26985c96cf6aaec0d277627f405957dbcf7481b5cdc7939",
                ),
            ],
            products = [
                JLLLibraryProduct(
                    :libgcc_s,
                    "bin\\libgcc_s_seh-1.dll",
                    [],
                    [:RTLD_LAZY, :RTLD_DEEPBIND],
                ),
                JLLLibraryProduct(
                    :libgfortran,
                    "bin\\libgfortran-3.dll",
                    [
                        JLLLibraryDep(nothing, :libgcc_s),
                        JLLLibraryDep(nothing, :libquadmath)
                    ],
                    [:RTLD_LAZY, :RTLD_DEEPBIND],
                ),
                JLLLibraryProduct(
                    :libgomp,
                    "bin\\libgomp-1.dll",
                    [],
                    [:RTLD_LAZY, :RTLD_DEEPBIND],
                ),
                JLLLibraryProduct(
                    :libssp,
                    "bin\\libssp-0.dll",
                    [],
                    [:RTLD_LAZY, :RTLD_DEEPBIND],
                ),
                JLLLibraryProduct(
                    :libstdcxx,
                    "bin\\libstdc++-6.dll",
                    [
                        JLLLibraryDep(nothing, :libgcc_s),
                    ],
                    [:RTLD_LAZY, :RTLD_DEEPBIND],
                ),
                JLLLibraryProduct(
                    :libquadmath,
                    "bin\\libquadmath.6.dll",
                    [],
                    [:RTLD_LAZY, :RTLD_DEEPBIND],
                ),
                JLLFileProduct(
                    :libgcc_a,
                    "lib\\libgcc.a",
                ),
                JLLFileProduct(
                    :libgcc_s_a,
                    "lib\\libgcc_s.a",
                ),
                JLLFileProduct(
                    :libmsvcrt_a,
                    "lib\\libmsvcrt.a",
                ),
                JLLFileProduct(
                    :libssp_dll_a,
                    "lib\\libssp.dll.a",
                ),
            ]
        ),

        JLLArtifactInfo(;
            src_version = v"1.0.5+1",
            deps = [],
            sources = [],
            platform = Platform("x86_64", "windows"; libgfortran_version = "4.0.0"),
            name = "default",
            treehash = "631feda26f3eb729a0c738e1762bb682009e1d0a",
            download_sources = [
                JLLArtifactSource(
                    "https://github.com/JuliaBinaryWrappers/CompilerSupportLibraries_jll.jl/releases/download/CompilerSupportLibraries-v1.0.5+1/CompilerSupportLibraries.v1.0.5.x86_64-w64-mingw32-libgfortran4.tar.gz",
                    "67b78465585297c7f4ac35aeb60121d69b420da350a61da1bc5336bcd0eceebf",
                ),
            ],
            products = [
                JLLLibraryProduct(
                    :libatomic,
                    "bin\\libatomic-1.dll",
                    [],
                    [:RTLD_LAZY, :RTLD_DEEPBIND],
                ),
                JLLLibraryProduct(
                    :libgcc_s,
                    "bin\\libgcc_s_seh-1.dll",
                    [],
                    [:RTLD_LAZY, :RTLD_DEEPBIND],
                ),
                JLLLibraryProduct(
                    :libgfortran,
                    "bin\\libgfortran-4.dll",
                    [
                        JLLLibraryDep(nothing, :libgcc_s),
                        JLLLibraryDep(nothing, :libquadmath)
                    ],
                    [:RTLD_LAZY, :RTLD_DEEPBIND],
                ),
                JLLLibraryProduct(
                    :libgomp,
                    "bin\\libgomp-1.dll",
                    [],
                    [:RTLD_LAZY, :RTLD_DEEPBIND],
                ),
                JLLLibraryProduct(
                    :libssp,
                    "bin\\libssp-0.dll",
                    [],
                    [:RTLD_LAZY, :RTLD_DEEPBIND],
                ),
                JLLLibraryProduct(
                    :libstdcxx,
                    "bin\\libstdc++-6.dll",
                    [
                        JLLLibraryDep(nothing, :libgcc_s),
                    ],
                    [:RTLD_LAZY, :RTLD_DEEPBIND],
                ),
                JLLLibraryProduct(
                    :libquadmath,
                    "bin\\libquadmath.6.dll",
                    [],
                    [:RTLD_LAZY, :RTLD_DEEPBIND],
                ),
                JLLFileProduct(
                    :libgcc_a,
                    "lib\\libgcc.a",
                ),
                JLLFileProduct(
                    :libgcc_s_a,
                    "lib\\libgcc_s.a",
                ),
                JLLFileProduct(
                    :libmsvcrt_a,
                    "lib\\libmsvcrt.a",
                ),
                JLLFileProduct(
                    :libssp_dll_a,
                    "lib\\libssp.dll.a",
                ),
            ]
        ),

        JLLArtifactInfo(;
            src_version = v"1.0.5+1",
            deps = [],
            sources = [],
            platform = Platform("x86_64", "windows"; libgfortran_version = "5.0.0"),
            name = "default",
            treehash = "d7339957c4aec4035c9452e6675ea3efd84c9866",
            download_sources = [
                JLLArtifactSource(
                    "https://github.com/JuliaBinaryWrappers/CompilerSupportLibraries_jll.jl/releases/download/CompilerSupportLibraries-v1.0.5+1/CompilerSupportLibraries.v1.0.5.x86_64-w64-mingw32-libgfortran5.tar.gz",
                    "f6d30b900ebbe18c9be98f50f32a5e5061136ac29747523f93e6b9f3003b9445",
                ),
            ],
            products = [
                JLLLibraryProduct(
                    :libatomic,
                    "bin\\libatomic-1.dll",
                    [],
                    [:RTLD_LAZY, :RTLD_DEEPBIND],
                ),
                JLLLibraryProduct(
                    :libgcc_s,
                    "bin\\libgcc_s_seh-1.dll",
                    [],
                    [:RTLD_LAZY, :RTLD_DEEPBIND],
                ),
                JLLLibraryProduct(
                    :libgfortran,
                    "bin\\libgfortran-5.dll",
                    [
                        JLLLibraryDep(nothing, :libgcc_s),
                        JLLLibraryDep(nothing, :libquadmath)
                    ],
                    [:RTLD_LAZY, :RTLD_DEEPBIND],
                ),
                JLLLibraryProduct(
                    :libgomp,
                    "bin\\libgomp-1.dll",
                    [],
                    [:RTLD_LAZY, :RTLD_DEEPBIND],
                ),
                JLLLibraryProduct(
                    :libssp,
                    "bin\\libssp-0.dll",
                    [],
                    [:RTLD_LAZY, :RTLD_DEEPBIND],
                ),
                JLLLibraryProduct(
                    :libstdcxx,
                    "bin\\libstdc++-6.dll",
                    [
                        JLLLibraryDep(nothing, :libgcc_s),
                    ],
                    [:RTLD_LAZY, :RTLD_DEEPBIND],
                ),
                JLLLibraryProduct(
                    :libquadmath,
                    "bin\\libquadmath.6.dll",
                    [],
                    [:RTLD_LAZY, :RTLD_DEEPBIND],
                ),
                JLLFileProduct(
                    :libgcc_a,
                    "lib\\libgcc.a",
                ),
                JLLFileProduct(
                    :libgcc_s_a,
                    "lib\\libgcc_s.a",
                ),
                JLLFileProduct(
                    :libmsvcrt_a,
                    "lib\\libmsvcrt.a",
                ),
                JLLFileProduct(
                    :libssp_dll_a,
                    "lib\\libssp.dll.a",
                ),
            ]
        ),

    ]
)

