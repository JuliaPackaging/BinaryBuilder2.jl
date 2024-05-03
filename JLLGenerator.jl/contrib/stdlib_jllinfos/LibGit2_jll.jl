jll = JLLInfo(;
    name = "LibGit2",
    version = v"1.6.4+0",
    artifacts = [
        JLLArtifactInfo(;
            src_version = v"1.6.4+0",
            deps = [
                JLLPackageDependency(
                    "MbedTLS_jll",
                    Base.UUID("c8ffd9c3-330d-5841-b78e-0817d7145fa1"),
                    "~2.28.0",
                ),
                JLLPackageDependency(
                    "LibSSH2_jll",
                    Base.UUID("29816b5a-b9ab-546f-933c-edad1886dfa8"),
                    "1.11.0",
                ),
            ],
            sources = [],
            platform = Platform("aarch64", "macos"; ),
            name = "default",
            treehash = "1fa3315b910ef2c762b6907f7cc57ba42184c8a8",
            download_sources = [
                JLLArtifactSource(
                    "https://github.com/JuliaBinaryWrappers/LibGit2_jll.jl/releases/download/LibGit2-v1.6.4+0/LibGit2.v1.6.4.aarch64-apple-darwin.tar.gz",
                    "42846f286ffd421f7f1ab04957acc6addefef5080c704aa09a5960f1c5ef7ee7",
                ),
            ],
            products = [
                JLLLibraryProduct(
                    :libgit2,
                    "lib/libgit2.1.6.4.dylib",
                    [
                        JLLLibraryDep(:MbedTLS_jll, :libmbedtls),
                        JLLLibraryDep(:MbedTLS_jll, :libmbedx509),
                        JLLLibraryDep(:MbedTLS_jll, :libmbedcrypto),
                        JLLLibraryDep(:LibSSH2_jll, :libssh2),
                    ],
                    flags = [:RTLD_LAZY, :RTLD_DEEPBIND],
                ),
            ]
        ),

        JLLArtifactInfo(;
            src_version = v"1.6.4+0",
            deps = [
                JLLPackageDependency(
                    "MbedTLS_jll",
                    Base.UUID("c8ffd9c3-330d-5841-b78e-0817d7145fa1"),
                    "~2.28.0",
                ),
                JLLPackageDependency(
                    "LibSSH2_jll",
                    Base.UUID("29816b5a-b9ab-546f-933c-edad1886dfa8"),
                    "1.11.0",
                ),
            ],
            sources = [],
            platform = Platform("aarch64", "linux"; libc = "glibc"),
            name = "default",
            treehash = "2b01a6fe8bb8261b29e08340dc1b56c39b7a3406",
            download_sources = [
                JLLArtifactSource(
                    "https://github.com/JuliaBinaryWrappers/LibGit2_jll.jl/releases/download/LibGit2-v1.6.4+0/LibGit2.v1.6.4.aarch64-linux-gnu.tar.gz",
                    "d729cee7318431c7ec3d641bbaecfb2285395a985c55df905d14b92879bd3eac",
                ),
            ],
            products = [
                JLLLibraryProduct(
                    :libgit2,
                    "lib/libgit2.so",
                    [
                        JLLLibraryDep(:MbedTLS_jll, :libmbedtls),
                        JLLLibraryDep(:MbedTLS_jll, :libmbedx509),
                        JLLLibraryDep(:MbedTLS_jll, :libmbedcrypto),
                        JLLLibraryDep(:LibSSH2_jll, :libssh2),
                    ],
                    flags = [:RTLD_LAZY, :RTLD_DEEPBIND],
                ),
            ]
        ),

        JLLArtifactInfo(;
            src_version = v"1.6.4+0",
            deps = [
                JLLPackageDependency(
                    "MbedTLS_jll",
                    Base.UUID("c8ffd9c3-330d-5841-b78e-0817d7145fa1"),
                    "~2.28.0",
                ),
                JLLPackageDependency(
                    "LibSSH2_jll",
                    Base.UUID("29816b5a-b9ab-546f-933c-edad1886dfa8"),
                    "1.11.0",
                ),
            ],
            sources = [],
            platform = Platform("aarch64", "linux"; libc = "musl"),
            name = "default",
            treehash = "179b40208b0dd1fb1c0ef7a72d63c6a513be31e8",
            download_sources = [
                JLLArtifactSource(
                    "https://github.com/JuliaBinaryWrappers/LibGit2_jll.jl/releases/download/LibGit2-v1.6.4+0/LibGit2.v1.6.4.aarch64-linux-musl.tar.gz",
                    "981c12336c9974bb461eb8d41a7c6fe25f35ee8fd29a1012e91696db439784d1",
                ),
            ],
            products = [
                JLLLibraryProduct(
                    :libgit2,
                    "lib/libgit2.so",
                    [
                        JLLLibraryDep(:MbedTLS_jll, :libmbedtls),
                        JLLLibraryDep(:MbedTLS_jll, :libmbedx509),
                        JLLLibraryDep(:MbedTLS_jll, :libmbedcrypto),
                        JLLLibraryDep(:LibSSH2_jll, :libssh2),
                    ],
                    flags = [:RTLD_LAZY, :RTLD_DEEPBIND],
                ),
            ]
        ),

        JLLArtifactInfo(;
            src_version = v"1.6.4+0",
            deps = [
                JLLPackageDependency(
                    "MbedTLS_jll",
                    Base.UUID("c8ffd9c3-330d-5841-b78e-0817d7145fa1"),
                    "~2.28.0",
                ),
                JLLPackageDependency(
                    "LibSSH2_jll",
                    Base.UUID("29816b5a-b9ab-546f-933c-edad1886dfa8"),
                    "1.11.0",
                ),
            ],
            sources = [],
            platform = Platform("armv6l", "linux"; call_abi = "eabihf", libc = "glibc"),
            name = "default",
            treehash = "fd7c8d9f766fd5cda1bd022ad0da16bc165cc498",
            download_sources = [
                JLLArtifactSource(
                    "https://github.com/JuliaBinaryWrappers/LibGit2_jll.jl/releases/download/LibGit2-v1.6.4+0/LibGit2.v1.6.4.armv6l-linux-gnueabihf.tar.gz",
                    "ed0731ac1c028caa19b91dcbbe14a2939a725ebe8bbf455ed4f54d2ab50ac5dc",
                ),
            ],
            products = [
                JLLLibraryProduct(
                    :libgit2,
                    "lib/libgit2.so",
                    [
                        JLLLibraryDep(:MbedTLS_jll, :libmbedtls),
                        JLLLibraryDep(:MbedTLS_jll, :libmbedx509),
                        JLLLibraryDep(:MbedTLS_jll, :libmbedcrypto),
                        JLLLibraryDep(:LibSSH2_jll, :libssh2),
                    ],
                    flags = [:RTLD_LAZY, :RTLD_DEEPBIND],
                ),
            ]
        ),

        JLLArtifactInfo(;
            src_version = v"1.6.4+0",
            deps = [
                JLLPackageDependency(
                    "MbedTLS_jll",
                    Base.UUID("c8ffd9c3-330d-5841-b78e-0817d7145fa1"),
                    "~2.28.0",
                ),
                JLLPackageDependency(
                    "LibSSH2_jll",
                    Base.UUID("29816b5a-b9ab-546f-933c-edad1886dfa8"),
                    "1.11.0",
                ),
            ],
            sources = [],
            platform = Platform("armv6l", "linux"; call_abi = "eabihf", libc = "musl"),
            name = "default",
            treehash = "cf8df2e522122a03cf6194985814f16a66138408",
            download_sources = [
                JLLArtifactSource(
                    "https://github.com/JuliaBinaryWrappers/LibGit2_jll.jl/releases/download/LibGit2-v1.6.4+0/LibGit2.v1.6.4.armv6l-linux-musleabihf.tar.gz",
                    "e645e88446e77f672aa288262db4a61e32688ecc27c868b4de0bc0d82452147c",
                ),
            ],
            products = [
                JLLLibraryProduct(
                    :libgit2,
                    "lib/libgit2.so",
                    [
                        JLLLibraryDep(:MbedTLS_jll, :libmbedtls),
                        JLLLibraryDep(:MbedTLS_jll, :libmbedx509),
                        JLLLibraryDep(:MbedTLS_jll, :libmbedcrypto),
                        JLLLibraryDep(:LibSSH2_jll, :libssh2),
                    ],
                    flags = [:RTLD_LAZY, :RTLD_DEEPBIND],
                ),
            ]
        ),

        JLLArtifactInfo(;
            src_version = v"1.6.4+0",
            deps = [
                JLLPackageDependency(
                    "MbedTLS_jll",
                    Base.UUID("c8ffd9c3-330d-5841-b78e-0817d7145fa1"),
                    "~2.28.0",
                ),
                JLLPackageDependency(
                    "LibSSH2_jll",
                    Base.UUID("29816b5a-b9ab-546f-933c-edad1886dfa8"),
                    "1.11.0",
                ),
            ],
            sources = [],
            platform = Platform("armv7l", "linux"; call_abi = "eabihf", libc = "glibc"),
            name = "default",
            treehash = "7d021f510967bcdcd0b21716a1ab59726f553947",
            download_sources = [
                JLLArtifactSource(
                    "https://github.com/JuliaBinaryWrappers/LibGit2_jll.jl/releases/download/LibGit2-v1.6.4+0/LibGit2.v1.6.4.armv7l-linux-gnueabihf.tar.gz",
                    "92aea6e9f307aa4eef0f27eb73edd4d23615312b86c8b26748ec8cfa294690df",
                ),
            ],
            products = [
                JLLLibraryProduct(
                    :libgit2,
                    "lib/libgit2.so",
                    [
                        JLLLibraryDep(:MbedTLS_jll, :libmbedtls),
                        JLLLibraryDep(:MbedTLS_jll, :libmbedx509),
                        JLLLibraryDep(:MbedTLS_jll, :libmbedcrypto),
                        JLLLibraryDep(:LibSSH2_jll, :libssh2),
                    ],
                    flags = [:RTLD_LAZY, :RTLD_DEEPBIND],
                ),
            ]
        ),

        JLLArtifactInfo(;
            src_version = v"1.6.4+0",
            deps = [
                JLLPackageDependency(
                    "MbedTLS_jll",
                    Base.UUID("c8ffd9c3-330d-5841-b78e-0817d7145fa1"),
                    "~2.28.0",
                ),
                JLLPackageDependency(
                    "LibSSH2_jll",
                    Base.UUID("29816b5a-b9ab-546f-933c-edad1886dfa8"),
                    "1.11.0",
                ),
            ],
            sources = [],
            platform = Platform("armv7l", "linux"; call_abi = "eabihf", libc = "musl"),
            name = "default",
            treehash = "655e30be87bca34bae192c27a78216c3f4a4e88a",
            download_sources = [
                JLLArtifactSource(
                    "https://github.com/JuliaBinaryWrappers/LibGit2_jll.jl/releases/download/LibGit2-v1.6.4+0/LibGit2.v1.6.4.armv7l-linux-musleabihf.tar.gz",
                    "81ba27d1a656cfa4406dab6cab3c5d82e5836a5437a91cb9ac9d06b13392bb87",
                ),
            ],
            products = [
                JLLLibraryProduct(
                    :libgit2,
                    "lib/libgit2.so",
                    [
                        JLLLibraryDep(:MbedTLS_jll, :libmbedtls),
                        JLLLibraryDep(:MbedTLS_jll, :libmbedx509),
                        JLLLibraryDep(:MbedTLS_jll, :libmbedcrypto),
                        JLLLibraryDep(:LibSSH2_jll, :libssh2),
                    ],
                    flags = [:RTLD_LAZY, :RTLD_DEEPBIND],
                ),
            ]
        ),

        JLLArtifactInfo(;
            src_version = v"1.6.4+0",
            deps = [
                JLLPackageDependency(
                    "MbedTLS_jll",
                    Base.UUID("c8ffd9c3-330d-5841-b78e-0817d7145fa1"),
                    "~2.28.0",
                ),
                JLLPackageDependency(
                    "LibSSH2_jll",
                    Base.UUID("29816b5a-b9ab-546f-933c-edad1886dfa8"),
                    "1.11.0",
                ),
            ],
            sources = [],
            platform = Platform("i686", "linux"; libc = "glibc"),
            name = "default",
            treehash = "7d33ed65bedb1422eeb41740d0ed6ae8160320c1",
            download_sources = [
                JLLArtifactSource(
                    "https://github.com/JuliaBinaryWrappers/LibGit2_jll.jl/releases/download/LibGit2-v1.6.4+0/LibGit2.v1.6.4.i686-linux-gnu.tar.gz",
                    "1c0e22381f26ee51d5a397c879f12e4d7aeee18faab50178cf4c9c0a21c0b371",
                ),
            ],
            products = [
                JLLLibraryProduct(
                    :libgit2,
                    "lib/libgit2.so",
                    [
                        JLLLibraryDep(:MbedTLS_jll, :libmbedtls),
                        JLLLibraryDep(:MbedTLS_jll, :libmbedx509),
                        JLLLibraryDep(:MbedTLS_jll, :libmbedcrypto),
                        JLLLibraryDep(:LibSSH2_jll, :libssh2),
                    ],
                    flags = [:RTLD_LAZY, :RTLD_DEEPBIND],
                ),
            ]
        ),

        JLLArtifactInfo(;
            src_version = v"1.6.4+0",
            deps = [
                JLLPackageDependency(
                    "MbedTLS_jll",
                    Base.UUID("c8ffd9c3-330d-5841-b78e-0817d7145fa1"),
                    "~2.28.0",
                ),
                JLLPackageDependency(
                    "LibSSH2_jll",
                    Base.UUID("29816b5a-b9ab-546f-933c-edad1886dfa8"),
                    "1.11.0",
                ),
            ],
            sources = [],
            platform = Platform("i686", "linux"; libc = "musl"),
            name = "default",
            treehash = "857a71c488bc4f6824c1fe70809c22fcb97944df",
            download_sources = [
                JLLArtifactSource(
                    "https://github.com/JuliaBinaryWrappers/LibGit2_jll.jl/releases/download/LibGit2-v1.6.4+0/LibGit2.v1.6.4.i686-linux-musl.tar.gz",
                    "a8d999e3dd8b461a5c8bd7cb13a35a65379ae368e84ba1f5fa98fb4ffc3693c1",
                ),
            ],
            products = [
                JLLLibraryProduct(
                    :libgit2,
                    "lib/libgit2.so",
                    [
                        JLLLibraryDep(:MbedTLS_jll, :libmbedtls),
                        JLLLibraryDep(:MbedTLS_jll, :libmbedx509),
                        JLLLibraryDep(:MbedTLS_jll, :libmbedcrypto),
                        JLLLibraryDep(:LibSSH2_jll, :libssh2),
                    ],
                    flags = [:RTLD_LAZY, :RTLD_DEEPBIND],
                ),
            ]
        ),

        JLLArtifactInfo(;
            src_version = v"1.6.4+0",
            deps = [
                JLLPackageDependency(
                    "MbedTLS_jll",
                    Base.UUID("c8ffd9c3-330d-5841-b78e-0817d7145fa1"),
                    "~2.28.0",
                ),
                JLLPackageDependency(
                    "LibSSH2_jll",
                    Base.UUID("29816b5a-b9ab-546f-933c-edad1886dfa8"),
                    "1.11.0",
                ),
            ],
            sources = [],
            platform = Platform("i686", "windows"; ),
            name = "default",
            treehash = "423365c60ab1553ba5aa6e8470b87a7d1a2e5011",
            download_sources = [
                JLLArtifactSource(
                    "https://github.com/JuliaBinaryWrappers/LibGit2_jll.jl/releases/download/LibGit2-v1.6.4+0/LibGit2.v1.6.4.i686-w64-mingw32.tar.gz",
                    "7140b0c2ea6ef44f20babfd56bf1026f5b16785a4c330f602a73d754f9a3c042",
                ),
            ],
            products = [
                JLLLibraryProduct(
                    :libgit2,
                    "bin\\libgit2.dll",
                    [
                        JLLLibraryDep(:MbedTLS_jll, :libmbedtls),
                        JLLLibraryDep(:MbedTLS_jll, :libmbedx509),
                        JLLLibraryDep(:MbedTLS_jll, :libmbedcrypto),
                        JLLLibraryDep(:LibSSH2_jll, :libssh2),
                    ],
                    flags = [:RTLD_LAZY, :RTLD_DEEPBIND],
                ),
            ]
        ),

        JLLArtifactInfo(;
            src_version = v"1.6.4+0",
            deps = [
                JLLPackageDependency(
                    "MbedTLS_jll",
                    Base.UUID("c8ffd9c3-330d-5841-b78e-0817d7145fa1"),
                    "~2.28.0",
                ),
                JLLPackageDependency(
                    "LibSSH2_jll",
                    Base.UUID("29816b5a-b9ab-546f-933c-edad1886dfa8"),
                    "1.11.0",
                ),
            ],
            sources = [],
            platform = Platform("powerpc64le", "linux"; libc = "glibc"),
            name = "default",
            treehash = "9f941e9721a1470d454f32a6d2515edbce7546f3",
            download_sources = [
                JLLArtifactSource(
                    "https://github.com/JuliaBinaryWrappers/LibGit2_jll.jl/releases/download/LibGit2-v1.6.4+0/LibGit2.v1.6.4.powerpc64le-linux-gnu.tar.gz",
                    "e81dfd183d2af8cb4c19fd12f17e03b2d5580c7a460addc0c1aaf6315548feb5",
                ),
            ],
            products = [
                JLLLibraryProduct(
                    :libgit2,
                    "lib/libgit2.so",
                    [
                        JLLLibraryDep(:MbedTLS_jll, :libmbedtls),
                        JLLLibraryDep(:MbedTLS_jll, :libmbedx509),
                        JLLLibraryDep(:MbedTLS_jll, :libmbedcrypto),
                        JLLLibraryDep(:LibSSH2_jll, :libssh2),
                    ],
                    flags = [:RTLD_LAZY, :RTLD_DEEPBIND],
                ),
            ]
        ),

        JLLArtifactInfo(;
            src_version = v"1.6.4+0",
            deps = [
                JLLPackageDependency(
                    "MbedTLS_jll",
                    Base.UUID("c8ffd9c3-330d-5841-b78e-0817d7145fa1"),
                    "~2.28.0",
                ),
                JLLPackageDependency(
                    "LibSSH2_jll",
                    Base.UUID("29816b5a-b9ab-546f-933c-edad1886dfa8"),
                    "1.11.0",
                ),
            ],
            sources = [],
            platform = Platform("x86_64", "macos"; ),
            name = "default",
            treehash = "a1a89a3c680bef6990c7468ba91279dc0834d911",
            download_sources = [
                JLLArtifactSource(
                    "https://github.com/JuliaBinaryWrappers/LibGit2_jll.jl/releases/download/LibGit2-v1.6.4+0/LibGit2.v1.6.4.x86_64-apple-darwin.tar.gz",
                    "812f9c37097e083eb62e246e2b3f8e250db9d03dbb94d99f9111206a4b5c4e9c",
                ),
            ],
            products = [
                JLLLibraryProduct(
                    :libgit2,
                    "lib/libgit2.1.6.4.dylib",
                    [
                        JLLLibraryDep(:MbedTLS_jll, :libmbedtls),
                        JLLLibraryDep(:MbedTLS_jll, :libmbedx509),
                        JLLLibraryDep(:MbedTLS_jll, :libmbedcrypto),
                        JLLLibraryDep(:LibSSH2_jll, :libssh2),
                    ],
                    flags = [:RTLD_LAZY, :RTLD_DEEPBIND],
                ),
            ]
        ),

        JLLArtifactInfo(;
            src_version = v"1.6.4+0",
            deps = [
                JLLPackageDependency(
                    "MbedTLS_jll",
                    Base.UUID("c8ffd9c3-330d-5841-b78e-0817d7145fa1"),
                    "~2.28.0",
                ),
                JLLPackageDependency(
                    "LibSSH2_jll",
                    Base.UUID("29816b5a-b9ab-546f-933c-edad1886dfa8"),
                    "1.11.0",
                ),
            ],
            sources = [],
            platform = Platform("x86_64", "linux"; libc = "glibc"),
            name = "default",
            treehash = "af66c88943df4020e0112f64e424bb5e5c418695",
            download_sources = [
                JLLArtifactSource(
                    "https://github.com/JuliaBinaryWrappers/LibGit2_jll.jl/releases/download/LibGit2-v1.6.4+0/LibGit2.v1.6.4.x86_64-linux-gnu.tar.gz",
                    "927ae04d2bbd6cabf064d161beb02af8e04a5077a5028539f75500b2af3a7642",
                ),
            ],
            products = [
                JLLLibraryProduct(
                    :libgit2,
                    "lib/libgit2.so",
                    [
                        JLLLibraryDep(:MbedTLS_jll, :libmbedtls),
                        JLLLibraryDep(:MbedTLS_jll, :libmbedx509),
                        JLLLibraryDep(:MbedTLS_jll, :libmbedcrypto),
                        JLLLibraryDep(:LibSSH2_jll, :libssh2),
                    ],
                    flags = [:RTLD_LAZY, :RTLD_DEEPBIND],
                ),
            ]
        ),

        JLLArtifactInfo(;
            src_version = v"1.6.4+0",
            deps = [
                JLLPackageDependency(
                    "MbedTLS_jll",
                    Base.UUID("c8ffd9c3-330d-5841-b78e-0817d7145fa1"),
                    "~2.28.0",
                ),
                JLLPackageDependency(
                    "LibSSH2_jll",
                    Base.UUID("29816b5a-b9ab-546f-933c-edad1886dfa8"),
                    "1.11.0",
                ),
            ],
            sources = [],
            platform = Platform("x86_64", "linux"; libc = "glibc", sanitize = "memory"),
            name = "default",
            treehash = "837a46e833548cc1e78a76e1a1a7d4d0ca0c15b1",
            download_sources = [
                JLLArtifactSource(
                    "https://github.com/JuliaBinaryWrappers/LibGit2_jll.jl/releases/download/LibGit2-v1.6.4+0/LibGit2.v1.6.4.x86_64-linux-gnu-sanitize+memory.tar.gz",
                    "967427f236a09d8cf303a1fb7278158ddab693d0af84bed647de859cbdba844a",
                ),
            ],
            products = [
                JLLLibraryProduct(
                    :libgit2,
                    "lib/libgit2.so",
                    [
                        JLLLibraryDep(:MbedTLS_jll, :libmbedtls),
                        JLLLibraryDep(:MbedTLS_jll, :libmbedx509),
                        JLLLibraryDep(:MbedTLS_jll, :libmbedcrypto),
                        JLLLibraryDep(:LibSSH2_jll, :libssh2),
                    ],
                    flags = [:RTLD_LAZY, :RTLD_DEEPBIND],
                ),
            ]
        ),

        JLLArtifactInfo(;
            src_version = v"1.6.4+0",
            deps = [
                JLLPackageDependency(
                    "MbedTLS_jll",
                    Base.UUID("c8ffd9c3-330d-5841-b78e-0817d7145fa1"),
                    "~2.28.0",
                ),
                JLLPackageDependency(
                    "LibSSH2_jll",
                    Base.UUID("29816b5a-b9ab-546f-933c-edad1886dfa8"),
                    "1.11.0",
                ),
            ],
            sources = [],
            platform = Platform("x86_64", "linux"; libc = "musl"),
            name = "default",
            treehash = "815a38e2180ceb65c93ea42270944665220d7556",
            download_sources = [
                JLLArtifactSource(
                    "https://github.com/JuliaBinaryWrappers/LibGit2_jll.jl/releases/download/LibGit2-v1.6.4+0/LibGit2.v1.6.4.x86_64-linux-musl.tar.gz",
                    "c33c8bee46b857644ad5cde06cfafbc94bd2d76e2d68ca8add8769d45f6da028",
                ),
            ],
            products = [
                JLLLibraryProduct(
                    :libgit2,
                    "lib/libgit2.so",
                    [
                        JLLLibraryDep(:MbedTLS_jll, :libmbedtls),
                        JLLLibraryDep(:MbedTLS_jll, :libmbedx509),
                        JLLLibraryDep(:MbedTLS_jll, :libmbedcrypto),
                        JLLLibraryDep(:LibSSH2_jll, :libssh2),
                    ],
                    flags = [:RTLD_LAZY, :RTLD_DEEPBIND],
                ),
            ]
        ),

        JLLArtifactInfo(;
            src_version = v"1.6.4+0",
            deps = [
                JLLPackageDependency(
                    "MbedTLS_jll",
                    Base.UUID("c8ffd9c3-330d-5841-b78e-0817d7145fa1"),
                    "~2.28.0",
                ),
                JLLPackageDependency(
                    "LibSSH2_jll",
                    Base.UUID("29816b5a-b9ab-546f-933c-edad1886dfa8"),
                    "1.11.0",
                ),
            ],
            sources = [],
            platform = Platform("x86_64", "freebsd"; ),
            name = "default",
            treehash = "7113cef90f4df95849f8269906ba98dca30ffdde",
            download_sources = [
                JLLArtifactSource(
                    "https://github.com/JuliaBinaryWrappers/LibGit2_jll.jl/releases/download/LibGit2-v1.6.4+0/LibGit2.v1.6.4.x86_64-unknown-freebsd.tar.gz",
                    "b8405c493b902d789c26a71dc42397dd2d876cb747c3533f873c6c0425b5480e",
                ),
            ],
            products = [
                JLLLibraryProduct(
                    :libgit2,
                    "lib/libgit2.so",
                    [
                        JLLLibraryDep(:MbedTLS_jll, :libmbedtls),
                        JLLLibraryDep(:MbedTLS_jll, :libmbedx509),
                        JLLLibraryDep(:MbedTLS_jll, :libmbedcrypto),
                        JLLLibraryDep(:LibSSH2_jll, :libssh2),
                    ],
                    flags = [:RTLD_LAZY, :RTLD_DEEPBIND],
                ),
            ]
        ),

        JLLArtifactInfo(;
            src_version = v"1.6.4+0",
            deps = [
                JLLPackageDependency(
                    "MbedTLS_jll",
                    Base.UUID("c8ffd9c3-330d-5841-b78e-0817d7145fa1"),
                    "~2.28.0",
                ),
                JLLPackageDependency(
                    "LibSSH2_jll",
                    Base.UUID("29816b5a-b9ab-546f-933c-edad1886dfa8"),
                    "1.11.0",
                ),
            ],
            sources = [],
            platform = Platform("x86_64", "windows"; ),
            name = "default",
            treehash = "8d263a68937e9543e7d7a321f2672e4d9f7e2c2c",
            download_sources = [
                JLLArtifactSource(
                    "https://github.com/JuliaBinaryWrappers/LibGit2_jll.jl/releases/download/LibGit2-v1.6.4+0/LibGit2.v1.6.4.x86_64-w64-mingw32.tar.gz",
                    "808f15c55d16ecf5569c1531596c3800d55405f100f377acd3a4d0fea6f0739a",
                ),
            ],
            products = [
                JLLLibraryProduct(
                    :libgit2,
                    "bin\\libgit2.dll",
                    [
                        JLLLibraryDep(:MbedTLS_jll, :libmbedtls),
                        JLLLibraryDep(:MbedTLS_jll, :libmbedx509),
                        JLLLibraryDep(:MbedTLS_jll, :libmbedcrypto),
                        JLLLibraryDep(:LibSSH2_jll, :libssh2),
                    ],
                    flags = [:RTLD_LAZY, :RTLD_DEEPBIND],
                ),
            ]
        ),

    ]
)

