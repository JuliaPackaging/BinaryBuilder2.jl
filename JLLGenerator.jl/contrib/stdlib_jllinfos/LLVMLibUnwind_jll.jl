jll = JLLInfo(;
    name = "LLVMLibUnwind",
    version = v"14.0.6+0",
    artifacts = [
        JLLArtifactInfo(;
            src_version = v"14.0.6+0",
            deps = [
                JLLPackageDependency(
                    "Pkg",
                    Base.UUID("44cfe95a-1eb2-52ea-b672-e2afdf69b78f"),
                    "*",
                ),
            ],
            sources = [],
            platform = Platform("aarch64", "macos"; ),
            name = "LLVMLibUnwind",
            treehash = "d0216103f87132d78406d58b1d1c35af34d6f43e",
            download_sources = [
                JLLArtifactSource(
                    "https://github.com/JuliaBinaryWrappers/LLVMLibUnwind_jll.jl/releases/download/LLVMLibUnwind-v14.0.6+0/LLVMLibUnwind.v14.0.6.aarch64-apple-darwin.tar.gz",
                    "623dca6b7384a4958f7dde2ee92cd5949d59ae16b9dabafaa6ac42a92b07f3c1",
                ),
            ],
            products = [
                JLLLibraryProduct(
                    :libunwind,
                    "lib/libunwind.1.0.dylib",
                    [],
                    [:RTLD_LAZY, :RTLD_DEEPBIND],
                ),
            ]
        ),

        JLLArtifactInfo(;
            src_version = v"14.0.6+0",
            deps = [
                JLLPackageDependency(
                    "Pkg",
                    Base.UUID("44cfe95a-1eb2-52ea-b672-e2afdf69b78f"),
                    "*",
                ),
            ],
            sources = [],
            platform = Platform("aarch64", "linux"; libc = "glibc"),
            name = "LLVMLibUnwind",
            treehash = "80942efd32ac89fb44d6592db303e5786250d216",
            download_sources = [
                JLLArtifactSource(
                    "https://github.com/JuliaBinaryWrappers/LLVMLibUnwind_jll.jl/releases/download/LLVMLibUnwind-v14.0.6+0/LLVMLibUnwind.v14.0.6.aarch64-linux-gnu.tar.gz",
                    "6b01f55debe121b9260c7cc783499b3abd62072c06a54ccf6ceb8783584a2eef",
                ),
            ],
            products = [
                JLLLibraryProduct(
                    :libunwind,
                    "lib/libunwind.so",
                    [],
                    [:RTLD_LAZY, :RTLD_DEEPBIND],
                ),
            ]
        ),

        JLLArtifactInfo(;
            src_version = v"14.0.6+0",
            deps = [
                JLLPackageDependency(
                    "Pkg",
                    Base.UUID("44cfe95a-1eb2-52ea-b672-e2afdf69b78f"),
                    "*",
                ),
            ],
            sources = [],
            platform = Platform("aarch64", "linux"; libc = "musl"),
            name = "LLVMLibUnwind",
            treehash = "a2b1a3aee377ad14a89fcbcafc0d1976c10fc7f5",
            download_sources = [
                JLLArtifactSource(
                    "https://github.com/JuliaBinaryWrappers/LLVMLibUnwind_jll.jl/releases/download/LLVMLibUnwind-v14.0.6+0/LLVMLibUnwind.v14.0.6.aarch64-linux-musl.tar.gz",
                    "a5a3e8b622ea0f1ce82456dc61e19e8f1639ebf2e159029ecd25006d29b092a9",
                ),
            ],
            products = [
                JLLLibraryProduct(
                    :libunwind,
                    "lib/libunwind.so",
                    [],
                    [:RTLD_LAZY, :RTLD_DEEPBIND],
                ),
            ]
        ),

        JLLArtifactInfo(;
            src_version = v"14.0.6+0",
            deps = [
                JLLPackageDependency(
                    "Pkg",
                    Base.UUID("44cfe95a-1eb2-52ea-b672-e2afdf69b78f"),
                    "*",
                ),
            ],
            sources = [],
            platform = Platform("armv6l", "linux"; call_abi = "eabihf", libc = "glibc"),
            name = "LLVMLibUnwind",
            treehash = "c22e9f612be4e53c1a874cb17c205e88b9ba5b5d",
            download_sources = [
                JLLArtifactSource(
                    "https://github.com/JuliaBinaryWrappers/LLVMLibUnwind_jll.jl/releases/download/LLVMLibUnwind-v14.0.6+0/LLVMLibUnwind.v14.0.6.armv6l-linux-gnueabihf.tar.gz",
                    "03f9dbc658ca32c4eab8443858fe7bec7623489c5b8bf39a67eb19fe946da29d",
                ),
            ],
            products = [
                JLLLibraryProduct(
                    :libunwind,
                    "lib/libunwind.so",
                    [],
                    [:RTLD_LAZY, :RTLD_DEEPBIND],
                ),
            ]
        ),

        JLLArtifactInfo(;
            src_version = v"14.0.6+0",
            deps = [
                JLLPackageDependency(
                    "Pkg",
                    Base.UUID("44cfe95a-1eb2-52ea-b672-e2afdf69b78f"),
                    "*",
                ),
            ],
            sources = [],
            platform = Platform("armv6l", "linux"; call_abi = "eabihf", libc = "musl"),
            name = "LLVMLibUnwind",
            treehash = "656cd9a3355139898ca598db1e8594aba1cd0133",
            download_sources = [
                JLLArtifactSource(
                    "https://github.com/JuliaBinaryWrappers/LLVMLibUnwind_jll.jl/releases/download/LLVMLibUnwind-v14.0.6+0/LLVMLibUnwind.v14.0.6.armv6l-linux-musleabihf.tar.gz",
                    "1aad7aa6b7f02f9e4d6b261f87fb12b2e6221e10f908c75963144aa981f89e87",
                ),
            ],
            products = [
                JLLLibraryProduct(
                    :libunwind,
                    "lib/libunwind.so",
                    [],
                    [:RTLD_LAZY, :RTLD_DEEPBIND],
                ),
            ]
        ),

        JLLArtifactInfo(;
            src_version = v"14.0.6+0",
            deps = [
                JLLPackageDependency(
                    "Pkg",
                    Base.UUID("44cfe95a-1eb2-52ea-b672-e2afdf69b78f"),
                    "*",
                ),
            ],
            sources = [],
            platform = Platform("armv7l", "linux"; call_abi = "eabihf", libc = "glibc"),
            name = "LLVMLibUnwind",
            treehash = "7eea8b2abef281531503dc1236ce445d4f30487a",
            download_sources = [
                JLLArtifactSource(
                    "https://github.com/JuliaBinaryWrappers/LLVMLibUnwind_jll.jl/releases/download/LLVMLibUnwind-v14.0.6+0/LLVMLibUnwind.v14.0.6.armv7l-linux-gnueabihf.tar.gz",
                    "55e1d063c986465ed5bb763cc3a7fcd1bd81d9fb058092a801e3cb61228af2ba",
                ),
            ],
            products = [
                JLLLibraryProduct(
                    :libunwind,
                    "lib/libunwind.so",
                    [],
                    [:RTLD_LAZY, :RTLD_DEEPBIND],
                ),
            ]
        ),

        JLLArtifactInfo(;
            src_version = v"14.0.6+0",
            deps = [
                JLLPackageDependency(
                    "Pkg",
                    Base.UUID("44cfe95a-1eb2-52ea-b672-e2afdf69b78f"),
                    "*",
                ),
            ],
            sources = [],
            platform = Platform("armv7l", "linux"; call_abi = "eabihf", libc = "musl"),
            name = "LLVMLibUnwind",
            treehash = "1cb431918ee6b492fe6e2bbafd5a3ebeb379c6ea",
            download_sources = [
                JLLArtifactSource(
                    "https://github.com/JuliaBinaryWrappers/LLVMLibUnwind_jll.jl/releases/download/LLVMLibUnwind-v14.0.6+0/LLVMLibUnwind.v14.0.6.armv7l-linux-musleabihf.tar.gz",
                    "9291199959027f1d6e18b990883af49b06004df2890da6c6d2dc76e03a9ec254",
                ),
            ],
            products = [
                JLLLibraryProduct(
                    :libunwind,
                    "lib/libunwind.so",
                    [],
                    [:RTLD_LAZY, :RTLD_DEEPBIND],
                ),
            ]
        ),

        JLLArtifactInfo(;
            src_version = v"14.0.6+0",
            deps = [
                JLLPackageDependency(
                    "Pkg",
                    Base.UUID("44cfe95a-1eb2-52ea-b672-e2afdf69b78f"),
                    "*",
                ),
            ],
            sources = [],
            platform = Platform("i686", "linux"; libc = "glibc"),
            name = "LLVMLibUnwind",
            treehash = "c08099ad2c88b4ad9c6eb20751b5eb8d878d3b00",
            download_sources = [
                JLLArtifactSource(
                    "https://github.com/JuliaBinaryWrappers/LLVMLibUnwind_jll.jl/releases/download/LLVMLibUnwind-v14.0.6+0/LLVMLibUnwind.v14.0.6.i686-linux-gnu.tar.gz",
                    "daf60d3ab5660d0df86b8c178577ef9c9d25ee0619932eb073ab0a29298384c9",
                ),
            ],
            products = [
                JLLLibraryProduct(
                    :libunwind,
                    "lib/libunwind.so",
                    [],
                    [:RTLD_LAZY, :RTLD_DEEPBIND],
                ),
            ]
        ),

        JLLArtifactInfo(;
            src_version = v"14.0.6+0",
            deps = [
                JLLPackageDependency(
                    "Pkg",
                    Base.UUID("44cfe95a-1eb2-52ea-b672-e2afdf69b78f"),
                    "*",
                ),
            ],
            sources = [],
            platform = Platform("i686", "linux"; libc = "musl"),
            name = "LLVMLibUnwind",
            treehash = "0772b241cdd0460f440622baf01bae407b802563",
            download_sources = [
                JLLArtifactSource(
                    "https://github.com/JuliaBinaryWrappers/LLVMLibUnwind_jll.jl/releases/download/LLVMLibUnwind-v14.0.6+0/LLVMLibUnwind.v14.0.6.i686-linux-musl.tar.gz",
                    "865fc8c233187ce469f7509bd909ceca65f1d55861140700ccd2cc982f90dc09",
                ),
            ],
            products = [
                JLLLibraryProduct(
                    :libunwind,
                    "lib/libunwind.so",
                    [],
                    [:RTLD_LAZY, :RTLD_DEEPBIND],
                ),
            ]
        ),

        JLLArtifactInfo(;
            src_version = v"14.0.6+0",
            deps = [
                JLLPackageDependency(
                    "Pkg",
                    Base.UUID("44cfe95a-1eb2-52ea-b672-e2afdf69b78f"),
                    "*",
                ),
            ],
            sources = [],
            platform = Platform("i686", "windows"; ),
            name = "LLVMLibUnwind",
            treehash = "d4668e66f4051d7689e58b8b33da0ad5a21148e1",
            download_sources = [
                JLLArtifactSource(
                    "https://github.com/JuliaBinaryWrappers/LLVMLibUnwind_jll.jl/releases/download/LLVMLibUnwind-v14.0.6+0/LLVMLibUnwind.v14.0.6.i686-w64-mingw32.tar.gz",
                    "3973b4d440bcf83bc9c9468064fb9477fce3bfdc6a703189deb586da6a7ca37e",
                ),
            ],
            products = [
                JLLLibraryProduct(
                    :libunwind,
                    "bin\\libunwind.dll",
                    [],
                    [:RTLD_LAZY, :RTLD_DEEPBIND],
                ),
            ]
        ),

        JLLArtifactInfo(;
            src_version = v"14.0.6+0",
            deps = [
                JLLPackageDependency(
                    "Pkg",
                    Base.UUID("44cfe95a-1eb2-52ea-b672-e2afdf69b78f"),
                    "*",
                ),
            ],
            sources = [],
            platform = Platform("powerpc64le", "linux"; libc = "glibc"),
            name = "LLVMLibUnwind",
            treehash = "9a16c639c33720fcb3c65c3f7b02242c63ca8f09",
            download_sources = [
                JLLArtifactSource(
                    "https://github.com/JuliaBinaryWrappers/LLVMLibUnwind_jll.jl/releases/download/LLVMLibUnwind-v14.0.6+0/LLVMLibUnwind.v14.0.6.powerpc64le-linux-gnu.tar.gz",
                    "d451f3dd73d2402eb070272e9472d68b6d676bf3f1cf8e6757f68bc76c50224e",
                ),
            ],
            products = [
                JLLLibraryProduct(
                    :libunwind,
                    "lib/libunwind.so",
                    [],
                    [:RTLD_LAZY, :RTLD_DEEPBIND],
                ),
            ]
        ),

        JLLArtifactInfo(;
            src_version = v"14.0.6+0",
            deps = [
                JLLPackageDependency(
                    "Pkg",
                    Base.UUID("44cfe95a-1eb2-52ea-b672-e2afdf69b78f"),
                    "*",
                ),
            ],
            sources = [],
            platform = Platform("x86_64", "macos"; ),
            name = "LLVMLibUnwind",
            treehash = "bd052264e5c60cf3651bf2b8a520c127ff6fdbd0",
            download_sources = [
                JLLArtifactSource(
                    "https://github.com/JuliaBinaryWrappers/LLVMLibUnwind_jll.jl/releases/download/LLVMLibUnwind-v14.0.6+0/LLVMLibUnwind.v14.0.6.x86_64-apple-darwin.tar.gz",
                    "65ef922d46664f08266f6091d4e5231246d1d5101cacbb108af76f3e972d8c1c",
                ),
            ],
            products = [
                JLLLibraryProduct(
                    :libunwind,
                    "lib/libunwind.1.0.dylib",
                    [],
                    [:RTLD_LAZY, :RTLD_DEEPBIND],
                ),
            ]
        ),

        JLLArtifactInfo(;
            src_version = v"14.0.6+0",
            deps = [
                JLLPackageDependency(
                    "Pkg",
                    Base.UUID("44cfe95a-1eb2-52ea-b672-e2afdf69b78f"),
                    "*",
                ),
            ],
            sources = [],
            platform = Platform("x86_64", "linux"; libc = "glibc"),
            name = "LLVMLibUnwind",
            treehash = "ca3013544821c1308431b9a65703b913c8a4f27b",
            download_sources = [
                JLLArtifactSource(
                    "https://github.com/JuliaBinaryWrappers/LLVMLibUnwind_jll.jl/releases/download/LLVMLibUnwind-v14.0.6+0/LLVMLibUnwind.v14.0.6.x86_64-linux-gnu.tar.gz",
                    "453529eee9db9cae6ddf2c5ab43dc6c87550cd00863cb0e95f294f554521b8de",
                ),
            ],
            products = [
                JLLLibraryProduct(
                    :libunwind,
                    "lib/libunwind.so",
                    [],
                    [:RTLD_LAZY, :RTLD_DEEPBIND],
                ),
            ]
        ),

        JLLArtifactInfo(;
            src_version = v"14.0.6+0",
            deps = [
                JLLPackageDependency(
                    "Pkg",
                    Base.UUID("44cfe95a-1eb2-52ea-b672-e2afdf69b78f"),
                    "*",
                ),
            ],
            sources = [],
            platform = Platform("x86_64", "linux"; libc = "musl"),
            name = "LLVMLibUnwind",
            treehash = "25124ad9efa0faee47b2425ed89055f51901440b",
            download_sources = [
                JLLArtifactSource(
                    "https://github.com/JuliaBinaryWrappers/LLVMLibUnwind_jll.jl/releases/download/LLVMLibUnwind-v14.0.6+0/LLVMLibUnwind.v14.0.6.x86_64-linux-musl.tar.gz",
                    "3563bb3035f4be0e21cd94f2f757ee0624febeadcb78b7decef1dd3c8d8dedb9",
                ),
            ],
            products = [
                JLLLibraryProduct(
                    :libunwind,
                    "lib/libunwind.so",
                    [],
                    [:RTLD_LAZY, :RTLD_DEEPBIND],
                ),
            ]
        ),

        JLLArtifactInfo(;
            src_version = v"14.0.6+0",
            deps = [
                JLLPackageDependency(
                    "Pkg",
                    Base.UUID("44cfe95a-1eb2-52ea-b672-e2afdf69b78f"),
                    "*",
                ),
            ],
            sources = [],
            platform = Platform("x86_64", "freebsd"; ),
            name = "LLVMLibUnwind",
            treehash = "c2e68305ee5edaafb3e32d79be10b9acc382a8d1",
            download_sources = [
                JLLArtifactSource(
                    "https://github.com/JuliaBinaryWrappers/LLVMLibUnwind_jll.jl/releases/download/LLVMLibUnwind-v14.0.6+0/LLVMLibUnwind.v14.0.6.x86_64-unknown-freebsd.tar.gz",
                    "287a34286b7d2b80ac6f8928877568f6112c905f241eb0d4d94ef01b7cc7ca29",
                ),
            ],
            products = [
                JLLLibraryProduct(
                    :libunwind,
                    "lib/libunwind.so",
                    [],
                    [:RTLD_LAZY, :RTLD_DEEPBIND],
                ),
            ]
        ),

        JLLArtifactInfo(;
            src_version = v"14.0.6+0",
            deps = [
                JLLPackageDependency(
                    "Pkg",
                    Base.UUID("44cfe95a-1eb2-52ea-b672-e2afdf69b78f"),
                    "*",
                ),
            ],
            sources = [],
            platform = Platform("x86_64", "windows"; ),
            name = "LLVMLibUnwind",
            treehash = "99489b237f07de9ef7a860e895fc72d9bc1d4958",
            download_sources = [
                JLLArtifactSource(
                    "https://github.com/JuliaBinaryWrappers/LLVMLibUnwind_jll.jl/releases/download/LLVMLibUnwind-v14.0.6+0/LLVMLibUnwind.v14.0.6.x86_64-w64-mingw32.tar.gz",
                    "e8e6b14fe17c6d25387d4a50ab614a4699536ef5d66e7c0635a65a4e2a856742",
                ),
            ],
            products = [
                JLLLibraryProduct(
                    :libunwind,
                    "bin\\libunwind.dll",
                    [],
                    [:RTLD_LAZY, :RTLD_DEEPBIND],
                ),
            ]
        ),

    ]
)

