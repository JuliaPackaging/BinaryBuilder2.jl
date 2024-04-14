jll = JLLInfo(;
    name = "LLD",
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
                JLLPackageDependency(
                    "libLLVM_jll",
                    Base.UUID("8f36deef-c2a5-5394-99ed-8e07531fb29a"),
                    "15.0.7",
                ),
            ],
            sources = [],
            platform = Platform("aarch64", "macos"; llvm_version = "15"),
            name = "default",
            treehash = "ef1ce1e0957a62c3c83e105e995149f4503f2e23",
            download_sources = [
                JLLArtifactSource(
                    "https://github.com/JuliaBinaryWrappers/LLD_jll.jl/releases/download/LLD-v15.0.7+8/LLD.v15.0.7.aarch64-apple-darwin-llvm_version+15.tar.gz",
                    "ed6e582dc8e1c0048899f0321d1fbe200fa60d1913fdb19bbd9af67895f8f726",
                ),
            ],
            products = [
                JLLExecutableProduct(
                    :dsymutil,
                    "tools/dsymutil",
                ),
                JLLExecutableProduct(
                    :lld,
                    "tools/lld",
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
                JLLPackageDependency(
                    "libLLVM_jll",
                    Base.UUID("8f36deef-c2a5-5394-99ed-8e07531fb29a"),
                    "15.0.7",
                ),
            ],
            sources = [],
            platform = Platform("aarch64", "macos"; llvm_version = "15.asserts"),
            name = "default",
            treehash = "802c244d18b91d814d85d10a54177d60dfac5e74",
            download_sources = [
                JLLArtifactSource(
                    "https://github.com/JuliaBinaryWrappers/LLD_jll.jl/releases/download/LLD-v15.0.7+8/LLD.v15.0.7.aarch64-apple-darwin-llvm_version+15.asserts.tar.gz",
                    "2d9d899e12dd220f75d184bad7d2571a418975047db91f7a41853d983884967d",
                ),
            ],
            products = [
                JLLExecutableProduct(
                    :dsymutil,
                    "tools/dsymutil",
                ),
                JLLExecutableProduct(
                    :lld,
                    "tools/lld",
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
                JLLPackageDependency(
                    "libLLVM_jll",
                    Base.UUID("8f36deef-c2a5-5394-99ed-8e07531fb29a"),
                    "15.0.7",
                ),
            ],
            sources = [],
            platform = Platform("aarch64", "linux"; cxxstring_abi = "cxx03", libc = "glibc", llvm_version = "15"),
            name = "default",
            treehash = "ba5d4d7dc306a60c04c53f4d6ae82bb8a9bf5f88",
            download_sources = [
                JLLArtifactSource(
                    "https://github.com/JuliaBinaryWrappers/LLD_jll.jl/releases/download/LLD-v15.0.7+8/LLD.v15.0.7.aarch64-linux-gnu-cxx03-llvm_version+15.tar.gz",
                    "a6b8b655a867cc310f689fc5a01e962c5db893c1ea156450610e15efce4def46",
                ),
            ],
            products = [
                JLLExecutableProduct(
                    :dsymutil,
                    "tools/dsymutil",
                ),
                JLLExecutableProduct(
                    :lld,
                    "tools/lld",
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
                JLLPackageDependency(
                    "libLLVM_jll",
                    Base.UUID("8f36deef-c2a5-5394-99ed-8e07531fb29a"),
                    "15.0.7",
                ),
            ],
            sources = [],
            platform = Platform("aarch64", "linux"; cxxstring_abi = "cxx03", libc = "glibc", llvm_version = "15.asserts"),
            name = "default",
            treehash = "5c602a4ce02a61eec334b97dc184154e47c34b6e",
            download_sources = [
                JLLArtifactSource(
                    "https://github.com/JuliaBinaryWrappers/LLD_jll.jl/releases/download/LLD-v15.0.7+8/LLD.v15.0.7.aarch64-linux-gnu-cxx03-llvm_version+15.asserts.tar.gz",
                    "1d8aa60bffba0233f5cbc9630d33affcdca02b9d0693607d633d70115bdff4dd",
                ),
            ],
            products = [
                JLLExecutableProduct(
                    :dsymutil,
                    "tools/dsymutil",
                ),
                JLLExecutableProduct(
                    :lld,
                    "tools/lld",
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
                JLLPackageDependency(
                    "libLLVM_jll",
                    Base.UUID("8f36deef-c2a5-5394-99ed-8e07531fb29a"),
                    "15.0.7",
                ),
            ],
            sources = [],
            platform = Platform("aarch64", "linux"; cxxstring_abi = "cxx11", libc = "glibc", llvm_version = "15"),
            name = "default",
            treehash = "2bfb1ea8b7c80362cfdf3edcd63745bfacbea6b8",
            download_sources = [
                JLLArtifactSource(
                    "https://github.com/JuliaBinaryWrappers/LLD_jll.jl/releases/download/LLD-v15.0.7+8/LLD.v15.0.7.aarch64-linux-gnu-cxx11-llvm_version+15.tar.gz",
                    "a4c71fcd3a1422b41b99912392b61ef677b3765aaf7e58b116c9b0e6d08105f6",
                ),
            ],
            products = [
                JLLExecutableProduct(
                    :dsymutil,
                    "tools/dsymutil",
                ),
                JLLExecutableProduct(
                    :lld,
                    "tools/lld",
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
                JLLPackageDependency(
                    "libLLVM_jll",
                    Base.UUID("8f36deef-c2a5-5394-99ed-8e07531fb29a"),
                    "15.0.7",
                ),
            ],
            sources = [],
            platform = Platform("aarch64", "linux"; cxxstring_abi = "cxx11", libc = "glibc", llvm_version = "15.asserts"),
            name = "default",
            treehash = "27356cdfb63678b6e57f4c71e8eccb4ee85066bc",
            download_sources = [
                JLLArtifactSource(
                    "https://github.com/JuliaBinaryWrappers/LLD_jll.jl/releases/download/LLD-v15.0.7+8/LLD.v15.0.7.aarch64-linux-gnu-cxx11-llvm_version+15.asserts.tar.gz",
                    "99f991a9ea7df595b56911168f644958a62b535d38c31a8c25873ea51085a328",
                ),
            ],
            products = [
                JLLExecutableProduct(
                    :dsymutil,
                    "tools/dsymutil",
                ),
                JLLExecutableProduct(
                    :lld,
                    "tools/lld",
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
                JLLPackageDependency(
                    "libLLVM_jll",
                    Base.UUID("8f36deef-c2a5-5394-99ed-8e07531fb29a"),
                    "15.0.7",
                ),
            ],
            sources = [],
            platform = Platform("aarch64", "linux"; cxxstring_abi = "cxx03", libc = "musl", llvm_version = "15"),
            name = "default",
            treehash = "8318e35411ea6d6fbd5ca60f2871602a747d9015",
            download_sources = [
                JLLArtifactSource(
                    "https://github.com/JuliaBinaryWrappers/LLD_jll.jl/releases/download/LLD-v15.0.7+8/LLD.v15.0.7.aarch64-linux-musl-cxx03-llvm_version+15.tar.gz",
                    "411b361dd962ea7b9a2ee7a90f540b8a77fc81edd723bc2e0e26096bfa9a996a",
                ),
            ],
            products = [
                JLLExecutableProduct(
                    :dsymutil,
                    "tools/dsymutil",
                ),
                JLLExecutableProduct(
                    :lld,
                    "tools/lld",
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
                JLLPackageDependency(
                    "libLLVM_jll",
                    Base.UUID("8f36deef-c2a5-5394-99ed-8e07531fb29a"),
                    "15.0.7",
                ),
            ],
            sources = [],
            platform = Platform("aarch64", "linux"; cxxstring_abi = "cxx03", libc = "musl", llvm_version = "15.asserts"),
            name = "default",
            treehash = "1e31e460722ff12025db354898aeadb600240767",
            download_sources = [
                JLLArtifactSource(
                    "https://github.com/JuliaBinaryWrappers/LLD_jll.jl/releases/download/LLD-v15.0.7+8/LLD.v15.0.7.aarch64-linux-musl-cxx03-llvm_version+15.asserts.tar.gz",
                    "4030c44daaa22bb625a4975d30d8acb4d2aad1917efb0975fe0b9389a2be2090",
                ),
            ],
            products = [
                JLLExecutableProduct(
                    :dsymutil,
                    "tools/dsymutil",
                ),
                JLLExecutableProduct(
                    :lld,
                    "tools/lld",
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
                JLLPackageDependency(
                    "libLLVM_jll",
                    Base.UUID("8f36deef-c2a5-5394-99ed-8e07531fb29a"),
                    "15.0.7",
                ),
            ],
            sources = [],
            platform = Platform("aarch64", "linux"; cxxstring_abi = "cxx11", libc = "musl", llvm_version = "15"),
            name = "default",
            treehash = "cc65d558eafa9f3dd4ce03315afe338adf731fef",
            download_sources = [
                JLLArtifactSource(
                    "https://github.com/JuliaBinaryWrappers/LLD_jll.jl/releases/download/LLD-v15.0.7+8/LLD.v15.0.7.aarch64-linux-musl-cxx11-llvm_version+15.tar.gz",
                    "0a68b44e2e0dfbe88f7679a74cd2cb4a985c89f41125737a3eb4d89b1b04c9eb",
                ),
            ],
            products = [
                JLLExecutableProduct(
                    :dsymutil,
                    "tools/dsymutil",
                ),
                JLLExecutableProduct(
                    :lld,
                    "tools/lld",
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
                JLLPackageDependency(
                    "libLLVM_jll",
                    Base.UUID("8f36deef-c2a5-5394-99ed-8e07531fb29a"),
                    "15.0.7",
                ),
            ],
            sources = [],
            platform = Platform("aarch64", "linux"; cxxstring_abi = "cxx11", libc = "musl", llvm_version = "15.asserts"),
            name = "default",
            treehash = "a16e85306ddcaa5b23602a1e055a56a6a3434023",
            download_sources = [
                JLLArtifactSource(
                    "https://github.com/JuliaBinaryWrappers/LLD_jll.jl/releases/download/LLD-v15.0.7+8/LLD.v15.0.7.aarch64-linux-musl-cxx11-llvm_version+15.asserts.tar.gz",
                    "ebe23b79c399a607a8ccef33dabdc2f7bca14aee91974b478c17f09858923c40",
                ),
            ],
            products = [
                JLLExecutableProduct(
                    :dsymutil,
                    "tools/dsymutil",
                ),
                JLLExecutableProduct(
                    :lld,
                    "tools/lld",
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
                JLLPackageDependency(
                    "libLLVM_jll",
                    Base.UUID("8f36deef-c2a5-5394-99ed-8e07531fb29a"),
                    "15.0.7",
                ),
            ],
            sources = [],
            platform = Platform("armv6l", "linux"; cxxstring_abi = "cxx03", call_abi = "eabihf", libc = "glibc", llvm_version = "15"),
            name = "default",
            treehash = "f05a8117ba66a791fe6da964359868b9146e061b",
            download_sources = [
                JLLArtifactSource(
                    "https://github.com/JuliaBinaryWrappers/LLD_jll.jl/releases/download/LLD-v15.0.7+8/LLD.v15.0.7.armv6l-linux-gnueabihf-cxx03-llvm_version+15.tar.gz",
                    "cd77de2167f8f7985ce8c044c08223e3ea0f95aab5c87db3a86356b230b7264c",
                ),
            ],
            products = [
                JLLExecutableProduct(
                    :dsymutil,
                    "tools/dsymutil",
                ),
                JLLExecutableProduct(
                    :lld,
                    "tools/lld",
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
                JLLPackageDependency(
                    "libLLVM_jll",
                    Base.UUID("8f36deef-c2a5-5394-99ed-8e07531fb29a"),
                    "15.0.7",
                ),
            ],
            sources = [],
            platform = Platform("armv6l", "linux"; cxxstring_abi = "cxx03", call_abi = "eabihf", libc = "glibc", llvm_version = "15.asserts"),
            name = "default",
            treehash = "1ebd29e830291c144c10361394224436f9e7f94a",
            download_sources = [
                JLLArtifactSource(
                    "https://github.com/JuliaBinaryWrappers/LLD_jll.jl/releases/download/LLD-v15.0.7+8/LLD.v15.0.7.armv6l-linux-gnueabihf-cxx03-llvm_version+15.asserts.tar.gz",
                    "8dc5ce9d0599de2b94961487451d6b170578c5b1e1065b5029837fe930ed29b4",
                ),
            ],
            products = [
                JLLExecutableProduct(
                    :dsymutil,
                    "tools/dsymutil",
                ),
                JLLExecutableProduct(
                    :lld,
                    "tools/lld",
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
                JLLPackageDependency(
                    "libLLVM_jll",
                    Base.UUID("8f36deef-c2a5-5394-99ed-8e07531fb29a"),
                    "15.0.7",
                ),
            ],
            sources = [],
            platform = Platform("armv6l", "linux"; cxxstring_abi = "cxx11", call_abi = "eabihf", libc = "glibc", llvm_version = "15"),
            name = "default",
            treehash = "426c91c1e7db917863972b2acf82fd1ed5ec1ec6",
            download_sources = [
                JLLArtifactSource(
                    "https://github.com/JuliaBinaryWrappers/LLD_jll.jl/releases/download/LLD-v15.0.7+8/LLD.v15.0.7.armv6l-linux-gnueabihf-cxx11-llvm_version+15.tar.gz",
                    "a292b2a9eec3bc34ecf874d975661b785ce37cb1812b3ecaf9933b4c1e587a9b",
                ),
            ],
            products = [
                JLLExecutableProduct(
                    :dsymutil,
                    "tools/dsymutil",
                ),
                JLLExecutableProduct(
                    :lld,
                    "tools/lld",
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
                JLLPackageDependency(
                    "libLLVM_jll",
                    Base.UUID("8f36deef-c2a5-5394-99ed-8e07531fb29a"),
                    "15.0.7",
                ),
            ],
            sources = [],
            platform = Platform("armv6l", "linux"; cxxstring_abi = "cxx11", call_abi = "eabihf", libc = "glibc", llvm_version = "15.asserts"),
            name = "default",
            treehash = "db231011b2379737285466c32919ea1a32ca25ac",
            download_sources = [
                JLLArtifactSource(
                    "https://github.com/JuliaBinaryWrappers/LLD_jll.jl/releases/download/LLD-v15.0.7+8/LLD.v15.0.7.armv6l-linux-gnueabihf-cxx11-llvm_version+15.asserts.tar.gz",
                    "69586ceef2204a13e62da1d85a87356004fe14392cedc6b34725ec00d9b81533",
                ),
            ],
            products = [
                JLLExecutableProduct(
                    :dsymutil,
                    "tools/dsymutil",
                ),
                JLLExecutableProduct(
                    :lld,
                    "tools/lld",
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
                JLLPackageDependency(
                    "libLLVM_jll",
                    Base.UUID("8f36deef-c2a5-5394-99ed-8e07531fb29a"),
                    "15.0.7",
                ),
            ],
            sources = [],
            platform = Platform("armv6l", "linux"; cxxstring_abi = "cxx03", call_abi = "eabihf", libc = "musl", llvm_version = "15"),
            name = "default",
            treehash = "7e30415fc23631913b900b0b2145c18395375a64",
            download_sources = [
                JLLArtifactSource(
                    "https://github.com/JuliaBinaryWrappers/LLD_jll.jl/releases/download/LLD-v15.0.7+8/LLD.v15.0.7.armv6l-linux-musleabihf-cxx03-llvm_version+15.tar.gz",
                    "298f9bb39565478b3b72924323a4a8e85980272a4e6a10dfa9f7560f7c30c57c",
                ),
            ],
            products = [
                JLLExecutableProduct(
                    :dsymutil,
                    "tools/dsymutil",
                ),
                JLLExecutableProduct(
                    :lld,
                    "tools/lld",
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
                JLLPackageDependency(
                    "libLLVM_jll",
                    Base.UUID("8f36deef-c2a5-5394-99ed-8e07531fb29a"),
                    "15.0.7",
                ),
            ],
            sources = [],
            platform = Platform("armv6l", "linux"; cxxstring_abi = "cxx03", call_abi = "eabihf", libc = "musl", llvm_version = "15.asserts"),
            name = "default",
            treehash = "3348f06eea3331939d3d09da7268e6a6456fb3aa",
            download_sources = [
                JLLArtifactSource(
                    "https://github.com/JuliaBinaryWrappers/LLD_jll.jl/releases/download/LLD-v15.0.7+8/LLD.v15.0.7.armv6l-linux-musleabihf-cxx03-llvm_version+15.asserts.tar.gz",
                    "cf7d97d10f24c5bc83be688cb00a60d5bce3b8c080e4476f9544a9aced8b25e7",
                ),
            ],
            products = [
                JLLExecutableProduct(
                    :dsymutil,
                    "tools/dsymutil",
                ),
                JLLExecutableProduct(
                    :lld,
                    "tools/lld",
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
                JLLPackageDependency(
                    "libLLVM_jll",
                    Base.UUID("8f36deef-c2a5-5394-99ed-8e07531fb29a"),
                    "15.0.7",
                ),
            ],
            sources = [],
            platform = Platform("armv6l", "linux"; cxxstring_abi = "cxx11", call_abi = "eabihf", libc = "musl", llvm_version = "15"),
            name = "default",
            treehash = "25cda0f6323d73396c33c5eef1024bdfadc7bd39",
            download_sources = [
                JLLArtifactSource(
                    "https://github.com/JuliaBinaryWrappers/LLD_jll.jl/releases/download/LLD-v15.0.7+8/LLD.v15.0.7.armv6l-linux-musleabihf-cxx11-llvm_version+15.tar.gz",
                    "1097a3da7979ccac08579dbd2e09cd239c5a039fb3e8297965e8e48682bdcd3c",
                ),
            ],
            products = [
                JLLExecutableProduct(
                    :dsymutil,
                    "tools/dsymutil",
                ),
                JLLExecutableProduct(
                    :lld,
                    "tools/lld",
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
                JLLPackageDependency(
                    "libLLVM_jll",
                    Base.UUID("8f36deef-c2a5-5394-99ed-8e07531fb29a"),
                    "15.0.7",
                ),
            ],
            sources = [],
            platform = Platform("armv6l", "linux"; cxxstring_abi = "cxx11", call_abi = "eabihf", libc = "musl", llvm_version = "15.asserts"),
            name = "default",
            treehash = "cba056b976aea5dde22e770f5ba8135ecbfe18e6",
            download_sources = [
                JLLArtifactSource(
                    "https://github.com/JuliaBinaryWrappers/LLD_jll.jl/releases/download/LLD-v15.0.7+8/LLD.v15.0.7.armv6l-linux-musleabihf-cxx11-llvm_version+15.asserts.tar.gz",
                    "3d4cf7665f7de5ff30a4cde98b21f358aa90f5be4827b0bb72ec9f6e7d12386c",
                ),
            ],
            products = [
                JLLExecutableProduct(
                    :dsymutil,
                    "tools/dsymutil",
                ),
                JLLExecutableProduct(
                    :lld,
                    "tools/lld",
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
                JLLPackageDependency(
                    "libLLVM_jll",
                    Base.UUID("8f36deef-c2a5-5394-99ed-8e07531fb29a"),
                    "15.0.7",
                ),
            ],
            sources = [],
            platform = Platform("armv7l", "linux"; cxxstring_abi = "cxx03", call_abi = "eabihf", libc = "glibc", llvm_version = "15"),
            name = "default",
            treehash = "ba99e551472235e898d85f52217ac66a2ce60de1",
            download_sources = [
                JLLArtifactSource(
                    "https://github.com/JuliaBinaryWrappers/LLD_jll.jl/releases/download/LLD-v15.0.7+8/LLD.v15.0.7.armv7l-linux-gnueabihf-cxx03-llvm_version+15.tar.gz",
                    "4783ef60b5eb1dfaa82897d31ecf41fca350c223f500b2b0892a7ad0e3b8fa5b",
                ),
            ],
            products = [
                JLLExecutableProduct(
                    :dsymutil,
                    "tools/dsymutil",
                ),
                JLLExecutableProduct(
                    :lld,
                    "tools/lld",
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
                JLLPackageDependency(
                    "libLLVM_jll",
                    Base.UUID("8f36deef-c2a5-5394-99ed-8e07531fb29a"),
                    "15.0.7",
                ),
            ],
            sources = [],
            platform = Platform("armv7l", "linux"; cxxstring_abi = "cxx03", call_abi = "eabihf", libc = "glibc", llvm_version = "15.asserts"),
            name = "default",
            treehash = "4e722a0a2c9a6d9eed6ac95f21ffd0a9104bf1dd",
            download_sources = [
                JLLArtifactSource(
                    "https://github.com/JuliaBinaryWrappers/LLD_jll.jl/releases/download/LLD-v15.0.7+8/LLD.v15.0.7.armv7l-linux-gnueabihf-cxx03-llvm_version+15.asserts.tar.gz",
                    "2d07df6100dd28892eb68797eb6138be4725cf289ceedfd6e7cd4553334fedc8",
                ),
            ],
            products = [
                JLLExecutableProduct(
                    :dsymutil,
                    "tools/dsymutil",
                ),
                JLLExecutableProduct(
                    :lld,
                    "tools/lld",
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
                JLLPackageDependency(
                    "libLLVM_jll",
                    Base.UUID("8f36deef-c2a5-5394-99ed-8e07531fb29a"),
                    "15.0.7",
                ),
            ],
            sources = [],
            platform = Platform("armv7l", "linux"; cxxstring_abi = "cxx11", call_abi = "eabihf", libc = "glibc", llvm_version = "15"),
            name = "default",
            treehash = "f5749efad7d4ec83023fb6c95ea3fc373ae5cd8a",
            download_sources = [
                JLLArtifactSource(
                    "https://github.com/JuliaBinaryWrappers/LLD_jll.jl/releases/download/LLD-v15.0.7+8/LLD.v15.0.7.armv7l-linux-gnueabihf-cxx11-llvm_version+15.tar.gz",
                    "8242e11fed94ceeee80e23fda3fd49523e46ed86c2d4bb58097b793c1df94519",
                ),
            ],
            products = [
                JLLExecutableProduct(
                    :dsymutil,
                    "tools/dsymutil",
                ),
                JLLExecutableProduct(
                    :lld,
                    "tools/lld",
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
                JLLPackageDependency(
                    "libLLVM_jll",
                    Base.UUID("8f36deef-c2a5-5394-99ed-8e07531fb29a"),
                    "15.0.7",
                ),
            ],
            sources = [],
            platform = Platform("armv7l", "linux"; cxxstring_abi = "cxx11", call_abi = "eabihf", libc = "glibc", llvm_version = "15.asserts"),
            name = "default",
            treehash = "df8e5a3fbdd08e86770f278b5cb94e86cb376053",
            download_sources = [
                JLLArtifactSource(
                    "https://github.com/JuliaBinaryWrappers/LLD_jll.jl/releases/download/LLD-v15.0.7+8/LLD.v15.0.7.armv7l-linux-gnueabihf-cxx11-llvm_version+15.asserts.tar.gz",
                    "f5a359ff6668ec8d468ce7107a302803d1f8131a33c7dc7dc98e3329399a1300",
                ),
            ],
            products = [
                JLLExecutableProduct(
                    :dsymutil,
                    "tools/dsymutil",
                ),
                JLLExecutableProduct(
                    :lld,
                    "tools/lld",
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
                JLLPackageDependency(
                    "libLLVM_jll",
                    Base.UUID("8f36deef-c2a5-5394-99ed-8e07531fb29a"),
                    "15.0.7",
                ),
            ],
            sources = [],
            platform = Platform("armv7l", "linux"; cxxstring_abi = "cxx03", call_abi = "eabihf", libc = "musl", llvm_version = "15"),
            name = "default",
            treehash = "9cb8de720e67dcda6609a0cc08ecb95241656ffd",
            download_sources = [
                JLLArtifactSource(
                    "https://github.com/JuliaBinaryWrappers/LLD_jll.jl/releases/download/LLD-v15.0.7+8/LLD.v15.0.7.armv7l-linux-musleabihf-cxx03-llvm_version+15.tar.gz",
                    "3ad9f40071957a6c761e916b1491fb660d1dc9309186d3f943a4190342777dc7",
                ),
            ],
            products = [
                JLLExecutableProduct(
                    :dsymutil,
                    "tools/dsymutil",
                ),
                JLLExecutableProduct(
                    :lld,
                    "tools/lld",
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
                JLLPackageDependency(
                    "libLLVM_jll",
                    Base.UUID("8f36deef-c2a5-5394-99ed-8e07531fb29a"),
                    "15.0.7",
                ),
            ],
            sources = [],
            platform = Platform("armv7l", "linux"; cxxstring_abi = "cxx03", call_abi = "eabihf", libc = "musl", llvm_version = "15.asserts"),
            name = "default",
            treehash = "6a63d2db3a9007cde8467d6d1afb66dd0188db3a",
            download_sources = [
                JLLArtifactSource(
                    "https://github.com/JuliaBinaryWrappers/LLD_jll.jl/releases/download/LLD-v15.0.7+8/LLD.v15.0.7.armv7l-linux-musleabihf-cxx03-llvm_version+15.asserts.tar.gz",
                    "e7f6c6cdc4240fff0969fe246de58338799205363fedacaaf621fbf360a6c782",
                ),
            ],
            products = [
                JLLExecutableProduct(
                    :dsymutil,
                    "tools/dsymutil",
                ),
                JLLExecutableProduct(
                    :lld,
                    "tools/lld",
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
                JLLPackageDependency(
                    "libLLVM_jll",
                    Base.UUID("8f36deef-c2a5-5394-99ed-8e07531fb29a"),
                    "15.0.7",
                ),
            ],
            sources = [],
            platform = Platform("armv7l", "linux"; cxxstring_abi = "cxx11", call_abi = "eabihf", libc = "musl", llvm_version = "15"),
            name = "default",
            treehash = "69d5ebfc5231e932ab11621c6616f14a696c147f",
            download_sources = [
                JLLArtifactSource(
                    "https://github.com/JuliaBinaryWrappers/LLD_jll.jl/releases/download/LLD-v15.0.7+8/LLD.v15.0.7.armv7l-linux-musleabihf-cxx11-llvm_version+15.tar.gz",
                    "79c98498b94be6ffa03f1c011d42430b87424169496aa1f47ce2a81713c6cf9d",
                ),
            ],
            products = [
                JLLExecutableProduct(
                    :dsymutil,
                    "tools/dsymutil",
                ),
                JLLExecutableProduct(
                    :lld,
                    "tools/lld",
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
                JLLPackageDependency(
                    "libLLVM_jll",
                    Base.UUID("8f36deef-c2a5-5394-99ed-8e07531fb29a"),
                    "15.0.7",
                ),
            ],
            sources = [],
            platform = Platform("armv7l", "linux"; cxxstring_abi = "cxx11", call_abi = "eabihf", libc = "musl", llvm_version = "15.asserts"),
            name = "default",
            treehash = "97af7cfc61090760989eb0d5f2d82714d6cdd139",
            download_sources = [
                JLLArtifactSource(
                    "https://github.com/JuliaBinaryWrappers/LLD_jll.jl/releases/download/LLD-v15.0.7+8/LLD.v15.0.7.armv7l-linux-musleabihf-cxx11-llvm_version+15.asserts.tar.gz",
                    "8d9c65ba241a2c426ebfe80ff61848567ac09ddb095f6523d715d9727c7d28ab",
                ),
            ],
            products = [
                JLLExecutableProduct(
                    :dsymutil,
                    "tools/dsymutil",
                ),
                JLLExecutableProduct(
                    :lld,
                    "tools/lld",
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
                JLLPackageDependency(
                    "libLLVM_jll",
                    Base.UUID("8f36deef-c2a5-5394-99ed-8e07531fb29a"),
                    "15.0.7",
                ),
            ],
            sources = [],
            platform = Platform("i686", "linux"; cxxstring_abi = "cxx03", libc = "glibc", llvm_version = "15"),
            name = "default",
            treehash = "cdea39a48b8d8c5088ad68fe4500bba06a96dbc6",
            download_sources = [
                JLLArtifactSource(
                    "https://github.com/JuliaBinaryWrappers/LLD_jll.jl/releases/download/LLD-v15.0.7+8/LLD.v15.0.7.i686-linux-gnu-cxx03-llvm_version+15.tar.gz",
                    "534e411acca016d97283a815f8e841f44813c765dff30bd9e1e1269cbab3731a",
                ),
            ],
            products = [
                JLLExecutableProduct(
                    :dsymutil,
                    "tools/dsymutil",
                ),
                JLLExecutableProduct(
                    :lld,
                    "tools/lld",
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
                JLLPackageDependency(
                    "libLLVM_jll",
                    Base.UUID("8f36deef-c2a5-5394-99ed-8e07531fb29a"),
                    "15.0.7",
                ),
            ],
            sources = [],
            platform = Platform("i686", "linux"; cxxstring_abi = "cxx03", libc = "glibc", llvm_version = "15.asserts"),
            name = "default",
            treehash = "d268c37cf568170678c4ab5d78166141426c10ce",
            download_sources = [
                JLLArtifactSource(
                    "https://github.com/JuliaBinaryWrappers/LLD_jll.jl/releases/download/LLD-v15.0.7+8/LLD.v15.0.7.i686-linux-gnu-cxx03-llvm_version+15.asserts.tar.gz",
                    "b3487a230c67422b4bcc0ad1b000a55902bffce834a74ed24230372b9ea2b7dd",
                ),
            ],
            products = [
                JLLExecutableProduct(
                    :dsymutil,
                    "tools/dsymutil",
                ),
                JLLExecutableProduct(
                    :lld,
                    "tools/lld",
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
                JLLPackageDependency(
                    "libLLVM_jll",
                    Base.UUID("8f36deef-c2a5-5394-99ed-8e07531fb29a"),
                    "15.0.7",
                ),
            ],
            sources = [],
            platform = Platform("i686", "linux"; cxxstring_abi = "cxx11", libc = "glibc", llvm_version = "15"),
            name = "default",
            treehash = "3243c6c23ced0085d101fb336f0f52e6791bb9ed",
            download_sources = [
                JLLArtifactSource(
                    "https://github.com/JuliaBinaryWrappers/LLD_jll.jl/releases/download/LLD-v15.0.7+8/LLD.v15.0.7.i686-linux-gnu-cxx11-llvm_version+15.tar.gz",
                    "e73e36ad7b0d0fbd4c0d181c8708a64f7c844b5443c7327c0aa48a7d9506d723",
                ),
            ],
            products = [
                JLLExecutableProduct(
                    :dsymutil,
                    "tools/dsymutil",
                ),
                JLLExecutableProduct(
                    :lld,
                    "tools/lld",
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
                JLLPackageDependency(
                    "libLLVM_jll",
                    Base.UUID("8f36deef-c2a5-5394-99ed-8e07531fb29a"),
                    "15.0.7",
                ),
            ],
            sources = [],
            platform = Platform("i686", "linux"; cxxstring_abi = "cxx11", libc = "glibc", llvm_version = "15.asserts"),
            name = "default",
            treehash = "9ccc1eadcf57457797db1b55d9c95a71480ebadc",
            download_sources = [
                JLLArtifactSource(
                    "https://github.com/JuliaBinaryWrappers/LLD_jll.jl/releases/download/LLD-v15.0.7+8/LLD.v15.0.7.i686-linux-gnu-cxx11-llvm_version+15.asserts.tar.gz",
                    "64fc98cf3067dfd3f94fe804bb96aec94a263237a07dc961a6ea638d5fa0e624",
                ),
            ],
            products = [
                JLLExecutableProduct(
                    :dsymutil,
                    "tools/dsymutil",
                ),
                JLLExecutableProduct(
                    :lld,
                    "tools/lld",
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
                JLLPackageDependency(
                    "libLLVM_jll",
                    Base.UUID("8f36deef-c2a5-5394-99ed-8e07531fb29a"),
                    "15.0.7",
                ),
            ],
            sources = [],
            platform = Platform("i686", "windows"; cxxstring_abi = "cxx03", llvm_version = "15"),
            name = "default",
            treehash = "eede84573119fdf18826fbe44bc70dc46af25451",
            download_sources = [
                JLLArtifactSource(
                    "https://github.com/JuliaBinaryWrappers/LLD_jll.jl/releases/download/LLD-v15.0.7+8/LLD.v15.0.7.i686-w64-mingw32-cxx03-llvm_version+15.tar.gz",
                    "be2b07f0799e3489d4eecaa3b17af6cc2aa4d780d41d45d0bb7aa9c60c5073e3",
                ),
            ],
            products = [
                JLLExecutableProduct(
                    :dsymutil,
                    "tools\\dsymutil.exe",
                ),
                JLLExecutableProduct(
                    :lld,
                    "tools\\lld.exe",
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
                JLLPackageDependency(
                    "libLLVM_jll",
                    Base.UUID("8f36deef-c2a5-5394-99ed-8e07531fb29a"),
                    "15.0.7",
                ),
            ],
            sources = [],
            platform = Platform("i686", "windows"; cxxstring_abi = "cxx03", llvm_version = "15.asserts"),
            name = "default",
            treehash = "6800b193e767b2502765b36877f5a1b00d3c948f",
            download_sources = [
                JLLArtifactSource(
                    "https://github.com/JuliaBinaryWrappers/LLD_jll.jl/releases/download/LLD-v15.0.7+8/LLD.v15.0.7.i686-w64-mingw32-cxx03-llvm_version+15.asserts.tar.gz",
                    "4196883faf5477f6ceb1347e90f16fd2035d7efe1cdc3e74845a6eab2ef6f695",
                ),
            ],
            products = [
                JLLExecutableProduct(
                    :dsymutil,
                    "tools\\dsymutil.exe",
                ),
                JLLExecutableProduct(
                    :lld,
                    "tools\\lld.exe",
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
                JLLPackageDependency(
                    "libLLVM_jll",
                    Base.UUID("8f36deef-c2a5-5394-99ed-8e07531fb29a"),
                    "15.0.7",
                ),
            ],
            sources = [],
            platform = Platform("i686", "windows"; cxxstring_abi = "cxx11", llvm_version = "15"),
            name = "default",
            treehash = "d4c2b0742ae0ed519d4460e73976b176bf0f5dec",
            download_sources = [
                JLLArtifactSource(
                    "https://github.com/JuliaBinaryWrappers/LLD_jll.jl/releases/download/LLD-v15.0.7+8/LLD.v15.0.7.i686-w64-mingw32-cxx11-llvm_version+15.tar.gz",
                    "0aa79000317cc6c53a2e5afee4220cae0204adaf26b71cfd2ca1325d5c4d9764",
                ),
            ],
            products = [
                JLLExecutableProduct(
                    :dsymutil,
                    "tools\\dsymutil.exe",
                ),
                JLLExecutableProduct(
                    :lld,
                    "tools\\lld.exe",
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
                JLLPackageDependency(
                    "libLLVM_jll",
                    Base.UUID("8f36deef-c2a5-5394-99ed-8e07531fb29a"),
                    "15.0.7",
                ),
            ],
            sources = [],
            platform = Platform("i686", "windows"; cxxstring_abi = "cxx11", llvm_version = "15.asserts"),
            name = "default",
            treehash = "b81ff9b1cc92f4d4789289419fe37b0b57cc86d9",
            download_sources = [
                JLLArtifactSource(
                    "https://github.com/JuliaBinaryWrappers/LLD_jll.jl/releases/download/LLD-v15.0.7+8/LLD.v15.0.7.i686-w64-mingw32-cxx11-llvm_version+15.asserts.tar.gz",
                    "af78d5e5826b82dcdfee2dd4657e6f691cd73787428e0b26734dc6a65d52321d",
                ),
            ],
            products = [
                JLLExecutableProduct(
                    :dsymutil,
                    "tools\\dsymutil.exe",
                ),
                JLLExecutableProduct(
                    :lld,
                    "tools\\lld.exe",
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
                JLLPackageDependency(
                    "libLLVM_jll",
                    Base.UUID("8f36deef-c2a5-5394-99ed-8e07531fb29a"),
                    "15.0.7",
                ),
            ],
            sources = [],
            platform = Platform("powerpc64le", "linux"; cxxstring_abi = "cxx03", libc = "glibc", llvm_version = "15"),
            name = "default",
            treehash = "77f20007d7c260b6a1dcab1186158569d43fdc21",
            download_sources = [
                JLLArtifactSource(
                    "https://github.com/JuliaBinaryWrappers/LLD_jll.jl/releases/download/LLD-v15.0.7+8/LLD.v15.0.7.powerpc64le-linux-gnu-cxx03-llvm_version+15.tar.gz",
                    "3303645b815406b5a2efe310a1ab52628c511a11ca7be70963d8ca5e9fb62a90",
                ),
            ],
            products = [
                JLLExecutableProduct(
                    :dsymutil,
                    "tools/dsymutil",
                ),
                JLLExecutableProduct(
                    :lld,
                    "tools/lld",
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
                JLLPackageDependency(
                    "libLLVM_jll",
                    Base.UUID("8f36deef-c2a5-5394-99ed-8e07531fb29a"),
                    "15.0.7",
                ),
            ],
            sources = [],
            platform = Platform("powerpc64le", "linux"; cxxstring_abi = "cxx03", libc = "glibc", llvm_version = "15.asserts"),
            name = "default",
            treehash = "15010b047916f819e1e5d309e8747f2e1351f637",
            download_sources = [
                JLLArtifactSource(
                    "https://github.com/JuliaBinaryWrappers/LLD_jll.jl/releases/download/LLD-v15.0.7+8/LLD.v15.0.7.powerpc64le-linux-gnu-cxx03-llvm_version+15.asserts.tar.gz",
                    "a9d3075e7baa728ab348211d750864200c7d70eba8569f33fdb6178fa8425428",
                ),
            ],
            products = [
                JLLExecutableProduct(
                    :dsymutil,
                    "tools/dsymutil",
                ),
                JLLExecutableProduct(
                    :lld,
                    "tools/lld",
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
                JLLPackageDependency(
                    "libLLVM_jll",
                    Base.UUID("8f36deef-c2a5-5394-99ed-8e07531fb29a"),
                    "15.0.7",
                ),
            ],
            sources = [],
            platform = Platform("powerpc64le", "linux"; cxxstring_abi = "cxx11", libc = "glibc", llvm_version = "15"),
            name = "default",
            treehash = "a00bc940eb1e0e8103ee2e9643c8dda060edba90",
            download_sources = [
                JLLArtifactSource(
                    "https://github.com/JuliaBinaryWrappers/LLD_jll.jl/releases/download/LLD-v15.0.7+8/LLD.v15.0.7.powerpc64le-linux-gnu-cxx11-llvm_version+15.tar.gz",
                    "594ce185ed38f502d4af0c459365fc90162b13d097a52588b3706ff4a4e1b5c3",
                ),
            ],
            products = [
                JLLExecutableProduct(
                    :dsymutil,
                    "tools/dsymutil",
                ),
                JLLExecutableProduct(
                    :lld,
                    "tools/lld",
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
                JLLPackageDependency(
                    "libLLVM_jll",
                    Base.UUID("8f36deef-c2a5-5394-99ed-8e07531fb29a"),
                    "15.0.7",
                ),
            ],
            sources = [],
            platform = Platform("powerpc64le", "linux"; cxxstring_abi = "cxx11", libc = "glibc", llvm_version = "15.asserts"),
            name = "default",
            treehash = "a031634a519c3a1079175152cb6bf50b9a490dea",
            download_sources = [
                JLLArtifactSource(
                    "https://github.com/JuliaBinaryWrappers/LLD_jll.jl/releases/download/LLD-v15.0.7+8/LLD.v15.0.7.powerpc64le-linux-gnu-cxx11-llvm_version+15.asserts.tar.gz",
                    "c9310c61d6efcc311150b26878c50f9054155c1d4fa22ae2cedf2015f02564ff",
                ),
            ],
            products = [
                JLLExecutableProduct(
                    :dsymutil,
                    "tools/dsymutil",
                ),
                JLLExecutableProduct(
                    :lld,
                    "tools/lld",
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
                JLLPackageDependency(
                    "libLLVM_jll",
                    Base.UUID("8f36deef-c2a5-5394-99ed-8e07531fb29a"),
                    "15.0.7",
                ),
            ],
            sources = [],
            platform = Platform("x86_64", "macos"; llvm_version = "15"),
            name = "default",
            treehash = "e154a79a43a96ef844c84f15aa54fb024831e82f",
            download_sources = [
                JLLArtifactSource(
                    "https://github.com/JuliaBinaryWrappers/LLD_jll.jl/releases/download/LLD-v15.0.7+8/LLD.v15.0.7.x86_64-apple-darwin-llvm_version+15.tar.gz",
                    "9e05e9dcf4c02318357309752b33f0f96aca909afa67ed080656d4f93596e3cc",
                ),
            ],
            products = [
                JLLExecutableProduct(
                    :dsymutil,
                    "tools/dsymutil",
                ),
                JLLExecutableProduct(
                    :lld,
                    "tools/lld",
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
                JLLPackageDependency(
                    "libLLVM_jll",
                    Base.UUID("8f36deef-c2a5-5394-99ed-8e07531fb29a"),
                    "15.0.7",
                ),
            ],
            sources = [],
            platform = Platform("x86_64", "macos"; llvm_version = "15.asserts"),
            name = "default",
            treehash = "1327474976d303f6c956a75afe574bdf4cdfbf6d",
            download_sources = [
                JLLArtifactSource(
                    "https://github.com/JuliaBinaryWrappers/LLD_jll.jl/releases/download/LLD-v15.0.7+8/LLD.v15.0.7.x86_64-apple-darwin-llvm_version+15.asserts.tar.gz",
                    "6bd2dd00375a00c68f185b65cb53a8ea00f245f9bc216bc07574ff07e3dca2f0",
                ),
            ],
            products = [
                JLLExecutableProduct(
                    :dsymutil,
                    "tools/dsymutil",
                ),
                JLLExecutableProduct(
                    :lld,
                    "tools/lld",
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
                JLLPackageDependency(
                    "libLLVM_jll",
                    Base.UUID("8f36deef-c2a5-5394-99ed-8e07531fb29a"),
                    "15.0.7",
                ),
            ],
            sources = [],
            platform = Platform("x86_64", "linux"; cxxstring_abi = "cxx03", libc = "glibc", llvm_version = "15"),
            name = "default",
            treehash = "efdb3feb796715857c5582e3de68f6e97b2e03a8",
            download_sources = [
                JLLArtifactSource(
                    "https://github.com/JuliaBinaryWrappers/LLD_jll.jl/releases/download/LLD-v15.0.7+8/LLD.v15.0.7.x86_64-linux-gnu-cxx03-llvm_version+15.tar.gz",
                    "e8e972659fd6257eb309535a7c7a4c9ac9c416975ad573f914d7cb14b4498bda",
                ),
            ],
            products = [
                JLLExecutableProduct(
                    :dsymutil,
                    "tools/dsymutil",
                ),
                JLLExecutableProduct(
                    :lld,
                    "tools/lld",
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
                JLLPackageDependency(
                    "libLLVM_jll",
                    Base.UUID("8f36deef-c2a5-5394-99ed-8e07531fb29a"),
                    "15.0.7",
                ),
            ],
            sources = [],
            platform = Platform("x86_64", "linux"; cxxstring_abi = "cxx03", libc = "glibc", llvm_version = "15.asserts"),
            name = "default",
            treehash = "b91fd869e9a4b45f6ef97f8009a1af0b23f3b752",
            download_sources = [
                JLLArtifactSource(
                    "https://github.com/JuliaBinaryWrappers/LLD_jll.jl/releases/download/LLD-v15.0.7+8/LLD.v15.0.7.x86_64-linux-gnu-cxx03-llvm_version+15.asserts.tar.gz",
                    "4f679cc9ba18816576dbd6479d0dcd9977747c0b2daff636608be9f88d3a1ac0",
                ),
            ],
            products = [
                JLLExecutableProduct(
                    :dsymutil,
                    "tools/dsymutil",
                ),
                JLLExecutableProduct(
                    :lld,
                    "tools/lld",
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
                JLLPackageDependency(
                    "libLLVM_jll",
                    Base.UUID("8f36deef-c2a5-5394-99ed-8e07531fb29a"),
                    "15.0.7",
                ),
            ],
            sources = [],
            platform = Platform("x86_64", "linux"; cxxstring_abi = "cxx11", libc = "glibc", llvm_version = "15"),
            name = "default",
            treehash = "ed9436eb4a82002857605e630018092e0ed6a383",
            download_sources = [
                JLLArtifactSource(
                    "https://github.com/JuliaBinaryWrappers/LLD_jll.jl/releases/download/LLD-v15.0.7+8/LLD.v15.0.7.x86_64-linux-gnu-cxx11-llvm_version+15.tar.gz",
                    "5d3d5cc67b9ca1e91aca43376bcfcd43e2cf75856a06fcd71a4e2b0c9e8e98b4",
                ),
            ],
            products = [
                JLLExecutableProduct(
                    :dsymutil,
                    "tools/dsymutil",
                ),
                JLLExecutableProduct(
                    :lld,
                    "tools/lld",
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
                JLLPackageDependency(
                    "libLLVM_jll",
                    Base.UUID("8f36deef-c2a5-5394-99ed-8e07531fb29a"),
                    "15.0.7",
                ),
            ],
            sources = [],
            platform = Platform("x86_64", "linux"; llvm_version = "15", sanitize = "memory", libc = "glibc", cxxstring_abi = "cxx11"),
            name = "default",
            treehash = "ed9436eb4a82002857605e630018092e0ed6a383",
            download_sources = [
                JLLArtifactSource(
                    "https://github.com/JuliaBinaryWrappers/LLD_jll.jl/releases/download/LLD-v15.0.7+8/LLD.v15.0.7.x86_64-linux-gnu-cxx11-sanitize+memory-llvm_version+15.tar.gz",
                    "5d3d5cc67b9ca1e91aca43376bcfcd43e2cf75856a06fcd71a4e2b0c9e8e98b4",
                ),
            ],
            products = [
                JLLExecutableProduct(
                    :dsymutil,
                    "tools/dsymutil",
                ),
                JLLExecutableProduct(
                    :lld,
                    "tools/lld",
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
                JLLPackageDependency(
                    "libLLVM_jll",
                    Base.UUID("8f36deef-c2a5-5394-99ed-8e07531fb29a"),
                    "15.0.7",
                ),
            ],
            sources = [],
            platform = Platform("x86_64", "linux"; cxxstring_abi = "cxx11", libc = "glibc", llvm_version = "15.asserts"),
            name = "default",
            treehash = "28481a3d9e9d2ee2f07576bf762d0935ebdc8265",
            download_sources = [
                JLLArtifactSource(
                    "https://github.com/JuliaBinaryWrappers/LLD_jll.jl/releases/download/LLD-v15.0.7+8/LLD.v15.0.7.x86_64-linux-gnu-cxx11-llvm_version+15.asserts.tar.gz",
                    "fe81b207b2d2835601464112b9c053a37b33d9e7bbb2099b76291badecb17f12",
                ),
            ],
            products = [
                JLLExecutableProduct(
                    :dsymutil,
                    "tools/dsymutil",
                ),
                JLLExecutableProduct(
                    :lld,
                    "tools/lld",
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
                JLLPackageDependency(
                    "libLLVM_jll",
                    Base.UUID("8f36deef-c2a5-5394-99ed-8e07531fb29a"),
                    "15.0.7",
                ),
            ],
            sources = [],
            platform = Platform("x86_64", "linux"; llvm_version = "15.asserts", sanitize = "memory", libc = "glibc", cxxstring_abi = "cxx11"),
            name = "default",
            treehash = "28481a3d9e9d2ee2f07576bf762d0935ebdc8265",
            download_sources = [
                JLLArtifactSource(
                    "https://github.com/JuliaBinaryWrappers/LLD_jll.jl/releases/download/LLD-v15.0.7+8/LLD.v15.0.7.x86_64-linux-gnu-cxx11-sanitize+memory-llvm_version+15.asserts.tar.gz",
                    "fe81b207b2d2835601464112b9c053a37b33d9e7bbb2099b76291badecb17f12",
                ),
            ],
            products = [
                JLLExecutableProduct(
                    :dsymutil,
                    "tools/dsymutil",
                ),
                JLLExecutableProduct(
                    :lld,
                    "tools/lld",
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
                JLLPackageDependency(
                    "libLLVM_jll",
                    Base.UUID("8f36deef-c2a5-5394-99ed-8e07531fb29a"),
                    "15.0.7",
                ),
            ],
            sources = [],
            platform = Platform("x86_64", "linux"; cxxstring_abi = "cxx03", libc = "musl", llvm_version = "15"),
            name = "default",
            treehash = "29091282664fa4ddb1181d78a812f741d9b71ddd",
            download_sources = [
                JLLArtifactSource(
                    "https://github.com/JuliaBinaryWrappers/LLD_jll.jl/releases/download/LLD-v15.0.7+8/LLD.v15.0.7.x86_64-linux-musl-cxx03-llvm_version+15.tar.gz",
                    "9bcf60edf5e61992fea4b3d3d56bee7f30c9b2afd40924eab4a37a06b22fd52b",
                ),
            ],
            products = [
                JLLExecutableProduct(
                    :dsymutil,
                    "tools/dsymutil",
                ),
                JLLExecutableProduct(
                    :lld,
                    "tools/lld",
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
                JLLPackageDependency(
                    "libLLVM_jll",
                    Base.UUID("8f36deef-c2a5-5394-99ed-8e07531fb29a"),
                    "15.0.7",
                ),
            ],
            sources = [],
            platform = Platform("x86_64", "linux"; cxxstring_abi = "cxx03", libc = "musl", llvm_version = "15.asserts"),
            name = "default",
            treehash = "7bc0a2eac9e57aae7c365ef25399df689db05d8b",
            download_sources = [
                JLLArtifactSource(
                    "https://github.com/JuliaBinaryWrappers/LLD_jll.jl/releases/download/LLD-v15.0.7+8/LLD.v15.0.7.x86_64-linux-musl-cxx03-llvm_version+15.asserts.tar.gz",
                    "da4147227062995fb4915a8457effe8e8b068d017ebe61d2b8a6c31f20c73366",
                ),
            ],
            products = [
                JLLExecutableProduct(
                    :dsymutil,
                    "tools/dsymutil",
                ),
                JLLExecutableProduct(
                    :lld,
                    "tools/lld",
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
                JLLPackageDependency(
                    "libLLVM_jll",
                    Base.UUID("8f36deef-c2a5-5394-99ed-8e07531fb29a"),
                    "15.0.7",
                ),
            ],
            sources = [],
            platform = Platform("x86_64", "linux"; cxxstring_abi = "cxx11", libc = "musl", llvm_version = "15"),
            name = "default",
            treehash = "5f7844193af0c70466fe74ccf8bf9867fd70de05",
            download_sources = [
                JLLArtifactSource(
                    "https://github.com/JuliaBinaryWrappers/LLD_jll.jl/releases/download/LLD-v15.0.7+8/LLD.v15.0.7.x86_64-linux-musl-cxx11-llvm_version+15.tar.gz",
                    "56e806da21e318b3297c1fde3e5a09e2779613768b334ed7a4422491cb49494e",
                ),
            ],
            products = [
                JLLExecutableProduct(
                    :dsymutil,
                    "tools/dsymutil",
                ),
                JLLExecutableProduct(
                    :lld,
                    "tools/lld",
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
                JLLPackageDependency(
                    "libLLVM_jll",
                    Base.UUID("8f36deef-c2a5-5394-99ed-8e07531fb29a"),
                    "15.0.7",
                ),
            ],
            sources = [],
            platform = Platform("x86_64", "linux"; cxxstring_abi = "cxx11", libc = "musl", llvm_version = "15.asserts"),
            name = "default",
            treehash = "bc8bd26c38953572f770d8bb2429eb3322625ed7",
            download_sources = [
                JLLArtifactSource(
                    "https://github.com/JuliaBinaryWrappers/LLD_jll.jl/releases/download/LLD-v15.0.7+8/LLD.v15.0.7.x86_64-linux-musl-cxx11-llvm_version+15.asserts.tar.gz",
                    "4e33cea5d492fa3554e02b17a42a657cabf9c613e8cffaee182d6696a99400d9",
                ),
            ],
            products = [
                JLLExecutableProduct(
                    :dsymutil,
                    "tools/dsymutil",
                ),
                JLLExecutableProduct(
                    :lld,
                    "tools/lld",
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
                JLLPackageDependency(
                    "libLLVM_jll",
                    Base.UUID("8f36deef-c2a5-5394-99ed-8e07531fb29a"),
                    "15.0.7",
                ),
            ],
            sources = [],
            platform = Platform("x86_64", "freebsd"; llvm_version = "15"),
            name = "default",
            treehash = "3a91a387d462f6a642bc5495eabf6d4e3251d4b5",
            download_sources = [
                JLLArtifactSource(
                    "https://github.com/JuliaBinaryWrappers/LLD_jll.jl/releases/download/LLD-v15.0.7+8/LLD.v15.0.7.x86_64-unknown-freebsd-llvm_version+15.tar.gz",
                    "d669a86acb81a1e3e925980975a01d37abe0abbc5047be295f397151f3c9aeae",
                ),
            ],
            products = [
                JLLExecutableProduct(
                    :dsymutil,
                    "tools/dsymutil",
                ),
                JLLExecutableProduct(
                    :lld,
                    "tools/lld",
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
                JLLPackageDependency(
                    "libLLVM_jll",
                    Base.UUID("8f36deef-c2a5-5394-99ed-8e07531fb29a"),
                    "15.0.7",
                ),
            ],
            sources = [],
            platform = Platform("x86_64", "freebsd"; llvm_version = "15.asserts"),
            name = "default",
            treehash = "66b7a0c69e5687d98143ec495717574bbaec0026",
            download_sources = [
                JLLArtifactSource(
                    "https://github.com/JuliaBinaryWrappers/LLD_jll.jl/releases/download/LLD-v15.0.7+8/LLD.v15.0.7.x86_64-unknown-freebsd-llvm_version+15.asserts.tar.gz",
                    "80f03173abf056795e68a772ab61f63dac00d5677e387ddcfa7b8f742b7cdfc3",
                ),
            ],
            products = [
                JLLExecutableProduct(
                    :dsymutil,
                    "tools/dsymutil",
                ),
                JLLExecutableProduct(
                    :lld,
                    "tools/lld",
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
                JLLPackageDependency(
                    "libLLVM_jll",
                    Base.UUID("8f36deef-c2a5-5394-99ed-8e07531fb29a"),
                    "15.0.7",
                ),
            ],
            sources = [],
            platform = Platform("x86_64", "windows"; cxxstring_abi = "cxx03", llvm_version = "15"),
            name = "default",
            treehash = "c539fd4e39cb84cb417adcd4131892cc2b06d07c",
            download_sources = [
                JLLArtifactSource(
                    "https://github.com/JuliaBinaryWrappers/LLD_jll.jl/releases/download/LLD-v15.0.7+8/LLD.v15.0.7.x86_64-w64-mingw32-cxx03-llvm_version+15.tar.gz",
                    "a1b82d75e2abfa000d60fd49228edcda314844dd2a2f73055c7b31fa6513841b",
                ),
            ],
            products = [
                JLLExecutableProduct(
                    :dsymutil,
                    "tools\\dsymutil.exe",
                ),
                JLLExecutableProduct(
                    :lld,
                    "tools\\lld.exe",
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
                JLLPackageDependency(
                    "libLLVM_jll",
                    Base.UUID("8f36deef-c2a5-5394-99ed-8e07531fb29a"),
                    "15.0.7",
                ),
            ],
            sources = [],
            platform = Platform("x86_64", "windows"; cxxstring_abi = "cxx03", llvm_version = "15.asserts"),
            name = "default",
            treehash = "67bc8e136606e7f8f0af5a2add18429b1e50a47b",
            download_sources = [
                JLLArtifactSource(
                    "https://github.com/JuliaBinaryWrappers/LLD_jll.jl/releases/download/LLD-v15.0.7+8/LLD.v15.0.7.x86_64-w64-mingw32-cxx03-llvm_version+15.asserts.tar.gz",
                    "2382c1e34f439b8289ff016231eab6f015205ba3311cff70f45fe55734672d44",
                ),
            ],
            products = [
                JLLExecutableProduct(
                    :dsymutil,
                    "tools\\dsymutil.exe",
                ),
                JLLExecutableProduct(
                    :lld,
                    "tools\\lld.exe",
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
                JLLPackageDependency(
                    "libLLVM_jll",
                    Base.UUID("8f36deef-c2a5-5394-99ed-8e07531fb29a"),
                    "15.0.7",
                ),
            ],
            sources = [],
            platform = Platform("x86_64", "windows"; cxxstring_abi = "cxx11", llvm_version = "15"),
            name = "default",
            treehash = "133f41193bea9f166e1a723dc71cd07fad1e74da",
            download_sources = [
                JLLArtifactSource(
                    "https://github.com/JuliaBinaryWrappers/LLD_jll.jl/releases/download/LLD-v15.0.7+8/LLD.v15.0.7.x86_64-w64-mingw32-cxx11-llvm_version+15.tar.gz",
                    "bad792894f56a05e6c4a3c1d8762ab027d5a0b128883dab62dc4c867b073a3a2",
                ),
            ],
            products = [
                JLLExecutableProduct(
                    :dsymutil,
                    "tools\\dsymutil.exe",
                ),
                JLLExecutableProduct(
                    :lld,
                    "tools\\lld.exe",
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
                JLLPackageDependency(
                    "libLLVM_jll",
                    Base.UUID("8f36deef-c2a5-5394-99ed-8e07531fb29a"),
                    "15.0.7",
                ),
            ],
            sources = [],
            platform = Platform("x86_64", "windows"; cxxstring_abi = "cxx11", llvm_version = "15.asserts"),
            name = "default",
            treehash = "d0ec82bb04323c3848a58db5cd6ae197a8b911da",
            download_sources = [
                JLLArtifactSource(
                    "https://github.com/JuliaBinaryWrappers/LLD_jll.jl/releases/download/LLD-v15.0.7+8/LLD.v15.0.7.x86_64-w64-mingw32-cxx11-llvm_version+15.asserts.tar.gz",
                    "4539a53daab64af4099636a6017c09dcd0bba24d0daa362d27602d15e3901b43",
                ),
            ],
            products = [
                JLLExecutableProduct(
                    :dsymutil,
                    "tools\\dsymutil.exe",
                ),
                JLLExecutableProduct(
                    :lld,
                    "tools\\lld.exe",
                ),
            ]
        ),

    ]
)

