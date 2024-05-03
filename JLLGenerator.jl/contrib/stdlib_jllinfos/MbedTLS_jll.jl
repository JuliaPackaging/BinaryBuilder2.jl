jll = JLLInfo(;
    name = "MbedTLS",
    version = v"2.28.2+1",
    artifacts = [
        JLLArtifactInfo(;
            src_version = v"2.28.2+1",
            deps = [
            ],
            sources = [],
            platform = Platform("aarch64", "macos"; ),
            name = "default",
            treehash = "6b00cebabc9c70c58d08f0e2d3fa4d39420e8ea4",
            download_sources = [
                JLLArtifactSource(
                    "https://github.com/JuliaBinaryWrappers/MbedTLS_jll.jl/releases/download/MbedTLS-v2.28.2+1/MbedTLS.v2.28.2.aarch64-apple-darwin.tar.gz",
                    "daa2afdea5fb8497183f43c36984cd78eb2fd8d3623fd6ab6d7d5540f53e49d9",
                ),
            ],
            products = [
                JLLLibraryProduct(
                    :libmbedcrypto,
                    "lib/libmbedcrypto.2.28.2.dylib",
                    [],
                    flags = [:RTLD_LAZY, :RTLD_DEEPBIND],
                ),
                JLLLibraryProduct(
                    :libmbedtls,
                    "lib/libmbedtls.14.dylib",
                    [
                        JLLLibraryDep(nothing, :libmbedcrypto),
                        JLLLibraryDep(nothing, :libmbedx509),
                    ],
                    flags = [:RTLD_LAZY, :RTLD_DEEPBIND],
                ),
                JLLLibraryProduct(
                    :libmbedx509,
                    "lib/libmbedx509.1.dylib",
                    [
                        JLLLibraryDep(nothing, :libmbedcrypto)
                    ],
                    flags = [:RTLD_LAZY, :RTLD_DEEPBIND],
                ),
            ]
        ),

        JLLArtifactInfo(;
            src_version = v"2.28.2+1",
            deps = [
            ],
            sources = [],
            platform = Platform("aarch64", "linux"; libc = "glibc"),
            name = "default",
            treehash = "b42b8d9c1c04291f2e1da12fa6f05e67659ef91d",
            download_sources = [
                JLLArtifactSource(
                    "https://github.com/JuliaBinaryWrappers/MbedTLS_jll.jl/releases/download/MbedTLS-v2.28.2+1/MbedTLS.v2.28.2.aarch64-linux-gnu.tar.gz",
                    "a08415399b0c1be7b0c4e4ecc8edfc4d11e31c98b9a152a80d639e3efff7c120",
                ),
            ],
            products = [
                JLLLibraryProduct(
                    :libmbedcrypto,
                    "lib/libmbedcrypto.so",
                    [],
                    flags = [:RTLD_LAZY, :RTLD_DEEPBIND],
                ),
                JLLLibraryProduct(
                    :libmbedtls,
                    "lib/libmbedtls.so",
                    [
                        JLLLibraryDep(nothing, :libmbedcrypto),
                        JLLLibraryDep(nothing, :libmbedx509),
                    ],
                    flags = [:RTLD_LAZY, :RTLD_DEEPBIND],
                ),
                JLLLibraryProduct(
                    :libmbedx509,
                    "lib/libmbedx509.so",
                    [
                        JLLLibraryDep(nothing, :libmbedcrypto)
                    ],
                    flags = [:RTLD_LAZY, :RTLD_DEEPBIND],
                ),
            ]
        ),

        JLLArtifactInfo(;
            src_version = v"2.28.2+1",
            deps = [
            ],
            sources = [],
            platform = Platform("aarch64", "linux"; libc = "musl"),
            name = "default",
            treehash = "85c80c7fcb8165763af7a979c667d1d8a6f857ca",
            download_sources = [
                JLLArtifactSource(
                    "https://github.com/JuliaBinaryWrappers/MbedTLS_jll.jl/releases/download/MbedTLS-v2.28.2+1/MbedTLS.v2.28.2.aarch64-linux-musl.tar.gz",
                    "d7a95989892f2ea8a899e51352ace0b07a96b7bcb84cb8a3a9eefbed1ba6f6cc",
                ),
            ],
            products = [
                JLLLibraryProduct(
                    :libmbedcrypto,
                    "lib/libmbedcrypto.so",
                    [],
                    flags = [:RTLD_LAZY, :RTLD_DEEPBIND],
                ),
                JLLLibraryProduct(
                    :libmbedtls,
                    "lib/libmbedtls.so",
                    [
                        JLLLibraryDep(nothing, :libmbedcrypto),
                        JLLLibraryDep(nothing, :libmbedx509),
                    ],
                    flags = [:RTLD_LAZY, :RTLD_DEEPBIND],
                ),
                JLLLibraryProduct(
                    :libmbedx509,
                    "lib/libmbedx509.so",
                    [
                        JLLLibraryDep(nothing, :libmbedcrypto)
                    ],
                    flags = [:RTLD_LAZY, :RTLD_DEEPBIND],
                ),
            ]
        ),

        JLLArtifactInfo(;
            src_version = v"2.28.2+1",
            deps = [
            ],
            sources = [],
            platform = Platform("armv6l", "linux"; call_abi = "eabihf", libc = "glibc"),
            name = "default",
            treehash = "cf1dffd8e8652c3e06f805df47e22a79e9fb2a89",
            download_sources = [
                JLLArtifactSource(
                    "https://github.com/JuliaBinaryWrappers/MbedTLS_jll.jl/releases/download/MbedTLS-v2.28.2+1/MbedTLS.v2.28.2.armv6l-linux-gnueabihf.tar.gz",
                    "4db76cbcf4ccd94bfe710ab670a8add6dc5903f1e1aad0ddeeafaf19febb4348",
                ),
            ],
            products = [
                JLLLibraryProduct(
                    :libmbedcrypto,
                    "lib/libmbedcrypto.so",
                    [],
                    flags = [:RTLD_LAZY, :RTLD_DEEPBIND],
                ),
                JLLLibraryProduct(
                    :libmbedtls,
                    "lib/libmbedtls.so",
                    [
                        JLLLibraryDep(nothing, :libmbedcrypto),
                        JLLLibraryDep(nothing, :libmbedx509),
                    ],
                    flags = [:RTLD_LAZY, :RTLD_DEEPBIND],
                ),
                JLLLibraryProduct(
                    :libmbedx509,
                    "lib/libmbedx509.so",
                    [
                        JLLLibraryDep(nothing, :libmbedcrypto)
                    ],
                    flags = [:RTLD_LAZY, :RTLD_DEEPBIND],
                ),
            ]
        ),

        JLLArtifactInfo(;
            src_version = v"2.28.2+1",
            deps = [
            ],
            sources = [],
            platform = Platform("armv6l", "linux"; call_abi = "eabihf", libc = "musl"),
            name = "default",
            treehash = "96c2e8bda3d2dd5b0fe181cf1a61a8018d1624e5",
            download_sources = [
                JLLArtifactSource(
                    "https://github.com/JuliaBinaryWrappers/MbedTLS_jll.jl/releases/download/MbedTLS-v2.28.2+1/MbedTLS.v2.28.2.armv6l-linux-musleabihf.tar.gz",
                    "bd7d5c6387c57bc7d2be5726b706a4deed63eae73ab51d1642d2f229bf84f3ef",
                ),
            ],
            products = [
                JLLLibraryProduct(
                    :libmbedcrypto,
                    "lib/libmbedcrypto.so",
                    [],
                    flags = [:RTLD_LAZY, :RTLD_DEEPBIND],
                ),
                JLLLibraryProduct(
                    :libmbedtls,
                    "lib/libmbedtls.so",
                    [
                        JLLLibraryDep(nothing, :libmbedcrypto),
                        JLLLibraryDep(nothing, :libmbedx509),
                    ],
                    flags = [:RTLD_LAZY, :RTLD_DEEPBIND],
                ),
                JLLLibraryProduct(
                    :libmbedx509,
                    "lib/libmbedx509.so",
                    [
                        JLLLibraryDep(nothing, :libmbedcrypto)
                    ],
                    flags = [:RTLD_LAZY, :RTLD_DEEPBIND],
                ),
            ]
        ),

        JLLArtifactInfo(;
            src_version = v"2.28.2+1",
            deps = [
            ],
            sources = [],
            platform = Platform("armv7l", "linux"; call_abi = "eabihf", libc = "glibc"),
            name = "default",
            treehash = "0e64bfe8701450bf4773702437b0ab5dd0fee059",
            download_sources = [
                JLLArtifactSource(
                    "https://github.com/JuliaBinaryWrappers/MbedTLS_jll.jl/releases/download/MbedTLS-v2.28.2+1/MbedTLS.v2.28.2.armv7l-linux-gnueabihf.tar.gz",
                    "4cce8eebdc4c8ed5dcdd762f09001beb2054473b372866a47cdb4ce9c57d68c7",
                ),
            ],
            products = [
                JLLLibraryProduct(
                    :libmbedcrypto,
                    "lib/libmbedcrypto.so",
                    [],
                    flags = [:RTLD_LAZY, :RTLD_DEEPBIND],
                ),
                JLLLibraryProduct(
                    :libmbedtls,
                    "lib/libmbedtls.so",
                    [
                        JLLLibraryDep(nothing, :libmbedcrypto),
                        JLLLibraryDep(nothing, :libmbedx509),
                    ],
                    flags = [:RTLD_LAZY, :RTLD_DEEPBIND],
                ),
                JLLLibraryProduct(
                    :libmbedx509,
                    "lib/libmbedx509.so",
                    [
                        JLLLibraryDep(nothing, :libmbedcrypto)
                    ],
                    flags = [:RTLD_LAZY, :RTLD_DEEPBIND],
                ),
            ]
        ),

        JLLArtifactInfo(;
            src_version = v"2.28.2+1",
            deps = [
            ],
            sources = [],
            platform = Platform("armv7l", "linux"; call_abi = "eabihf", libc = "musl"),
            name = "default",
            treehash = "05e2116e9c4e5bc081a663da7c97cbf4851b55e7",
            download_sources = [
                JLLArtifactSource(
                    "https://github.com/JuliaBinaryWrappers/MbedTLS_jll.jl/releases/download/MbedTLS-v2.28.2+1/MbedTLS.v2.28.2.armv7l-linux-musleabihf.tar.gz",
                    "befb9912a19a66384bf38e2c62a4c531969326761dbc75998c9e74343b8cbcd7",
                ),
            ],
            products = [
                JLLLibraryProduct(
                    :libmbedcrypto,
                    "lib/libmbedcrypto.so",
                    [],
                    flags = [:RTLD_LAZY, :RTLD_DEEPBIND],
                ),
                JLLLibraryProduct(
                    :libmbedtls,
                    "lib/libmbedtls.so",
                    [
                        JLLLibraryDep(nothing, :libmbedcrypto),
                        JLLLibraryDep(nothing, :libmbedx509),
                    ],
                    flags = [:RTLD_LAZY, :RTLD_DEEPBIND],
                ),
                JLLLibraryProduct(
                    :libmbedx509,
                    "lib/libmbedx509.so",
                    [
                        JLLLibraryDep(nothing, :libmbedcrypto)
                    ],
                    flags = [:RTLD_LAZY, :RTLD_DEEPBIND],
                ),
            ]
        ),

        JLLArtifactInfo(;
            src_version = v"2.28.2+1",
            deps = [
            ],
            sources = [],
            platform = Platform("i686", "linux"; libc = "glibc"),
            name = "default",
            treehash = "8db2d7b2459270ff1a33b62f2031dd598e53a71d",
            download_sources = [
                JLLArtifactSource(
                    "https://github.com/JuliaBinaryWrappers/MbedTLS_jll.jl/releases/download/MbedTLS-v2.28.2+1/MbedTLS.v2.28.2.i686-linux-gnu.tar.gz",
                    "c709ab659245ebf802c003f62e3d3d82f8be5bdeee689e4b6fcd9f236b1eabc2",
                ),
            ],
            products = [
                JLLLibraryProduct(
                    :libmbedcrypto,
                    "lib/libmbedcrypto.so",
                    [],
                    flags = [:RTLD_LAZY, :RTLD_DEEPBIND],
                ),
                JLLLibraryProduct(
                    :libmbedtls,
                    "lib/libmbedtls.so",
                    [
                        JLLLibraryDep(nothing, :libmbedcrypto),
                        JLLLibraryDep(nothing, :libmbedx509),
                    ],
                    flags = [:RTLD_LAZY, :RTLD_DEEPBIND],
                ),
                JLLLibraryProduct(
                    :libmbedx509,
                    "lib/libmbedx509.so",
                    [
                        JLLLibraryDep(nothing, :libmbedcrypto)
                    ],
                    flags = [:RTLD_LAZY, :RTLD_DEEPBIND],
                ),
            ]
        ),

        JLLArtifactInfo(;
            src_version = v"2.28.2+1",
            deps = [
            ],
            sources = [],
            platform = Platform("i686", "linux"; libc = "musl"),
            name = "default",
            treehash = "1df91c33d48b7cdc4d8b618417817e79c4be103f",
            download_sources = [
                JLLArtifactSource(
                    "https://github.com/JuliaBinaryWrappers/MbedTLS_jll.jl/releases/download/MbedTLS-v2.28.2+1/MbedTLS.v2.28.2.i686-linux-musl.tar.gz",
                    "471725d3c9031c0fb749aeaa65a212ee3aa313ab3c702b945d2e2ee1fa81e5ab",
                ),
            ],
            products = [
                JLLLibraryProduct(
                    :libmbedcrypto,
                    "lib/libmbedcrypto.so",
                    [],
                    flags = [:RTLD_LAZY, :RTLD_DEEPBIND],
                ),
                JLLLibraryProduct(
                    :libmbedtls,
                    "lib/libmbedtls.so",
                    [
                        JLLLibraryDep(nothing, :libmbedcrypto),
                        JLLLibraryDep(nothing, :libmbedx509),
                    ],
                    flags = [:RTLD_LAZY, :RTLD_DEEPBIND],
                ),
                JLLLibraryProduct(
                    :libmbedx509,
                    "lib/libmbedx509.so",
                    [
                        JLLLibraryDep(nothing, :libmbedcrypto)
                    ],
                    flags = [:RTLD_LAZY, :RTLD_DEEPBIND],
                ),
            ]
        ),

        JLLArtifactInfo(;
            src_version = v"2.28.2+1",
            deps = [
            ],
            sources = [],
            platform = Platform("i686", "windows"; ),
            name = "default",
            treehash = "9d47941b1964c94479a8ff0da13eb7c3d21e0b9f",
            download_sources = [
                JLLArtifactSource(
                    "https://github.com/JuliaBinaryWrappers/MbedTLS_jll.jl/releases/download/MbedTLS-v2.28.2+1/MbedTLS.v2.28.2.i686-w64-mingw32.tar.gz",
                    "335896e0d72bca4491212f9dd19f7dbc594f090ab56c80a23b57cacf2ea7cd25",
                ),
            ],
            products = [
                JLLLibraryProduct(
                    :libmbedcrypto,
                    "bin\\libmbedcrypto.dll",
                    [],
                    flags = [:RTLD_LAZY, :RTLD_DEEPBIND],
                ),
                JLLLibraryProduct(
                    :libmbedtls,
                    "bin\\libmbedtls.dll",
                    [
                        JLLLibraryDep(nothing, :libmbedcrypto),
                        JLLLibraryDep(nothing, :libmbedx509),
                    ],
                    flags = [:RTLD_LAZY, :RTLD_DEEPBIND],
                ),
                JLLLibraryProduct(
                    :libmbedx509,
                    "bin\\libmbedx509.dll",
                    [
                        JLLLibraryDep(nothing, :libmbedcrypto)
                    ],
                    flags = [:RTLD_LAZY, :RTLD_DEEPBIND],
                ),
            ]
        ),

        JLLArtifactInfo(;
            src_version = v"2.28.2+1",
            deps = [
            ],
            sources = [],
            platform = Platform("powerpc64le", "linux"; libc = "glibc"),
            name = "default",
            treehash = "aaa809f503b178fb474675c9c62e3274112dcec0",
            download_sources = [
                JLLArtifactSource(
                    "https://github.com/JuliaBinaryWrappers/MbedTLS_jll.jl/releases/download/MbedTLS-v2.28.2+1/MbedTLS.v2.28.2.powerpc64le-linux-gnu.tar.gz",
                    "6e46314ab56c694e4da7d3c7df018c27d0554f5370fea2258c000a23e90382fe",
                ),
            ],
            products = [
                JLLLibraryProduct(
                    :libmbedcrypto,
                    "lib/libmbedcrypto.so",
                    [],
                    flags = [:RTLD_LAZY, :RTLD_DEEPBIND],
                ),
                JLLLibraryProduct(
                    :libmbedtls,
                    "lib/libmbedtls.so",
                    [
                        JLLLibraryDep(nothing, :libmbedcrypto),
                        JLLLibraryDep(nothing, :libmbedx509),
                    ],
                    flags = [:RTLD_LAZY, :RTLD_DEEPBIND],
                ),
                JLLLibraryProduct(
                    :libmbedx509,
                    "lib/libmbedx509.so",
                    [
                        JLLLibraryDep(nothing, :libmbedcrypto)
                    ],
                    flags = [:RTLD_LAZY, :RTLD_DEEPBIND],
                ),
            ]
        ),

        JLLArtifactInfo(;
            src_version = v"2.28.2+1",
            deps = [
            ],
            sources = [],
            platform = Platform("x86_64", "macos"; ),
            name = "default",
            treehash = "dec22f7759af1138d31556acfac30be30e95131b",
            download_sources = [
                JLLArtifactSource(
                    "https://github.com/JuliaBinaryWrappers/MbedTLS_jll.jl/releases/download/MbedTLS-v2.28.2+1/MbedTLS.v2.28.2.x86_64-apple-darwin.tar.gz",
                    "30020447db786bab52048f368bb7a2ffaa99e64af914e6fa68ad7a6a2f0386a0",
                ),
            ],
            products = [
                JLLLibraryProduct(
                    :libmbedcrypto,
                    "lib/libmbedcrypto.2.28.2.dylib",
                    [],
                    flags = [:RTLD_LAZY, :RTLD_DEEPBIND],
                ),
                JLLLibraryProduct(
                    :libmbedtls,
                    "lib/libmbedtls.14.dylib",
                    [
                        JLLLibraryDep(nothing, :libmbedcrypto),
                        JLLLibraryDep(nothing, :libmbedx509),
                    ],
                    flags = [:RTLD_LAZY, :RTLD_DEEPBIND],
                ),
                JLLLibraryProduct(
                    :libmbedx509,
                    "lib/libmbedx509.1.dylib",
                    [
                        JLLLibraryDep(nothing, :libmbedcrypto)
                    ],
                    flags = [:RTLD_LAZY, :RTLD_DEEPBIND],
                ),
            ]
        ),

        JLLArtifactInfo(;
            src_version = v"2.28.2+1",
            deps = [
            ],
            sources = [],
            platform = Platform("x86_64", "linux"; libc = "glibc"),
            name = "default",
            treehash = "0d38ec9dacb183ab809ef6ea8e5ada17e99cbbdf",
            download_sources = [
                JLLArtifactSource(
                    "https://github.com/JuliaBinaryWrappers/MbedTLS_jll.jl/releases/download/MbedTLS-v2.28.2+1/MbedTLS.v2.28.2.x86_64-linux-gnu.tar.gz",
                    "a31ed4ff6032ad2c3ec1afae9c6a668618973b2380d3a7bf65e92e83a210415e",
                ),
            ],
            products = [
                JLLLibraryProduct(
                    :libmbedcrypto,
                    "lib/libmbedcrypto.so",
                    [],
                    flags = [:RTLD_LAZY, :RTLD_DEEPBIND],
                ),
                JLLLibraryProduct(
                    :libmbedtls,
                    "lib/libmbedtls.so",
                    [
                        JLLLibraryDep(nothing, :libmbedcrypto),
                        JLLLibraryDep(nothing, :libmbedx509),
                    ],
                    flags = [:RTLD_LAZY, :RTLD_DEEPBIND],
                ),
                JLLLibraryProduct(
                    :libmbedx509,
                    "lib/libmbedx509.so",
                    [
                        JLLLibraryDep(nothing, :libmbedcrypto)
                    ],
                    flags = [:RTLD_LAZY, :RTLD_DEEPBIND],
                ),
            ]
        ),

        JLLArtifactInfo(;
            src_version = v"2.28.2+1",
            deps = [
            ],
            sources = [],
            platform = Platform("x86_64", "linux"; libc = "glibc", sanitize = "memory"),
            name = "default",
            treehash = "fc9e68415873ee933e485edb10e0eb451d726eb8",
            download_sources = [
                JLLArtifactSource(
                    "https://github.com/JuliaBinaryWrappers/MbedTLS_jll.jl/releases/download/MbedTLS-v2.28.2+1/MbedTLS.v2.28.2.x86_64-linux-gnu-sanitize+memory.tar.gz",
                    "41fa5637e227d545729d0cb51b9f6e0cd306ae72b44a1b59895de080509dcf91",
                ),
            ],
            products = [
                JLLLibraryProduct(
                    :libmbedcrypto,
                    "lib/libmbedcrypto.so",
                    [],
                    flags = [:RTLD_LAZY, :RTLD_DEEPBIND],
                ),
                JLLLibraryProduct(
                    :libmbedtls,
                    "lib/libmbedtls.so",
                    [
                        JLLLibraryDep(nothing, :libmbedcrypto),
                        JLLLibraryDep(nothing, :libmbedx509),
                    ],
                    flags = [:RTLD_LAZY, :RTLD_DEEPBIND],
                ),
                JLLLibraryProduct(
                    :libmbedx509,
                    "lib/libmbedx509.so",
                    [
                        JLLLibraryDep(nothing, :libmbedcrypto)
                    ],
                    flags = [:RTLD_LAZY, :RTLD_DEEPBIND],
                ),
            ]
        ),

        JLLArtifactInfo(;
            src_version = v"2.28.2+1",
            deps = [
            ],
            sources = [],
            platform = Platform("x86_64", "linux"; libc = "musl"),
            name = "default",
            treehash = "48782ed0747248d75c8ed93ea0b0de24e30b007f",
            download_sources = [
                JLLArtifactSource(
                    "https://github.com/JuliaBinaryWrappers/MbedTLS_jll.jl/releases/download/MbedTLS-v2.28.2+1/MbedTLS.v2.28.2.x86_64-linux-musl.tar.gz",
                    "8f8fef6da60a3cf446bd854b1fcd97fbe5b3302d12bc1a27718adf1d547b907d",
                ),
            ],
            products = [
                JLLLibraryProduct(
                    :libmbedcrypto,
                    "lib/libmbedcrypto.so",
                    [],
                    flags = [:RTLD_LAZY, :RTLD_DEEPBIND],
                ),
                JLLLibraryProduct(
                    :libmbedtls,
                    "lib/libmbedtls.so",
                    [
                        JLLLibraryDep(nothing, :libmbedcrypto),
                        JLLLibraryDep(nothing, :libmbedx509),
                    ],
                    flags = [:RTLD_LAZY, :RTLD_DEEPBIND],
                ),
                JLLLibraryProduct(
                    :libmbedx509,
                    "lib/libmbedx509.so",
                    [
                        JLLLibraryDep(nothing, :libmbedcrypto)
                    ],
                    flags = [:RTLD_LAZY, :RTLD_DEEPBIND],
                ),
            ]
        ),

        JLLArtifactInfo(;
            src_version = v"2.28.2+1",
            deps = [
            ],
            sources = [],
            platform = Platform("x86_64", "freebsd"; ),
            name = "default",
            treehash = "aa2ccc261a2a19e24168e87a74bb08643d173d52",
            download_sources = [
                JLLArtifactSource(
                    "https://github.com/JuliaBinaryWrappers/MbedTLS_jll.jl/releases/download/MbedTLS-v2.28.2+1/MbedTLS.v2.28.2.x86_64-unknown-freebsd.tar.gz",
                    "cac52e1e62ce4efcaf5cbc23be1d6e06015a9a8c1cb0c0d5d17dc4de94d9d5a0",
                ),
            ],
            products = [
                JLLLibraryProduct(
                    :libmbedcrypto,
                    "lib/libmbedcrypto.so",
                    [],
                    flags = [:RTLD_LAZY, :RTLD_DEEPBIND],
                ),
                JLLLibraryProduct(
                    :libmbedtls,
                    "lib/libmbedtls.so",
                    [
                        JLLLibraryDep(nothing, :libmbedcrypto),
                        JLLLibraryDep(nothing, :libmbedx509),
                    ],
                    flags = [:RTLD_LAZY, :RTLD_DEEPBIND],
                ),
                JLLLibraryProduct(
                    :libmbedx509,
                    "lib/libmbedx509.so",
                    [
                        JLLLibraryDep(nothing, :libmbedcrypto)
                    ],
                    flags = [:RTLD_LAZY, :RTLD_DEEPBIND],
                ),
            ]
        ),

        JLLArtifactInfo(;
            src_version = v"2.28.2+1",
            deps = [
            ],
            sources = [],
            platform = Platform("x86_64", "windows"; ),
            name = "default",
            treehash = "90144a6ea975a3930e7a2a0aeb4b02652195689a",
            download_sources = [
                JLLArtifactSource(
                    "https://github.com/JuliaBinaryWrappers/MbedTLS_jll.jl/releases/download/MbedTLS-v2.28.2+1/MbedTLS.v2.28.2.x86_64-w64-mingw32.tar.gz",
                    "d333b93cf63b4be1b3451ed334ce1cd83f66f36b6c7589ce8702c684e437d33d",
                ),
            ],
            products = [
                JLLLibraryProduct(
                    :libmbedcrypto,
                    "bin\\libmbedcrypto.dll",
                    [],
                    flags = [:RTLD_LAZY, :RTLD_DEEPBIND],
                ),
                JLLLibraryProduct(
                    :libmbedtls,
                    "bin\\libmbedtls.dll",
                    [
                        JLLLibraryDep(nothing, :libmbedcrypto),
                        JLLLibraryDep(nothing, :libmbedx509),
                    ],
                    flags = [:RTLD_LAZY, :RTLD_DEEPBIND],
                ),
                JLLLibraryProduct(
                    :libmbedx509,
                    "bin\\libmbedx509.dll",
                    [
                        JLLLibraryDep(nothing, :libmbedcrypto)
                    ],
                    flags = [:RTLD_LAZY, :RTLD_DEEPBIND],
                ),
            ]
        ),

    ]
)

