jll = JLLInfo(;
    name = "LibUnwind",
    version = v"1.5.0+5",
    artifacts = [
        JLLArtifactInfo(;
            src_version = v"1.5.0+5",
            deps = [
                JLLPackageDependency(
                    "Zlib_jll",
                    Base.UUID("83775a58-1f1d-513f-b197-d71354ab007a"),
                    "*",
                ),
            ],
            sources = [],
            platform = Platform("aarch64", "linux"; libc = "glibc"),
            name = "LibUnwind",
            treehash = "7bccd2ab421474277a5978c81cb73a90a7a71ca3",
            download_sources = [
                JLLArtifactSource(
                    "https://github.com/JuliaBinaryWrappers/LibUnwind_jll.jl/releases/download/LibUnwind-v1.5.0+5/LibUnwind.v1.5.0.aarch64-linux-gnu.tar.gz",
                    "16cf1d96c775a6195451a8402f96ac61e19125ac4841bd9b4d6c6c7f589482bf",
                ),
            ],
            products = [
                JLLLibraryProduct(
                    :libunwind,
                    "lib/libunwind.so",
                    [
                        JLLLibraryDep(:Zlib_jll, :libz),
                    ],
                    [:RTLD_LAZY, :RTLD_DEEPBIND],
                ),
            ]
        ),

        JLLArtifactInfo(;
            src_version = v"1.5.0+5",
            deps = [
                JLLPackageDependency(
                    "Zlib_jll",
                    Base.UUID("83775a58-1f1d-513f-b197-d71354ab007a"),
                    "*",
                ),
            ],
            sources = [],
            platform = Platform("aarch64", "linux"; libc = "musl"),
            name = "LibUnwind",
            treehash = "54f7330814d267d3e58b78ee0af4973dd30ceadb",
            download_sources = [
                JLLArtifactSource(
                    "https://github.com/JuliaBinaryWrappers/LibUnwind_jll.jl/releases/download/LibUnwind-v1.5.0+5/LibUnwind.v1.5.0.aarch64-linux-musl.tar.gz",
                    "06dff7ba17d36f917a4d6a7ea80ccc1a49ecec01c3a42a63d665df1e531c0931",
                ),
            ],
            products = [
                JLLLibraryProduct(
                    :libunwind,
                    "lib/libunwind.so",
                    [
                        JLLLibraryDep(:Zlib_jll, :libz),
                    ],
                    [:RTLD_LAZY, :RTLD_DEEPBIND],
                ),
            ]
        ),

        JLLArtifactInfo(;
            src_version = v"1.5.0+5",
            deps = [
                JLLPackageDependency(
                    "Zlib_jll",
                    Base.UUID("83775a58-1f1d-513f-b197-d71354ab007a"),
                    "*",
                ),
            ],
            sources = [],
            platform = Platform("armv6l", "linux"; call_abi = "eabihf", libc = "glibc"),
            name = "LibUnwind",
            treehash = "c9a3ca68c98504d0b08dd14717fed19a34bd13b0",
            download_sources = [
                JLLArtifactSource(
                    "https://github.com/JuliaBinaryWrappers/LibUnwind_jll.jl/releases/download/LibUnwind-v1.5.0+5/LibUnwind.v1.5.0.armv6l-linux-gnueabihf.tar.gz",
                    "336ab9dcc11e4224fe2775183c05ac46b445259a3fa316e79466ed5ae0af5f1f",
                ),
            ],
            products = [
                JLLLibraryProduct(
                    :libunwind,
                    "lib/libunwind.so",
                    [
                        JLLLibraryDep(:Zlib_jll, :libz),
                    ],
                    [:RTLD_LAZY, :RTLD_DEEPBIND],
                ),
            ]
        ),

        JLLArtifactInfo(;
            src_version = v"1.5.0+5",
            deps = [
                JLLPackageDependency(
                    "Zlib_jll",
                    Base.UUID("83775a58-1f1d-513f-b197-d71354ab007a"),
                    "*",
                ),
            ],
            sources = [],
            platform = Platform("armv6l", "linux"; call_abi = "eabihf", libc = "musl"),
            name = "LibUnwind",
            treehash = "f80fda871c960dfb83b1231bfd3d7c39cb21ea0c",
            download_sources = [
                JLLArtifactSource(
                    "https://github.com/JuliaBinaryWrappers/LibUnwind_jll.jl/releases/download/LibUnwind-v1.5.0+5/LibUnwind.v1.5.0.armv6l-linux-musleabihf.tar.gz",
                    "1a50f46c9dba014f09273b026fe33cc9466b62d943510b3568b4014ce53125c4",
                ),
            ],
            products = [
                JLLLibraryProduct(
                    :libunwind,
                    "lib/libunwind.so",
                    [
                        JLLLibraryDep(:Zlib_jll, :libz),
                    ],
                    [:RTLD_LAZY, :RTLD_DEEPBIND],
                ),
            ]
        ),

        JLLArtifactInfo(;
            src_version = v"1.5.0+5",
            deps = [
                JLLPackageDependency(
                    "Zlib_jll",
                    Base.UUID("83775a58-1f1d-513f-b197-d71354ab007a"),
                    "*",
                ),
            ],
            sources = [],
            platform = Platform("armv7l", "linux"; call_abi = "eabihf", libc = "glibc"),
            name = "LibUnwind",
            treehash = "e2a1517082330b0357a4a192cd4b844740e4c9db",
            download_sources = [
                JLLArtifactSource(
                    "https://github.com/JuliaBinaryWrappers/LibUnwind_jll.jl/releases/download/LibUnwind-v1.5.0+5/LibUnwind.v1.5.0.armv7l-linux-gnueabihf.tar.gz",
                    "d038cb94017d90c27a3ebf221b4807babd68ab5968e9bfdf70a38d27920463c5",
                ),
            ],
            products = [
                JLLLibraryProduct(
                    :libunwind,
                    "lib/libunwind.so",
                    [
                        JLLLibraryDep(:Zlib_jll, :libz),
                    ],
                    [:RTLD_LAZY, :RTLD_DEEPBIND],
                ),
            ]
        ),

        JLLArtifactInfo(;
            src_version = v"1.5.0+5",
            deps = [
                JLLPackageDependency(
                    "Zlib_jll",
                    Base.UUID("83775a58-1f1d-513f-b197-d71354ab007a"),
                    "*",
                ),
            ],
            sources = [],
            platform = Platform("armv7l", "linux"; call_abi = "eabihf", libc = "musl"),
            name = "LibUnwind",
            treehash = "6db8c9473279028a23a59715f9c81e9f96af0403",
            download_sources = [
                JLLArtifactSource(
                    "https://github.com/JuliaBinaryWrappers/LibUnwind_jll.jl/releases/download/LibUnwind-v1.5.0+5/LibUnwind.v1.5.0.armv7l-linux-musleabihf.tar.gz",
                    "cbd6f0ffdc772368d41ae9f580e4616a6a7a9ce2caf47f3124acf3452b8f3f0c",
                ),
            ],
            products = [
                JLLLibraryProduct(
                    :libunwind,
                    "lib/libunwind.so",
                    [
                        JLLLibraryDep(:Zlib_jll, :libz),
                    ],
                    [:RTLD_LAZY, :RTLD_DEEPBIND],
                ),
            ]
        ),

        JLLArtifactInfo(;
            src_version = v"1.5.0+5",
            deps = [
                JLLPackageDependency(
                    "Zlib_jll",
                    Base.UUID("83775a58-1f1d-513f-b197-d71354ab007a"),
                    "*",
                ),
            ],
            sources = [],
            platform = Platform("i686", "linux"; libc = "glibc"),
            name = "LibUnwind",
            treehash = "fca03b9f31307428fe8f3c3752ae52a7c8f53d8c",
            download_sources = [
                JLLArtifactSource(
                    "https://github.com/JuliaBinaryWrappers/LibUnwind_jll.jl/releases/download/LibUnwind-v1.5.0+5/LibUnwind.v1.5.0.i686-linux-gnu.tar.gz",
                    "ecd22a98b7b6e6246f68c1a93717ac78da87bdfdf5976a3da6d2af07b85fd9ff",
                ),
            ],
            products = [
                JLLLibraryProduct(
                    :libunwind,
                    "lib/libunwind.so",
                    [
                        JLLLibraryDep(:Zlib_jll, :libz),
                    ],
                    [:RTLD_LAZY, :RTLD_DEEPBIND],
                ),
            ]
        ),

        JLLArtifactInfo(;
            src_version = v"1.5.0+5",
            deps = [
                JLLPackageDependency(
                    "Zlib_jll",
                    Base.UUID("83775a58-1f1d-513f-b197-d71354ab007a"),
                    "*",
                ),
            ],
            sources = [],
            platform = Platform("i686", "linux"; libc = "musl"),
            name = "LibUnwind",
            treehash = "cb71fc8cf968e95d696c759cabb41ca8fc18221c",
            download_sources = [
                JLLArtifactSource(
                    "https://github.com/JuliaBinaryWrappers/LibUnwind_jll.jl/releases/download/LibUnwind-v1.5.0+5/LibUnwind.v1.5.0.i686-linux-musl.tar.gz",
                    "6e76702b6a5eedcbb49ccc3f272b41c120f46e400938780790c6dfdf1881e5ba",
                ),
            ],
            products = [
                JLLLibraryProduct(
                    :libunwind,
                    "lib/libunwind.so",
                    [
                        JLLLibraryDep(:Zlib_jll, :libz),
                    ],
                    [:RTLD_LAZY, :RTLD_DEEPBIND],
                ),
            ]
        ),

        JLLArtifactInfo(;
            src_version = v"1.5.0+5",
            deps = [
                JLLPackageDependency(
                    "Zlib_jll",
                    Base.UUID("83775a58-1f1d-513f-b197-d71354ab007a"),
                    "*",
                ),
            ],
            sources = [],
            platform = Platform("powerpc64le", "linux"; libc = "glibc"),
            name = "LibUnwind",
            treehash = "ad20fc787f7438d705f5e705427e44856d422a7e",
            download_sources = [
                JLLArtifactSource(
                    "https://github.com/JuliaBinaryWrappers/LibUnwind_jll.jl/releases/download/LibUnwind-v1.5.0+5/LibUnwind.v1.5.0.powerpc64le-linux-gnu.tar.gz",
                    "a2f95e19da0bc2162619eb9e714e8f2e55d13bd6a2db7859943386853692f2d5",
                ),
            ],
            products = [
                JLLLibraryProduct(
                    :libunwind,
                    "lib/libunwind.so",
                    [
                        JLLLibraryDep(:Zlib_jll, :libz),
                    ],
                    [:RTLD_LAZY, :RTLD_DEEPBIND],
                ),
            ]
        ),

        JLLArtifactInfo(;
            src_version = v"1.5.0+5",
            deps = [
                JLLPackageDependency(
                    "Zlib_jll",
                    Base.UUID("83775a58-1f1d-513f-b197-d71354ab007a"),
                    "*",
                ),
            ],
            sources = [],
            platform = Platform("x86_64", "linux"; libc = "glibc"),
            name = "LibUnwind",
            treehash = "ef6dd6c946402ed82ada48211d70a5d2c2653869",
            download_sources = [
                JLLArtifactSource(
                    "https://github.com/JuliaBinaryWrappers/LibUnwind_jll.jl/releases/download/LibUnwind-v1.5.0+5/LibUnwind.v1.5.0.x86_64-linux-gnu.tar.gz",
                    "9aa77c84e6cd934512cd713e53592f7deef6776da544af858e95a55e277bdf20",
                ),
            ],
            products = [
                JLLLibraryProduct(
                    :libunwind,
                    "lib/libunwind.so",
                    [
                        JLLLibraryDep(:Zlib_jll, :libz),
                    ],
                    [:RTLD_LAZY, :RTLD_DEEPBIND],
                ),
            ]
        ),

        JLLArtifactInfo(;
            src_version = v"1.5.0+5",
            deps = [
                JLLPackageDependency(
                    "Zlib_jll",
                    Base.UUID("83775a58-1f1d-513f-b197-d71354ab007a"),
                    "*",
                ),
            ],
            sources = [],
            platform = Platform("x86_64", "linux"; libc = "glibc", sanitize = "memory"),
            name = "LibUnwind",
            treehash = "93495ad4ec5fff6b1ae02343bab9d1fa8647f174",
            download_sources = [
                JLLArtifactSource(
                    "https://github.com/JuliaBinaryWrappers/LibUnwind_jll.jl/releases/download/LibUnwind-v1.5.0+5/LibUnwind.v1.5.0.x86_64-linux-gnu-sanitize+memory.tar.gz",
                    "086cfc647672c08fc99b3b1839a4a440cc5287e25bb0d133fa5cfc27aa421dff",
                ),
            ],
            products = [
                JLLLibraryProduct(
                    :libunwind,
                    "lib/libunwind.so",
                    [
                        JLLLibraryDep(:Zlib_jll, :libz),
                    ],
                    [:RTLD_LAZY, :RTLD_DEEPBIND],
                ),
            ]
        ),

        JLLArtifactInfo(;
            src_version = v"1.5.0+5",
            deps = [
                JLLPackageDependency(
                    "Zlib_jll",
                    Base.UUID("83775a58-1f1d-513f-b197-d71354ab007a"),
                    "*",
                ),
            ],
            sources = [],
            platform = Platform("x86_64", "linux"; libc = "musl"),
            name = "LibUnwind",
            treehash = "1d93ec1aed750373ab131eaa94fa743707aee0d0",
            download_sources = [
                JLLArtifactSource(
                    "https://github.com/JuliaBinaryWrappers/LibUnwind_jll.jl/releases/download/LibUnwind-v1.5.0+5/LibUnwind.v1.5.0.x86_64-linux-musl.tar.gz",
                    "6cea96a2bdb399df96f020d432a1240743fa329687f958079e0304eccc9b9167",
                ),
            ],
            products = [
                JLLLibraryProduct(
                    :libunwind,
                    "lib/libunwind.so",
                    [
                        JLLLibraryDep(:Zlib_jll, :libz),
                    ],
                    [:RTLD_LAZY, :RTLD_DEEPBIND],
                ),
            ]
        ),

        JLLArtifactInfo(;
            src_version = v"1.5.0+5",
            deps = [
                JLLPackageDependency(
                    "Zlib_jll",
                    Base.UUID("83775a58-1f1d-513f-b197-d71354ab007a"),
                    "*",
                ),
            ],
            sources = [],
            platform = Platform("x86_64", "freebsd"; ),
            name = "LibUnwind",
            treehash = "05c326aeaa21044f58574f6b4c3205afa8479fd1",
            download_sources = [
                JLLArtifactSource(
                    "https://github.com/JuliaBinaryWrappers/LibUnwind_jll.jl/releases/download/LibUnwind-v1.5.0+5/LibUnwind.v1.5.0.x86_64-unknown-freebsd.tar.gz",
                    "469efa47b10159c33e8f7428d1926a48e2bb18e97cb75191012eb48bcf6ad5b0",
                ),
            ],
            products = [
                JLLLibraryProduct(
                    :libunwind,
                    "lib/libunwind.so",
                    [
                        JLLLibraryDep(:Zlib_jll, :libz),
                    ],
                    [:RTLD_LAZY, :RTLD_DEEPBIND],
                ),
            ]
        ),

    ]
)

