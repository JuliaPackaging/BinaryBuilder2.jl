jll = JLLInfo(;
    name = "MPFR",
    version = v"4.2.0+1",
    artifacts = [
        JLLArtifactInfo(;
            src_version = v"4.2.0+1",
            deps = [
                JLLPackageDependency(
                    "GMP_jll",
                    Base.UUID("781609d7-10c4-51f6-84f2-b8444358ff6d"),
                    "*",
                ),
            ],
            sources = [],
            platform = Platform("aarch64", "macos"; ),
            name = "default",
            treehash = "a9e5305df78a7d0575d091e2bb2e013a7b70f3ad",
            download_sources = [
                JLLArtifactSource(
                    "https://github.com/JuliaBinaryWrappers/MPFR_jll.jl/releases/download/MPFR-v4.2.0+1/MPFR.v4.2.0.aarch64-apple-darwin.tar.gz",
                    "a2536fde298b9af5400cadb7d499257d0684ad3e3dc1761f09606ce6032d46b4",
                ),
            ],
            products = [
                JLLLibraryProduct(
                    :libmpfr,
                    "lib/libmpfr.6.dylib",
                    [JLLLibraryDep(:GMP_jll, :libgmp)],
                    [:RTLD_LAZY, :RTLD_DEEPBIND],
                ),
            ]
        ),

        JLLArtifactInfo(;
            src_version = v"4.2.0+1",
            deps = [
                JLLPackageDependency(
                    "GMP_jll",
                    Base.UUID("781609d7-10c4-51f6-84f2-b8444358ff6d"),
                    "*",
                ),
            ],
            sources = [],
            platform = Platform("aarch64", "linux"; libc = "glibc"),
            name = "default",
            treehash = "47f064ecc33f236db4c592254286e789f14cf3e5",
            download_sources = [
                JLLArtifactSource(
                    "https://github.com/JuliaBinaryWrappers/MPFR_jll.jl/releases/download/MPFR-v4.2.0+1/MPFR.v4.2.0.aarch64-linux-gnu.tar.gz",
                    "87118c29a52fc11fffd56829a2de0298da514bbd125aaaf6a08937e666687006",
                ),
            ],
            products = [
                JLLLibraryProduct(
                    :libmpfr,
                    "lib/libmpfr.so",
                    [JLLLibraryDep(:GMP_jll, :libgmp)],
                    [:RTLD_LAZY, :RTLD_DEEPBIND],
                ),
            ]
        ),

        JLLArtifactInfo(;
            src_version = v"4.2.0+1",
            deps = [
                JLLPackageDependency(
                    "GMP_jll",
                    Base.UUID("781609d7-10c4-51f6-84f2-b8444358ff6d"),
                    "*",
                ),
            ],
            sources = [],
            platform = Platform("aarch64", "linux"; libc = "musl"),
            name = "default",
            treehash = "fc556967ee7a2ef8d4794d848647acde5d41b234",
            download_sources = [
                JLLArtifactSource(
                    "https://github.com/JuliaBinaryWrappers/MPFR_jll.jl/releases/download/MPFR-v4.2.0+1/MPFR.v4.2.0.aarch64-linux-musl.tar.gz",
                    "8dd4a734d6a869b4f92313728937b583a42775243ebf758a98aedc3722e0e54b",
                ),
            ],
            products = [
                JLLLibraryProduct(
                    :libmpfr,
                    "lib/libmpfr.so",
                    [JLLLibraryDep(:GMP_jll, :libgmp)],
                    [:RTLD_LAZY, :RTLD_DEEPBIND],
                ),
            ]
        ),

        JLLArtifactInfo(;
            src_version = v"4.2.0+1",
            deps = [
                JLLPackageDependency(
                    "GMP_jll",
                    Base.UUID("781609d7-10c4-51f6-84f2-b8444358ff6d"),
                    "*",
                ),
            ],
            sources = [],
            platform = Platform("armv6l", "linux"; call_abi = "eabihf", libc = "glibc"),
            name = "default",
            treehash = "67c2f93cab74f7680d7f1eaf8629c2001cc0ab36",
            download_sources = [
                JLLArtifactSource(
                    "https://github.com/JuliaBinaryWrappers/MPFR_jll.jl/releases/download/MPFR-v4.2.0+1/MPFR.v4.2.0.armv6l-linux-gnueabihf.tar.gz",
                    "edb4772a43f83413d875c439a5220c403dbf1892b03806a490766a58f652204c",
                ),
            ],
            products = [
                JLLLibraryProduct(
                    :libmpfr,
                    "lib/libmpfr.so",
                    [JLLLibraryDep(:GMP_jll, :libgmp)],
                    [:RTLD_LAZY, :RTLD_DEEPBIND],
                ),
            ]
        ),

        JLLArtifactInfo(;
            src_version = v"4.2.0+1",
            deps = [
                JLLPackageDependency(
                    "GMP_jll",
                    Base.UUID("781609d7-10c4-51f6-84f2-b8444358ff6d"),
                    "*",
                ),
            ],
            sources = [],
            platform = Platform("armv6l", "linux"; call_abi = "eabihf", libc = "musl"),
            name = "default",
            treehash = "ad0a98ed528b465a5c5013f18e27caba38f2eb0a",
            download_sources = [
                JLLArtifactSource(
                    "https://github.com/JuliaBinaryWrappers/MPFR_jll.jl/releases/download/MPFR-v4.2.0+1/MPFR.v4.2.0.armv6l-linux-musleabihf.tar.gz",
                    "3320b765aa8715f9db703f2bfc048367118469a600608fdb913e809aa2467342",
                ),
            ],
            products = [
                JLLLibraryProduct(
                    :libmpfr,
                    "lib/libmpfr.so",
                    [JLLLibraryDep(:GMP_jll, :libgmp)],
                    [:RTLD_LAZY, :RTLD_DEEPBIND],
                ),
            ]
        ),

        JLLArtifactInfo(;
            src_version = v"4.2.0+1",
            deps = [
                JLLPackageDependency(
                    "GMP_jll",
                    Base.UUID("781609d7-10c4-51f6-84f2-b8444358ff6d"),
                    "*",
                ),
            ],
            sources = [],
            platform = Platform("armv7l", "linux"; call_abi = "eabihf", libc = "glibc"),
            name = "default",
            treehash = "f8e115aad74210e4dff991918680367c9554fe71",
            download_sources = [
                JLLArtifactSource(
                    "https://github.com/JuliaBinaryWrappers/MPFR_jll.jl/releases/download/MPFR-v4.2.0+1/MPFR.v4.2.0.armv7l-linux-gnueabihf.tar.gz",
                    "24f64d8b974ef452ea40d61a4be7162f237d601793124e7ed0069c2771f0b435",
                ),
            ],
            products = [
                JLLLibraryProduct(
                    :libmpfr,
                    "lib/libmpfr.so",
                    [JLLLibraryDep(:GMP_jll, :libgmp)],
                    [:RTLD_LAZY, :RTLD_DEEPBIND],
                ),
            ]
        ),

        JLLArtifactInfo(;
            src_version = v"4.2.0+1",
            deps = [
                JLLPackageDependency(
                    "GMP_jll",
                    Base.UUID("781609d7-10c4-51f6-84f2-b8444358ff6d"),
                    "*",
                ),
            ],
            sources = [],
            platform = Platform("armv7l", "linux"; call_abi = "eabihf", libc = "musl"),
            name = "default",
            treehash = "33a3d7d60b635feaf0070579d39695f8c37768f5",
            download_sources = [
                JLLArtifactSource(
                    "https://github.com/JuliaBinaryWrappers/MPFR_jll.jl/releases/download/MPFR-v4.2.0+1/MPFR.v4.2.0.armv7l-linux-musleabihf.tar.gz",
                    "a7b19f14a5afa78f78d37dd5eb87cf1b0dd4ffe9f855b9efb93606ff4de4f4f0",
                ),
            ],
            products = [
                JLLLibraryProduct(
                    :libmpfr,
                    "lib/libmpfr.so",
                    [JLLLibraryDep(:GMP_jll, :libgmp)],
                    [:RTLD_LAZY, :RTLD_DEEPBIND],
                ),
            ]
        ),

        JLLArtifactInfo(;
            src_version = v"4.2.0+1",
            deps = [
                JLLPackageDependency(
                    "GMP_jll",
                    Base.UUID("781609d7-10c4-51f6-84f2-b8444358ff6d"),
                    "*",
                ),
            ],
            sources = [],
            platform = Platform("i686", "linux"; libc = "glibc"),
            name = "default",
            treehash = "9567b1aa1c6b36bd744cd4909c44a1b6e340a4d3",
            download_sources = [
                JLLArtifactSource(
                    "https://github.com/JuliaBinaryWrappers/MPFR_jll.jl/releases/download/MPFR-v4.2.0+1/MPFR.v4.2.0.i686-linux-gnu.tar.gz",
                    "fddab5df4b29468d1070fa32d6d4b1436a09973ad0873db54d1576133fb7ddb8",
                ),
            ],
            products = [
                JLLLibraryProduct(
                    :libmpfr,
                    "lib/libmpfr.so",
                    [JLLLibraryDep(:GMP_jll, :libgmp)],
                    [:RTLD_LAZY, :RTLD_DEEPBIND],
                ),
            ]
        ),

        JLLArtifactInfo(;
            src_version = v"4.2.0+1",
            deps = [
                JLLPackageDependency(
                    "GMP_jll",
                    Base.UUID("781609d7-10c4-51f6-84f2-b8444358ff6d"),
                    "*",
                ),
            ],
            sources = [],
            platform = Platform("i686", "linux"; libc = "musl"),
            name = "default",
            treehash = "87bbb044f7256bfda73754c06ac3295227943e59",
            download_sources = [
                JLLArtifactSource(
                    "https://github.com/JuliaBinaryWrappers/MPFR_jll.jl/releases/download/MPFR-v4.2.0+1/MPFR.v4.2.0.i686-linux-musl.tar.gz",
                    "0679979d89c66608ac6d10f9844f1d994b9a1f1d5c6a03959490eea391e41ccd",
                ),
            ],
            products = [
                JLLLibraryProduct(
                    :libmpfr,
                    "lib/libmpfr.so",
                    [JLLLibraryDep(:GMP_jll, :libgmp)],
                    [:RTLD_LAZY, :RTLD_DEEPBIND],
                ),
            ]
        ),

        JLLArtifactInfo(;
            src_version = v"4.2.0+1",
            deps = [
                JLLPackageDependency(
                    "GMP_jll",
                    Base.UUID("781609d7-10c4-51f6-84f2-b8444358ff6d"),
                    "*",
                ),
            ],
            sources = [],
            platform = Platform("i686", "windows"; ),
            name = "default",
            treehash = "625d68f2f50a4e97413608e737252910dce45f72",
            download_sources = [
                JLLArtifactSource(
                    "https://github.com/JuliaBinaryWrappers/MPFR_jll.jl/releases/download/MPFR-v4.2.0+1/MPFR.v4.2.0.i686-w64-mingw32.tar.gz",
                    "5b06c303690d87e5d0ae1d136a05435de5e072496d8cce28bfbed553d698be40",
                ),
            ],
            products = [
                JLLLibraryProduct(
                    :libmpfr,
                    "bin\\libmpfr-6.dll",
                    [JLLLibraryDep(:GMP_jll, :libgmp)],
                    [:RTLD_LAZY, :RTLD_DEEPBIND],
                ),
            ]
        ),

        JLLArtifactInfo(;
            src_version = v"4.2.0+1",
            deps = [
                JLLPackageDependency(
                    "GMP_jll",
                    Base.UUID("781609d7-10c4-51f6-84f2-b8444358ff6d"),
                    "*",
                ),
            ],
            sources = [],
            platform = Platform("powerpc64le", "linux"; libc = "glibc"),
            name = "default",
            treehash = "23b1bce0565ddaa718689e917e875c3260a72323",
            download_sources = [
                JLLArtifactSource(
                    "https://github.com/JuliaBinaryWrappers/MPFR_jll.jl/releases/download/MPFR-v4.2.0+1/MPFR.v4.2.0.powerpc64le-linux-gnu.tar.gz",
                    "be1b3270c1b2e3c417dbfe23b0dd70acb7c5eca493ec4122cb441514dd27c960",
                ),
            ],
            products = [
                JLLLibraryProduct(
                    :libmpfr,
                    "lib/libmpfr.so",
                    [JLLLibraryDep(:GMP_jll, :libgmp)],
                    [:RTLD_LAZY, :RTLD_DEEPBIND],
                ),
            ]
        ),

        JLLArtifactInfo(;
            src_version = v"4.2.0+1",
            deps = [
                JLLPackageDependency(
                    "GMP_jll",
                    Base.UUID("781609d7-10c4-51f6-84f2-b8444358ff6d"),
                    "*",
                ),
            ],
            sources = [],
            platform = Platform("x86_64", "macos"; ),
            name = "default",
            treehash = "8e85bb2fd10661c7c8ee2e5e1529c276d4f6674b",
            download_sources = [
                JLLArtifactSource(
                    "https://github.com/JuliaBinaryWrappers/MPFR_jll.jl/releases/download/MPFR-v4.2.0+1/MPFR.v4.2.0.x86_64-apple-darwin.tar.gz",
                    "4df77a90ebbe293f573a2013495e9a3edc4a5a43f1ec049d20bc54b98833bfa2",
                ),
            ],
            products = [
                JLLLibraryProduct(
                    :libmpfr,
                    "lib/libmpfr.6.dylib",
                    [JLLLibraryDep(:GMP_jll, :libgmp)],
                    [:RTLD_LAZY, :RTLD_DEEPBIND],
                ),
            ]
        ),

        JLLArtifactInfo(;
            src_version = v"4.2.0+1",
            deps = [
                JLLPackageDependency(
                    "GMP_jll",
                    Base.UUID("781609d7-10c4-51f6-84f2-b8444358ff6d"),
                    "*",
                ),
            ],
            sources = [],
            platform = Platform("x86_64", "linux"; libc = "glibc"),
            name = "default",
            treehash = "4cf8caed8385dd82ced6c69cd05a6458046d3ec4",
            download_sources = [
                JLLArtifactSource(
                    "https://github.com/JuliaBinaryWrappers/MPFR_jll.jl/releases/download/MPFR-v4.2.0+1/MPFR.v4.2.0.x86_64-linux-gnu.tar.gz",
                    "612de389397df50248bf882d1ca4419e20417e058986263de6cf4f4c84fdb4d1",
                ),
            ],
            products = [
                JLLLibraryProduct(
                    :libmpfr,
                    "lib/libmpfr.so",
                    [JLLLibraryDep(:GMP_jll, :libgmp)],
                    [:RTLD_LAZY, :RTLD_DEEPBIND],
                ),
            ]
        ),

        JLLArtifactInfo(;
            src_version = v"4.2.0+1",
            deps = [
                JLLPackageDependency(
                    "GMP_jll",
                    Base.UUID("781609d7-10c4-51f6-84f2-b8444358ff6d"),
                    "*",
                ),
            ],
            sources = [],
            platform = Platform("x86_64", "linux"; libc = "glibc", sanitize = "memory"),
            name = "default",
            treehash = "532f9292502576ed48e70324a923ab88c3891336",
            download_sources = [
                JLLArtifactSource(
                    "https://github.com/JuliaBinaryWrappers/MPFR_jll.jl/releases/download/MPFR-v4.2.0+1/MPFR.v4.2.0.x86_64-linux-gnu-sanitize+memory.tar.gz",
                    "64841241c72ff3a1a387231af7ab40d079da1a80671473bb29e20ab635e7af24",
                ),
            ],
            products = [
                JLLLibraryProduct(
                    :libmpfr,
                    "lib/libmpfr.so",
                    [JLLLibraryDep(:GMP_jll, :libgmp)],
                    [:RTLD_LAZY, :RTLD_DEEPBIND],
                ),
            ]
        ),

        JLLArtifactInfo(;
            src_version = v"4.2.0+1",
            deps = [
                JLLPackageDependency(
                    "GMP_jll",
                    Base.UUID("781609d7-10c4-51f6-84f2-b8444358ff6d"),
                    "*",
                ),
            ],
            sources = [],
            platform = Platform("x86_64", "linux"; libc = "musl"),
            name = "default",
            treehash = "2825bf5d82553d935ab224441f0d8129a7508aa3",
            download_sources = [
                JLLArtifactSource(
                    "https://github.com/JuliaBinaryWrappers/MPFR_jll.jl/releases/download/MPFR-v4.2.0+1/MPFR.v4.2.0.x86_64-linux-musl.tar.gz",
                    "7e436e1d9424938d20ea60078f658a8ccadbd5b640a8f16844469eef9bcf6ed2",
                ),
            ],
            products = [
                JLLLibraryProduct(
                    :libmpfr,
                    "lib/libmpfr.so",
                    [JLLLibraryDep(:GMP_jll, :libgmp)],
                    [:RTLD_LAZY, :RTLD_DEEPBIND],
                ),
            ]
        ),

        JLLArtifactInfo(;
            src_version = v"4.2.0+1",
            deps = [
                JLLPackageDependency(
                    "GMP_jll",
                    Base.UUID("781609d7-10c4-51f6-84f2-b8444358ff6d"),
                    "*",
                ),
            ],
            sources = [],
            platform = Platform("x86_64", "freebsd"; ),
            name = "default",
            treehash = "3d16350d354772b951f71f75a0c5d941d0d0ec80",
            download_sources = [
                JLLArtifactSource(
                    "https://github.com/JuliaBinaryWrappers/MPFR_jll.jl/releases/download/MPFR-v4.2.0+1/MPFR.v4.2.0.x86_64-unknown-freebsd.tar.gz",
                    "a5f3e3bd442dfe188abcb8201cc29219908e139e2935837e86d6a55ae64e6514",
                ),
            ],
            products = [
                JLLLibraryProduct(
                    :libmpfr,
                    "lib/libmpfr.so",
                    [JLLLibraryDep(:GMP_jll, :libgmp)],
                    [:RTLD_LAZY, :RTLD_DEEPBIND],
                ),
            ]
        ),

        JLLArtifactInfo(;
            src_version = v"4.2.0+1",
            deps = [
                JLLPackageDependency(
                    "GMP_jll",
                    Base.UUID("781609d7-10c4-51f6-84f2-b8444358ff6d"),
                    "*",
                ),
            ],
            sources = [],
            platform = Platform("x86_64", "windows"; ),
            name = "default",
            treehash = "fed2debf51bf67947940940f940f4a55cfe94744",
            download_sources = [
                JLLArtifactSource(
                    "https://github.com/JuliaBinaryWrappers/MPFR_jll.jl/releases/download/MPFR-v4.2.0+1/MPFR.v4.2.0.x86_64-w64-mingw32.tar.gz",
                    "3dc31357c994a7bbe4076c130e5f60aba1bfac0a32e789db404b44ed8cb2defa",
                ),
            ],
            products = [
                JLLLibraryProduct(
                    :libmpfr,
                    "bin\\libmpfr-6.dll",
                    [JLLLibraryDep(:GMP_jll, :libgmp)],
                    [:RTLD_LAZY, :RTLD_DEEPBIND],
                ),
            ]
        ),

    ]
)

