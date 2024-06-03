jll = JLLInfo(;
    name = "HelloWorldC",
    version = v"1.3.0+0",
    builds = [
        JLLBuildInfo(;
            src_version = v"1.3.0+0",
            deps = [
            ],
            sources = [],
            platform = Platform("aarch64", "macos"; ),
            name = "default",
            artifact = JLLArtifactBinding(;
                treehash = "d4036700fbbf29b31f5d1d5d948547edd3b70e11",
                download_sources = [
                    JLLArtifactSource(
                        "https://github.com/JuliaBinaryWrappers/HelloWorldC_jll.jl/releases/download/HelloWorldC-v1.3.0+0/HelloWorldC.v1.3.0.aarch64-apple-darwin.tar.gz",
                        "1fd55f038a73c89f4e22b437a9182421e0d31c50bd4912c719215f6a736d50f1",
                    ),
                ],
            ),
            products = [
                JLLExecutableProduct(
                    :hello_world,
                    "bin/hello_world",
                ),
                JLLExecutableProduct(
                    :hello_world_doppelganger,
                    "bin/hello_world",
                ),
            ]
        ),

        JLLBuildInfo(;
            src_version = v"1.3.0+0",
            deps = [
            ],
            sources = [],
            platform = Platform("aarch64", "linux"; libc = "glibc"),
            name = "default",
            artifact = JLLArtifactBinding(;
                treehash = "c82465bd6d0aa1369ff2fd961b73884d1f5de49a",
                download_sources = [
                    JLLArtifactSource(
                        "https://github.com/JuliaBinaryWrappers/HelloWorldC_jll.jl/releases/download/HelloWorldC-v1.3.0+0/HelloWorldC.v1.3.0.aarch64-linux-gnu.tar.gz",
                        "5bfa84332c7ee485ca8e2eee216ad9fa77b2c43d5f261baa823e301b7c789ec4",
                    ),
                ],
            ),
            products = [
                JLLExecutableProduct(
                    :hello_world,
                    "bin/hello_world",
                ),
                JLLExecutableProduct(
                    :hello_world_doppelganger,
                    "bin/hello_world",
                ),
            ]
        ),

        JLLBuildInfo(;
            src_version = v"1.3.0+0",
            deps = [
            ],
            sources = [],
            platform = Platform("aarch64", "linux"; libc = "musl"),
            name = "default",
            artifact = JLLArtifactBinding(;
                treehash = "cb4b8c88778c6cd93b6df38ec5b95a2678434f5d",
                download_sources = [
                    JLLArtifactSource(
                        "https://github.com/JuliaBinaryWrappers/HelloWorldC_jll.jl/releases/download/HelloWorldC-v1.3.0+0/HelloWorldC.v1.3.0.aarch64-linux-musl.tar.gz",
                        "924df1c2a386f79a2727a2f989393102649a24863214f2e88cb4a677d3d22e14",
                    ),
                ],
            ),
            products = [
                JLLExecutableProduct(
                    :hello_world,
                    "bin/hello_world",
                ),
                JLLExecutableProduct(
                    :hello_world_doppelganger,
                    "bin/hello_world",
                ),
            ]
        ),

        JLLBuildInfo(;
            src_version = v"1.3.0+0",
            deps = [
            ],
            sources = [],
            platform = Platform("armv6l", "linux"; call_abi = "eabihf", libc = "glibc"),
            name = "default",
            artifact = JLLArtifactBinding(;
                treehash = "20a32b71145b67e708f63fb5880a7243727aec0f",
                download_sources = [
                    JLLArtifactSource(
                        "https://github.com/JuliaBinaryWrappers/HelloWorldC_jll.jl/releases/download/HelloWorldC-v1.3.0+0/HelloWorldC.v1.3.0.armv6l-linux-gnueabihf.tar.gz",
                        "6f0997b0aad387ba6e2402530642bb4ded85b0243460d2e4b13d94f2c8340a44",
                    ),
                ],
            ),
            products = [
                JLLExecutableProduct(
                    :hello_world,
                    "bin/hello_world",
                ),
                JLLExecutableProduct(
                    :hello_world_doppelganger,
                    "bin/hello_world",
                ),
            ]
        ),

        JLLBuildInfo(;
            src_version = v"1.3.0+0",
            deps = [
            ],
            sources = [],
            platform = Platform("armv6l", "linux"; call_abi = "eabihf", libc = "musl"),
            name = "default",
            artifact = JLLArtifactBinding(;
                treehash = "c1179604ea37fa66ee6d5d592c7bbfd1f20292c3",
                download_sources = [
                    JLLArtifactSource(
                        "https://github.com/JuliaBinaryWrappers/HelloWorldC_jll.jl/releases/download/HelloWorldC-v1.3.0+0/HelloWorldC.v1.3.0.armv6l-linux-musleabihf.tar.gz",
                        "0aca47bce6f09c38a7939277a593deb988123fe59f7992225a1ede8e174f1b06",
                    ),
                ],
            ),
            products = [
                JLLExecutableProduct(
                    :hello_world,
                    "bin/hello_world",
                ),
                JLLExecutableProduct(
                    :hello_world_doppelganger,
                    "bin/hello_world",
                ),
            ]
        ),

        JLLBuildInfo(;
            src_version = v"1.3.0+0",
            deps = [
            ],
            sources = [],
            platform = Platform("armv7l", "linux"; call_abi = "eabihf", libc = "glibc"),
            name = "default",
            artifact = JLLArtifactBinding(;
                treehash = "0a8e7b523ef6be31311aefe9983a488616e58201",
                download_sources = [
                    JLLArtifactSource(
                        "https://github.com/JuliaBinaryWrappers/HelloWorldC_jll.jl/releases/download/HelloWorldC-v1.3.0+0/HelloWorldC.v1.3.0.armv7l-linux-gnueabihf.tar.gz",
                        "f29f4da556d2b4ee9eaff7740aa0f9436406b75b0f1ec428e881a47ab7b7477b",
                    ),
                ],
            ),
            products = [
                JLLExecutableProduct(
                    :hello_world,
                    "bin/hello_world",
                ),
                JLLExecutableProduct(
                    :hello_world_doppelganger,
                    "bin/hello_world",
                ),
            ]
        ),

        JLLBuildInfo(;
            src_version = v"1.3.0+0",
            deps = [
            ],
            sources = [],
            platform = Platform("armv7l", "linux"; call_abi = "eabihf", libc = "musl"),
            name = "default",
            artifact = JLLArtifactBinding(;
                treehash = "ca94b4d87f1a276066a2994733142e35046c41dd",
                download_sources = [
                    JLLArtifactSource(
                        "https://github.com/JuliaBinaryWrappers/HelloWorldC_jll.jl/releases/download/HelloWorldC-v1.3.0+0/HelloWorldC.v1.3.0.armv7l-linux-musleabihf.tar.gz",
                        "5fb4019d6d797e5e3860cfec90cab12f6865fa624e87b51c20220a44bb94846a",
                    ),
                ],
            ),
            products = [
                JLLExecutableProduct(
                    :hello_world,
                    "bin/hello_world",
                ),
                JLLExecutableProduct(
                    :hello_world_doppelganger,
                    "bin/hello_world",
                ),
            ]
        ),

        JLLBuildInfo(;
            src_version = v"1.3.0+0",
            deps = [
            ],
            sources = [],
            platform = Platform("i686", "linux"; libc = "glibc"),
            name = "default",
            artifact = JLLArtifactBinding(;
                treehash = "cb1aefe048a6c0395b6b664695c20cb50dbec8e3",
                download_sources = [
                    JLLArtifactSource(
                        "https://github.com/JuliaBinaryWrappers/HelloWorldC_jll.jl/releases/download/HelloWorldC-v1.3.0+0/HelloWorldC.v1.3.0.i686-linux-gnu.tar.gz",
                        "c79def491d702590b9c82599d40c4e755251dbb49669d0290f9a1a7bf1d91a1a",
                    ),
                ],
            ),
            products = [
                JLLExecutableProduct(
                    :hello_world,
                    "bin/hello_world",
                ),
                JLLExecutableProduct(
                    :hello_world_doppelganger,
                    "bin/hello_world",
                ),
            ]
        ),

        JLLBuildInfo(;
            src_version = v"1.3.0+0",
            deps = [
            ],
            sources = [],
            platform = Platform("i686", "linux"; libc = "musl"),
            name = "default",
            artifact = JLLArtifactBinding(;
                treehash = "b50220be02e9c839749f91a70694ae68c2712c8e",
                download_sources = [
                    JLLArtifactSource(
                        "https://github.com/JuliaBinaryWrappers/HelloWorldC_jll.jl/releases/download/HelloWorldC-v1.3.0+0/HelloWorldC.v1.3.0.i686-linux-musl.tar.gz",
                        "6aecc06cf803ad16703744610deb243a21b39e19ae1951a38977610881698f9e",
                    ),
                ],
            ),
            products = [
                JLLExecutableProduct(
                    :hello_world,
                    "bin/hello_world",
                ),
                JLLExecutableProduct(
                    :hello_world_doppelganger,
                    "bin/hello_world",
                ),
            ]
        ),

        JLLBuildInfo(;
            src_version = v"1.3.0+0",
            deps = [
            ],
            sources = [],
            platform = Platform("i686", "windows"; ),
            name = "default",
            artifact = JLLArtifactBinding(;
                treehash = "0f7597f042d16d438f9684e20ca57ea22e4e15c1",
                download_sources = [
                    JLLArtifactSource(
                        "https://github.com/JuliaBinaryWrappers/HelloWorldC_jll.jl/releases/download/HelloWorldC-v1.3.0+0/HelloWorldC.v1.3.0.i686-w64-mingw32.tar.gz",
                        "5f14f5ade1314e777432bd85cd075ae9d31e28352e646f90adf0444a7a54f76b",
                    ),
                ],
            ),
            products = [
                JLLExecutableProduct(
                    :hello_world,
                    "bin\\hello_world.exe",
                ),
                JLLExecutableProduct(
                    :hello_world_doppelganger,
                    "bin\\hello_world.exe",
                ),
            ]
        ),

        JLLBuildInfo(;
            src_version = v"1.3.0+0",
            deps = [
            ],
            sources = [],
            platform = Platform("powerpc64le", "linux"; libc = "glibc"),
            name = "default",
            artifact = JLLArtifactBinding(;
                treehash = "5e9c87fc4e3372c27a77061a49d97fa5002df0e4",
                download_sources = [
                    JLLArtifactSource(
                        "https://github.com/JuliaBinaryWrappers/HelloWorldC_jll.jl/releases/download/HelloWorldC-v1.3.0+0/HelloWorldC.v1.3.0.powerpc64le-linux-gnu.tar.gz",
                        "e2a728b29124fc7408d6e47cc6fc943d0336d1386e56a3775a0665b34528881b",
                    ),
                ],
            ),
            products = [
                JLLExecutableProduct(
                    :hello_world,
                    "bin/hello_world",
                ),
                JLLExecutableProduct(
                    :hello_world_doppelganger,
                    "bin/hello_world",
                ),
            ]
        ),

        JLLBuildInfo(;
            src_version = v"1.3.0+0",
            deps = [
            ],
            sources = [],
            platform = Platform("x86_64", "macos"; ),
            name = "default",
            artifact = JLLArtifactBinding(;
                treehash = "09ed293f6f5ebfcaf90eef2b4d45c402d834d33e",
                download_sources = [
                    JLLArtifactSource(
                        "https://github.com/JuliaBinaryWrappers/HelloWorldC_jll.jl/releases/download/HelloWorldC-v1.3.0+0/HelloWorldC.v1.3.0.x86_64-apple-darwin.tar.gz",
                        "9feabdcb8341d37d0c8b1acb5840e1c9d524632c5aff40c05b5e0e1d621a7e30",
                    ),
                ],
            ),
            products = [
                JLLExecutableProduct(
                    :hello_world,
                    "bin/hello_world",
                ),
                JLLExecutableProduct(
                    :hello_world_doppelganger,
                    "bin/hello_world",
                ),
            ]
        ),

        JLLBuildInfo(;
            src_version = v"1.3.0+0",
            deps = [
            ],
            sources = [],
            platform = Platform("x86_64", "linux"; libc = "glibc"),
            name = "default",
            artifact = JLLArtifactBinding(;
                treehash = "8c8251b0c21615bce0701995eded26ac7697b5cc",
                download_sources = [
                    JLLArtifactSource(
                        "https://github.com/JuliaBinaryWrappers/HelloWorldC_jll.jl/releases/download/HelloWorldC-v1.3.0+0/HelloWorldC.v1.3.0.x86_64-linux-gnu.tar.gz",
                        "974f7e1d1cdbebad149e51fed4f1b7c6a0b5ccfa350f7d252dfcf66c2dbf9f63",
                    ),
                ],
            ),
            products = [
                JLLExecutableProduct(
                    :hello_world,
                    "bin/hello_world",
                ),
                JLLExecutableProduct(
                    :hello_world_doppelganger,
                    "bin/hello_world",
                ),
            ]
        ),

        JLLBuildInfo(;
            src_version = v"1.3.0+0",
            deps = [
            ],
            sources = [],
            platform = Platform("x86_64", "linux"; libc = "musl"),
            name = "default",
            artifact = JLLArtifactBinding(;
                treehash = "cfaaf0517421585561e3b30dd6f53f6c14b2835f",
                download_sources = [
                    JLLArtifactSource(
                        "https://github.com/JuliaBinaryWrappers/HelloWorldC_jll.jl/releases/download/HelloWorldC-v1.3.0+0/HelloWorldC.v1.3.0.x86_64-linux-musl.tar.gz",
                        "25d3d6ecc753f4dbbcaab0db7b6c20b29b0a79b0c31f7a26a0cf18c365d27809",
                    ),
                ],
            ),
            products = [
                JLLExecutableProduct(
                    :hello_world,
                    "bin/hello_world",
                ),
                JLLExecutableProduct(
                    :hello_world_doppelganger,
                    "bin/hello_world",
                ),
            ]
        ),

        JLLBuildInfo(;
            src_version = v"1.3.0+0",
            deps = [
            ],
            sources = [],
            platform = Platform("x86_64", "freebsd"; ),
            name = "default",
            artifact = JLLArtifactBinding(;
                treehash = "9adaeee1375ffd66613afe71f111dad3a88fb302",
                download_sources = [
                    JLLArtifactSource(
                        "https://github.com/JuliaBinaryWrappers/HelloWorldC_jll.jl/releases/download/HelloWorldC-v1.3.0+0/HelloWorldC.v1.3.0.x86_64-unknown-freebsd.tar.gz",
                        "8e59a00a9238d1605af09ec3a76c8bb5ad012b5621f5ccb7de6cf73f89fbf18f",
                    ),
                ],
            ),
            products = [
                JLLExecutableProduct(
                    :hello_world,
                    "bin/hello_world",
                ),
                JLLExecutableProduct(
                    :hello_world_doppelganger,
                    "bin/hello_world",
                ),
            ]
        ),

        JLLBuildInfo(;
            src_version = v"1.3.0+0",
            deps = [
            ],
            sources = [],
            platform = Platform("x86_64", "windows"; ),
            name = "default",
            artifact = JLLArtifactBinding(;
                treehash = "59955b315ce95abd82f71d29389be3b734b14821",
                download_sources = [
                    JLLArtifactSource(
                        "https://github.com/JuliaBinaryWrappers/HelloWorldC_jll.jl/releases/download/HelloWorldC-v1.3.0+0/HelloWorldC.v1.3.0.x86_64-w64-mingw32.tar.gz",
                        "47bbead5cbdfca1b23544b1b398e8a2194c78ab8a772ca3075084c4a9ab75fb7",
                    ),
                ],
            ),
            products = [
                JLLExecutableProduct(
                    :hello_world,
                    "bin\\hello_world.exe",
                ),
                JLLExecutableProduct(
                    :hello_world_doppelganger,
                    "bin\\hello_world.exe",
                ),
            ]
        ),

    ]
)

