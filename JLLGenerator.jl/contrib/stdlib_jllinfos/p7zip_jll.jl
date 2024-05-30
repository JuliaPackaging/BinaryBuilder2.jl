jll = JLLInfo(;
    name = "p7zip",
    version = v"17.4.0+2",
    builds = [
        JLLBuildInfo(;
            src_version = v"17.4.0+2",
            deps = [
            ],
            sources = [],
            platform = Platform("aarch64", "macos"; ),
            name = "default",
            artifact = JLLArtifactBinding(;
                treehash = "1dcc3281ed4311962a0989539cf87b3adfad9d7d",
                download_sources = [
                    JLLArtifactSource(
                        "https://github.com/JuliaBinaryWrappers/p7zip_jll.jl/releases/download/p7zip-v17.4.0+2/p7zip.v17.4.0.aarch64-apple-darwin.tar.gz",
                        "b25c5dc18347f24f0c34e26195e987c6e8fbf945e6a7bf507edc4fc2e236c380",
                    ),
                ],
            ),
            products = [
                JLLExecutableProduct(
                    :p7zip,
                    "bin/7z",
                ),
            ]
        ),

        JLLBuildInfo(;
            src_version = v"17.4.0+2",
            deps = [
            ],
            sources = [],
            platform = Platform("aarch64", "linux"; libc = "glibc"),
            name = "default",
            artifact = JLLArtifactBinding(;
                treehash = "a62f15ea9fecf083e359aeafd20d80afe07195bd",
                download_sources = [
                    JLLArtifactSource(
                        "https://github.com/JuliaBinaryWrappers/p7zip_jll.jl/releases/download/p7zip-v17.4.0+2/p7zip.v17.4.0.aarch64-linux-gnu.tar.gz",
                        "6df6ebed568d4234146512bc0f0d80ce85d76ed45a649a230562a1d2d57a87a7",
                    ),
                ],
            ),
            products = [
                JLLExecutableProduct(
                    :p7zip,
                    "bin/7z",
                ),
            ]
        ),

        JLLBuildInfo(;
            src_version = v"17.4.0+2",
            deps = [
            ],
            sources = [],
            platform = Platform("aarch64", "linux"; libc = "musl"),
            name = "default",
            artifact = JLLArtifactBinding(;
                treehash = "16c98fad8c79cabdbd4390ea18f0c480f68df726",
                download_sources = [
                    JLLArtifactSource(
                        "https://github.com/JuliaBinaryWrappers/p7zip_jll.jl/releases/download/p7zip-v17.4.0+2/p7zip.v17.4.0.aarch64-linux-musl.tar.gz",
                        "6d4f02cdff6791db33d67296b23823e10d59b1292603c48578570a3547ce2dc0",
                    ),
                ],
            ),
            products = [
                JLLExecutableProduct(
                    :p7zip,
                    "bin/7z",
                ),
            ]
        ),

        JLLBuildInfo(;
            src_version = v"17.4.0+2",
            deps = [
            ],
            sources = [],
            platform = Platform("armv6l", "linux"; call_abi = "eabihf", libc = "glibc"),
            name = "default",
            artifact = JLLArtifactBinding(;
                treehash = "b1b4485b3f633e4de39496c416279c972039ee40",
                download_sources = [
                    JLLArtifactSource(
                        "https://github.com/JuliaBinaryWrappers/p7zip_jll.jl/releases/download/p7zip-v17.4.0+2/p7zip.v17.4.0.armv6l-linux-gnueabihf.tar.gz",
                        "c59dacd29c6f022a0e3e6ad835bc948e8de9c59baefbc99520d2077a4237fa1f",
                    ),
                ],
            ),
            products = [
                JLLExecutableProduct(
                    :p7zip,
                    "bin/7z",
                ),
            ]
        ),

        JLLBuildInfo(;
            src_version = v"17.4.0+2",
            deps = [
            ],
            sources = [],
            platform = Platform("armv6l", "linux"; call_abi = "eabihf", libc = "musl"),
            name = "default",
            artifact = JLLArtifactBinding(;
                treehash = "f249e27802158360f0f9851bbc40753d03e3621c",
                download_sources = [
                    JLLArtifactSource(
                        "https://github.com/JuliaBinaryWrappers/p7zip_jll.jl/releases/download/p7zip-v17.4.0+2/p7zip.v17.4.0.armv6l-linux-musleabihf.tar.gz",
                        "417f0a8aa68687addc100c4d37ec1b17bbc27c2945d0382109c415f749a289e0",
                    ),
                ],
            ),
            products = [
                JLLExecutableProduct(
                    :p7zip,
                    "bin/7z",
                ),
            ]
        ),

        JLLBuildInfo(;
            src_version = v"17.4.0+2",
            deps = [
            ],
            sources = [],
            platform = Platform("armv7l", "linux"; call_abi = "eabihf", libc = "glibc"),
            name = "default",
            artifact = JLLArtifactBinding(;
                treehash = "289e527b85bdd00820418ad582baf213bc417d3e",
                download_sources = [
                    JLLArtifactSource(
                        "https://github.com/JuliaBinaryWrappers/p7zip_jll.jl/releases/download/p7zip-v17.4.0+2/p7zip.v17.4.0.armv7l-linux-gnueabihf.tar.gz",
                        "28d80aa4c13f2debd0564a5ab977b5211672eb22bf428083a9cc95c5be528f34",
                    ),
                ],
            ),
            products = [
                JLLExecutableProduct(
                    :p7zip,
                    "bin/7z",
                ),
            ]
        ),

        JLLBuildInfo(;
            src_version = v"17.4.0+2",
            deps = [
            ],
            sources = [],
            platform = Platform("armv7l", "linux"; call_abi = "eabihf", libc = "musl"),
            name = "default",
            artifact = JLLArtifactBinding(;
                treehash = "4d439f9dbf6cedfc50f2a201f1778bdcad8a3526",
                download_sources = [
                    JLLArtifactSource(
                        "https://github.com/JuliaBinaryWrappers/p7zip_jll.jl/releases/download/p7zip-v17.4.0+2/p7zip.v17.4.0.armv7l-linux-musleabihf.tar.gz",
                        "514f3cefd3752ee4a082f1df3e69613ec15eb5953a3c44c4a59e32fec4a2f757",
                    ),
                ],
            ),
            products = [
                JLLExecutableProduct(
                    :p7zip,
                    "bin/7z",
                ),
            ]
        ),

        JLLBuildInfo(;
            src_version = v"17.4.0+2",
            deps = [
            ],
            sources = [],
            platform = Platform("i686", "linux"; libc = "glibc"),
            name = "default",
            artifact = JLLArtifactBinding(;
                treehash = "439479eafe9957ca1a79be625bda27807ac8ab10",
                download_sources = [
                    JLLArtifactSource(
                        "https://github.com/JuliaBinaryWrappers/p7zip_jll.jl/releases/download/p7zip-v17.4.0+2/p7zip.v17.4.0.i686-linux-gnu.tar.gz",
                        "b25369d5be18fad55c67eecddccb20e58396f6cdea67cc9114792c713bf152b0",
                    ),
                ],
            ),
            products = [
                JLLExecutableProduct(
                    :p7zip,
                    "bin/7z",
                ),
            ]
        ),

        JLLBuildInfo(;
            src_version = v"17.4.0+2",
            deps = [
            ],
            sources = [],
            platform = Platform("i686", "linux"; libc = "musl"),
            name = "default",
            artifact = JLLArtifactBinding(;
                treehash = "f92692de550d3b9c0aa3698b328a2ead636a2b49",
                download_sources = [
                    JLLArtifactSource(
                        "https://github.com/JuliaBinaryWrappers/p7zip_jll.jl/releases/download/p7zip-v17.4.0+2/p7zip.v17.4.0.i686-linux-musl.tar.gz",
                        "af6bc80d004027eadc1cc06a54ca5c10a3f702913b6f5377aaf990c1bd34cfe5",
                    ),
                ],
            ),
            products = [
                JLLExecutableProduct(
                    :p7zip,
                    "bin/7z",
                ),
            ]
        ),

        JLLBuildInfo(;
            src_version = v"17.4.0+2",
            deps = [
            ],
            sources = [],
            platform = Platform("i686", "windows"; ),
            name = "default",
            artifact = JLLArtifactBinding(;
                treehash = "7af5a8176f39cd2ba0fb8f8c0d92f54ba8ef6d19",
                download_sources = [
                    JLLArtifactSource(
                        "https://github.com/JuliaBinaryWrappers/p7zip_jll.jl/releases/download/p7zip-v17.4.0+2/p7zip.v17.4.0.i686-w64-mingw32.tar.gz",
                        "09420d30598940a548e2c3067057c09b03a805ed4f8fbfedc3775927a2427191",
                    ),
                ],
            ),
            products = [
                JLLExecutableProduct(
                    :p7zip,
                    "bin\\7z.exe",
                ),
            ]
        ),

        JLLBuildInfo(;
            src_version = v"17.4.0+2",
            deps = [
            ],
            sources = [],
            platform = Platform("powerpc64le", "linux"; libc = "glibc"),
            name = "default",
            artifact = JLLArtifactBinding(;
                treehash = "25e27d9ed9603692a03644a062166bc24e7c8328",
                download_sources = [
                    JLLArtifactSource(
                        "https://github.com/JuliaBinaryWrappers/p7zip_jll.jl/releases/download/p7zip-v17.4.0+2/p7zip.v17.4.0.powerpc64le-linux-gnu.tar.gz",
                        "78f110129efd20e13e72aee990ec27a3b39771a65b3fd570f3d5b8e43333478c",
                    ),
                ],
            ),
            products = [
                JLLExecutableProduct(
                    :p7zip,
                    "bin/7z",
                ),
            ]
        ),

        JLLBuildInfo(;
            src_version = v"17.4.0+2",
            deps = [
            ],
            sources = [],
            platform = Platform("x86_64", "macos"; ),
            name = "default",
            artifact = JLLArtifactBinding(;
                treehash = "1fbfb151d58d4f845f29d1d3d844419c8a4a953e",
                download_sources = [
                    JLLArtifactSource(
                        "https://github.com/JuliaBinaryWrappers/p7zip_jll.jl/releases/download/p7zip-v17.4.0+2/p7zip.v17.4.0.x86_64-apple-darwin.tar.gz",
                        "3f618d0d3f7202ed96f5ca6c9ccc99113328c0f52acf15fb652dea72063c5598",
                    ),
                ],
            ),
            products = [
                JLLExecutableProduct(
                    :p7zip,
                    "bin/7z",
                ),
            ]
        ),

        JLLBuildInfo(;
            src_version = v"17.4.0+2",
            deps = [
            ],
            sources = [],
            platform = Platform("x86_64", "linux"; libc = "glibc"),
            name = "default",
            artifact = JLLArtifactBinding(;
                treehash = "de27fd0a6e94c6ad71626d05187c0e2ce07fe891",
                download_sources = [
                    JLLArtifactSource(
                        "https://github.com/JuliaBinaryWrappers/p7zip_jll.jl/releases/download/p7zip-v17.4.0+2/p7zip.v17.4.0.x86_64-linux-gnu.tar.gz",
                        "2616e3b35b6862a218a8fcf651ea00a9860140091e94705967a2fe0404f8ac98",
                    ),
                ],
            ),
            products = [
                JLLExecutableProduct(
                    :p7zip,
                    "bin/7z",
                ),
            ]
        ),

        JLLBuildInfo(;
            src_version = v"17.4.0+2",
            deps = [
            ],
            sources = [],
            platform = Platform("x86_64", "linux"; libc = "glibc", sanitize = "memory"),
            name = "default",
            artifact = JLLArtifactBinding(;
                treehash = "9836314e344e72ca3f389a3fc5713a2484f41205",
                download_sources = [
                    JLLArtifactSource(
                        "https://github.com/JuliaBinaryWrappers/p7zip_jll.jl/releases/download/p7zip-v17.4.0+2/p7zip.v17.4.0.x86_64-linux-gnu-sanitize+memory.tar.gz",
                        "1e5cd802ba1f49781f55ae6740f24756ad8ad8f1521e32365e4c7c2c62fa7c03",
                    ),
                ],
            ),
            products = [
                JLLExecutableProduct(
                    :p7zip,
                    "bin/7z",
                ),
            ]
        ),

        JLLBuildInfo(;
            src_version = v"17.4.0+2",
            deps = [
            ],
            sources = [],
            platform = Platform("x86_64", "linux"; libc = "musl"),
            name = "default",
            artifact = JLLArtifactBinding(;
                treehash = "37ef55f1aceab33bfd3b8ef1202620e532e4f397",
                download_sources = [
                    JLLArtifactSource(
                        "https://github.com/JuliaBinaryWrappers/p7zip_jll.jl/releases/download/p7zip-v17.4.0+2/p7zip.v17.4.0.x86_64-linux-musl.tar.gz",
                        "a33e0f936a5b346b63c628ef62ff03b4ab8b47836887935396ffcd6e7aae4cb4",
                    ),
                ],
            ),
            products = [
                JLLExecutableProduct(
                    :p7zip,
                    "bin/7z",
                ),
            ]
        ),

        JLLBuildInfo(;
            src_version = v"17.4.0+2",
            deps = [
            ],
            sources = [],
            platform = Platform("x86_64", "freebsd"; ),
            name = "default",
            artifact = JLLArtifactBinding(;
                treehash = "1748418979265a0240356001c408c03e6bde5eaa",
                download_sources = [
                    JLLArtifactSource(
                        "https://github.com/JuliaBinaryWrappers/p7zip_jll.jl/releases/download/p7zip-v17.4.0+2/p7zip.v17.4.0.x86_64-unknown-freebsd.tar.gz",
                        "a3574157b06257057eca503dd64ca5be5498c42334c6443bc4a98bffa6ab7609",
                    ),
                ],
            ),
            products = [
                JLLExecutableProduct(
                    :p7zip,
                    "bin/7z",
                ),
            ]
        ),

        JLLBuildInfo(;
            src_version = v"17.4.0+2",
            deps = [
            ],
            sources = [],
            platform = Platform("x86_64", "windows"; ),
            name = "default",
            artifact = JLLArtifactBinding(;
                treehash = "b106d776cbf05287153a8ada4271194afc5d9fdf",
                download_sources = [
                    JLLArtifactSource(
                        "https://github.com/JuliaBinaryWrappers/p7zip_jll.jl/releases/download/p7zip-v17.4.0+2/p7zip.v17.4.0.x86_64-w64-mingw32.tar.gz",
                        "5683f277809d22dd31e854dc7dbda043d632cb5501f5378cbee14d2eacf6f15b",
                    ),
                ],
            ),
            products = [
                JLLExecutableProduct(
                    :p7zip,
                    "bin\\7z.exe",
                ),
            ]
        ),

    ]
)

