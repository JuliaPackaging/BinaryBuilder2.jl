jll = JLLInfo(;
    name = "LibSSH2",
    version = v"1.11.0+1",
    builds = [
        JLLBuildInfo(;
            src_version = v"1.11.0+1",
            deps = [
                JLLPackageDependency(
                    "MbedTLS_jll",
                    Base.UUID("c8ffd9c3-330d-5841-b78e-0817d7145fa1"),
                    "~2.28.0",
                ),
            ],
            sources = [],
            platform = Platform("aarch64", "macos"; ),
            name = "default",
            artifact = JLLArtifactBinding(;
                treehash = "e2f243fe7eaa362996b95dc6a64cf8df1381c97a",
                download_sources = [
                    JLLArtifactSource(
                        "https://github.com/JuliaBinaryWrappers/LibSSH2_jll.jl/releases/download/LibSSH2-v1.11.0+1/LibSSH2.v1.11.0.aarch64-apple-darwin.tar.gz",
                        "d5186af4155ce0259c7f4ecd9be02223f4b443f82bcc0bea23d8aa19720f886c",
                    ),
                ],
            ),
            products = [
                JLLLibraryProduct(
                    :libssh2,
                    "lib/libssh2.1.0.1.dylib",
                    [
                        JLLLibraryDep(:MbedTLS_jll, :libmbedtls),
                        JLLLibraryDep(:MbedTLS_jll, :libmbedx509),
                        JLLLibraryDep(:MbedTLS_jll, :libmbedcrypto),
                    ],
                    flags = [:RTLD_LAZY, :RTLD_DEEPBIND],
                ),
            ]
        ),

        JLLBuildInfo(;
            src_version = v"1.11.0+1",
            deps = [
                JLLPackageDependency(
                    "MbedTLS_jll",
                    Base.UUID("c8ffd9c3-330d-5841-b78e-0817d7145fa1"),
                    "~2.28.0",
                ),
            ],
            sources = [],
            platform = Platform("aarch64", "linux"; libc = "glibc"),
            name = "default",
            artifact = JLLArtifactBinding(;
                treehash = "e8266798f3428b59e21cdb385545a2b15373f517",
                download_sources = [
                    JLLArtifactSource(
                        "https://github.com/JuliaBinaryWrappers/LibSSH2_jll.jl/releases/download/LibSSH2-v1.11.0+1/LibSSH2.v1.11.0.aarch64-linux-gnu.tar.gz",
                        "4677fdc4c3b673456d3a4d129821383d69d736d95dcaeaabe8f3a760efcb9a33",
                    ),
                ],
            ),
            products = [
                JLLLibraryProduct(
                    :libssh2,
                    "lib/libssh2.so",
                    [
                        JLLLibraryDep(:MbedTLS_jll, :libmbedtls),
                        JLLLibraryDep(:MbedTLS_jll, :libmbedx509),
                        JLLLibraryDep(:MbedTLS_jll, :libmbedcrypto),
                    ],
                    flags = [:RTLD_LAZY, :RTLD_DEEPBIND],
                ),
            ]
        ),

        JLLBuildInfo(;
            src_version = v"1.11.0+1",
            deps = [
                JLLPackageDependency(
                    "MbedTLS_jll",
                    Base.UUID("c8ffd9c3-330d-5841-b78e-0817d7145fa1"),
                    "~2.28.0",
                ),
            ],
            sources = [],
            platform = Platform("aarch64", "linux"; libc = "musl"),
            name = "default",
            artifact = JLLArtifactBinding(;
                treehash = "67d35f9dea978ab01c235c03c82961bef58cd8c3",
                download_sources = [
                    JLLArtifactSource(
                        "https://github.com/JuliaBinaryWrappers/LibSSH2_jll.jl/releases/download/LibSSH2-v1.11.0+1/LibSSH2.v1.11.0.aarch64-linux-musl.tar.gz",
                        "eb0d55a67a7e37e2b7965470ee459596d14741af8df0b8adac5e04bfa3ef750c",
                    ),
                ],
            ),
            products = [
                JLLLibraryProduct(
                    :libssh2,
                    "lib/libssh2.so",
                    [
                        JLLLibraryDep(:MbedTLS_jll, :libmbedtls),
                        JLLLibraryDep(:MbedTLS_jll, :libmbedx509),
                        JLLLibraryDep(:MbedTLS_jll, :libmbedcrypto),
                    ],
                    flags = [:RTLD_LAZY, :RTLD_DEEPBIND],
                ),
            ]
        ),

        JLLBuildInfo(;
            src_version = v"1.11.0+1",
            deps = [
                JLLPackageDependency(
                    "MbedTLS_jll",
                    Base.UUID("c8ffd9c3-330d-5841-b78e-0817d7145fa1"),
                    "~2.28.0",
                ),
            ],
            sources = [],
            platform = Platform("armv6l", "linux"; call_abi = "eabihf", libc = "glibc"),
            name = "default",
            artifact = JLLArtifactBinding(;
                treehash = "fe5592c8057d05b89fb03e71a37febe1604442e9",
                download_sources = [
                    JLLArtifactSource(
                        "https://github.com/JuliaBinaryWrappers/LibSSH2_jll.jl/releases/download/LibSSH2-v1.11.0+1/LibSSH2.v1.11.0.armv6l-linux-gnueabihf.tar.gz",
                        "1c2ddb46af3f08e8c6b7bc8ed0809220b498849046a8087c4941d62f4dbc2259",
                    ),
                ],
            ),
            products = [
                JLLLibraryProduct(
                    :libssh2,
                    "lib/libssh2.so",
                    [
                        JLLLibraryDep(:MbedTLS_jll, :libmbedtls),
                        JLLLibraryDep(:MbedTLS_jll, :libmbedx509),
                        JLLLibraryDep(:MbedTLS_jll, :libmbedcrypto),
                    ],
                    flags = [:RTLD_LAZY, :RTLD_DEEPBIND],
                ),
            ]
        ),

        JLLBuildInfo(;
            src_version = v"1.11.0+1",
            deps = [
                JLLPackageDependency(
                    "MbedTLS_jll",
                    Base.UUID("c8ffd9c3-330d-5841-b78e-0817d7145fa1"),
                    "~2.28.0",
                ),
            ],
            sources = [],
            platform = Platform("armv6l", "linux"; call_abi = "eabihf", libc = "musl"),
            name = "default",
            artifact = JLLArtifactBinding(;
                treehash = "6a9a82a197f45c0466eb65c0272fea36fd6dd3ea",
                download_sources = [
                    JLLArtifactSource(
                        "https://github.com/JuliaBinaryWrappers/LibSSH2_jll.jl/releases/download/LibSSH2-v1.11.0+1/LibSSH2.v1.11.0.armv6l-linux-musleabihf.tar.gz",
                        "fb1ac2626c19b359b69377c3e1280de6e9dca1bf9428b62c7e4eab3bb4d609e5",
                    ),
                ],
            ),
            products = [
                JLLLibraryProduct(
                    :libssh2,
                    "lib/libssh2.so",
                    [
                        JLLLibraryDep(:MbedTLS_jll, :libmbedtls),
                        JLLLibraryDep(:MbedTLS_jll, :libmbedx509),
                        JLLLibraryDep(:MbedTLS_jll, :libmbedcrypto),
                    ],
                    flags = [:RTLD_LAZY, :RTLD_DEEPBIND],
                ),
            ]
        ),

        JLLBuildInfo(;
            src_version = v"1.11.0+1",
            deps = [
                JLLPackageDependency(
                    "MbedTLS_jll",
                    Base.UUID("c8ffd9c3-330d-5841-b78e-0817d7145fa1"),
                    "~2.28.0",
                ),
            ],
            sources = [],
            platform = Platform("armv7l", "linux"; call_abi = "eabihf", libc = "glibc"),
            name = "default",
            artifact = JLLArtifactBinding(;
                treehash = "6445d9cc1c3fb413dc233c075310fe670791e17c",
                download_sources = [
                    JLLArtifactSource(
                        "https://github.com/JuliaBinaryWrappers/LibSSH2_jll.jl/releases/download/LibSSH2-v1.11.0+1/LibSSH2.v1.11.0.armv7l-linux-gnueabihf.tar.gz",
                        "5c798a57eb040a35c172357d63d6f3ce682ea195526733961e2396b59d6e0c9a",
                    ),
                ],
            ),
            products = [
                JLLLibraryProduct(
                    :libssh2,
                    "lib/libssh2.so",
                    [
                        JLLLibraryDep(:MbedTLS_jll, :libmbedtls),
                        JLLLibraryDep(:MbedTLS_jll, :libmbedx509),
                        JLLLibraryDep(:MbedTLS_jll, :libmbedcrypto),
                    ],
                    flags = [:RTLD_LAZY, :RTLD_DEEPBIND],
                ),
            ]
        ),

        JLLBuildInfo(;
            src_version = v"1.11.0+1",
            deps = [
                JLLPackageDependency(
                    "MbedTLS_jll",
                    Base.UUID("c8ffd9c3-330d-5841-b78e-0817d7145fa1"),
                    "~2.28.0",
                ),
            ],
            sources = [],
            platform = Platform("armv7l", "linux"; call_abi = "eabihf", libc = "musl"),
            name = "default",
            artifact = JLLArtifactBinding(;
                treehash = "081a745d5cebabcb2adfa6c4d2f96e48f6512565",
                download_sources = [
                    JLLArtifactSource(
                        "https://github.com/JuliaBinaryWrappers/LibSSH2_jll.jl/releases/download/LibSSH2-v1.11.0+1/LibSSH2.v1.11.0.armv7l-linux-musleabihf.tar.gz",
                        "d1a8d9addc622aa83900d88f388855ba554ecc8b94d4d2c6cb758624a6023269",
                    ),
                ],
            ),
            products = [
                JLLLibraryProduct(
                    :libssh2,
                    "lib/libssh2.so",
                    [
                        JLLLibraryDep(:MbedTLS_jll, :libmbedtls),
                        JLLLibraryDep(:MbedTLS_jll, :libmbedx509),
                        JLLLibraryDep(:MbedTLS_jll, :libmbedcrypto),
                    ],
                    flags = [:RTLD_LAZY, :RTLD_DEEPBIND],
                ),
            ]
        ),

        JLLBuildInfo(;
            src_version = v"1.11.0+1",
            deps = [
                JLLPackageDependency(
                    "MbedTLS_jll",
                    Base.UUID("c8ffd9c3-330d-5841-b78e-0817d7145fa1"),
                    "~2.28.0",
                ),
            ],
            sources = [],
            platform = Platform("i686", "linux"; libc = "glibc"),
            name = "default",
            artifact = JLLArtifactBinding(;
                treehash = "1538366dc1ef9f1df1f1c553f18577d23f99d3ea",
                download_sources = [
                    JLLArtifactSource(
                        "https://github.com/JuliaBinaryWrappers/LibSSH2_jll.jl/releases/download/LibSSH2-v1.11.0+1/LibSSH2.v1.11.0.i686-linux-gnu.tar.gz",
                        "c14a0e2bc8fb9ae52f9fbb92834386631dc978ff20579d4181ef61bac4d9461b",
                    ),
                ],
            ),
            products = [
                JLLLibraryProduct(
                    :libssh2,
                    "lib/libssh2.so",
                    [
                        JLLLibraryDep(:MbedTLS_jll, :libmbedtls),
                        JLLLibraryDep(:MbedTLS_jll, :libmbedx509),
                        JLLLibraryDep(:MbedTLS_jll, :libmbedcrypto),
                    ],
                    flags = [:RTLD_LAZY, :RTLD_DEEPBIND],
                ),
            ]
        ),

        JLLBuildInfo(;
            src_version = v"1.11.0+1",
            deps = [
                JLLPackageDependency(
                    "MbedTLS_jll",
                    Base.UUID("c8ffd9c3-330d-5841-b78e-0817d7145fa1"),
                    "~2.28.0",
                ),
            ],
            sources = [],
            platform = Platform("i686", "linux"; libc = "musl"),
            name = "default",
            artifact = JLLArtifactBinding(;
                treehash = "75704c9368f8122d55ecf719591acd0201c4d186",
                download_sources = [
                    JLLArtifactSource(
                        "https://github.com/JuliaBinaryWrappers/LibSSH2_jll.jl/releases/download/LibSSH2-v1.11.0+1/LibSSH2.v1.11.0.i686-linux-musl.tar.gz",
                        "19c2b64820816b11138a836e42dd3fd9ee54d90eb4ca8c4fcf0a96435435bf4f",
                    ),
                ],
            ),
            products = [
                JLLLibraryProduct(
                    :libssh2,
                    "lib/libssh2.so",
                    [
                        JLLLibraryDep(:MbedTLS_jll, :libmbedtls),
                        JLLLibraryDep(:MbedTLS_jll, :libmbedx509),
                        JLLLibraryDep(:MbedTLS_jll, :libmbedcrypto),
                    ],
                    flags = [:RTLD_LAZY, :RTLD_DEEPBIND],
                ),
            ]
        ),

        JLLBuildInfo(;
            src_version = v"1.11.0+1",
            deps = [
                JLLPackageDependency(
                    "MbedTLS_jll",
                    Base.UUID("c8ffd9c3-330d-5841-b78e-0817d7145fa1"),
                    "~2.28.0",
                ),
            ],
            sources = [],
            platform = Platform("i686", "windows"; ),
            name = "default",
            artifact = JLLArtifactBinding(;
                treehash = "e9e14b2ddae42d2feb2cfff65162a740ecba4f14",
                download_sources = [
                    JLLArtifactSource(
                        "https://github.com/JuliaBinaryWrappers/LibSSH2_jll.jl/releases/download/LibSSH2-v1.11.0+1/LibSSH2.v1.11.0.i686-w64-mingw32.tar.gz",
                        "4132bda8ff5d170f80b61f2e7fc60f8153481b0f11963c909ba61e6b9e8b5fa4",
                    ),
                ],
            ),
            products = [
                JLLLibraryProduct(
                    :libssh2,
                    "bin\\libssh2.dll",
                    [
                        JLLLibraryDep(:MbedTLS_jll, :libmbedtls),
                        JLLLibraryDep(:MbedTLS_jll, :libmbedx509),
                        JLLLibraryDep(:MbedTLS_jll, :libmbedcrypto),
                    ],
                    flags = [:RTLD_LAZY, :RTLD_DEEPBIND],
                ),
            ]
        ),

        JLLBuildInfo(;
            src_version = v"1.11.0+1",
            deps = [
                JLLPackageDependency(
                    "MbedTLS_jll",
                    Base.UUID("c8ffd9c3-330d-5841-b78e-0817d7145fa1"),
                    "~2.28.0",
                ),
            ],
            sources = [],
            platform = Platform("powerpc64le", "linux"; libc = "glibc"),
            name = "default",
            artifact = JLLArtifactBinding(;
                treehash = "385951074415fefa85f6749d65821b361d355446",
                download_sources = [
                    JLLArtifactSource(
                        "https://github.com/JuliaBinaryWrappers/LibSSH2_jll.jl/releases/download/LibSSH2-v1.11.0+1/LibSSH2.v1.11.0.powerpc64le-linux-gnu.tar.gz",
                        "8565ee46336ba53e930730a66e35523dcd27a3c52d4024ad04ed680545584d5b",
                    ),
                ],
            ),
            products = [
                JLLLibraryProduct(
                    :libssh2,
                    "lib/libssh2.so",
                    [
                        JLLLibraryDep(:MbedTLS_jll, :libmbedtls),
                        JLLLibraryDep(:MbedTLS_jll, :libmbedx509),
                        JLLLibraryDep(:MbedTLS_jll, :libmbedcrypto),
                    ],
                    flags = [:RTLD_LAZY, :RTLD_DEEPBIND],
                ),
            ]
        ),

        JLLBuildInfo(;
            src_version = v"1.11.0+1",
            deps = [
                JLLPackageDependency(
                    "MbedTLS_jll",
                    Base.UUID("c8ffd9c3-330d-5841-b78e-0817d7145fa1"),
                    "~2.28.0",
                ),
            ],
            sources = [],
            platform = Platform("x86_64", "macos"; ),
            name = "default",
            artifact = JLLArtifactBinding(;
                treehash = "24e17c1d1c5dbff028cfb594f96a8b6cfb1c798d",
                download_sources = [
                    JLLArtifactSource(
                        "https://github.com/JuliaBinaryWrappers/LibSSH2_jll.jl/releases/download/LibSSH2-v1.11.0+1/LibSSH2.v1.11.0.x86_64-apple-darwin.tar.gz",
                        "e33dcbbc5695271e6c6c29ebb8faeaa036d149ee483b2af83456b0c6696a432b",
                    ),
                ],
            ),
            products = [
                JLLLibraryProduct(
                    :libssh2,
                    "lib/libssh2.1.0.1.dylib",
                    [
                        JLLLibraryDep(:MbedTLS_jll, :libmbedtls),
                        JLLLibraryDep(:MbedTLS_jll, :libmbedx509),
                        JLLLibraryDep(:MbedTLS_jll, :libmbedcrypto),
                    ],
                    flags = [:RTLD_LAZY, :RTLD_DEEPBIND],
                ),
            ]
        ),

        JLLBuildInfo(;
            src_version = v"1.11.0+1",
            deps = [
                JLLPackageDependency(
                    "MbedTLS_jll",
                    Base.UUID("c8ffd9c3-330d-5841-b78e-0817d7145fa1"),
                    "~2.28.0",
                ),
            ],
            sources = [],
            platform = Platform("x86_64", "linux"; libc = "glibc"),
            name = "default",
            artifact = JLLArtifactBinding(;
                treehash = "b2ace9a02cfac998377c2e43287cd810076cb6f6",
                download_sources = [
                    JLLArtifactSource(
                        "https://github.com/JuliaBinaryWrappers/LibSSH2_jll.jl/releases/download/LibSSH2-v1.11.0+1/LibSSH2.v1.11.0.x86_64-linux-gnu.tar.gz",
                        "51ea9f9fb5a5f736db6ec645c782540685e3740dbe99ad8cde3d96029dc3c7f9",
                    ),
                ],
            ),
            products = [
                JLLLibraryProduct(
                    :libssh2,
                    "lib/libssh2.so",
                    [
                        JLLLibraryDep(:MbedTLS_jll, :libmbedtls),
                        JLLLibraryDep(:MbedTLS_jll, :libmbedx509),
                        JLLLibraryDep(:MbedTLS_jll, :libmbedcrypto),
                    ],
                    flags = [:RTLD_LAZY, :RTLD_DEEPBIND],
                ),
            ]
        ),

        JLLBuildInfo(;
            src_version = v"1.11.0+1",
            deps = [
                JLLPackageDependency(
                    "MbedTLS_jll",
                    Base.UUID("c8ffd9c3-330d-5841-b78e-0817d7145fa1"),
                    "~2.28.0",
                ),
            ],
            sources = [],
            platform = Platform("x86_64", "linux"; libc = "glibc", sanitize = "memory"),
            name = "default",
            artifact = JLLArtifactBinding(;
                treehash = "abad310b25586783ff910a4bb4b7f85adf3e515f",
                download_sources = [
                    JLLArtifactSource(
                        "https://github.com/JuliaBinaryWrappers/LibSSH2_jll.jl/releases/download/LibSSH2-v1.11.0+1/LibSSH2.v1.11.0.x86_64-linux-gnu-sanitize+memory.tar.gz",
                        "4bcaa51202a2bdee5eadcc4661498115c358845c09cd9ce8f201059c07064c93",
                    ),
                ],
            ),
            products = [
                JLLLibraryProduct(
                    :libssh2,
                    "lib/libssh2.so",
                    [
                        JLLLibraryDep(:MbedTLS_jll, :libmbedtls),
                        JLLLibraryDep(:MbedTLS_jll, :libmbedx509),
                        JLLLibraryDep(:MbedTLS_jll, :libmbedcrypto),
                    ],
                    flags = [:RTLD_LAZY, :RTLD_DEEPBIND],
                ),
            ]
        ),

        JLLBuildInfo(;
            src_version = v"1.11.0+1",
            deps = [
                JLLPackageDependency(
                    "MbedTLS_jll",
                    Base.UUID("c8ffd9c3-330d-5841-b78e-0817d7145fa1"),
                    "~2.28.0",
                ),
            ],
            sources = [],
            platform = Platform("x86_64", "linux"; libc = "musl"),
            name = "default",
            artifact = JLLArtifactBinding(;
                treehash = "68010cc3dea1d1ca7a4a21090321fdd91a81c92c",
                download_sources = [
                    JLLArtifactSource(
                        "https://github.com/JuliaBinaryWrappers/LibSSH2_jll.jl/releases/download/LibSSH2-v1.11.0+1/LibSSH2.v1.11.0.x86_64-linux-musl.tar.gz",
                        "27d663300467fa21263aacf44b78b74b9dabdc53275443f23ce3babd585d3f91",
                    ),
                ],
            ),
            products = [
                JLLLibraryProduct(
                    :libssh2,
                    "lib/libssh2.so",
                    [
                        JLLLibraryDep(:MbedTLS_jll, :libmbedtls),
                        JLLLibraryDep(:MbedTLS_jll, :libmbedx509),
                        JLLLibraryDep(:MbedTLS_jll, :libmbedcrypto),
                    ],
                    flags = [:RTLD_LAZY, :RTLD_DEEPBIND],
                ),
            ]
        ),

        JLLBuildInfo(;
            src_version = v"1.11.0+1",
            deps = [
                JLLPackageDependency(
                    "MbedTLS_jll",
                    Base.UUID("c8ffd9c3-330d-5841-b78e-0817d7145fa1"),
                    "~2.28.0",
                ),
            ],
            sources = [],
            platform = Platform("x86_64", "freebsd"; ),
            name = "default",
            artifact = JLLArtifactBinding(;
                treehash = "c6d541cbf8369fc143c3dcffe1f481a06c6cc37d",
                download_sources = [
                    JLLArtifactSource(
                        "https://github.com/JuliaBinaryWrappers/LibSSH2_jll.jl/releases/download/LibSSH2-v1.11.0+1/LibSSH2.v1.11.0.x86_64-unknown-freebsd.tar.gz",
                        "da3d3882c38a16e41e5d5986f10a877049b1896e53161284f44c24a6179d2efd",
                    ),
                ],
            ),
            products = [
                JLLLibraryProduct(
                    :libssh2,
                    "lib/libssh2.so",
                    [
                        JLLLibraryDep(:MbedTLS_jll, :libmbedtls),
                        JLLLibraryDep(:MbedTLS_jll, :libmbedx509),
                        JLLLibraryDep(:MbedTLS_jll, :libmbedcrypto),
                    ],
                    flags = [:RTLD_LAZY, :RTLD_DEEPBIND],
                ),
            ]
        ),

        JLLBuildInfo(;
            src_version = v"1.11.0+1",
            deps = [
                JLLPackageDependency(
                    "MbedTLS_jll",
                    Base.UUID("c8ffd9c3-330d-5841-b78e-0817d7145fa1"),
                    "~2.28.0",
                ),
            ],
            sources = [],
            platform = Platform("x86_64", "windows"; ),
            name = "default",
            artifact = JLLArtifactBinding(;
                treehash = "c0fd843f776ce605d25f79c22aecad9df23b24df",
                download_sources = [
                    JLLArtifactSource(
                        "https://github.com/JuliaBinaryWrappers/LibSSH2_jll.jl/releases/download/LibSSH2-v1.11.0+1/LibSSH2.v1.11.0.x86_64-w64-mingw32.tar.gz",
                        "2345fdf5554b06ddd1d91c8e3a191b71bdd6019a5de82461a9002f230d5ad897",
                    ),
                ],
            ),
            products = [
                JLLLibraryProduct(
                    :libssh2,
                    "bin\\libssh2.dll",
                    [
                        JLLLibraryDep(:MbedTLS_jll, :libmbedtls),
                        JLLLibraryDep(:MbedTLS_jll, :libmbedx509),
                        JLLLibraryDep(:MbedTLS_jll, :libmbedcrypto),
                    ],
                    flags = [:RTLD_LAZY, :RTLD_DEEPBIND],
                ),
            ]
        ),

    ]
)

