jll = JLLInfo(;
    name = "dSFMT",
    version = v"2.2.4+4",
    artifacts = [
        JLLArtifactInfo(;
            src_version = v"2.2.4+4",
            deps = [],
            sources = [],
            platform = Platform("aarch64", "macos"; ),
            name = "dSFMT",
            treehash = "edf61885d6b11e64ffabe3826d163bd7d4523d22",
            download_sources = [
                JLLArtifactSource(
                    "https://github.com/JuliaBinaryWrappers/dSFMT_jll.jl/releases/download/dSFMT-v2.2.4+4/dSFMT.v2.2.4.aarch64-apple-darwin.tar.gz",
                    "a5d364115a65cecf6891685c1b8d95f96b5b9ea2099c5b1d04a11f1a21548ac5",
                ),
            ],
            products = [
                JLLLibraryProduct(
                    :libdSFMT,
                    "lib/libdSFMT.dylib",
                    [],
                    [:RTLD_LAZY, :RTLD_DEEPBIND],
                ),
            ]
        ),

        JLLArtifactInfo(;
            src_version = v"2.2.4+4",
            deps = [],
            sources = [],
            platform = Platform("aarch64", "linux"; libc = "glibc"),
            name = "dSFMT",
            treehash = "7336cebf442e4c41f8d7f51c3276e63a58c620f7",
            download_sources = [
                JLLArtifactSource(
                    "https://github.com/JuliaBinaryWrappers/dSFMT_jll.jl/releases/download/dSFMT-v2.2.4+4/dSFMT.v2.2.4.aarch64-linux-gnu.tar.gz",
                    "fd2147de47079f541abf1e740c89fd5428a83b23b42137b7d1ffa19d3e1c0076",
                ),
            ],
            products = [
                JLLLibraryProduct(
                    :libdSFMT,
                    "lib/libdSFMT.so",
                    [],
                    [:RTLD_LAZY, :RTLD_DEEPBIND],
                ),
            ]
        ),

        JLLArtifactInfo(;
            src_version = v"2.2.4+4",
            deps = [],
            sources = [],
            platform = Platform("aarch64", "linux"; libc = "musl"),
            name = "dSFMT",
            treehash = "aa2d6168ccc4bd699ba6f8a47ad990b7559b4a0e",
            download_sources = [
                JLLArtifactSource(
                    "https://github.com/JuliaBinaryWrappers/dSFMT_jll.jl/releases/download/dSFMT-v2.2.4+4/dSFMT.v2.2.4.aarch64-linux-musl.tar.gz",
                    "86829833de6f223b15c564f461f1cc4b5fc105a2d60340445cefdba513561097",
                ),
            ],
            products = [
                JLLLibraryProduct(
                    :libdSFMT,
                    "lib/libdSFMT.so",
                    [],
                    [:RTLD_LAZY, :RTLD_DEEPBIND],
                ),
            ]
        ),

        JLLArtifactInfo(;
            src_version = v"2.2.4+4",
            deps = [],
            sources = [],
            platform = Platform("armv6l", "linux"; call_abi = "eabihf", libc = "glibc"),
            name = "dSFMT",
            treehash = "0c6a8d227238dc38010dd76267fcd1e122999af2",
            download_sources = [
                JLLArtifactSource(
                    "https://github.com/JuliaBinaryWrappers/dSFMT_jll.jl/releases/download/dSFMT-v2.2.4+4/dSFMT.v2.2.4.armv6l-linux-gnueabihf.tar.gz",
                    "b990709db455c72d94be6a9d9705ca40c49ae2fdb7467153c081afe63935cb0e",
                ),
            ],
            products = [
                JLLLibraryProduct(
                    :libdSFMT,
                    "lib/libdSFMT.so",
                    [],
                    [:RTLD_LAZY, :RTLD_DEEPBIND],
                ),
            ]
        ),

        JLLArtifactInfo(;
            src_version = v"2.2.4+4",
            deps = [],
            sources = [],
            platform = Platform("armv6l", "linux"; call_abi = "eabihf", libc = "musl"),
            name = "dSFMT",
            treehash = "8c7a50737bbab934cde1efa29fd0d01fa5cb6598",
            download_sources = [
                JLLArtifactSource(
                    "https://github.com/JuliaBinaryWrappers/dSFMT_jll.jl/releases/download/dSFMT-v2.2.4+4/dSFMT.v2.2.4.armv6l-linux-musleabihf.tar.gz",
                    "ee151f2d5cc9ecb79fa29ae64cd319607776c9a0c7bfb747481b36a53b6e015d",
                ),
            ],
            products = [
                JLLLibraryProduct(
                    :libdSFMT,
                    "lib/libdSFMT.so",
                    [],
                    [:RTLD_LAZY, :RTLD_DEEPBIND],
                ),
            ]
        ),

        JLLArtifactInfo(;
            src_version = v"2.2.4+4",
            deps = [],
            sources = [],
            platform = Platform("armv7l", "linux"; call_abi = "eabihf", libc = "glibc"),
            name = "dSFMT",
            treehash = "9561002894a0c2c9bd3b6d3a7f8b2a41a6e5b930",
            download_sources = [
                JLLArtifactSource(
                    "https://github.com/JuliaBinaryWrappers/dSFMT_jll.jl/releases/download/dSFMT-v2.2.4+4/dSFMT.v2.2.4.armv7l-linux-gnueabihf.tar.gz",
                    "e7009a43e949afa15e0d3d34ed14f139ddc40a3e642fe669c7ce3aa86b53f877",
                ),
            ],
            products = [
                JLLLibraryProduct(
                    :libdSFMT,
                    "lib/libdSFMT.so",
                    [],
                    [:RTLD_LAZY, :RTLD_DEEPBIND],
                ),
            ]
        ),

        JLLArtifactInfo(;
            src_version = v"2.2.4+4",
            deps = [],
            sources = [],
            platform = Platform("armv7l", "linux"; call_abi = "eabihf", libc = "musl"),
            name = "dSFMT",
            treehash = "d0a2ad0f6140582346c0b25bc7e22b74199f064c",
            download_sources = [
                JLLArtifactSource(
                    "https://github.com/JuliaBinaryWrappers/dSFMT_jll.jl/releases/download/dSFMT-v2.2.4+4/dSFMT.v2.2.4.armv7l-linux-musleabihf.tar.gz",
                    "2264153394970e1f8fe04e7995ac4cd4912913a0030bde2991fcabef105d5c74",
                ),
            ],
            products = [
                JLLLibraryProduct(
                    :libdSFMT,
                    "lib/libdSFMT.so",
                    [],
                    [:RTLD_LAZY, :RTLD_DEEPBIND],
                ),
            ]
        ),

        JLLArtifactInfo(;
            src_version = v"2.2.4+4",
            deps = [],
            sources = [],
            platform = Platform("i686", "linux"; libc = "glibc"),
            name = "dSFMT",
            treehash = "d1193f2f568de06aa4ec848088cfca1adfd5f18e",
            download_sources = [
                JLLArtifactSource(
                    "https://github.com/JuliaBinaryWrappers/dSFMT_jll.jl/releases/download/dSFMT-v2.2.4+4/dSFMT.v2.2.4.i686-linux-gnu.tar.gz",
                    "4d05cd28e8e2df39647ce3f2aef3a910e89261be1f1e5c2a712bb7e10aa3f9e0",
                ),
            ],
            products = [
                JLLLibraryProduct(
                    :libdSFMT,
                    "lib/libdSFMT.so",
                    [],
                    [:RTLD_LAZY, :RTLD_DEEPBIND],
                ),
            ]
        ),

        JLLArtifactInfo(;
            src_version = v"2.2.4+4",
            deps = [],
            sources = [],
            platform = Platform("i686", "linux"; libc = "musl"),
            name = "dSFMT",
            treehash = "fe260cf16bff8871e78b4e6609ad99a0efe4edb7",
            download_sources = [
                JLLArtifactSource(
                    "https://github.com/JuliaBinaryWrappers/dSFMT_jll.jl/releases/download/dSFMT-v2.2.4+4/dSFMT.v2.2.4.i686-linux-musl.tar.gz",
                    "3c81f411886ba3fd2ee9bcdb08be7a502b1c37339f9b7831185a7d5e844e756e",
                ),
            ],
            products = [
                JLLLibraryProduct(
                    :libdSFMT,
                    "lib/libdSFMT.so",
                    [],
                    [:RTLD_LAZY, :RTLD_DEEPBIND],
                ),
            ]
        ),

        JLLArtifactInfo(;
            src_version = v"2.2.4+4",
            deps = [],
            sources = [],
            platform = Platform("i686", "windows"; ),
            name = "dSFMT",
            treehash = "c8027b75d3d27eb2a3a74535e2dd632934a5c66f",
            download_sources = [
                JLLArtifactSource(
                    "https://github.com/JuliaBinaryWrappers/dSFMT_jll.jl/releases/download/dSFMT-v2.2.4+4/dSFMT.v2.2.4.i686-w64-mingw32.tar.gz",
                    "086ea8c8fd8e1383c6aa09a78a831d13faa3a8976f80cd22a38a683a40d4b333",
                ),
            ],
            products = [
                JLLLibraryProduct(
                    :libdSFMT,
                    "bin\\libdSFMT.dll",
                    [],
                    [:RTLD_LAZY, :RTLD_DEEPBIND],
                ),
            ]
        ),

        JLLArtifactInfo(;
            src_version = v"2.2.4+4",
            deps = [],
            sources = [],
            platform = Platform("powerpc64le", "linux"; libc = "glibc"),
            name = "dSFMT",
            treehash = "d8fd2267bb50fd6b4602b4a8d89673ee22284888",
            download_sources = [
                JLLArtifactSource(
                    "https://github.com/JuliaBinaryWrappers/dSFMT_jll.jl/releases/download/dSFMT-v2.2.4+4/dSFMT.v2.2.4.powerpc64le-linux-gnu.tar.gz",
                    "d5308c8331dbff504ad695fc9ca97724f407ade82af24ecda7471c95c554e354",
                ),
            ],
            products = [
                JLLLibraryProduct(
                    :libdSFMT,
                    "lib/libdSFMT.so",
                    [],
                    [:RTLD_LAZY, :RTLD_DEEPBIND],
                ),
            ]
        ),

        JLLArtifactInfo(;
            src_version = v"2.2.4+4",
            deps = [],
            sources = [],
            platform = Platform("x86_64", "macos"; ),
            name = "dSFMT",
            treehash = "ff50225db6bdc43bb6f61390628d6596b5a4269d",
            download_sources = [
                JLLArtifactSource(
                    "https://github.com/JuliaBinaryWrappers/dSFMT_jll.jl/releases/download/dSFMT-v2.2.4+4/dSFMT.v2.2.4.x86_64-apple-darwin.tar.gz",
                    "dd3547535399d68c163a8b92e803fb6cbd037e5b26d0fe8416954a3361025d1d",
                ),
            ],
            products = [
                JLLLibraryProduct(
                    :libdSFMT,
                    "lib/libdSFMT.dylib",
                    [],
                    [:RTLD_LAZY, :RTLD_DEEPBIND],
                ),
            ]
        ),

        JLLArtifactInfo(;
            src_version = v"2.2.4+4",
            deps = [],
            sources = [],
            platform = Platform("x86_64", "linux"; libc = "glibc"),
            name = "dSFMT",
            treehash = "059b1cf362cca007c9c3b1251443c8569743f7f3",
            download_sources = [
                JLLArtifactSource(
                    "https://github.com/JuliaBinaryWrappers/dSFMT_jll.jl/releases/download/dSFMT-v2.2.4+4/dSFMT.v2.2.4.x86_64-linux-gnu.tar.gz",
                    "438e961781bfa19a281c610a92755d53182f8da0c093aa529451e58e7379b382",
                ),
            ],
            products = [
                JLLLibraryProduct(
                    :libdSFMT,
                    "lib/libdSFMT.so",
                    [],
                    [:RTLD_LAZY, :RTLD_DEEPBIND],
                ),
            ]
        ),

        JLLArtifactInfo(;
            src_version = v"2.2.4+4",
            deps = [],
            sources = [],
            platform = Platform("x86_64", "linux"; libc = "glibc", sanitize = "memory"),
            name = "dSFMT",
            treehash = "504b4bb6fa837d8208a8d070481e10fae4948da2",
            download_sources = [
                JLLArtifactSource(
                    "https://github.com/JuliaBinaryWrappers/dSFMT_jll.jl/releases/download/dSFMT-v2.2.4+4/dSFMT.v2.2.4.x86_64-linux-gnu-sanitize+memory.tar.gz",
                    "1dcf4dd26730a3fc4e2466f191f2485cefcc1bb9ac1415dc47be7472b94ff902",
                ),
            ],
            products = [
                JLLLibraryProduct(
                    :libdSFMT,
                    "lib/libdSFMT.so",
                    [],
                    [:RTLD_LAZY, :RTLD_DEEPBIND],
                ),
            ]
        ),

        JLLArtifactInfo(;
            src_version = v"2.2.4+4",
            deps = [],
            sources = [],
            platform = Platform("x86_64", "linux"; libc = "musl"),
            name = "dSFMT",
            treehash = "7b18209ca9b9d0150947ac5ba267ca7660a8c07d",
            download_sources = [
                JLLArtifactSource(
                    "https://github.com/JuliaBinaryWrappers/dSFMT_jll.jl/releases/download/dSFMT-v2.2.4+4/dSFMT.v2.2.4.x86_64-linux-musl.tar.gz",
                    "0b210bd71984550ac923f41428458988c947e897d0210c6be1594da11d2d803f",
                ),
            ],
            products = [
                JLLLibraryProduct(
                    :libdSFMT,
                    "lib/libdSFMT.so",
                    [],
                    [:RTLD_LAZY, :RTLD_DEEPBIND],
                ),
            ]
        ),

        JLLArtifactInfo(;
            src_version = v"2.2.4+4",
            deps = [],
            sources = [],
            platform = Platform("x86_64", "freebsd"; ),
            name = "dSFMT",
            treehash = "45b4104a8d90268df7c1c2e651944e70d1a0bd7c",
            download_sources = [
                JLLArtifactSource(
                    "https://github.com/JuliaBinaryWrappers/dSFMT_jll.jl/releases/download/dSFMT-v2.2.4+4/dSFMT.v2.2.4.x86_64-unknown-freebsd.tar.gz",
                    "572dadcd6e6102fb33626bbb3a3dd9bb8f3cd23515f5a2d8fcdc37caf9ada046",
                ),
            ],
            products = [
                JLLLibraryProduct(
                    :libdSFMT,
                    "lib/libdSFMT.so",
                    [],
                    [:RTLD_LAZY, :RTLD_DEEPBIND],
                ),
            ]
        ),

        JLLArtifactInfo(;
            src_version = v"2.2.4+4",
            deps = [],
            sources = [],
            platform = Platform("x86_64", "windows"; ),
            name = "dSFMT",
            treehash = "12f3002eb0f008fe2995ed4b3665c3ffdebba7c7",
            download_sources = [
                JLLArtifactSource(
                    "https://github.com/JuliaBinaryWrappers/dSFMT_jll.jl/releases/download/dSFMT-v2.2.4+4/dSFMT.v2.2.4.x86_64-w64-mingw32.tar.gz",
                    "5e16edf5a53fb0bc707ac3cd4082d4cc86a05a655bac09d3bdfce829675cf79b",
                ),
            ],
            products = [
                JLLLibraryProduct(
                    :libdSFMT,
                    "bin\\libdSFMT.dll",
                    [],
                    [:RTLD_LAZY, :RTLD_DEEPBIND],
                ),
            ]
        ),

    ]
)

