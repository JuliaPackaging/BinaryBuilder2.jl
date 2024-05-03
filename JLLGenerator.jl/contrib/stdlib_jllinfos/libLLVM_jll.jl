jll = JLLInfo(;
    name = "libLLVM",
    version = v"15.0.7+8",
    artifacts = [
        JLLArtifactInfo(;
            src_version = v"15.0.7+8",
            deps = [
                JLLPackageDependency(
                    "Zlib_jll",
                    Base.UUID("83775a58-1f1d-513f-b197-d71354ab007a"),
                    "*",
                ),
                JLLPackageDependency(
                    "TOML",
                    Base.UUID("fa267f1f-6049-4f14-aa54-33bafae1ed76"),
                    "*",
                ),
            ],
            sources = [],
            platform = Platform("aarch64", "macos"; llvm_version = "15"),
            name = "default",
            treehash = "97571655c91d9aee2cf4334aaeb50fafdfb37282",
            download_sources = [
                JLLArtifactSource(
                    "https://github.com/JuliaBinaryWrappers/libLLVM_jll.jl/releases/download/libLLVM-v15.0.7+8/libLLVM.v15.0.7.aarch64-apple-darwin-llvm_version+15.tar.gz",
                    "eb4848e193aa8c33a46e85fef2b05e120f76b6ade6c7ceb79113656d559464c2",
                ),
            ],
            products = [
                JLLLibraryProduct(
                    :libllvm,
                    "lib/libLLVM.dylib",
                    [
                        JLLLibraryDep(:Zlib_jll, :libz),
                    ],
                    flags = [:RTLD_LAZY, :RTLD_DEEPBIND],
                ),
                JLLExecutableProduct(
                    :llvm_config,
                    "tools/llvm-config",
                ),
            ]
        ),

        JLLArtifactInfo(;
            src_version = v"15.0.7+8",
            deps = [
                JLLPackageDependency(
                    "Zlib_jll",
                    Base.UUID("83775a58-1f1d-513f-b197-d71354ab007a"),
                    "*",
                ),
                JLLPackageDependency(
                    "TOML",
                    Base.UUID("fa267f1f-6049-4f14-aa54-33bafae1ed76"),
                    "*",
                ),
            ],
            sources = [],
            platform = Platform("aarch64", "macos"; llvm_version = "15.asserts"),
            name = "default",
            treehash = "b22b511adaf51f0847dff19aa8ecdf8742ed0059",
            download_sources = [
                JLLArtifactSource(
                    "https://github.com/JuliaBinaryWrappers/libLLVM_jll.jl/releases/download/libLLVM-v15.0.7+8/libLLVM.v15.0.7.aarch64-apple-darwin-llvm_version+15.asserts.tar.gz",
                    "b9b7e2259fb93a456cff61b4362d44757f30c33c1e08991b7ffe7e60d40ae708",
                ),
            ],
            products = [
                JLLLibraryProduct(
                    :libllvm,
                    "lib/libLLVM.dylib",
                    [
                        JLLLibraryDep(:Zlib_jll, :libz),
                    ],
                    flags = [:RTLD_LAZY, :RTLD_DEEPBIND],
                ),
                JLLExecutableProduct(
                    :llvm_config,
                    "tools/llvm-config",
                ),
            ]
        ),

        JLLArtifactInfo(;
            src_version = v"15.0.7+8",
            deps = [
                JLLPackageDependency(
                    "Zlib_jll",
                    Base.UUID("83775a58-1f1d-513f-b197-d71354ab007a"),
                    "*",
                ),
                JLLPackageDependency(
                    "TOML",
                    Base.UUID("fa267f1f-6049-4f14-aa54-33bafae1ed76"),
                    "*",
                ),
            ],
            sources = [],
            platform = Platform("aarch64", "linux"; cxxstring_abi = "cxx03", libc = "glibc", llvm_version = "15"),
            name = "default",
            treehash = "8cbd94a7d5be584b67d1099d786b28e3b1ff5e90",
            download_sources = [
                JLLArtifactSource(
                    "https://github.com/JuliaBinaryWrappers/libLLVM_jll.jl/releases/download/libLLVM-v15.0.7+8/libLLVM.v15.0.7.aarch64-linux-gnu-cxx03-llvm_version+15.tar.gz",
                    "aacb1b1ea4db4832589fa8d3fa35d92761ad4d038fdacbf19fce1ca3ffaaaccc",
                ),
            ],
            products = [
                JLLLibraryProduct(
                    :libllvm,
                    "lib/libLLVM-15jl.so",
                    [
                        JLLLibraryDep(:Zlib_jll, :libz),
                    ],
                    flags = [:RTLD_LAZY, :RTLD_DEEPBIND],
                ),
                JLLExecutableProduct(
                    :llvm_config,
                    "tools/llvm-config",
                ),
            ]
        ),

        JLLArtifactInfo(;
            src_version = v"15.0.7+8",
            deps = [
                JLLPackageDependency(
                    "Zlib_jll",
                    Base.UUID("83775a58-1f1d-513f-b197-d71354ab007a"),
                    "*",
                ),
                JLLPackageDependency(
                    "TOML",
                    Base.UUID("fa267f1f-6049-4f14-aa54-33bafae1ed76"),
                    "*",
                ),
            ],
            sources = [],
            platform = Platform("aarch64", "linux"; cxxstring_abi = "cxx03", libc = "glibc", llvm_version = "15.asserts"),
            name = "default",
            treehash = "d696ec20362910088f0761b33d9924c7030acacb",
            download_sources = [
                JLLArtifactSource(
                    "https://github.com/JuliaBinaryWrappers/libLLVM_jll.jl/releases/download/libLLVM-v15.0.7+8/libLLVM.v15.0.7.aarch64-linux-gnu-cxx03-llvm_version+15.asserts.tar.gz",
                    "adff60489c1adf7263cbc4befa0402457283f7c1ee7b0ff2cf5d91df3b2e12b1",
                ),
            ],
            products = [
                JLLLibraryProduct(
                    :libllvm,
                    "lib/libLLVM-15jl.so",
                    [
                        JLLLibraryDep(:Zlib_jll, :libz),
                    ],
                    flags = [:RTLD_LAZY, :RTLD_DEEPBIND],
                ),
                JLLExecutableProduct(
                    :llvm_config,
                    "tools/llvm-config",
                ),
            ]
        ),

        JLLArtifactInfo(;
            src_version = v"15.0.7+8",
            deps = [
                JLLPackageDependency(
                    "Zlib_jll",
                    Base.UUID("83775a58-1f1d-513f-b197-d71354ab007a"),
                    "*",
                ),
                JLLPackageDependency(
                    "TOML",
                    Base.UUID("fa267f1f-6049-4f14-aa54-33bafae1ed76"),
                    "*",
                ),
            ],
            sources = [],
            platform = Platform("aarch64", "linux"; cxxstring_abi = "cxx11", libc = "glibc", llvm_version = "15"),
            name = "default",
            treehash = "24acbfc4fccc97602f8a78bd8fbe830980274def",
            download_sources = [
                JLLArtifactSource(
                    "https://github.com/JuliaBinaryWrappers/libLLVM_jll.jl/releases/download/libLLVM-v15.0.7+8/libLLVM.v15.0.7.aarch64-linux-gnu-cxx11-llvm_version+15.tar.gz",
                    "b9218e2454872072fa3e763eb85c6906911192e047a06e13b76abeb8cdb6d571",
                ),
            ],
            products = [
                JLLLibraryProduct(
                    :libllvm,
                    "lib/libLLVM-15jl.so",
                    [
                        JLLLibraryDep(:Zlib_jll, :libz),
                    ],
                    flags = [:RTLD_LAZY, :RTLD_DEEPBIND],
                ),
                JLLExecutableProduct(
                    :llvm_config,
                    "tools/llvm-config",
                ),
            ]
        ),

        JLLArtifactInfo(;
            src_version = v"15.0.7+8",
            deps = [
                JLLPackageDependency(
                    "Zlib_jll",
                    Base.UUID("83775a58-1f1d-513f-b197-d71354ab007a"),
                    "*",
                ),
                JLLPackageDependency(
                    "TOML",
                    Base.UUID("fa267f1f-6049-4f14-aa54-33bafae1ed76"),
                    "*",
                ),
            ],
            sources = [],
            platform = Platform("aarch64", "linux"; cxxstring_abi = "cxx11", libc = "glibc", llvm_version = "15.asserts"),
            name = "default",
            treehash = "f0d931f02abd10500c5b45be29d6dec79b45e017",
            download_sources = [
                JLLArtifactSource(
                    "https://github.com/JuliaBinaryWrappers/libLLVM_jll.jl/releases/download/libLLVM-v15.0.7+8/libLLVM.v15.0.7.aarch64-linux-gnu-cxx11-llvm_version+15.asserts.tar.gz",
                    "dde848f37f6f937e3a17abb9a94b09fd9435edfbea1922ef4e8d7cd5928f0e2f",
                ),
            ],
            products = [
                JLLLibraryProduct(
                    :libllvm,
                    "lib/libLLVM-15jl.so",
                    [
                        JLLLibraryDep(:Zlib_jll, :libz),
                    ],
                    flags = [:RTLD_LAZY, :RTLD_DEEPBIND],
                ),
                JLLExecutableProduct(
                    :llvm_config,
                    "tools/llvm-config",
                ),
            ]
        ),

        JLLArtifactInfo(;
            src_version = v"15.0.7+8",
            deps = [
                JLLPackageDependency(
                    "Zlib_jll",
                    Base.UUID("83775a58-1f1d-513f-b197-d71354ab007a"),
                    "*",
                ),
                JLLPackageDependency(
                    "TOML",
                    Base.UUID("fa267f1f-6049-4f14-aa54-33bafae1ed76"),
                    "*",
                ),
            ],
            sources = [],
            platform = Platform("aarch64", "linux"; cxxstring_abi = "cxx03", libc = "musl", llvm_version = "15"),
            name = "default",
            treehash = "8710c8e9abd1f4b76a111b75e4e2adb0f40d3573",
            download_sources = [
                JLLArtifactSource(
                    "https://github.com/JuliaBinaryWrappers/libLLVM_jll.jl/releases/download/libLLVM-v15.0.7+8/libLLVM.v15.0.7.aarch64-linux-musl-cxx03-llvm_version+15.tar.gz",
                    "e72474d06b44b5ebe8f7f6b7bc214a04d5c4f14dba19b8c64b9c51ed84a516cf",
                ),
            ],
            products = [
                JLLLibraryProduct(
                    :libllvm,
                    "lib/libLLVM-15jl.so",
                    [
                        JLLLibraryDep(:Zlib_jll, :libz),
                    ],
                    flags = [:RTLD_LAZY, :RTLD_DEEPBIND],
                ),
                JLLExecutableProduct(
                    :llvm_config,
                    "tools/llvm-config",
                ),
            ]
        ),

        JLLArtifactInfo(;
            src_version = v"15.0.7+8",
            deps = [
                JLLPackageDependency(
                    "Zlib_jll",
                    Base.UUID("83775a58-1f1d-513f-b197-d71354ab007a"),
                    "*",
                ),
                JLLPackageDependency(
                    "TOML",
                    Base.UUID("fa267f1f-6049-4f14-aa54-33bafae1ed76"),
                    "*",
                ),
            ],
            sources = [],
            platform = Platform("aarch64", "linux"; cxxstring_abi = "cxx03", libc = "musl", llvm_version = "15.asserts"),
            name = "default",
            treehash = "917ee6877968b3d62c74a7930e250e5f9299a890",
            download_sources = [
                JLLArtifactSource(
                    "https://github.com/JuliaBinaryWrappers/libLLVM_jll.jl/releases/download/libLLVM-v15.0.7+8/libLLVM.v15.0.7.aarch64-linux-musl-cxx03-llvm_version+15.asserts.tar.gz",
                    "7ab1a53724a098975bcb5c87c0eca22d9b070bb63ff5debb9392bd9e40b6ce21",
                ),
            ],
            products = [
                JLLLibraryProduct(
                    :libllvm,
                    "lib/libLLVM-15jl.so",
                    [
                        JLLLibraryDep(:Zlib_jll, :libz),
                    ],
                    flags = [:RTLD_LAZY, :RTLD_DEEPBIND],
                ),
                JLLExecutableProduct(
                    :llvm_config,
                    "tools/llvm-config",
                ),
            ]
        ),

        JLLArtifactInfo(;
            src_version = v"15.0.7+8",
            deps = [
                JLLPackageDependency(
                    "Zlib_jll",
                    Base.UUID("83775a58-1f1d-513f-b197-d71354ab007a"),
                    "*",
                ),
                JLLPackageDependency(
                    "TOML",
                    Base.UUID("fa267f1f-6049-4f14-aa54-33bafae1ed76"),
                    "*",
                ),
            ],
            sources = [],
            platform = Platform("aarch64", "linux"; cxxstring_abi = "cxx11", libc = "musl", llvm_version = "15"),
            name = "default",
            treehash = "6c250e2fab604c86f1dafff1105b6011e6ff9e66",
            download_sources = [
                JLLArtifactSource(
                    "https://github.com/JuliaBinaryWrappers/libLLVM_jll.jl/releases/download/libLLVM-v15.0.7+8/libLLVM.v15.0.7.aarch64-linux-musl-cxx11-llvm_version+15.tar.gz",
                    "62b150c94048b3cee3a92bccd3fb43bd7d9c616ba66bb27c3797c437006b7c3a",
                ),
            ],
            products = [
                JLLLibraryProduct(
                    :libllvm,
                    "lib/libLLVM-15jl.so",
                    [
                        JLLLibraryDep(:Zlib_jll, :libz),
                    ],
                    flags = [:RTLD_LAZY, :RTLD_DEEPBIND],
                ),
                JLLExecutableProduct(
                    :llvm_config,
                    "tools/llvm-config",
                ),
            ]
        ),

        JLLArtifactInfo(;
            src_version = v"15.0.7+8",
            deps = [
                JLLPackageDependency(
                    "Zlib_jll",
                    Base.UUID("83775a58-1f1d-513f-b197-d71354ab007a"),
                    "*",
                ),
                JLLPackageDependency(
                    "TOML",
                    Base.UUID("fa267f1f-6049-4f14-aa54-33bafae1ed76"),
                    "*",
                ),
            ],
            sources = [],
            platform = Platform("aarch64", "linux"; cxxstring_abi = "cxx11", libc = "musl", llvm_version = "15.asserts"),
            name = "default",
            treehash = "725bb348ffa98122ed64f764fddc3539e8570867",
            download_sources = [
                JLLArtifactSource(
                    "https://github.com/JuliaBinaryWrappers/libLLVM_jll.jl/releases/download/libLLVM-v15.0.7+8/libLLVM.v15.0.7.aarch64-linux-musl-cxx11-llvm_version+15.asserts.tar.gz",
                    "a84d1951d3bc6b17eaf8ada3dc11ba9200c87f0bf3fc77860cb2eb1fa2705dff",
                ),
            ],
            products = [
                JLLLibraryProduct(
                    :libllvm,
                    "lib/libLLVM-15jl.so",
                    [
                        JLLLibraryDep(:Zlib_jll, :libz),
                    ],
                    flags = [:RTLD_LAZY, :RTLD_DEEPBIND],
                ),
                JLLExecutableProduct(
                    :llvm_config,
                    "tools/llvm-config",
                ),
            ]
        ),

        JLLArtifactInfo(;
            src_version = v"15.0.7+8",
            deps = [
                JLLPackageDependency(
                    "Zlib_jll",
                    Base.UUID("83775a58-1f1d-513f-b197-d71354ab007a"),
                    "*",
                ),
                JLLPackageDependency(
                    "TOML",
                    Base.UUID("fa267f1f-6049-4f14-aa54-33bafae1ed76"),
                    "*",
                ),
            ],
            sources = [],
            platform = Platform("armv6l", "linux"; cxxstring_abi = "cxx03", call_abi = "eabihf", libc = "glibc", llvm_version = "15"),
            name = "default",
            treehash = "dbef3c5689d2f0928c8696f591138d0e1d48c7cf",
            download_sources = [
                JLLArtifactSource(
                    "https://github.com/JuliaBinaryWrappers/libLLVM_jll.jl/releases/download/libLLVM-v15.0.7+8/libLLVM.v15.0.7.armv6l-linux-gnueabihf-cxx03-llvm_version+15.tar.gz",
                    "d537cc8ba78f5d72e3bae0904985e42cf1835c69a9d8c2682341b570f7b627e5",
                ),
            ],
            products = [
                JLLLibraryProduct(
                    :libllvm,
                    "lib/libLLVM-15jl.so",
                    [
                        JLLLibraryDep(:Zlib_jll, :libz),
                    ],
                    flags = [:RTLD_LAZY, :RTLD_DEEPBIND],
                ),
                JLLExecutableProduct(
                    :llvm_config,
                    "tools/llvm-config",
                ),
            ]
        ),

        JLLArtifactInfo(;
            src_version = v"15.0.7+8",
            deps = [
                JLLPackageDependency(
                    "Zlib_jll",
                    Base.UUID("83775a58-1f1d-513f-b197-d71354ab007a"),
                    "*",
                ),
                JLLPackageDependency(
                    "TOML",
                    Base.UUID("fa267f1f-6049-4f14-aa54-33bafae1ed76"),
                    "*",
                ),
            ],
            sources = [],
            platform = Platform("armv6l", "linux"; cxxstring_abi = "cxx03", call_abi = "eabihf", libc = "glibc", llvm_version = "15.asserts"),
            name = "default",
            treehash = "98a845171373c33f088aa2d79009170f976368ad",
            download_sources = [
                JLLArtifactSource(
                    "https://github.com/JuliaBinaryWrappers/libLLVM_jll.jl/releases/download/libLLVM-v15.0.7+8/libLLVM.v15.0.7.armv6l-linux-gnueabihf-cxx03-llvm_version+15.asserts.tar.gz",
                    "8fa686601d536085cf086713b74777cebcdc007d67c40e84becea23161374118",
                ),
            ],
            products = [
                JLLLibraryProduct(
                    :libllvm,
                    "lib/libLLVM-15jl.so",
                    [
                        JLLLibraryDep(:Zlib_jll, :libz),
                    ],
                    flags = [:RTLD_LAZY, :RTLD_DEEPBIND],
                ),
                JLLExecutableProduct(
                    :llvm_config,
                    "tools/llvm-config",
                ),
            ]
        ),

        JLLArtifactInfo(;
            src_version = v"15.0.7+8",
            deps = [
                JLLPackageDependency(
                    "Zlib_jll",
                    Base.UUID("83775a58-1f1d-513f-b197-d71354ab007a"),
                    "*",
                ),
                JLLPackageDependency(
                    "TOML",
                    Base.UUID("fa267f1f-6049-4f14-aa54-33bafae1ed76"),
                    "*",
                ),
            ],
            sources = [],
            platform = Platform("armv6l", "linux"; cxxstring_abi = "cxx11", call_abi = "eabihf", libc = "glibc", llvm_version = "15"),
            name = "default",
            treehash = "2525e144d30b6ad0b548c29cc004b0720b19cb59",
            download_sources = [
                JLLArtifactSource(
                    "https://github.com/JuliaBinaryWrappers/libLLVM_jll.jl/releases/download/libLLVM-v15.0.7+8/libLLVM.v15.0.7.armv6l-linux-gnueabihf-cxx11-llvm_version+15.tar.gz",
                    "5d33b47784bed1f0f1be6b8aba2c3e3ea4a0b71bd3377e741611fd9c2a0868e4",
                ),
            ],
            products = [
                JLLLibraryProduct(
                    :libllvm,
                    "lib/libLLVM-15jl.so",
                    [
                        JLLLibraryDep(:Zlib_jll, :libz),
                    ],
                    flags = [:RTLD_LAZY, :RTLD_DEEPBIND],
                ),
                JLLExecutableProduct(
                    :llvm_config,
                    "tools/llvm-config",
                ),
            ]
        ),

        JLLArtifactInfo(;
            src_version = v"15.0.7+8",
            deps = [
                JLLPackageDependency(
                    "Zlib_jll",
                    Base.UUID("83775a58-1f1d-513f-b197-d71354ab007a"),
                    "*",
                ),
                JLLPackageDependency(
                    "TOML",
                    Base.UUID("fa267f1f-6049-4f14-aa54-33bafae1ed76"),
                    "*",
                ),
            ],
            sources = [],
            platform = Platform("armv6l", "linux"; cxxstring_abi = "cxx11", call_abi = "eabihf", libc = "glibc", llvm_version = "15.asserts"),
            name = "default",
            treehash = "4340250008819e658ee621ab66a8cfdf005cc5ae",
            download_sources = [
                JLLArtifactSource(
                    "https://github.com/JuliaBinaryWrappers/libLLVM_jll.jl/releases/download/libLLVM-v15.0.7+8/libLLVM.v15.0.7.armv6l-linux-gnueabihf-cxx11-llvm_version+15.asserts.tar.gz",
                    "dcacd9007900f09dc45c1610fe24f82b1f0172860b7fb0dff06f6e069723d941",
                ),
            ],
            products = [
                JLLLibraryProduct(
                    :libllvm,
                    "lib/libLLVM-15jl.so",
                    [
                        JLLLibraryDep(:Zlib_jll, :libz),
                    ],
                    flags = [:RTLD_LAZY, :RTLD_DEEPBIND],
                ),
                JLLExecutableProduct(
                    :llvm_config,
                    "tools/llvm-config",
                ),
            ]
        ),

        JLLArtifactInfo(;
            src_version = v"15.0.7+8",
            deps = [
                JLLPackageDependency(
                    "Zlib_jll",
                    Base.UUID("83775a58-1f1d-513f-b197-d71354ab007a"),
                    "*",
                ),
                JLLPackageDependency(
                    "TOML",
                    Base.UUID("fa267f1f-6049-4f14-aa54-33bafae1ed76"),
                    "*",
                ),
            ],
            sources = [],
            platform = Platform("armv6l", "linux"; cxxstring_abi = "cxx03", call_abi = "eabihf", libc = "musl", llvm_version = "15"),
            name = "default",
            treehash = "1c77a547ab3e5625d84c628cb3bb55ec3f145f6c",
            download_sources = [
                JLLArtifactSource(
                    "https://github.com/JuliaBinaryWrappers/libLLVM_jll.jl/releases/download/libLLVM-v15.0.7+8/libLLVM.v15.0.7.armv6l-linux-musleabihf-cxx03-llvm_version+15.tar.gz",
                    "0dbd985dfe96c05124077b1770e0f70fa78e62e6bf877fb6e1d78f6536ad2ae2",
                ),
            ],
            products = [
                JLLLibraryProduct(
                    :libllvm,
                    "lib/libLLVM-15jl.so",
                    [
                        JLLLibraryDep(:Zlib_jll, :libz),
                    ],
                    flags = [:RTLD_LAZY, :RTLD_DEEPBIND],
                ),
                JLLExecutableProduct(
                    :llvm_config,
                    "tools/llvm-config",
                ),
            ]
        ),

        JLLArtifactInfo(;
            src_version = v"15.0.7+8",
            deps = [
                JLLPackageDependency(
                    "Zlib_jll",
                    Base.UUID("83775a58-1f1d-513f-b197-d71354ab007a"),
                    "*",
                ),
                JLLPackageDependency(
                    "TOML",
                    Base.UUID("fa267f1f-6049-4f14-aa54-33bafae1ed76"),
                    "*",
                ),
            ],
            sources = [],
            platform = Platform("armv6l", "linux"; cxxstring_abi = "cxx03", call_abi = "eabihf", libc = "musl", llvm_version = "15.asserts"),
            name = "default",
            treehash = "b5b56e149c8a94859bf3cfd981d056497f5be8cd",
            download_sources = [
                JLLArtifactSource(
                    "https://github.com/JuliaBinaryWrappers/libLLVM_jll.jl/releases/download/libLLVM-v15.0.7+8/libLLVM.v15.0.7.armv6l-linux-musleabihf-cxx03-llvm_version+15.asserts.tar.gz",
                    "54706285d0cc724b60558720df3be863c76f076c983647858d9df94050f3861c",
                ),
            ],
            products = [
                JLLLibraryProduct(
                    :libllvm,
                    "lib/libLLVM-15jl.so",
                    [
                        JLLLibraryDep(:Zlib_jll, :libz),
                    ],
                    flags = [:RTLD_LAZY, :RTLD_DEEPBIND],
                ),
                JLLExecutableProduct(
                    :llvm_config,
                    "tools/llvm-config",
                ),
            ]
        ),

        JLLArtifactInfo(;
            src_version = v"15.0.7+8",
            deps = [
                JLLPackageDependency(
                    "Zlib_jll",
                    Base.UUID("83775a58-1f1d-513f-b197-d71354ab007a"),
                    "*",
                ),
                JLLPackageDependency(
                    "TOML",
                    Base.UUID("fa267f1f-6049-4f14-aa54-33bafae1ed76"),
                    "*",
                ),
            ],
            sources = [],
            platform = Platform("armv6l", "linux"; cxxstring_abi = "cxx11", call_abi = "eabihf", libc = "musl", llvm_version = "15"),
            name = "default",
            treehash = "d5234fd49623eb661c972129853e91196783f971",
            download_sources = [
                JLLArtifactSource(
                    "https://github.com/JuliaBinaryWrappers/libLLVM_jll.jl/releases/download/libLLVM-v15.0.7+8/libLLVM.v15.0.7.armv6l-linux-musleabihf-cxx11-llvm_version+15.tar.gz",
                    "2bbb82a757551016eccc4f9ff5f0102b0f2a59067e84f7afdfc568ca78108b3c",
                ),
            ],
            products = [
                JLLLibraryProduct(
                    :libllvm,
                    "lib/libLLVM-15jl.so",
                    [
                        JLLLibraryDep(:Zlib_jll, :libz),
                    ],
                    flags = [:RTLD_LAZY, :RTLD_DEEPBIND],
                ),
                JLLExecutableProduct(
                    :llvm_config,
                    "tools/llvm-config",
                ),
            ]
        ),

        JLLArtifactInfo(;
            src_version = v"15.0.7+8",
            deps = [
                JLLPackageDependency(
                    "Zlib_jll",
                    Base.UUID("83775a58-1f1d-513f-b197-d71354ab007a"),
                    "*",
                ),
                JLLPackageDependency(
                    "TOML",
                    Base.UUID("fa267f1f-6049-4f14-aa54-33bafae1ed76"),
                    "*",
                ),
            ],
            sources = [],
            platform = Platform("armv6l", "linux"; cxxstring_abi = "cxx11", call_abi = "eabihf", libc = "musl", llvm_version = "15.asserts"),
            name = "default",
            treehash = "ab50439d8683b42dfc6c117525a5b1e2191f4882",
            download_sources = [
                JLLArtifactSource(
                    "https://github.com/JuliaBinaryWrappers/libLLVM_jll.jl/releases/download/libLLVM-v15.0.7+8/libLLVM.v15.0.7.armv6l-linux-musleabihf-cxx11-llvm_version+15.asserts.tar.gz",
                    "4102d24adb4afac08b70a1a6b88e0cb1c29c182c1f8c18d34556bc14e831fca8",
                ),
            ],
            products = [
                JLLLibraryProduct(
                    :libllvm,
                    "lib/libLLVM-15jl.so",
                    [
                        JLLLibraryDep(:Zlib_jll, :libz),
                    ],
                    flags = [:RTLD_LAZY, :RTLD_DEEPBIND],
                ),
                JLLExecutableProduct(
                    :llvm_config,
                    "tools/llvm-config",
                ),
            ]
        ),

        JLLArtifactInfo(;
            src_version = v"15.0.7+8",
            deps = [
                JLLPackageDependency(
                    "Zlib_jll",
                    Base.UUID("83775a58-1f1d-513f-b197-d71354ab007a"),
                    "*",
                ),
                JLLPackageDependency(
                    "TOML",
                    Base.UUID("fa267f1f-6049-4f14-aa54-33bafae1ed76"),
                    "*",
                ),
            ],
            sources = [],
            platform = Platform("armv7l", "linux"; cxxstring_abi = "cxx03", call_abi = "eabihf", libc = "glibc", llvm_version = "15"),
            name = "default",
            treehash = "2f901e4a0f0fc7c8bc4f6768635439af5143ade0",
            download_sources = [
                JLLArtifactSource(
                    "https://github.com/JuliaBinaryWrappers/libLLVM_jll.jl/releases/download/libLLVM-v15.0.7+8/libLLVM.v15.0.7.armv7l-linux-gnueabihf-cxx03-llvm_version+15.tar.gz",
                    "c91a5a5ee5210214885063e93b8d2fe80921b88c917783a7485bdd2681943e83",
                ),
            ],
            products = [
                JLLLibraryProduct(
                    :libllvm,
                    "lib/libLLVM-15jl.so",
                    [
                        JLLLibraryDep(:Zlib_jll, :libz),
                    ],
                    flags = [:RTLD_LAZY, :RTLD_DEEPBIND],
                ),
                JLLExecutableProduct(
                    :llvm_config,
                    "tools/llvm-config",
                ),
            ]
        ),

        JLLArtifactInfo(;
            src_version = v"15.0.7+8",
            deps = [
                JLLPackageDependency(
                    "Zlib_jll",
                    Base.UUID("83775a58-1f1d-513f-b197-d71354ab007a"),
                    "*",
                ),
                JLLPackageDependency(
                    "TOML",
                    Base.UUID("fa267f1f-6049-4f14-aa54-33bafae1ed76"),
                    "*",
                ),
            ],
            sources = [],
            platform = Platform("armv7l", "linux"; cxxstring_abi = "cxx03", call_abi = "eabihf", libc = "glibc", llvm_version = "15.asserts"),
            name = "default",
            treehash = "efa315ee53fe9aa63ca41ad517771602e156128f",
            download_sources = [
                JLLArtifactSource(
                    "https://github.com/JuliaBinaryWrappers/libLLVM_jll.jl/releases/download/libLLVM-v15.0.7+8/libLLVM.v15.0.7.armv7l-linux-gnueabihf-cxx03-llvm_version+15.asserts.tar.gz",
                    "7fa8c4397167d48650279ec116e3fe2b685c32eed8f22fa5efd69445578cd2e6",
                ),
            ],
            products = [
                JLLLibraryProduct(
                    :libllvm,
                    "lib/libLLVM-15jl.so",
                    [
                        JLLLibraryDep(:Zlib_jll, :libz),
                    ],
                    flags = [:RTLD_LAZY, :RTLD_DEEPBIND],
                ),
                JLLExecutableProduct(
                    :llvm_config,
                    "tools/llvm-config",
                ),
            ]
        ),

        JLLArtifactInfo(;
            src_version = v"15.0.7+8",
            deps = [
                JLLPackageDependency(
                    "Zlib_jll",
                    Base.UUID("83775a58-1f1d-513f-b197-d71354ab007a"),
                    "*",
                ),
                JLLPackageDependency(
                    "TOML",
                    Base.UUID("fa267f1f-6049-4f14-aa54-33bafae1ed76"),
                    "*",
                ),
            ],
            sources = [],
            platform = Platform("armv7l", "linux"; cxxstring_abi = "cxx11", call_abi = "eabihf", libc = "glibc", llvm_version = "15"),
            name = "default",
            treehash = "f6c956631463e2f86230019e16159c7b8ccdf83e",
            download_sources = [
                JLLArtifactSource(
                    "https://github.com/JuliaBinaryWrappers/libLLVM_jll.jl/releases/download/libLLVM-v15.0.7+8/libLLVM.v15.0.7.armv7l-linux-gnueabihf-cxx11-llvm_version+15.tar.gz",
                    "7749192eccb49139636a1156d8fb1e82867217830d1bc5efdeb2fdb060761e12",
                ),
            ],
            products = [
                JLLLibraryProduct(
                    :libllvm,
                    "lib/libLLVM-15jl.so",
                    [
                        JLLLibraryDep(:Zlib_jll, :libz),
                    ],
                    flags = [:RTLD_LAZY, :RTLD_DEEPBIND],
                ),
                JLLExecutableProduct(
                    :llvm_config,
                    "tools/llvm-config",
                ),
            ]
        ),

        JLLArtifactInfo(;
            src_version = v"15.0.7+8",
            deps = [
                JLLPackageDependency(
                    "Zlib_jll",
                    Base.UUID("83775a58-1f1d-513f-b197-d71354ab007a"),
                    "*",
                ),
                JLLPackageDependency(
                    "TOML",
                    Base.UUID("fa267f1f-6049-4f14-aa54-33bafae1ed76"),
                    "*",
                ),
            ],
            sources = [],
            platform = Platform("armv7l", "linux"; cxxstring_abi = "cxx11", call_abi = "eabihf", libc = "glibc", llvm_version = "15.asserts"),
            name = "default",
            treehash = "f6c8af4ec810b6e49074207e4b899590e7fda9eb",
            download_sources = [
                JLLArtifactSource(
                    "https://github.com/JuliaBinaryWrappers/libLLVM_jll.jl/releases/download/libLLVM-v15.0.7+8/libLLVM.v15.0.7.armv7l-linux-gnueabihf-cxx11-llvm_version+15.asserts.tar.gz",
                    "304652da82e3cf6ae99325ae3ff2d19fa2795a3152eceba43e36fa7a4f81b331",
                ),
            ],
            products = [
                JLLLibraryProduct(
                    :libllvm,
                    "lib/libLLVM-15jl.so",
                    [
                        JLLLibraryDep(:Zlib_jll, :libz),
                    ],
                    flags = [:RTLD_LAZY, :RTLD_DEEPBIND],
                ),
                JLLExecutableProduct(
                    :llvm_config,
                    "tools/llvm-config",
                ),
            ]
        ),

        JLLArtifactInfo(;
            src_version = v"15.0.7+8",
            deps = [
                JLLPackageDependency(
                    "Zlib_jll",
                    Base.UUID("83775a58-1f1d-513f-b197-d71354ab007a"),
                    "*",
                ),
                JLLPackageDependency(
                    "TOML",
                    Base.UUID("fa267f1f-6049-4f14-aa54-33bafae1ed76"),
                    "*",
                ),
            ],
            sources = [],
            platform = Platform("armv7l", "linux"; cxxstring_abi = "cxx03", call_abi = "eabihf", libc = "musl", llvm_version = "15"),
            name = "default",
            treehash = "5be9fcfaf13dcd572328ba8aaa830325b8116197",
            download_sources = [
                JLLArtifactSource(
                    "https://github.com/JuliaBinaryWrappers/libLLVM_jll.jl/releases/download/libLLVM-v15.0.7+8/libLLVM.v15.0.7.armv7l-linux-musleabihf-cxx03-llvm_version+15.tar.gz",
                    "c61a11ac3481c1e6ca280ebe23e03e0cd6325676d6b71f9d8b6e06a0ad576515",
                ),
            ],
            products = [
                JLLLibraryProduct(
                    :libllvm,
                    "lib/libLLVM-15jl.so",
                    [
                        JLLLibraryDep(:Zlib_jll, :libz),
                    ],
                    flags = [:RTLD_LAZY, :RTLD_DEEPBIND],
                ),
                JLLExecutableProduct(
                    :llvm_config,
                    "tools/llvm-config",
                ),
            ]
        ),

        JLLArtifactInfo(;
            src_version = v"15.0.7+8",
            deps = [
                JLLPackageDependency(
                    "Zlib_jll",
                    Base.UUID("83775a58-1f1d-513f-b197-d71354ab007a"),
                    "*",
                ),
                JLLPackageDependency(
                    "TOML",
                    Base.UUID("fa267f1f-6049-4f14-aa54-33bafae1ed76"),
                    "*",
                ),
            ],
            sources = [],
            platform = Platform("armv7l", "linux"; cxxstring_abi = "cxx03", call_abi = "eabihf", libc = "musl", llvm_version = "15.asserts"),
            name = "default",
            treehash = "50c3c84f188b2fc132cb0c6af3c0360c7ff68044",
            download_sources = [
                JLLArtifactSource(
                    "https://github.com/JuliaBinaryWrappers/libLLVM_jll.jl/releases/download/libLLVM-v15.0.7+8/libLLVM.v15.0.7.armv7l-linux-musleabihf-cxx03-llvm_version+15.asserts.tar.gz",
                    "733424141ef42a0e55ade4edc28ebd9a7ced2abaa9ea8134bed35a25ed89fc1c",
                ),
            ],
            products = [
                JLLLibraryProduct(
                    :libllvm,
                    "lib/libLLVM-15jl.so",
                    [
                        JLLLibraryDep(:Zlib_jll, :libz),
                    ],
                    flags = [:RTLD_LAZY, :RTLD_DEEPBIND],
                ),
                JLLExecutableProduct(
                    :llvm_config,
                    "tools/llvm-config",
                ),
            ]
        ),

        JLLArtifactInfo(;
            src_version = v"15.0.7+8",
            deps = [
                JLLPackageDependency(
                    "Zlib_jll",
                    Base.UUID("83775a58-1f1d-513f-b197-d71354ab007a"),
                    "*",
                ),
                JLLPackageDependency(
                    "TOML",
                    Base.UUID("fa267f1f-6049-4f14-aa54-33bafae1ed76"),
                    "*",
                ),
            ],
            sources = [],
            platform = Platform("armv7l", "linux"; cxxstring_abi = "cxx11", call_abi = "eabihf", libc = "musl", llvm_version = "15"),
            name = "default",
            treehash = "0815696ec063b57b240e43b3035011e3e31638a4",
            download_sources = [
                JLLArtifactSource(
                    "https://github.com/JuliaBinaryWrappers/libLLVM_jll.jl/releases/download/libLLVM-v15.0.7+8/libLLVM.v15.0.7.armv7l-linux-musleabihf-cxx11-llvm_version+15.tar.gz",
                    "2f8198d8f8914c991eea76b553621d1754c6168f19dda2cde18403d1598e5523",
                ),
            ],
            products = [
                JLLLibraryProduct(
                    :libllvm,
                    "lib/libLLVM-15jl.so",
                    [
                        JLLLibraryDep(:Zlib_jll, :libz),
                    ],
                    flags = [:RTLD_LAZY, :RTLD_DEEPBIND],
                ),
                JLLExecutableProduct(
                    :llvm_config,
                    "tools/llvm-config",
                ),
            ]
        ),

        JLLArtifactInfo(;
            src_version = v"15.0.7+8",
            deps = [
                JLLPackageDependency(
                    "Zlib_jll",
                    Base.UUID("83775a58-1f1d-513f-b197-d71354ab007a"),
                    "*",
                ),
                JLLPackageDependency(
                    "TOML",
                    Base.UUID("fa267f1f-6049-4f14-aa54-33bafae1ed76"),
                    "*",
                ),
            ],
            sources = [],
            platform = Platform("armv7l", "linux"; cxxstring_abi = "cxx11", call_abi = "eabihf", libc = "musl", llvm_version = "15.asserts"),
            name = "default",
            treehash = "cb41396133647f298673ab7dcdb7aa9ed7618be8",
            download_sources = [
                JLLArtifactSource(
                    "https://github.com/JuliaBinaryWrappers/libLLVM_jll.jl/releases/download/libLLVM-v15.0.7+8/libLLVM.v15.0.7.armv7l-linux-musleabihf-cxx11-llvm_version+15.asserts.tar.gz",
                    "2732800820a6711efa8c2d078d065d87ca2f9abfc961aa2e170dcec30a3afcbb",
                ),
            ],
            products = [
                JLLLibraryProduct(
                    :libllvm,
                    "lib/libLLVM-15jl.so",
                    [
                        JLLLibraryDep(:Zlib_jll, :libz),
                    ],
                    flags = [:RTLD_LAZY, :RTLD_DEEPBIND],
                ),
                JLLExecutableProduct(
                    :llvm_config,
                    "tools/llvm-config",
                ),
            ]
        ),

        JLLArtifactInfo(;
            src_version = v"15.0.7+8",
            deps = [
                JLLPackageDependency(
                    "Zlib_jll",
                    Base.UUID("83775a58-1f1d-513f-b197-d71354ab007a"),
                    "*",
                ),
                JLLPackageDependency(
                    "TOML",
                    Base.UUID("fa267f1f-6049-4f14-aa54-33bafae1ed76"),
                    "*",
                ),
            ],
            sources = [],
            platform = Platform("i686", "linux"; cxxstring_abi = "cxx03", libc = "glibc", llvm_version = "15"),
            name = "default",
            treehash = "72cdc10dc360d1fe0836ed251bdb98300e0cdce0",
            download_sources = [
                JLLArtifactSource(
                    "https://github.com/JuliaBinaryWrappers/libLLVM_jll.jl/releases/download/libLLVM-v15.0.7+8/libLLVM.v15.0.7.i686-linux-gnu-cxx03-llvm_version+15.tar.gz",
                    "a8551c3268bc9936bebaec5ce3931ff9501b72d99704669afcee660866501f7e",
                ),
            ],
            products = [
                JLLLibraryProduct(
                    :libllvm,
                    "lib/libLLVM-15jl.so",
                    [
                        JLLLibraryDep(:Zlib_jll, :libz),
                    ],
                    flags = [:RTLD_LAZY, :RTLD_DEEPBIND],
                ),
                JLLExecutableProduct(
                    :llvm_config,
                    "tools/llvm-config",
                ),
            ]
        ),

        JLLArtifactInfo(;
            src_version = v"15.0.7+8",
            deps = [
                JLLPackageDependency(
                    "Zlib_jll",
                    Base.UUID("83775a58-1f1d-513f-b197-d71354ab007a"),
                    "*",
                ),
                JLLPackageDependency(
                    "TOML",
                    Base.UUID("fa267f1f-6049-4f14-aa54-33bafae1ed76"),
                    "*",
                ),
            ],
            sources = [],
            platform = Platform("i686", "linux"; cxxstring_abi = "cxx03", libc = "glibc", llvm_version = "15.asserts"),
            name = "default",
            treehash = "6d7b9554164c9fc562d23284f9d4b606178c3292",
            download_sources = [
                JLLArtifactSource(
                    "https://github.com/JuliaBinaryWrappers/libLLVM_jll.jl/releases/download/libLLVM-v15.0.7+8/libLLVM.v15.0.7.i686-linux-gnu-cxx03-llvm_version+15.asserts.tar.gz",
                    "0a78b402e20b7aed3e10e3592de73cb918a45c5666374a30b6745e852d12d276",
                ),
            ],
            products = [
                JLLLibraryProduct(
                    :libllvm,
                    "lib/libLLVM-15jl.so",
                    [
                        JLLLibraryDep(:Zlib_jll, :libz),
                    ],
                    flags = [:RTLD_LAZY, :RTLD_DEEPBIND],
                ),
                JLLExecutableProduct(
                    :llvm_config,
                    "tools/llvm-config",
                ),
            ]
        ),

        JLLArtifactInfo(;
            src_version = v"15.0.7+8",
            deps = [
                JLLPackageDependency(
                    "Zlib_jll",
                    Base.UUID("83775a58-1f1d-513f-b197-d71354ab007a"),
                    "*",
                ),
                JLLPackageDependency(
                    "TOML",
                    Base.UUID("fa267f1f-6049-4f14-aa54-33bafae1ed76"),
                    "*",
                ),
            ],
            sources = [],
            platform = Platform("i686", "linux"; cxxstring_abi = "cxx11", libc = "glibc", llvm_version = "15"),
            name = "default",
            treehash = "bf3241ce878b68c573280020191fb1bfe3f27923",
            download_sources = [
                JLLArtifactSource(
                    "https://github.com/JuliaBinaryWrappers/libLLVM_jll.jl/releases/download/libLLVM-v15.0.7+8/libLLVM.v15.0.7.i686-linux-gnu-cxx11-llvm_version+15.tar.gz",
                    "59aa1929838ec9775ea8e62c2101832218c46e9db82c6c7c653d1b6e33b28c20",
                ),
            ],
            products = [
                JLLLibraryProduct(
                    :libllvm,
                    "lib/libLLVM-15jl.so",
                    [
                        JLLLibraryDep(:Zlib_jll, :libz),
                    ],
                    flags = [:RTLD_LAZY, :RTLD_DEEPBIND],
                ),
                JLLExecutableProduct(
                    :llvm_config,
                    "tools/llvm-config",
                ),
            ]
        ),

        JLLArtifactInfo(;
            src_version = v"15.0.7+8",
            deps = [
                JLLPackageDependency(
                    "Zlib_jll",
                    Base.UUID("83775a58-1f1d-513f-b197-d71354ab007a"),
                    "*",
                ),
                JLLPackageDependency(
                    "TOML",
                    Base.UUID("fa267f1f-6049-4f14-aa54-33bafae1ed76"),
                    "*",
                ),
            ],
            sources = [],
            platform = Platform("i686", "linux"; cxxstring_abi = "cxx11", libc = "glibc", llvm_version = "15.asserts"),
            name = "default",
            treehash = "f7f51809bd78f9fff4d6be967b2ccee8f5899481",
            download_sources = [
                JLLArtifactSource(
                    "https://github.com/JuliaBinaryWrappers/libLLVM_jll.jl/releases/download/libLLVM-v15.0.7+8/libLLVM.v15.0.7.i686-linux-gnu-cxx11-llvm_version+15.asserts.tar.gz",
                    "d7c7030bcf0fe914d8d2f0582b8372e83eb4e8b0a37b33182f088e41e63c18f0",
                ),
            ],
            products = [
                JLLLibraryProduct(
                    :libllvm,
                    "lib/libLLVM-15jl.so",
                    [
                        JLLLibraryDep(:Zlib_jll, :libz),
                    ],
                    flags = [:RTLD_LAZY, :RTLD_DEEPBIND],
                ),
                JLLExecutableProduct(
                    :llvm_config,
                    "tools/llvm-config",
                ),
            ]
        ),

        JLLArtifactInfo(;
            src_version = v"15.0.7+8",
            deps = [
                JLLPackageDependency(
                    "Zlib_jll",
                    Base.UUID("83775a58-1f1d-513f-b197-d71354ab007a"),
                    "*",
                ),
                JLLPackageDependency(
                    "TOML",
                    Base.UUID("fa267f1f-6049-4f14-aa54-33bafae1ed76"),
                    "*",
                ),
            ],
            sources = [],
            platform = Platform("i686", "windows"; cxxstring_abi = "cxx03", llvm_version = "15"),
            name = "default",
            treehash = "55364f774681a5378c2f8e788b6b0b270c2119de",
            download_sources = [
                JLLArtifactSource(
                    "https://github.com/JuliaBinaryWrappers/libLLVM_jll.jl/releases/download/libLLVM-v15.0.7+8/libLLVM.v15.0.7.i686-w64-mingw32-cxx03-llvm_version+15.tar.gz",
                    "9ff0b37311252de7b7f7af68d28a08e1c61fb1edc3c310a0981c5ade5faa47c3",
                ),
            ],
            products = [
                JLLLibraryProduct(
                    :libllvm,
                    "bin\\libLLVM-15jl.dll",
                    [
                        JLLLibraryDep(:Zlib_jll, :libz),
                    ],
                    flags = [:RTLD_LAZY, :RTLD_DEEPBIND],
                ),
                JLLExecutableProduct(
                    :llvm_config,
                    "tools\\llvm-config.exe",
                ),
            ]
        ),

        JLLArtifactInfo(;
            src_version = v"15.0.7+8",
            deps = [
                JLLPackageDependency(
                    "Zlib_jll",
                    Base.UUID("83775a58-1f1d-513f-b197-d71354ab007a"),
                    "*",
                ),
                JLLPackageDependency(
                    "TOML",
                    Base.UUID("fa267f1f-6049-4f14-aa54-33bafae1ed76"),
                    "*",
                ),
            ],
            sources = [],
            platform = Platform("i686", "windows"; cxxstring_abi = "cxx03", llvm_version = "15.asserts"),
            name = "default",
            treehash = "a91cbbb51007e4376b4fa91dbc83c99ee7e78561",
            download_sources = [
                JLLArtifactSource(
                    "https://github.com/JuliaBinaryWrappers/libLLVM_jll.jl/releases/download/libLLVM-v15.0.7+8/libLLVM.v15.0.7.i686-w64-mingw32-cxx03-llvm_version+15.asserts.tar.gz",
                    "8dfdff4b8a792bacd6e2b717c39fe0ade80581b988eaa274879428dfb43b237b",
                ),
            ],
            products = [
                JLLLibraryProduct(
                    :libllvm,
                    "bin\\libLLVM-15jl.dll",
                    [
                        JLLLibraryDep(:Zlib_jll, :libz),
                    ],
                    flags = [:RTLD_LAZY, :RTLD_DEEPBIND],
                ),
                JLLExecutableProduct(
                    :llvm_config,
                    "tools\\llvm-config.exe",
                ),
            ]
        ),

        JLLArtifactInfo(;
            src_version = v"15.0.7+8",
            deps = [
                JLLPackageDependency(
                    "Zlib_jll",
                    Base.UUID("83775a58-1f1d-513f-b197-d71354ab007a"),
                    "*",
                ),
                JLLPackageDependency(
                    "TOML",
                    Base.UUID("fa267f1f-6049-4f14-aa54-33bafae1ed76"),
                    "*",
                ),
            ],
            sources = [],
            platform = Platform("i686", "windows"; cxxstring_abi = "cxx11", llvm_version = "15"),
            name = "default",
            treehash = "1afcf5eff81efd9c5650c37de74de283d96a4939",
            download_sources = [
                JLLArtifactSource(
                    "https://github.com/JuliaBinaryWrappers/libLLVM_jll.jl/releases/download/libLLVM-v15.0.7+8/libLLVM.v15.0.7.i686-w64-mingw32-cxx11-llvm_version+15.tar.gz",
                    "c1d586eb20fed37f858a0c39d42fa3ed382bd5e56a1e02ac7f4a5a1a7e45c96d",
                ),
            ],
            products = [
                JLLLibraryProduct(
                    :libllvm,
                    "bin\\libLLVM-15jl.dll",
                    [
                        JLLLibraryDep(:Zlib_jll, :libz),
                    ],
                    flags = [:RTLD_LAZY, :RTLD_DEEPBIND],
                ),
                JLLExecutableProduct(
                    :llvm_config,
                    "tools\\llvm-config.exe",
                ),
            ]
        ),

        JLLArtifactInfo(;
            src_version = v"15.0.7+8",
            deps = [
                JLLPackageDependency(
                    "Zlib_jll",
                    Base.UUID("83775a58-1f1d-513f-b197-d71354ab007a"),
                    "*",
                ),
                JLLPackageDependency(
                    "TOML",
                    Base.UUID("fa267f1f-6049-4f14-aa54-33bafae1ed76"),
                    "*",
                ),
            ],
            sources = [],
            platform = Platform("i686", "windows"; cxxstring_abi = "cxx11", llvm_version = "15.asserts"),
            name = "default",
            treehash = "d976d627a3060c42bd2523958dd3eb1904eeee69",
            download_sources = [
                JLLArtifactSource(
                    "https://github.com/JuliaBinaryWrappers/libLLVM_jll.jl/releases/download/libLLVM-v15.0.7+8/libLLVM.v15.0.7.i686-w64-mingw32-cxx11-llvm_version+15.asserts.tar.gz",
                    "9918eecb8a2c1fc799d9c9aa7799084d63a1774ea4ceb89946d520e45dafc729",
                ),
            ],
            products = [
                JLLLibraryProduct(
                    :libllvm,
                    "bin\\libLLVM-15jl.dll",
                    [
                        JLLLibraryDep(:Zlib_jll, :libz),
                    ],
                    flags = [:RTLD_LAZY, :RTLD_DEEPBIND],
                ),
                JLLExecutableProduct(
                    :llvm_config,
                    "tools\\llvm-config.exe",
                ),
            ]
        ),

        JLLArtifactInfo(;
            src_version = v"15.0.7+8",
            deps = [
                JLLPackageDependency(
                    "Zlib_jll",
                    Base.UUID("83775a58-1f1d-513f-b197-d71354ab007a"),
                    "*",
                ),
                JLLPackageDependency(
                    "TOML",
                    Base.UUID("fa267f1f-6049-4f14-aa54-33bafae1ed76"),
                    "*",
                ),
            ],
            sources = [],
            platform = Platform("powerpc64le", "linux"; cxxstring_abi = "cxx03", libc = "glibc", llvm_version = "15"),
            name = "default",
            treehash = "fd6077017814993a78260e11df1c0c435e2afb61",
            download_sources = [
                JLLArtifactSource(
                    "https://github.com/JuliaBinaryWrappers/libLLVM_jll.jl/releases/download/libLLVM-v15.0.7+8/libLLVM.v15.0.7.powerpc64le-linux-gnu-cxx03-llvm_version+15.tar.gz",
                    "92fd5356850cc0e6ee0f957dc746b5ba386394d6f5511c708bbea560c5c78c3a",
                ),
            ],
            products = [
                JLLLibraryProduct(
                    :libllvm,
                    "lib/libLLVM-15jl.so",
                    [
                        JLLLibraryDep(:Zlib_jll, :libz),
                    ],
                    flags = [:RTLD_LAZY, :RTLD_DEEPBIND],
                ),
                JLLExecutableProduct(
                    :llvm_config,
                    "tools/llvm-config",
                ),
            ]
        ),

        JLLArtifactInfo(;
            src_version = v"15.0.7+8",
            deps = [
                JLLPackageDependency(
                    "Zlib_jll",
                    Base.UUID("83775a58-1f1d-513f-b197-d71354ab007a"),
                    "*",
                ),
                JLLPackageDependency(
                    "TOML",
                    Base.UUID("fa267f1f-6049-4f14-aa54-33bafae1ed76"),
                    "*",
                ),
            ],
            sources = [],
            platform = Platform("powerpc64le", "linux"; cxxstring_abi = "cxx03", libc = "glibc", llvm_version = "15.asserts"),
            name = "default",
            treehash = "48ae1f7bb47445b3a7a2afdaa46340c4ef67eacd",
            download_sources = [
                JLLArtifactSource(
                    "https://github.com/JuliaBinaryWrappers/libLLVM_jll.jl/releases/download/libLLVM-v15.0.7+8/libLLVM.v15.0.7.powerpc64le-linux-gnu-cxx03-llvm_version+15.asserts.tar.gz",
                    "71e25028b99e16aeb9f382a076e194c101967cc37515a6bf9534a3a410235c96",
                ),
            ],
            products = [
                JLLLibraryProduct(
                    :libllvm,
                    "lib/libLLVM-15jl.so",
                    [
                        JLLLibraryDep(:Zlib_jll, :libz),
                    ],
                    flags = [:RTLD_LAZY, :RTLD_DEEPBIND],
                ),
                JLLExecutableProduct(
                    :llvm_config,
                    "tools/llvm-config",
                ),
            ]
        ),

        JLLArtifactInfo(;
            src_version = v"15.0.7+8",
            deps = [
                JLLPackageDependency(
                    "Zlib_jll",
                    Base.UUID("83775a58-1f1d-513f-b197-d71354ab007a"),
                    "*",
                ),
                JLLPackageDependency(
                    "TOML",
                    Base.UUID("fa267f1f-6049-4f14-aa54-33bafae1ed76"),
                    "*",
                ),
            ],
            sources = [],
            platform = Platform("powerpc64le", "linux"; cxxstring_abi = "cxx11", libc = "glibc", llvm_version = "15"),
            name = "default",
            treehash = "2e4603c76730df004cb7570428e69b24ba1ae61a",
            download_sources = [
                JLLArtifactSource(
                    "https://github.com/JuliaBinaryWrappers/libLLVM_jll.jl/releases/download/libLLVM-v15.0.7+8/libLLVM.v15.0.7.powerpc64le-linux-gnu-cxx11-llvm_version+15.tar.gz",
                    "6b9f891ef7e2f3a543211192e17e9b4807e53a7d3253479b2cc6a956e111c5b0",
                ),
            ],
            products = [
                JLLLibraryProduct(
                    :libllvm,
                    "lib/libLLVM-15jl.so",
                    [
                        JLLLibraryDep(:Zlib_jll, :libz),
                    ],
                    flags = [:RTLD_LAZY, :RTLD_DEEPBIND],
                ),
                JLLExecutableProduct(
                    :llvm_config,
                    "tools/llvm-config",
                ),
            ]
        ),

        JLLArtifactInfo(;
            src_version = v"15.0.7+8",
            deps = [
                JLLPackageDependency(
                    "Zlib_jll",
                    Base.UUID("83775a58-1f1d-513f-b197-d71354ab007a"),
                    "*",
                ),
                JLLPackageDependency(
                    "TOML",
                    Base.UUID("fa267f1f-6049-4f14-aa54-33bafae1ed76"),
                    "*",
                ),
            ],
            sources = [],
            platform = Platform("powerpc64le", "linux"; cxxstring_abi = "cxx11", libc = "glibc", llvm_version = "15.asserts"),
            name = "default",
            treehash = "5fdae5bb95e83dc7e14f53ef07a45e877aeb8ebf",
            download_sources = [
                JLLArtifactSource(
                    "https://github.com/JuliaBinaryWrappers/libLLVM_jll.jl/releases/download/libLLVM-v15.0.7+8/libLLVM.v15.0.7.powerpc64le-linux-gnu-cxx11-llvm_version+15.asserts.tar.gz",
                    "ad49aa75cdbeaeb3377ce163378f9f726b803ece74e3a96fd9a9630f69a0e1ba",
                ),
            ],
            products = [
                JLLLibraryProduct(
                    :libllvm,
                    "lib/libLLVM-15jl.so",
                    [
                        JLLLibraryDep(:Zlib_jll, :libz),
                    ],
                    flags = [:RTLD_LAZY, :RTLD_DEEPBIND],
                ),
                JLLExecutableProduct(
                    :llvm_config,
                    "tools/llvm-config",
                ),
            ]
        ),

        JLLArtifactInfo(;
            src_version = v"15.0.7+8",
            deps = [
                JLLPackageDependency(
                    "Zlib_jll",
                    Base.UUID("83775a58-1f1d-513f-b197-d71354ab007a"),
                    "*",
                ),
                JLLPackageDependency(
                    "TOML",
                    Base.UUID("fa267f1f-6049-4f14-aa54-33bafae1ed76"),
                    "*",
                ),
            ],
            sources = [],
            platform = Platform("x86_64", "macos"; llvm_version = "15"),
            name = "default",
            treehash = "822587194a18a1664a4fea63e7381311dde6da9e",
            download_sources = [
                JLLArtifactSource(
                    "https://github.com/JuliaBinaryWrappers/libLLVM_jll.jl/releases/download/libLLVM-v15.0.7+8/libLLVM.v15.0.7.x86_64-apple-darwin-llvm_version+15.tar.gz",
                    "44a78815f768090de8831cec8b9cbb409e7319d64987682f19941c4f2a083307",
                ),
            ],
            products = [
                JLLLibraryProduct(
                    :libllvm,
                    "lib/libLLVM.dylib",
                    [
                        JLLLibraryDep(:Zlib_jll, :libz),
                    ],
                    flags = [:RTLD_LAZY, :RTLD_DEEPBIND],
                ),
                JLLExecutableProduct(
                    :llvm_config,
                    "tools/llvm-config",
                ),
            ]
        ),

        JLLArtifactInfo(;
            src_version = v"15.0.7+8",
            deps = [
                JLLPackageDependency(
                    "Zlib_jll",
                    Base.UUID("83775a58-1f1d-513f-b197-d71354ab007a"),
                    "*",
                ),
                JLLPackageDependency(
                    "TOML",
                    Base.UUID("fa267f1f-6049-4f14-aa54-33bafae1ed76"),
                    "*",
                ),
            ],
            sources = [],
            platform = Platform("x86_64", "macos"; llvm_version = "15.asserts"),
            name = "default",
            treehash = "0a4bf23beea1e20748363a63a85539021be52ed4",
            download_sources = [
                JLLArtifactSource(
                    "https://github.com/JuliaBinaryWrappers/libLLVM_jll.jl/releases/download/libLLVM-v15.0.7+8/libLLVM.v15.0.7.x86_64-apple-darwin-llvm_version+15.asserts.tar.gz",
                    "b8165608c56aa7209d5d1d8d80c48fe7d980606c511c3efa4099a3db8af11073",
                ),
            ],
            products = [
                JLLLibraryProduct(
                    :libllvm,
                    "lib/libLLVM.dylib",
                    [
                        JLLLibraryDep(:Zlib_jll, :libz),
                    ],
                    flags = [:RTLD_LAZY, :RTLD_DEEPBIND],
                ),
                JLLExecutableProduct(
                    :llvm_config,
                    "tools/llvm-config",
                ),
            ]
        ),

        JLLArtifactInfo(;
            src_version = v"15.0.7+8",
            deps = [
                JLLPackageDependency(
                    "Zlib_jll",
                    Base.UUID("83775a58-1f1d-513f-b197-d71354ab007a"),
                    "*",
                ),
                JLLPackageDependency(
                    "TOML",
                    Base.UUID("fa267f1f-6049-4f14-aa54-33bafae1ed76"),
                    "*",
                ),
            ],
            sources = [],
            platform = Platform("x86_64", "linux"; cxxstring_abi = "cxx03", libc = "glibc", llvm_version = "15"),
            name = "default",
            treehash = "7aefd885c9a10d4f3b1e61b4a169513af863db76",
            download_sources = [
                JLLArtifactSource(
                    "https://github.com/JuliaBinaryWrappers/libLLVM_jll.jl/releases/download/libLLVM-v15.0.7+8/libLLVM.v15.0.7.x86_64-linux-gnu-cxx03-llvm_version+15.tar.gz",
                    "9f50b122fc32b67d80e703a21282612c77afc1d3983c5ebaf5304252d8200d5f",
                ),
            ],
            products = [
                JLLLibraryProduct(
                    :libllvm,
                    "lib/libLLVM-15jl.so",
                    [
                        JLLLibraryDep(:Zlib_jll, :libz),
                    ],
                    flags = [:RTLD_LAZY, :RTLD_DEEPBIND],
                ),
                JLLExecutableProduct(
                    :llvm_config,
                    "tools/llvm-config",
                ),
            ]
        ),

        JLLArtifactInfo(;
            src_version = v"15.0.7+8",
            deps = [
                JLLPackageDependency(
                    "Zlib_jll",
                    Base.UUID("83775a58-1f1d-513f-b197-d71354ab007a"),
                    "*",
                ),
                JLLPackageDependency(
                    "TOML",
                    Base.UUID("fa267f1f-6049-4f14-aa54-33bafae1ed76"),
                    "*",
                ),
            ],
            sources = [],
            platform = Platform("x86_64", "linux"; cxxstring_abi = "cxx03", libc = "glibc", llvm_version = "15.asserts"),
            name = "default",
            treehash = "e628a40953ef4aaae1eaa28897b8c03d8c66d97c",
            download_sources = [
                JLLArtifactSource(
                    "https://github.com/JuliaBinaryWrappers/libLLVM_jll.jl/releases/download/libLLVM-v15.0.7+8/libLLVM.v15.0.7.x86_64-linux-gnu-cxx03-llvm_version+15.asserts.tar.gz",
                    "37b01bfffacafdf846f6ea91993f813bc90d363ecf211b5df2009c35325eaee9",
                ),
            ],
            products = [
                JLLLibraryProduct(
                    :libllvm,
                    "lib/libLLVM-15jl.so",
                    [
                        JLLLibraryDep(:Zlib_jll, :libz),
                    ],
                    flags = [:RTLD_LAZY, :RTLD_DEEPBIND],
                ),
                JLLExecutableProduct(
                    :llvm_config,
                    "tools/llvm-config",
                ),
            ]
        ),

        JLLArtifactInfo(;
            src_version = v"15.0.7+8",
            deps = [
                JLLPackageDependency(
                    "Zlib_jll",
                    Base.UUID("83775a58-1f1d-513f-b197-d71354ab007a"),
                    "*",
                ),
                JLLPackageDependency(
                    "TOML",
                    Base.UUID("fa267f1f-6049-4f14-aa54-33bafae1ed76"),
                    "*",
                ),
            ],
            sources = [],
            platform = Platform("x86_64", "linux"; cxxstring_abi = "cxx11", libc = "glibc", llvm_version = "15"),
            name = "default",
            treehash = "ed7eb62cb0410cda7ddb562713cbebbba97617b2",
            download_sources = [
                JLLArtifactSource(
                    "https://github.com/JuliaBinaryWrappers/libLLVM_jll.jl/releases/download/libLLVM-v15.0.7+8/libLLVM.v15.0.7.x86_64-linux-gnu-cxx11-llvm_version+15.tar.gz",
                    "d842e2a320b46cacfe397b81dd93db164f2d5ace7b3ea20a83a5a5d435b7539e",
                ),
            ],
            products = [
                JLLLibraryProduct(
                    :libllvm,
                    "lib/libLLVM-15jl.so",
                    [
                        JLLLibraryDep(:Zlib_jll, :libz),
                    ],
                    flags = [:RTLD_LAZY, :RTLD_DEEPBIND],
                ),
                JLLExecutableProduct(
                    :llvm_config,
                    "tools/llvm-config",
                ),
            ]
        ),

        JLLArtifactInfo(;
            src_version = v"15.0.7+8",
            deps = [
                JLLPackageDependency(
                    "Zlib_jll",
                    Base.UUID("83775a58-1f1d-513f-b197-d71354ab007a"),
                    "*",
                ),
                JLLPackageDependency(
                    "TOML",
                    Base.UUID("fa267f1f-6049-4f14-aa54-33bafae1ed76"),
                    "*",
                ),
            ],
            sources = [],
            platform = Platform("x86_64", "linux"; llvm_version = "15", sanitize = "memory", libc = "glibc", cxxstring_abi = "cxx11"),
            name = "default",
            treehash = "ed7eb62cb0410cda7ddb562713cbebbba97617b2",
            download_sources = [
                JLLArtifactSource(
                    "https://github.com/JuliaBinaryWrappers/libLLVM_jll.jl/releases/download/libLLVM-v15.0.7+8/libLLVM.v15.0.7.x86_64-linux-gnu-cxx11-sanitize+memory-llvm_version+15.tar.gz",
                    "d842e2a320b46cacfe397b81dd93db164f2d5ace7b3ea20a83a5a5d435b7539e",
                ),
            ],
            products = [
                JLLLibraryProduct(
                    :libllvm,
                    "lib/libLLVM-15jl.so",
                    [
                        JLLLibraryDep(:Zlib_jll, :libz),
                    ],
                    flags = [:RTLD_LAZY, :RTLD_DEEPBIND],
                ),
                JLLExecutableProduct(
                    :llvm_config,
                    "tools/llvm-config",
                ),
            ]
        ),

        JLLArtifactInfo(;
            src_version = v"15.0.7+8",
            deps = [
                JLLPackageDependency(
                    "Zlib_jll",
                    Base.UUID("83775a58-1f1d-513f-b197-d71354ab007a"),
                    "*",
                ),
                JLLPackageDependency(
                    "TOML",
                    Base.UUID("fa267f1f-6049-4f14-aa54-33bafae1ed76"),
                    "*",
                ),
            ],
            sources = [],
            platform = Platform("x86_64", "linux"; cxxstring_abi = "cxx11", libc = "glibc", llvm_version = "15.asserts"),
            name = "default",
            treehash = "9f8f6174cc5830ef988184b19bc0470d761e943c",
            download_sources = [
                JLLArtifactSource(
                    "https://github.com/JuliaBinaryWrappers/libLLVM_jll.jl/releases/download/libLLVM-v15.0.7+8/libLLVM.v15.0.7.x86_64-linux-gnu-cxx11-llvm_version+15.asserts.tar.gz",
                    "9043fa323c1696557d59a1823e4e2546b69b773b1cf1e1ea0d666d440853b6c9",
                ),
            ],
            products = [
                JLLLibraryProduct(
                    :libllvm,
                    "lib/libLLVM-15jl.so",
                    [
                        JLLLibraryDep(:Zlib_jll, :libz),
                    ],
                    flags = [:RTLD_LAZY, :RTLD_DEEPBIND],
                ),
                JLLExecutableProduct(
                    :llvm_config,
                    "tools/llvm-config",
                ),
            ]
        ),

        JLLArtifactInfo(;
            src_version = v"15.0.7+8",
            deps = [
                JLLPackageDependency(
                    "Zlib_jll",
                    Base.UUID("83775a58-1f1d-513f-b197-d71354ab007a"),
                    "*",
                ),
                JLLPackageDependency(
                    "TOML",
                    Base.UUID("fa267f1f-6049-4f14-aa54-33bafae1ed76"),
                    "*",
                ),
            ],
            sources = [],
            platform = Platform("x86_64", "linux"; llvm_version = "15.asserts", sanitize = "memory", libc = "glibc", cxxstring_abi = "cxx11"),
            name = "default",
            treehash = "9f8f6174cc5830ef988184b19bc0470d761e943c",
            download_sources = [
                JLLArtifactSource(
                    "https://github.com/JuliaBinaryWrappers/libLLVM_jll.jl/releases/download/libLLVM-v15.0.7+8/libLLVM.v15.0.7.x86_64-linux-gnu-cxx11-sanitize+memory-llvm_version+15.asserts.tar.gz",
                    "9043fa323c1696557d59a1823e4e2546b69b773b1cf1e1ea0d666d440853b6c9",
                ),
            ],
            products = [
                JLLLibraryProduct(
                    :libllvm,
                    "lib/libLLVM-15jl.so",
                    [
                        JLLLibraryDep(:Zlib_jll, :libz),
                    ],
                    flags = [:RTLD_LAZY, :RTLD_DEEPBIND],
                ),
                JLLExecutableProduct(
                    :llvm_config,
                    "tools/llvm-config",
                ),
            ]
        ),

        JLLArtifactInfo(;
            src_version = v"15.0.7+8",
            deps = [
                JLLPackageDependency(
                    "Zlib_jll",
                    Base.UUID("83775a58-1f1d-513f-b197-d71354ab007a"),
                    "*",
                ),
                JLLPackageDependency(
                    "TOML",
                    Base.UUID("fa267f1f-6049-4f14-aa54-33bafae1ed76"),
                    "*",
                ),
            ],
            sources = [],
            platform = Platform("x86_64", "linux"; cxxstring_abi = "cxx03", libc = "musl", llvm_version = "15"),
            name = "default",
            treehash = "f5a9ce6123e4e182adb61a537d3cb38f2efe23b3",
            download_sources = [
                JLLArtifactSource(
                    "https://github.com/JuliaBinaryWrappers/libLLVM_jll.jl/releases/download/libLLVM-v15.0.7+8/libLLVM.v15.0.7.x86_64-linux-musl-cxx03-llvm_version+15.tar.gz",
                    "e544aa91089d51d66314c8c409ea1f4b5eb30671dc9c50c598ae80ff0559f279",
                ),
            ],
            products = [
                JLLLibraryProduct(
                    :libllvm,
                    "lib/libLLVM-15jl.so",
                    [
                        JLLLibraryDep(:Zlib_jll, :libz),
                    ],
                    flags = [:RTLD_LAZY, :RTLD_DEEPBIND],
                ),
                JLLExecutableProduct(
                    :llvm_config,
                    "tools/llvm-config",
                ),
            ]
        ),

        JLLArtifactInfo(;
            src_version = v"15.0.7+8",
            deps = [
                JLLPackageDependency(
                    "Zlib_jll",
                    Base.UUID("83775a58-1f1d-513f-b197-d71354ab007a"),
                    "*",
                ),
                JLLPackageDependency(
                    "TOML",
                    Base.UUID("fa267f1f-6049-4f14-aa54-33bafae1ed76"),
                    "*",
                ),
            ],
            sources = [],
            platform = Platform("x86_64", "linux"; cxxstring_abi = "cxx03", libc = "musl", llvm_version = "15.asserts"),
            name = "default",
            treehash = "895dd658dc0546d2d8074f3e31128d7f092b9295",
            download_sources = [
                JLLArtifactSource(
                    "https://github.com/JuliaBinaryWrappers/libLLVM_jll.jl/releases/download/libLLVM-v15.0.7+8/libLLVM.v15.0.7.x86_64-linux-musl-cxx03-llvm_version+15.asserts.tar.gz",
                    "bcd3e144ba9b5ac8d6762d0ce6eb78f927c56a8fb13c699f3e648006188f1ea6",
                ),
            ],
            products = [
                JLLLibraryProduct(
                    :libllvm,
                    "lib/libLLVM-15jl.so",
                    [
                        JLLLibraryDep(:Zlib_jll, :libz),
                    ],
                    flags = [:RTLD_LAZY, :RTLD_DEEPBIND],
                ),
                JLLExecutableProduct(
                    :llvm_config,
                    "tools/llvm-config",
                ),
            ]
        ),

        JLLArtifactInfo(;
            src_version = v"15.0.7+8",
            deps = [
                JLLPackageDependency(
                    "Zlib_jll",
                    Base.UUID("83775a58-1f1d-513f-b197-d71354ab007a"),
                    "*",
                ),
                JLLPackageDependency(
                    "TOML",
                    Base.UUID("fa267f1f-6049-4f14-aa54-33bafae1ed76"),
                    "*",
                ),
            ],
            sources = [],
            platform = Platform("x86_64", "linux"; cxxstring_abi = "cxx11", libc = "musl", llvm_version = "15"),
            name = "default",
            treehash = "9c5bd4f23e89c60e80e3aeef8907b4a41853d7c9",
            download_sources = [
                JLLArtifactSource(
                    "https://github.com/JuliaBinaryWrappers/libLLVM_jll.jl/releases/download/libLLVM-v15.0.7+8/libLLVM.v15.0.7.x86_64-linux-musl-cxx11-llvm_version+15.tar.gz",
                    "10b475e90f1d9525acd6e23c09dd2309e918b951badd141df7c445b0c4710d5a",
                ),
            ],
            products = [
                JLLLibraryProduct(
                    :libllvm,
                    "lib/libLLVM-15jl.so",
                    [
                        JLLLibraryDep(:Zlib_jll, :libz),
                    ],
                    flags = [:RTLD_LAZY, :RTLD_DEEPBIND],
                ),
                JLLExecutableProduct(
                    :llvm_config,
                    "tools/llvm-config",
                ),
            ]
        ),

        JLLArtifactInfo(;
            src_version = v"15.0.7+8",
            deps = [
                JLLPackageDependency(
                    "Zlib_jll",
                    Base.UUID("83775a58-1f1d-513f-b197-d71354ab007a"),
                    "*",
                ),
                JLLPackageDependency(
                    "TOML",
                    Base.UUID("fa267f1f-6049-4f14-aa54-33bafae1ed76"),
                    "*",
                ),
            ],
            sources = [],
            platform = Platform("x86_64", "linux"; cxxstring_abi = "cxx11", libc = "musl", llvm_version = "15.asserts"),
            name = "default",
            treehash = "36b219dda552e94acd9c6f1db103c6b3ff8918c5",
            download_sources = [
                JLLArtifactSource(
                    "https://github.com/JuliaBinaryWrappers/libLLVM_jll.jl/releases/download/libLLVM-v15.0.7+8/libLLVM.v15.0.7.x86_64-linux-musl-cxx11-llvm_version+15.asserts.tar.gz",
                    "988c742bcc9b7b6d683140bce8df63418e82019f6a7b24653c5e0498490ef3fb",
                ),
            ],
            products = [
                JLLLibraryProduct(
                    :libllvm,
                    "lib/libLLVM-15jl.so",
                    [
                        JLLLibraryDep(:Zlib_jll, :libz),
                    ],
                    flags = [:RTLD_LAZY, :RTLD_DEEPBIND],
                ),
                JLLExecutableProduct(
                    :llvm_config,
                    "tools/llvm-config",
                ),
            ]
        ),

        JLLArtifactInfo(;
            src_version = v"15.0.7+8",
            deps = [
                JLLPackageDependency(
                    "Zlib_jll",
                    Base.UUID("83775a58-1f1d-513f-b197-d71354ab007a"),
                    "*",
                ),
                JLLPackageDependency(
                    "TOML",
                    Base.UUID("fa267f1f-6049-4f14-aa54-33bafae1ed76"),
                    "*",
                ),
            ],
            sources = [],
            platform = Platform("x86_64", "freebsd"; llvm_version = "15"),
            name = "default",
            treehash = "e8e4629c84e60d5333cbb10abab8e773fca7a1de",
            download_sources = [
                JLLArtifactSource(
                    "https://github.com/JuliaBinaryWrappers/libLLVM_jll.jl/releases/download/libLLVM-v15.0.7+8/libLLVM.v15.0.7.x86_64-unknown-freebsd-llvm_version+15.tar.gz",
                    "0a0f421fb110dfee8a25ed6214be1649ac41dffa30fb8fbcac9d29ccaecc367d",
                ),
            ],
            products = [
                JLLLibraryProduct(
                    :libllvm,
                    "lib/libLLVM-15jl.so",
                    [
                        JLLLibraryDep(:Zlib_jll, :libz),
                    ],
                    flags = [:RTLD_LAZY, :RTLD_DEEPBIND],
                ),
                JLLExecutableProduct(
                    :llvm_config,
                    "tools/llvm-config",
                ),
            ]
        ),

        JLLArtifactInfo(;
            src_version = v"15.0.7+8",
            deps = [
                JLLPackageDependency(
                    "Zlib_jll",
                    Base.UUID("83775a58-1f1d-513f-b197-d71354ab007a"),
                    "*",
                ),
                JLLPackageDependency(
                    "TOML",
                    Base.UUID("fa267f1f-6049-4f14-aa54-33bafae1ed76"),
                    "*",
                ),
            ],
            sources = [],
            platform = Platform("x86_64", "freebsd"; llvm_version = "15.asserts"),
            name = "default",
            treehash = "9e4ef10d337b446cec4d7a946d6bb2937127467d",
            download_sources = [
                JLLArtifactSource(
                    "https://github.com/JuliaBinaryWrappers/libLLVM_jll.jl/releases/download/libLLVM-v15.0.7+8/libLLVM.v15.0.7.x86_64-unknown-freebsd-llvm_version+15.asserts.tar.gz",
                    "65939a689d64eeb584bb8fa85c04f16dcd1e62427e49932888ee0ab92fd66301",
                ),
            ],
            products = [
                JLLLibraryProduct(
                    :libllvm,
                    "lib/libLLVM-15jl.so",
                    [
                        JLLLibraryDep(:Zlib_jll, :libz),
                    ],
                    flags = [:RTLD_LAZY, :RTLD_DEEPBIND],
                ),
                JLLExecutableProduct(
                    :llvm_config,
                    "tools/llvm-config",
                ),
            ]
        ),

        JLLArtifactInfo(;
            src_version = v"15.0.7+8",
            deps = [
                JLLPackageDependency(
                    "Zlib_jll",
                    Base.UUID("83775a58-1f1d-513f-b197-d71354ab007a"),
                    "*",
                ),
                JLLPackageDependency(
                    "TOML",
                    Base.UUID("fa267f1f-6049-4f14-aa54-33bafae1ed76"),
                    "*",
                ),
            ],
            sources = [],
            platform = Platform("x86_64", "windows"; cxxstring_abi = "cxx03", llvm_version = "15"),
            name = "default",
            treehash = "d55eec021ed05e30257b6a635556269faa89760d",
            download_sources = [
                JLLArtifactSource(
                    "https://github.com/JuliaBinaryWrappers/libLLVM_jll.jl/releases/download/libLLVM-v15.0.7+8/libLLVM.v15.0.7.x86_64-w64-mingw32-cxx03-llvm_version+15.tar.gz",
                    "a25f2acaf11d569931782674d9ff41217220d5afc436d2ced64c8506820a672f",
                ),
            ],
            products = [
                JLLLibraryProduct(
                    :libllvm,
                    "bin\\libLLVM-15jl.dll",
                    [
                        JLLLibraryDep(:Zlib_jll, :libz),
                    ],
                    flags = [:RTLD_LAZY, :RTLD_DEEPBIND],
                ),
                JLLExecutableProduct(
                    :llvm_config,
                    "tools\\llvm-config.exe",
                ),
            ]
        ),

        JLLArtifactInfo(;
            src_version = v"15.0.7+8",
            deps = [
                JLLPackageDependency(
                    "Zlib_jll",
                    Base.UUID("83775a58-1f1d-513f-b197-d71354ab007a"),
                    "*",
                ),
                JLLPackageDependency(
                    "TOML",
                    Base.UUID("fa267f1f-6049-4f14-aa54-33bafae1ed76"),
                    "*",
                ),
            ],
            sources = [],
            platform = Platform("x86_64", "windows"; cxxstring_abi = "cxx03", llvm_version = "15.asserts"),
            name = "default",
            treehash = "71a981a9f802ac86f93f5b0bdb0b55531ee0f4a6",
            download_sources = [
                JLLArtifactSource(
                    "https://github.com/JuliaBinaryWrappers/libLLVM_jll.jl/releases/download/libLLVM-v15.0.7+8/libLLVM.v15.0.7.x86_64-w64-mingw32-cxx03-llvm_version+15.asserts.tar.gz",
                    "91dd5288715098c18ce7e17567e3062bce26c935c4c2fafd0fbbbb6d2b97e105",
                ),
            ],
            products = [
                JLLLibraryProduct(
                    :libllvm,
                    "bin\\libLLVM-15jl.dll",
                    [
                        JLLLibraryDep(:Zlib_jll, :libz),
                    ],
                    flags = [:RTLD_LAZY, :RTLD_DEEPBIND],
                ),
                JLLExecutableProduct(
                    :llvm_config,
                    "tools\\llvm-config.exe",
                ),
            ]
        ),

        JLLArtifactInfo(;
            src_version = v"15.0.7+8",
            deps = [
                JLLPackageDependency(
                    "Zlib_jll",
                    Base.UUID("83775a58-1f1d-513f-b197-d71354ab007a"),
                    "*",
                ),
                JLLPackageDependency(
                    "TOML",
                    Base.UUID("fa267f1f-6049-4f14-aa54-33bafae1ed76"),
                    "*",
                ),
            ],
            sources = [],
            platform = Platform("x86_64", "windows"; cxxstring_abi = "cxx11", llvm_version = "15"),
            name = "default",
            treehash = "9a709947c8f9e7237eb7ced1720678b1523be326",
            download_sources = [
                JLLArtifactSource(
                    "https://github.com/JuliaBinaryWrappers/libLLVM_jll.jl/releases/download/libLLVM-v15.0.7+8/libLLVM.v15.0.7.x86_64-w64-mingw32-cxx11-llvm_version+15.tar.gz",
                    "b0b98fe7b9f8d679a9e4fbc3cf210fbcb2cd4e97fc40f91e385c67c573246914",
                ),
            ],
            products = [
                JLLLibraryProduct(
                    :libllvm,
                    "bin\\libLLVM-15jl.dll",
                    [
                        JLLLibraryDep(:Zlib_jll, :libz),
                    ],
                    flags = [:RTLD_LAZY, :RTLD_DEEPBIND],
                ),
                JLLExecutableProduct(
                    :llvm_config,
                    "tools\\llvm-config.exe",
                ),
            ]
        ),

        JLLArtifactInfo(;
            src_version = v"15.0.7+8",
            deps = [
                JLLPackageDependency(
                    "Zlib_jll",
                    Base.UUID("83775a58-1f1d-513f-b197-d71354ab007a"),
                    "*",
                ),
                JLLPackageDependency(
                    "TOML",
                    Base.UUID("fa267f1f-6049-4f14-aa54-33bafae1ed76"),
                    "*",
                ),
            ],
            sources = [],
            platform = Platform("x86_64", "windows"; cxxstring_abi = "cxx11", llvm_version = "15.asserts"),
            name = "default",
            treehash = "e2aaf4b533b04fb51b655fbb8e804ee3673eece0",
            download_sources = [
                JLLArtifactSource(
                    "https://github.com/JuliaBinaryWrappers/libLLVM_jll.jl/releases/download/libLLVM-v15.0.7+8/libLLVM.v15.0.7.x86_64-w64-mingw32-cxx11-llvm_version+15.asserts.tar.gz",
                    "d4ae587e73ed905aeacd05ce85805d163310fed8ab3d0f0c860da7611103e3f1",
                ),
            ],
            products = [
                JLLLibraryProduct(
                    :libllvm,
                    "bin\\libLLVM-15jl.dll",
                    [
                        JLLLibraryDep(:Zlib_jll, :libz),
                    ],
                    flags = [:RTLD_LAZY, :RTLD_DEEPBIND],
                ),
                JLLExecutableProduct(
                    :llvm_config,
                    "tools\\llvm-config.exe",
                ),
            ]
        ),

    ]
)

