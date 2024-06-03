jll = JLLInfo(;
    name = "PCRE2",
    version = v"10.42.0+1",
    builds = [
        JLLBuildInfo(;
            src_version = v"10.42.0+1",
            deps = [
            ],
            sources = [],
            platform = Platform("aarch64", "macos"; ),
            name = "default",
            artifact = JLLArtifactBinding(;
                treehash = "14298736692555e66e2085582cce63b441cd1c7d",
                download_sources = [
                    JLLArtifactSource(
                        "https://github.com/JuliaBinaryWrappers/PCRE2_jll.jl/releases/download/PCRE2-v10.42.0+1/PCRE2.v10.42.0.aarch64-apple-darwin.tar.gz",
                        "9acab46b36ec2d7eb4bf556fec3a9f28ca0ee4dfea0d76e5c1e8e30c18cc32c4",
                    ),
                ],
            ),
            products = [
                JLLLibraryProduct(
                    :libpcre2_16,
                    "lib/libpcre2-16.0.dylib",
                    [],
                    flags = [:RTLD_LAZY, :RTLD_DEEPBIND],
                ),
                JLLLibraryProduct(
                    :libpcre2_32,
                    "lib/libpcre2-32.0.dylib",
                    [],
                    flags = [:RTLD_LAZY, :RTLD_DEEPBIND],
                ),
                JLLLibraryProduct(
                    :libpcre2_8,
                    "lib/libpcre2-8.0.dylib",
                    [],
                    flags = [:RTLD_LAZY, :RTLD_DEEPBIND],
                ),
            ]
        ),

        JLLBuildInfo(;
            src_version = v"10.42.0+1",
            deps = [
            ],
            sources = [],
            platform = Platform("aarch64", "linux"; libc = "glibc"),
            name = "default",
            artifact = JLLArtifactBinding(;
                treehash = "31429d09cf15567a5ff6ca0b037bf47d9c75f8eb",
                download_sources = [
                    JLLArtifactSource(
                        "https://github.com/JuliaBinaryWrappers/PCRE2_jll.jl/releases/download/PCRE2-v10.42.0+1/PCRE2.v10.42.0.aarch64-linux-gnu.tar.gz",
                        "cda05df078a687378d2e957767bfcd977fbb154381b495d25f96f8611ad2f4cd",
                    ),
                ],
            ),
            products = [
                JLLLibraryProduct(
                    :libpcre2_16,
                    "lib/libpcre2-16.so",
                    [],
                    flags = [:RTLD_LAZY, :RTLD_DEEPBIND],
                ),
                JLLLibraryProduct(
                    :libpcre2_32,
                    "lib/libpcre2-32.so",
                    [],
                    flags = [:RTLD_LAZY, :RTLD_DEEPBIND],
                ),
                JLLLibraryProduct(
                    :libpcre2_8,
                    "lib/libpcre2-8.so",
                    [],
                    flags = [:RTLD_LAZY, :RTLD_DEEPBIND],
                ),
            ]
        ),

        JLLBuildInfo(;
            src_version = v"10.42.0+1",
            deps = [
            ],
            sources = [],
            platform = Platform("aarch64", "linux"; libc = "musl"),
            name = "default",
            artifact = JLLArtifactBinding(;
                treehash = "630ebee79c58b82af97590e0b1701a0ea467a9ac",
                download_sources = [
                    JLLArtifactSource(
                        "https://github.com/JuliaBinaryWrappers/PCRE2_jll.jl/releases/download/PCRE2-v10.42.0+1/PCRE2.v10.42.0.aarch64-linux-musl.tar.gz",
                        "7ed0bed23ee3072af9275d482c0388d856d21fdfb3fd1ba120f5ed528b7cf3d4",
                    ),
                ],
            ),
            products = [
                JLLLibraryProduct(
                    :libpcre2_16,
                    "lib/libpcre2-16.so",
                    [],
                    flags = [:RTLD_LAZY, :RTLD_DEEPBIND],
                ),
                JLLLibraryProduct(
                    :libpcre2_32,
                    "lib/libpcre2-32.so",
                    [],
                    flags = [:RTLD_LAZY, :RTLD_DEEPBIND],
                ),
                JLLLibraryProduct(
                    :libpcre2_8,
                    "lib/libpcre2-8.so",
                    [],
                    flags = [:RTLD_LAZY, :RTLD_DEEPBIND],
                ),
            ]
        ),

        JLLBuildInfo(;
            src_version = v"10.42.0+1",
            deps = [
            ],
            sources = [],
            platform = Platform("armv6l", "linux"; call_abi = "eabihf", libc = "glibc"),
            name = "default",
            artifact = JLLArtifactBinding(;
                treehash = "7062811416ada0ceb09b2ae838cb5c787345401c",
                download_sources = [
                    JLLArtifactSource(
                        "https://github.com/JuliaBinaryWrappers/PCRE2_jll.jl/releases/download/PCRE2-v10.42.0+1/PCRE2.v10.42.0.armv6l-linux-gnueabihf.tar.gz",
                        "bc09abee36f66b22bc129ced7a744d961dac758dabd583aa4da25c67cbbc262d",
                    ),
                ],
            ),
            products = [
                JLLLibraryProduct(
                    :libpcre2_16,
                    "lib/libpcre2-16.so",
                    [],
                    flags = [:RTLD_LAZY, :RTLD_DEEPBIND],
                ),
                JLLLibraryProduct(
                    :libpcre2_32,
                    "lib/libpcre2-32.so",
                    [],
                    flags = [:RTLD_LAZY, :RTLD_DEEPBIND],
                ),
                JLLLibraryProduct(
                    :libpcre2_8,
                    "lib/libpcre2-8.so",
                    [],
                    flags = [:RTLD_LAZY, :RTLD_DEEPBIND],
                ),
            ]
        ),

        JLLBuildInfo(;
            src_version = v"10.42.0+1",
            deps = [
            ],
            sources = [],
            platform = Platform("armv6l", "linux"; call_abi = "eabihf", libc = "musl"),
            name = "default",
            artifact = JLLArtifactBinding(;
                treehash = "c3cc15c4a125d759e36d7ad805887acca0ef3f99",
                download_sources = [
                    JLLArtifactSource(
                        "https://github.com/JuliaBinaryWrappers/PCRE2_jll.jl/releases/download/PCRE2-v10.42.0+1/PCRE2.v10.42.0.armv6l-linux-musleabihf.tar.gz",
                        "91f3e949e50fb18d055a8bb5afde7836d3f3c38b4c186a176073a6b4a3d45a9b",
                    ),
                ],
            ),
            products = [
                JLLLibraryProduct(
                    :libpcre2_16,
                    "lib/libpcre2-16.so",
                    [],
                    flags = [:RTLD_LAZY, :RTLD_DEEPBIND],
                ),
                JLLLibraryProduct(
                    :libpcre2_32,
                    "lib/libpcre2-32.so",
                    [],
                    flags = [:RTLD_LAZY, :RTLD_DEEPBIND],
                ),
                JLLLibraryProduct(
                    :libpcre2_8,
                    "lib/libpcre2-8.so",
                    [],
                    flags = [:RTLD_LAZY, :RTLD_DEEPBIND],
                ),
            ]
        ),

        JLLBuildInfo(;
            src_version = v"10.42.0+1",
            deps = [
            ],
            sources = [],
            platform = Platform("armv7l", "linux"; call_abi = "eabihf", libc = "glibc"),
            name = "default",
            artifact = JLLArtifactBinding(;
                treehash = "d9ecb7965fb99d492e56d2ed66a8e10c194e1eb7",
                download_sources = [
                    JLLArtifactSource(
                        "https://github.com/JuliaBinaryWrappers/PCRE2_jll.jl/releases/download/PCRE2-v10.42.0+1/PCRE2.v10.42.0.armv7l-linux-gnueabihf.tar.gz",
                        "3e44528650f5f2943a64a61db7dbd89dd4c837e0d6dd1b31b8e4de7099d2f542",
                    ),
                ],
            ),
            products = [
                JLLLibraryProduct(
                    :libpcre2_16,
                    "lib/libpcre2-16.so",
                    [],
                    flags = [:RTLD_LAZY, :RTLD_DEEPBIND],
                ),
                JLLLibraryProduct(
                    :libpcre2_32,
                    "lib/libpcre2-32.so",
                    [],
                    flags = [:RTLD_LAZY, :RTLD_DEEPBIND],
                ),
                JLLLibraryProduct(
                    :libpcre2_8,
                    "lib/libpcre2-8.so",
                    [],
                    flags = [:RTLD_LAZY, :RTLD_DEEPBIND],
                ),
            ]
        ),

        JLLBuildInfo(;
            src_version = v"10.42.0+1",
            deps = [
            ],
            sources = [],
            platform = Platform("armv7l", "linux"; call_abi = "eabihf", libc = "musl"),
            name = "default",
            artifact = JLLArtifactBinding(;
                treehash = "2f7e2ad63d8a1e06b79492b2d13511bba3c7d0ad",
                download_sources = [
                    JLLArtifactSource(
                        "https://github.com/JuliaBinaryWrappers/PCRE2_jll.jl/releases/download/PCRE2-v10.42.0+1/PCRE2.v10.42.0.armv7l-linux-musleabihf.tar.gz",
                        "375c2cc30af3349023e222e383053e5692ba2555c66cd21a5b375b0f2e5b822b",
                    ),
                ],
            ),
            products = [
                JLLLibraryProduct(
                    :libpcre2_16,
                    "lib/libpcre2-16.so",
                    [],
                    flags = [:RTLD_LAZY, :RTLD_DEEPBIND],
                ),
                JLLLibraryProduct(
                    :libpcre2_32,
                    "lib/libpcre2-32.so",
                    [],
                    flags = [:RTLD_LAZY, :RTLD_DEEPBIND],
                ),
                JLLLibraryProduct(
                    :libpcre2_8,
                    "lib/libpcre2-8.so",
                    [],
                    flags = [:RTLD_LAZY, :RTLD_DEEPBIND],
                ),
            ]
        ),

        JLLBuildInfo(;
            src_version = v"10.42.0+1",
            deps = [
            ],
            sources = [],
            platform = Platform("i686", "linux"; libc = "glibc"),
            name = "default",
            artifact = JLLArtifactBinding(;
                treehash = "8b025325f774e72af4a979cb4d9a59dc269266d0",
                download_sources = [
                    JLLArtifactSource(
                        "https://github.com/JuliaBinaryWrappers/PCRE2_jll.jl/releases/download/PCRE2-v10.42.0+1/PCRE2.v10.42.0.i686-linux-gnu.tar.gz",
                        "171f007e1e3bcadd7954fdead9a55f1109dde28643676351305c22c4d9aba56b",
                    ),
                ],
            ),
            products = [
                JLLLibraryProduct(
                    :libpcre2_16,
                    "lib/libpcre2-16.so",
                    [],
                    flags = [:RTLD_LAZY, :RTLD_DEEPBIND],
                ),
                JLLLibraryProduct(
                    :libpcre2_32,
                    "lib/libpcre2-32.so",
                    [],
                    flags = [:RTLD_LAZY, :RTLD_DEEPBIND],
                ),
                JLLLibraryProduct(
                    :libpcre2_8,
                    "lib/libpcre2-8.so",
                    [],
                    flags = [:RTLD_LAZY, :RTLD_DEEPBIND],
                ),
            ]
        ),

        JLLBuildInfo(;
            src_version = v"10.42.0+1",
            deps = [
            ],
            sources = [],
            platform = Platform("i686", "linux"; libc = "musl"),
            name = "default",
            artifact = JLLArtifactBinding(;
                treehash = "18aae5804e2d3ad417caca3f7b23561fefef0eae",
                download_sources = [
                    JLLArtifactSource(
                        "https://github.com/JuliaBinaryWrappers/PCRE2_jll.jl/releases/download/PCRE2-v10.42.0+1/PCRE2.v10.42.0.i686-linux-musl.tar.gz",
                        "3c7e678d9afdc71e54f9421ab948b15c8ca8c0cedaa2156c74801dc360669674",
                    ),
                ],
            ),
            products = [
                JLLLibraryProduct(
                    :libpcre2_16,
                    "lib/libpcre2-16.so",
                    [],
                    flags = [:RTLD_LAZY, :RTLD_DEEPBIND],
                ),
                JLLLibraryProduct(
                    :libpcre2_32,
                    "lib/libpcre2-32.so",
                    [],
                    flags = [:RTLD_LAZY, :RTLD_DEEPBIND],
                ),
                JLLLibraryProduct(
                    :libpcre2_8,
                    "lib/libpcre2-8.so",
                    [],
                    flags = [:RTLD_LAZY, :RTLD_DEEPBIND],
                ),
            ]
        ),

        JLLBuildInfo(;
            src_version = v"10.42.0+1",
            deps = [
            ],
            sources = [],
            platform = Platform("i686", "windows"; ),
            name = "default",
            artifact = JLLArtifactBinding(;
                treehash = "83426ffc11dda49af0f10b9c203ec2faf9f74e5c",
                download_sources = [
                    JLLArtifactSource(
                        "https://github.com/JuliaBinaryWrappers/PCRE2_jll.jl/releases/download/PCRE2-v10.42.0+1/PCRE2.v10.42.0.i686-w64-mingw32.tar.gz",
                        "e6ef9992aa69d41596114d2f6e1a1eb01fa84fcf43ad1ed868bfaac8aaaf1f70",
                    ),
                ],
            ),
            products = [
                JLLLibraryProduct(
                    :libpcre2_16,
                    "bin\\libpcre2-16-0.dll",
                    [],
                    flags = [:RTLD_LAZY, :RTLD_DEEPBIND],
                ),
                JLLLibraryProduct(
                    :libpcre2_32,
                    "bin\\libpcre2-32-0.dll",
                    [],
                    flags = [:RTLD_LAZY, :RTLD_DEEPBIND],
                ),
                JLLLibraryProduct(
                    :libpcre2_8,
                    "bin\\libpcre2-8-0.dll",
                    [],
                    flags = [:RTLD_LAZY, :RTLD_DEEPBIND],
                ),
            ]
        ),

        JLLBuildInfo(;
            src_version = v"10.42.0+1",
            deps = [
            ],
            sources = [],
            platform = Platform("powerpc64le", "linux"; libc = "glibc"),
            name = "default",
            artifact = JLLArtifactBinding(;
                treehash = "60766178331382a43e86830ea09b025e4d7e0e4a",
                download_sources = [
                    JLLArtifactSource(
                        "https://github.com/JuliaBinaryWrappers/PCRE2_jll.jl/releases/download/PCRE2-v10.42.0+1/PCRE2.v10.42.0.powerpc64le-linux-gnu.tar.gz",
                        "5ab4757a03fb81e6db6b2dff255350fe65857361a647cca59dda0e792d65ff0c",
                    ),
                ],
            ),
            products = [
                JLLLibraryProduct(
                    :libpcre2_16,
                    "lib/libpcre2-16.so",
                    [],
                    flags = [:RTLD_LAZY, :RTLD_DEEPBIND],
                ),
                JLLLibraryProduct(
                    :libpcre2_32,
                    "lib/libpcre2-32.so",
                    [],
                    flags = [:RTLD_LAZY, :RTLD_DEEPBIND],
                ),
                JLLLibraryProduct(
                    :libpcre2_8,
                    "lib/libpcre2-8.so",
                    [],
                    flags = [:RTLD_LAZY, :RTLD_DEEPBIND],
                ),
            ]
        ),

        JLLBuildInfo(;
            src_version = v"10.42.0+1",
            deps = [
            ],
            sources = [],
            platform = Platform("x86_64", "macos"; ),
            name = "default",
            artifact = JLLArtifactBinding(;
                treehash = "1ca034aab6ed29e8ae96e6cbc35a416df707304d",
                download_sources = [
                    JLLArtifactSource(
                        "https://github.com/JuliaBinaryWrappers/PCRE2_jll.jl/releases/download/PCRE2-v10.42.0+1/PCRE2.v10.42.0.x86_64-apple-darwin.tar.gz",
                        "dfeff62a5a7f01220c6dd660cf8fc8b80b6219b077dadedfc527a0916fbe4afc",
                    ),
                ],
            ),
            products = [
                JLLLibraryProduct(
                    :libpcre2_16,
                    "lib/libpcre2-16.0.dylib",
                    [],
                    flags = [:RTLD_LAZY, :RTLD_DEEPBIND],
                ),
                JLLLibraryProduct(
                    :libpcre2_32,
                    "lib/libpcre2-32.0.dylib",
                    [],
                    flags = [:RTLD_LAZY, :RTLD_DEEPBIND],
                ),
                JLLLibraryProduct(
                    :libpcre2_8,
                    "lib/libpcre2-8.0.dylib",
                    [],
                    flags = [:RTLD_LAZY, :RTLD_DEEPBIND],
                ),
            ]
        ),

        JLLBuildInfo(;
            src_version = v"10.42.0+1",
            deps = [
            ],
            sources = [],
            platform = Platform("x86_64", "linux"; libc = "glibc"),
            name = "default",
            artifact = JLLArtifactBinding(;
                treehash = "710cb767c2ea11a0e0b7750fb57771d5243b5c7d",
                download_sources = [
                    JLLArtifactSource(
                        "https://github.com/JuliaBinaryWrappers/PCRE2_jll.jl/releases/download/PCRE2-v10.42.0+1/PCRE2.v10.42.0.x86_64-linux-gnu.tar.gz",
                        "0d18594db4906bdc81af7ebea8f1b6357394189b2e586bf9ef2225ce858636a2",
                    ),
                ],
            ),
            products = [
                JLLLibraryProduct(
                    :libpcre2_16,
                    "lib/libpcre2-16.so",
                    [],
                    flags = [:RTLD_LAZY, :RTLD_DEEPBIND],
                ),
                JLLLibraryProduct(
                    :libpcre2_32,
                    "lib/libpcre2-32.so",
                    [],
                    flags = [:RTLD_LAZY, :RTLD_DEEPBIND],
                ),
                JLLLibraryProduct(
                    :libpcre2_8,
                    "lib/libpcre2-8.so",
                    [],
                    flags = [:RTLD_LAZY, :RTLD_DEEPBIND],
                ),
            ]
        ),

        JLLBuildInfo(;
            src_version = v"10.42.0+1",
            deps = [
            ],
            sources = [],
            platform = Platform("x86_64", "linux"; libc = "glibc", sanitize = "memory"),
            name = "default",
            artifact = JLLArtifactBinding(;
                treehash = "29e0a31f3348afa155f29dd3e324e37c688b8aa2",
                download_sources = [
                    JLLArtifactSource(
                        "https://github.com/JuliaBinaryWrappers/PCRE2_jll.jl/releases/download/PCRE2-v10.42.0+1/PCRE2.v10.42.0.x86_64-linux-gnu-sanitize+memory.tar.gz",
                        "ab5f60cd3edb183afb397b40ecfdb39fe9ca13e98514ce4f97cdf3874a253cb2",
                    ),
                ],
            ),
            products = [
                JLLLibraryProduct(
                    :libpcre2_16,
                    "lib/libpcre2-16.so",
                    [],
                    flags = [:RTLD_LAZY, :RTLD_DEEPBIND],
                ),
                JLLLibraryProduct(
                    :libpcre2_32,
                    "lib/libpcre2-32.so",
                    [],
                    flags = [:RTLD_LAZY, :RTLD_DEEPBIND],
                ),
                JLLLibraryProduct(
                    :libpcre2_8,
                    "lib/libpcre2-8.so",
                    [],
                    flags = [:RTLD_LAZY, :RTLD_DEEPBIND],
                ),
            ]
        ),

        JLLBuildInfo(;
            src_version = v"10.42.0+1",
            deps = [
            ],
            sources = [],
            platform = Platform("x86_64", "linux"; libc = "musl"),
            name = "default",
            artifact = JLLArtifactBinding(;
                treehash = "647d1ea71de9c849e3565dc42757d7abf4f272e8",
                download_sources = [
                    JLLArtifactSource(
                        "https://github.com/JuliaBinaryWrappers/PCRE2_jll.jl/releases/download/PCRE2-v10.42.0+1/PCRE2.v10.42.0.x86_64-linux-musl.tar.gz",
                        "d519b58519f27b7643709cd26d4404a873cf73c8cf516c3c53a1e2efabfbfb68",
                    ),
                ],
            ),
            products = [
                JLLLibraryProduct(
                    :libpcre2_16,
                    "lib/libpcre2-16.so",
                    [],
                    flags = [:RTLD_LAZY, :RTLD_DEEPBIND],
                ),
                JLLLibraryProduct(
                    :libpcre2_32,
                    "lib/libpcre2-32.so",
                    [],
                    flags = [:RTLD_LAZY, :RTLD_DEEPBIND],
                ),
                JLLLibraryProduct(
                    :libpcre2_8,
                    "lib/libpcre2-8.so",
                    [],
                    flags = [:RTLD_LAZY, :RTLD_DEEPBIND],
                ),
            ]
        ),

        JLLBuildInfo(;
            src_version = v"10.42.0+1",
            deps = [
            ],
            sources = [],
            platform = Platform("x86_64", "freebsd"; ),
            name = "default",
            artifact = JLLArtifactBinding(;
                treehash = "e4deb1e0d7e569dd14270cf027941e994cd05121",
                download_sources = [
                    JLLArtifactSource(
                        "https://github.com/JuliaBinaryWrappers/PCRE2_jll.jl/releases/download/PCRE2-v10.42.0+1/PCRE2.v10.42.0.x86_64-unknown-freebsd.tar.gz",
                        "910f09dcdec08606570174c0d811fde81682adb3afcb5aca398f5fedb3725334",
                    ),
                ],
            ),
            products = [
                JLLLibraryProduct(
                    :libpcre2_16,
                    "lib/libpcre2-16.so",
                    [],
                    flags = [:RTLD_LAZY, :RTLD_DEEPBIND],
                ),
                JLLLibraryProduct(
                    :libpcre2_32,
                    "lib/libpcre2-32.so",
                    [],
                    flags = [:RTLD_LAZY, :RTLD_DEEPBIND],
                ),
                JLLLibraryProduct(
                    :libpcre2_8,
                    "lib/libpcre2-8.so",
                    [],
                    flags = [:RTLD_LAZY, :RTLD_DEEPBIND],
                ),
            ]
        ),

        JLLBuildInfo(;
            src_version = v"10.42.0+1",
            deps = [
            ],
            sources = [],
            platform = Platform("x86_64", "windows"; ),
            name = "default",
            artifact = JLLArtifactBinding(;
                treehash = "5430473e053ea273f9bf326983f47aace82e3093",
                download_sources = [
                    JLLArtifactSource(
                        "https://github.com/JuliaBinaryWrappers/PCRE2_jll.jl/releases/download/PCRE2-v10.42.0+1/PCRE2.v10.42.0.x86_64-w64-mingw32.tar.gz",
                        "e6ddeb8af97225d1674c7bfb352d07aac49af525dd427ea4b5d81ebdc1ed8d05",
                    ),
                ],
            ),
            products = [
                JLLLibraryProduct(
                    :libpcre2_16,
                    "bin\\libpcre2-16-0.dll",
                    [],
                    flags = [:RTLD_LAZY, :RTLD_DEEPBIND],
                ),
                JLLLibraryProduct(
                    :libpcre2_32,
                    "bin\\libpcre2-32-0.dll",
                    [],
                    flags = [:RTLD_LAZY, :RTLD_DEEPBIND],
                ),
                JLLLibraryProduct(
                    :libpcre2_8,
                    "bin\\libpcre2-8-0.dll",
                    [],
                    flags = [:RTLD_LAZY, :RTLD_DEEPBIND],
                ),
            ]
        ),

    ]
)

