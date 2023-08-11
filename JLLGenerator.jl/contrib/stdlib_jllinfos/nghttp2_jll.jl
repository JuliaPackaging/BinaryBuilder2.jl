jll = JLLInfo(;
    name = "nghttp2",
    version = v"1.52.0+1",
    artifacts = [
        JLLArtifactInfo(;
            src_version = v"1.52.0+1",
            deps = [
            ],
            sources = [],
            platform = Platform("aarch64", "macos"; ),
            name = "nghttp2",
            treehash = "5bdf176d27a679d485fd66a415859ac7e838ae9a",
            download_sources = [
                JLLArtifactSource(
                    "https://github.com/JuliaBinaryWrappers/nghttp2_jll.jl/releases/download/nghttp2-v1.52.0+1/nghttp2.v1.52.0.aarch64-apple-darwin.tar.gz",
                    "87e9075e7abc5d7e869086b8e7eaf229ccb654ea9998979adf74fcc5b7a61b8c",
                ),
            ],
            products = [
                JLLLibraryProduct(
                    :libnghttp2,
                    "lib/libnghttp2.14.dylib",
                    [],
                    [:RTLD_LAZY, :RTLD_DEEPBIND],
                ),
            ]
        ),

        JLLArtifactInfo(;
            src_version = v"1.52.0+1",
            deps = [
            ],
            sources = [],
            platform = Platform("aarch64", "linux"; libc = "glibc"),
            name = "nghttp2",
            treehash = "ee643801313cd1bf7f641f359584e1b11f1cd732",
            download_sources = [
                JLLArtifactSource(
                    "https://github.com/JuliaBinaryWrappers/nghttp2_jll.jl/releases/download/nghttp2-v1.52.0+1/nghttp2.v1.52.0.aarch64-linux-gnu.tar.gz",
                    "d6ac81e1be76ba535e50f2674d6b8cef1ef21c09936978caef69c0d37f6e2485",
                ),
            ],
            products = [
                JLLLibraryProduct(
                    :libnghttp2,
                    "lib/libnghttp2.so",
                    [],
                    [:RTLD_LAZY, :RTLD_DEEPBIND],
                ),
            ]
        ),

        JLLArtifactInfo(;
            src_version = v"1.52.0+1",
            deps = [
            ],
            sources = [],
            platform = Platform("aarch64", "linux"; libc = "musl"),
            name = "nghttp2",
            treehash = "8b6ab2a01e3649c51b9cec010606e71a5d921be5",
            download_sources = [
                JLLArtifactSource(
                    "https://github.com/JuliaBinaryWrappers/nghttp2_jll.jl/releases/download/nghttp2-v1.52.0+1/nghttp2.v1.52.0.aarch64-linux-musl.tar.gz",
                    "05a8f45d63b3584b69b4f04ca589ed3d38fd05740d7e2d09afc71be1e013c4aa",
                ),
            ],
            products = [
                JLLLibraryProduct(
                    :libnghttp2,
                    "lib/libnghttp2.so",
                    [],
                    [:RTLD_LAZY, :RTLD_DEEPBIND],
                ),
            ]
        ),

        JLLArtifactInfo(;
            src_version = v"1.52.0+1",
            deps = [
            ],
            sources = [],
            platform = Platform("armv6l", "linux"; call_abi = "eabihf", libc = "glibc"),
            name = "nghttp2",
            treehash = "c2559b9e4ac0363bd3ef40d0f67da51633bd2d88",
            download_sources = [
                JLLArtifactSource(
                    "https://github.com/JuliaBinaryWrappers/nghttp2_jll.jl/releases/download/nghttp2-v1.52.0+1/nghttp2.v1.52.0.armv6l-linux-gnueabihf.tar.gz",
                    "b33e930b62ef1c2b0483de0735478b5df9236ae4abdb367cf3a2a719401e23f9",
                ),
            ],
            products = [
                JLLLibraryProduct(
                    :libnghttp2,
                    "lib/libnghttp2.so",
                    [],
                    [:RTLD_LAZY, :RTLD_DEEPBIND],
                ),
            ]
        ),

        JLLArtifactInfo(;
            src_version = v"1.52.0+1",
            deps = [
            ],
            sources = [],
            platform = Platform("armv6l", "linux"; call_abi = "eabihf", libc = "musl"),
            name = "nghttp2",
            treehash = "b6a24c38296a077f11fc59a584450abe86cdd6af",
            download_sources = [
                JLLArtifactSource(
                    "https://github.com/JuliaBinaryWrappers/nghttp2_jll.jl/releases/download/nghttp2-v1.52.0+1/nghttp2.v1.52.0.armv6l-linux-musleabihf.tar.gz",
                    "8082b28e366b1dd8f2e046269a037ff00f25ef78f490433ccfe8fc87f0ee2269",
                ),
            ],
            products = [
                JLLLibraryProduct(
                    :libnghttp2,
                    "lib/libnghttp2.so",
                    [],
                    [:RTLD_LAZY, :RTLD_DEEPBIND],
                ),
            ]
        ),

        JLLArtifactInfo(;
            src_version = v"1.52.0+1",
            deps = [
            ],
            sources = [],
            platform = Platform("armv7l", "linux"; call_abi = "eabihf", libc = "glibc"),
            name = "nghttp2",
            treehash = "6d2477dff94d1c9637caf0db5418a4518376a88a",
            download_sources = [
                JLLArtifactSource(
                    "https://github.com/JuliaBinaryWrappers/nghttp2_jll.jl/releases/download/nghttp2-v1.52.0+1/nghttp2.v1.52.0.armv7l-linux-gnueabihf.tar.gz",
                    "423d39a5dc42563547e6fec02dce49c523349ad348e6ba0c949196cce69efc41",
                ),
            ],
            products = [
                JLLLibraryProduct(
                    :libnghttp2,
                    "lib/libnghttp2.so",
                    [],
                    [:RTLD_LAZY, :RTLD_DEEPBIND],
                ),
            ]
        ),

        JLLArtifactInfo(;
            src_version = v"1.52.0+1",
            deps = [
            ],
            sources = [],
            platform = Platform("armv7l", "linux"; call_abi = "eabihf", libc = "musl"),
            name = "nghttp2",
            treehash = "e207a079addd37872edd3f5adbbdd5b198f881b4",
            download_sources = [
                JLLArtifactSource(
                    "https://github.com/JuliaBinaryWrappers/nghttp2_jll.jl/releases/download/nghttp2-v1.52.0+1/nghttp2.v1.52.0.armv7l-linux-musleabihf.tar.gz",
                    "549f3554a750088c919efd68333dfcb20ffc2db0feabeb83dc7a852419cb29fc",
                ),
            ],
            products = [
                JLLLibraryProduct(
                    :libnghttp2,
                    "lib/libnghttp2.so",
                    [],
                    [:RTLD_LAZY, :RTLD_DEEPBIND],
                ),
            ]
        ),

        JLLArtifactInfo(;
            src_version = v"1.52.0+1",
            deps = [
            ],
            sources = [],
            platform = Platform("i686", "linux"; libc = "glibc"),
            name = "nghttp2",
            treehash = "11a67bb89e9baf1093e8949f8844eafa333891d6",
            download_sources = [
                JLLArtifactSource(
                    "https://github.com/JuliaBinaryWrappers/nghttp2_jll.jl/releases/download/nghttp2-v1.52.0+1/nghttp2.v1.52.0.i686-linux-gnu.tar.gz",
                    "60e4d13c17f7b7e850fa542dd0771a6c24b82bcc42c3e6681e8a4ac58c71a724",
                ),
            ],
            products = [
                JLLLibraryProduct(
                    :libnghttp2,
                    "lib/libnghttp2.so",
                    [],
                    [:RTLD_LAZY, :RTLD_DEEPBIND],
                ),
            ]
        ),

        JLLArtifactInfo(;
            src_version = v"1.52.0+1",
            deps = [
            ],
            sources = [],
            platform = Platform("i686", "linux"; libc = "musl"),
            name = "nghttp2",
            treehash = "6867390c22cd2b63fdc0f4c48bf0ec31207b389e",
            download_sources = [
                JLLArtifactSource(
                    "https://github.com/JuliaBinaryWrappers/nghttp2_jll.jl/releases/download/nghttp2-v1.52.0+1/nghttp2.v1.52.0.i686-linux-musl.tar.gz",
                    "f50666213f117de7bee2b06a4bb6207d6919469fd92f451f54fe84cd7a8fea62",
                ),
            ],
            products = [
                JLLLibraryProduct(
                    :libnghttp2,
                    "lib/libnghttp2.so",
                    [],
                    [:RTLD_LAZY, :RTLD_DEEPBIND],
                ),
            ]
        ),

        JLLArtifactInfo(;
            src_version = v"1.52.0+1",
            deps = [
            ],
            sources = [],
            platform = Platform("i686", "windows"; ),
            name = "nghttp2",
            treehash = "d4127a2ea695da2d7bdb1cc636956324a412c7f1",
            download_sources = [
                JLLArtifactSource(
                    "https://github.com/JuliaBinaryWrappers/nghttp2_jll.jl/releases/download/nghttp2-v1.52.0+1/nghttp2.v1.52.0.i686-w64-mingw32.tar.gz",
                    "e7eaf5d0dcabd25e1ad741e9100ce8943a9537e29b6607f8867acfbf13f73eca",
                ),
            ],
            products = [
                JLLLibraryProduct(
                    :libnghttp2,
                    "bin\\libnghttp2-14.dll",
                    [],
                    [:RTLD_LAZY, :RTLD_DEEPBIND],
                ),
            ]
        ),

        JLLArtifactInfo(;
            src_version = v"1.52.0+1",
            deps = [
            ],
            sources = [],
            platform = Platform("powerpc64le", "linux"; libc = "glibc"),
            name = "nghttp2",
            treehash = "e6747a03d561d8f669a6e3c8e52e0f1eb9ffa154",
            download_sources = [
                JLLArtifactSource(
                    "https://github.com/JuliaBinaryWrappers/nghttp2_jll.jl/releases/download/nghttp2-v1.52.0+1/nghttp2.v1.52.0.powerpc64le-linux-gnu.tar.gz",
                    "1f666ff9ec159de9f015a314116b1ca4e275529d86df12064df247fe89e216e6",
                ),
            ],
            products = [
                JLLLibraryProduct(
                    :libnghttp2,
                    "lib/libnghttp2.so",
                    [],
                    [:RTLD_LAZY, :RTLD_DEEPBIND],
                ),
            ]
        ),

        JLLArtifactInfo(;
            src_version = v"1.52.0+1",
            deps = [
            ],
            sources = [],
            platform = Platform("x86_64", "macos"; ),
            name = "nghttp2",
            treehash = "a3e87e54c611248fae619d45233f10bebd8c071a",
            download_sources = [
                JLLArtifactSource(
                    "https://github.com/JuliaBinaryWrappers/nghttp2_jll.jl/releases/download/nghttp2-v1.52.0+1/nghttp2.v1.52.0.x86_64-apple-darwin.tar.gz",
                    "beb18f93e657081d17605d16e4fb08f33237ef38f6491704c59db2e8bbf6b0de",
                ),
            ],
            products = [
                JLLLibraryProduct(
                    :libnghttp2,
                    "lib/libnghttp2.14.dylib",
                    [],
                    [:RTLD_LAZY, :RTLD_DEEPBIND],
                ),
            ]
        ),

        JLLArtifactInfo(;
            src_version = v"1.52.0+1",
            deps = [
            ],
            sources = [],
            platform = Platform("x86_64", "linux"; libc = "glibc"),
            name = "nghttp2",
            treehash = "5ac5cd90363a5fdedcd7321dd3b7f93ec39462d3",
            download_sources = [
                JLLArtifactSource(
                    "https://github.com/JuliaBinaryWrappers/nghttp2_jll.jl/releases/download/nghttp2-v1.52.0+1/nghttp2.v1.52.0.x86_64-linux-gnu.tar.gz",
                    "58777344b69ab50a019d07e2368df315c94167f759897286ff338a1c3d3e9efb",
                ),
            ],
            products = [
                JLLLibraryProduct(
                    :libnghttp2,
                    "lib/libnghttp2.so",
                    [],
                    [:RTLD_LAZY, :RTLD_DEEPBIND],
                ),
            ]
        ),

        JLLArtifactInfo(;
            src_version = v"1.52.0+1",
            deps = [
            ],
            sources = [],
            platform = Platform("x86_64", "linux"; libc = "glibc", sanitize = "memory"),
            name = "nghttp2",
            treehash = "6cdb43dcb66f8a50d53a51cf64ba1a44242c8fda",
            download_sources = [
                JLLArtifactSource(
                    "https://github.com/JuliaBinaryWrappers/nghttp2_jll.jl/releases/download/nghttp2-v1.52.0+1/nghttp2.v1.52.0.x86_64-linux-gnu-sanitize+memory.tar.gz",
                    "4116b0c728a3f14ce36c62d46cb6b087203b74058872a6e7389ef839bca774e9",
                ),
            ],
            products = [
                JLLLibraryProduct(
                    :libnghttp2,
                    "lib/libnghttp2.so",
                    [],
                    [:RTLD_LAZY, :RTLD_DEEPBIND],
                ),
            ]
        ),

        JLLArtifactInfo(;
            src_version = v"1.52.0+1",
            deps = [
            ],
            sources = [],
            platform = Platform("x86_64", "linux"; libc = "musl"),
            name = "nghttp2",
            treehash = "f4135004438423aa9703155ead9feaea941cccd2",
            download_sources = [
                JLLArtifactSource(
                    "https://github.com/JuliaBinaryWrappers/nghttp2_jll.jl/releases/download/nghttp2-v1.52.0+1/nghttp2.v1.52.0.x86_64-linux-musl.tar.gz",
                    "565e4182bdfb9c4084c1b0ff1c4bed8086bd318054d873be6c53a68474a16c09",
                ),
            ],
            products = [
                JLLLibraryProduct(
                    :libnghttp2,
                    "lib/libnghttp2.so",
                    [],
                    [:RTLD_LAZY, :RTLD_DEEPBIND],
                ),
            ]
        ),

        JLLArtifactInfo(;
            src_version = v"1.52.0+1",
            deps = [
            ],
            sources = [],
            platform = Platform("x86_64", "freebsd"; ),
            name = "nghttp2",
            treehash = "a68c4ec5569996dcf33de8e2c5d7d9c399902cc1",
            download_sources = [
                JLLArtifactSource(
                    "https://github.com/JuliaBinaryWrappers/nghttp2_jll.jl/releases/download/nghttp2-v1.52.0+1/nghttp2.v1.52.0.x86_64-unknown-freebsd.tar.gz",
                    "31f5d85db8b114838c0f35d9dc1b6d97193c7d529c3a3a679cc8e3157d0bf786",
                ),
            ],
            products = [
                JLLLibraryProduct(
                    :libnghttp2,
                    "lib/libnghttp2.so",
                    [],
                    [:RTLD_LAZY, :RTLD_DEEPBIND],
                ),
            ]
        ),

        JLLArtifactInfo(;
            src_version = v"1.52.0+1",
            deps = [
            ],
            sources = [],
            platform = Platform("x86_64", "windows"; ),
            name = "nghttp2",
            treehash = "a576f703ca94346b43fae9985fefe15fe3949897",
            download_sources = [
                JLLArtifactSource(
                    "https://github.com/JuliaBinaryWrappers/nghttp2_jll.jl/releases/download/nghttp2-v1.52.0+1/nghttp2.v1.52.0.x86_64-w64-mingw32.tar.gz",
                    "adaabfbe123e7007b136b4ce0cf45beced44af2a82c7261cacc76a059ded7891",
                ),
            ],
            products = [
                JLLLibraryProduct(
                    :libnghttp2,
                    "bin\\libnghttp2-14.dll",
                    [],
                    [:RTLD_LAZY, :RTLD_DEEPBIND],
                ),
            ]
        ),

    ]
)

