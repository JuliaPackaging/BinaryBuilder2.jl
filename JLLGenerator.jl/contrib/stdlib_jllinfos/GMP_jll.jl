jll = JLLInfo(;
    name = "GMP",
    version = v"6.2.1+5",
    artifacts = [
        JLLArtifactInfo(;
            src_version = v"6.2.1+5",
            deps = [],
            sources = [],
            platform = Platform("aarch64", "macos"; ),
            name = "default",
            treehash = "eb4e87c9b0a79957edcf050a5a9c13d6e99eb80d",
            download_sources = [
                JLLArtifactSource(
                    "https://github.com/JuliaBinaryWrappers/GMP_jll.jl/releases/download/GMP-v6.2.1+5/GMP.v6.2.1.aarch64-apple-darwin.tar.gz",
                    "0ad178f4af6d1e29f1fa53125cd7b56d2153a38af7dbb87f97f8cdc4334f3b72",
                ),
            ],
            products = [
                JLLLibraryProduct(
                    :libgmp,
                    "lib/libgmp.10.dylib",
                    [],
                    flags = [:RTLD_LAZY, :RTLD_DEEPBIND],
                ),
                JLLLibraryProduct(
                    :libgmpxx,
                    "lib/libgmpxx.4.dylib",
                    [
                        JLLLibraryDep(nothing, :libgmp),
                    ],
                    flags = [:RTLD_LAZY, :RTLD_DEEPBIND],
                ),
            ]
        ),

        JLLArtifactInfo(;
            src_version = v"6.2.1+5",
            deps = [],
            sources = [],
            platform = Platform("aarch64", "linux"; libc = "glibc", cxxstring_abi = "cxx03"),
            name = "default",
            treehash = "438763d0a0d11ca36b300e9324b99a83b725adf9",
            download_sources = [
                JLLArtifactSource(
                    "https://github.com/JuliaBinaryWrappers/GMP_jll.jl/releases/download/GMP-v6.2.1+5/GMP.v6.2.1.aarch64-linux-gnu-cxx03.tar.gz",
                    "1d317eb5aa6a0872f807c7f3a5bac141cfc607c6e5b20806c668983199f81e90",
                ),
            ],
            products = [
                JLLLibraryProduct(
                    :libgmp,
                    "lib/libgmp.so",
                    [],
                    flags = [:RTLD_LAZY, :RTLD_DEEPBIND],
                ),
                JLLLibraryProduct(
                    :libgmpxx,
                    "lib/libgmpxx.so",
                    [
                        JLLLibraryDep(nothing, :libgmp),
                    ],
                    flags = [:RTLD_LAZY, :RTLD_DEEPBIND],
                ),
            ]
        ),

        JLLArtifactInfo(;
            src_version = v"6.2.1+5",
            deps = [],
            sources = [],
            platform = Platform("aarch64", "linux"; libc = "glibc", cxxstring_abi = "cxx11"),
            name = "default",
            treehash = "b804693dba33bda298f5f890b9afd2600db2f546",
            download_sources = [
                JLLArtifactSource(
                    "https://github.com/JuliaBinaryWrappers/GMP_jll.jl/releases/download/GMP-v6.2.1+5/GMP.v6.2.1.aarch64-linux-gnu-cxx11.tar.gz",
                    "fcd9aba37abb579427b39d41f50f0175dff087edd12be81c4251592422f1f3c9",
                ),
            ],
            products = [
                JLLLibraryProduct(
                    :libgmp,
                    "lib/libgmp.so",
                    [],
                    flags = [:RTLD_LAZY, :RTLD_DEEPBIND],
                ),
                JLLLibraryProduct(
                    :libgmpxx,
                    "lib/libgmpxx.so",
                    [
                        JLLLibraryDep(nothing, :libgmp),
                    ],
                    flags = [:RTLD_LAZY, :RTLD_DEEPBIND],
                ),
            ]
        ),

        JLLArtifactInfo(;
            src_version = v"6.2.1+5",
            deps = [],
            sources = [],
            platform = Platform("aarch64", "linux"; libc = "musl", cxxstring_abi = "cxx03"),
            name = "default",
            treehash = "69310c54157613a7e35c8e6d4938d5600cbf3048",
            download_sources = [
                JLLArtifactSource(
                    "https://github.com/JuliaBinaryWrappers/GMP_jll.jl/releases/download/GMP-v6.2.1+5/GMP.v6.2.1.aarch64-linux-musl-cxx03.tar.gz",
                    "b90f4d3a7546ffd437440c2eda91e031aaaaecb280c11d0a619130801aa29fad",
                ),
            ],
            products = [
                JLLLibraryProduct(
                    :libgmp,
                    "lib/libgmp.so",
                    [],
                    flags = [:RTLD_LAZY, :RTLD_DEEPBIND],
                ),
                JLLLibraryProduct(
                    :libgmpxx,
                    "lib/libgmpxx.so",
                    [
                        JLLLibraryDep(nothing, :libgmp),
                    ],
                    flags = [:RTLD_LAZY, :RTLD_DEEPBIND],
                ),
            ]
        ),

        JLLArtifactInfo(;
            src_version = v"6.2.1+5",
            deps = [],
            sources = [],
            platform = Platform("aarch64", "linux"; libc = "musl", cxxstring_abi = "cxx11"),
            name = "default",
            treehash = "3eee3abb987916d9c01ca5fbe64ab199f53ddb84",
            download_sources = [
                JLLArtifactSource(
                    "https://github.com/JuliaBinaryWrappers/GMP_jll.jl/releases/download/GMP-v6.2.1+5/GMP.v6.2.1.aarch64-linux-musl-cxx11.tar.gz",
                    "b4ab45e7b07b99e3adec944382d66ebc7a19973fd291696c076be8409e7d9c81",
                ),
            ],
            products = [
                JLLLibraryProduct(
                    :libgmp,
                    "lib/libgmp.so",
                    [],
                    flags = [:RTLD_LAZY, :RTLD_DEEPBIND],
                ),
                JLLLibraryProduct(
                    :libgmpxx,
                    "lib/libgmpxx.so",
                    [
                        JLLLibraryDep(nothing, :libgmp),
                    ],
                    flags = [:RTLD_LAZY, :RTLD_DEEPBIND],
                ),
            ]
        ),

        JLLArtifactInfo(;
            src_version = v"6.2.1+5",
            deps = [],
            sources = [],
            platform = Platform("armv6l", "linux"; call_abi = "eabihf", libc = "glibc", cxxstring_abi = "cxx03"),
            name = "default",
            treehash = "5b3aa03ec084ff4dfbb487627747ef8e07db7db7",
            download_sources = [
                JLLArtifactSource(
                    "https://github.com/JuliaBinaryWrappers/GMP_jll.jl/releases/download/GMP-v6.2.1+5/GMP.v6.2.1.armv6l-linux-gnueabihf-cxx03.tar.gz",
                    "b72e9e7ce28eae4e9c4888a6b98627a74cb9fc7252c9807e516868b0163d05dc",
                ),
            ],
            products = [
                JLLLibraryProduct(
                    :libgmp,
                    "lib/libgmp.so",
                    [],
                    flags = [:RTLD_LAZY, :RTLD_DEEPBIND],
                ),
                JLLLibraryProduct(
                    :libgmpxx,
                    "lib/libgmpxx.so",
                    [
                        JLLLibraryDep(nothing, :libgmp),
                    ],
                    flags = [:RTLD_LAZY, :RTLD_DEEPBIND],
                ),
            ]
        ),

        JLLArtifactInfo(;
            src_version = v"6.2.1+5",
            deps = [],
            sources = [],
            platform = Platform("armv6l", "linux"; call_abi = "eabihf", libc = "glibc", cxxstring_abi = "cxx11"),
            name = "default",
            treehash = "846ff0fe875c1ed45b4aef5b97cbe2cf860daa3a",
            download_sources = [
                JLLArtifactSource(
                    "https://github.com/JuliaBinaryWrappers/GMP_jll.jl/releases/download/GMP-v6.2.1+5/GMP.v6.2.1.armv6l-linux-gnueabihf-cxx11.tar.gz",
                    "72f85534c35197adf85ca817264f8ac87ccef13a6f20e8c12c881c44ee89e098",
                ),
            ],
            products = [
                JLLLibraryProduct(
                    :libgmp,
                    "lib/libgmp.so",
                    [],
                    flags = [:RTLD_LAZY, :RTLD_DEEPBIND],
                ),
                JLLLibraryProduct(
                    :libgmpxx,
                    "lib/libgmpxx.so",
                    [
                        JLLLibraryDep(nothing, :libgmp),
                    ],
                    flags = [:RTLD_LAZY, :RTLD_DEEPBIND],
                ),
            ]
        ),

        JLLArtifactInfo(;
            src_version = v"6.2.1+5",
            deps = [],
            sources = [],
            platform = Platform("armv6l", "linux"; call_abi = "eabihf", libc = "musl", cxxstring_abi = "cxx03"),
            name = "default",
            treehash = "96708d222bc7767b241604a35fa6358bc38c2938",
            download_sources = [
                JLLArtifactSource(
                    "https://github.com/JuliaBinaryWrappers/GMP_jll.jl/releases/download/GMP-v6.2.1+5/GMP.v6.2.1.armv6l-linux-musleabihf-cxx03.tar.gz",
                    "24ecf1cca679e385dbd84a69e00975a7e4c19110693fab9e91e7a6991a6fccf4",
                ),
            ],
            products = [
                JLLLibraryProduct(
                    :libgmp,
                    "lib/libgmp.so",
                    [],
                    flags = [:RTLD_LAZY, :RTLD_DEEPBIND],
                ),
                JLLLibraryProduct(
                    :libgmpxx,
                    "lib/libgmpxx.so",
                    [
                        JLLLibraryDep(nothing, :libgmp),
                    ],
                    flags = [:RTLD_LAZY, :RTLD_DEEPBIND],
                ),
            ]
        ),

        JLLArtifactInfo(;
            src_version = v"6.2.1+5",
            deps = [],
            sources = [],
            platform = Platform("armv6l", "linux"; call_abi = "eabihf", libc = "musl", cxxstring_abi = "cxx11"),
            name = "default",
            treehash = "ca5e84c59416facfe091b21c9773aad771f7d27d",
            download_sources = [
                JLLArtifactSource(
                    "https://github.com/JuliaBinaryWrappers/GMP_jll.jl/releases/download/GMP-v6.2.1+5/GMP.v6.2.1.armv6l-linux-musleabihf-cxx11.tar.gz",
                    "7463fdd77d169bbc2563ddd28feff22faf4b73e3415ee0ec91f3f783f0bb4f44",
                ),
            ],
            products = [
                JLLLibraryProduct(
                    :libgmp,
                    "lib/libgmp.so",
                    [],
                    flags = [:RTLD_LAZY, :RTLD_DEEPBIND],
                ),
                JLLLibraryProduct(
                    :libgmpxx,
                    "lib/libgmpxx.so",
                    [
                        JLLLibraryDep(nothing, :libgmp),
                    ],
                    flags = [:RTLD_LAZY, :RTLD_DEEPBIND],
                ),
            ]
        ),

        JLLArtifactInfo(;
            src_version = v"6.2.1+5",
            deps = [],
            sources = [],
            platform = Platform("armv7l", "linux"; call_abi = "eabihf", libc = "glibc", cxxstring_abi = "cxx03"),
            name = "default",
            treehash = "d50ce369d4ccdb62f7a8b28141026e4481119cb4",
            download_sources = [
                JLLArtifactSource(
                    "https://github.com/JuliaBinaryWrappers/GMP_jll.jl/releases/download/GMP-v6.2.1+5/GMP.v6.2.1.armv7l-linux-gnueabihf-cxx03.tar.gz",
                    "77fc26147536c31c4baef1fc0300eb6092ae8b98f1c9875c7ceb7ddfc6f51041",
                ),
            ],
            products = [
                JLLLibraryProduct(
                    :libgmp,
                    "lib/libgmp.so",
                    [],
                    flags = [:RTLD_LAZY, :RTLD_DEEPBIND],
                ),
                JLLLibraryProduct(
                    :libgmpxx,
                    "lib/libgmpxx.so",
                    [
                        JLLLibraryDep(nothing, :libgmp),
                    ],
                    flags = [:RTLD_LAZY, :RTLD_DEEPBIND],
                ),
            ]
        ),

        JLLArtifactInfo(;
            src_version = v"6.2.1+5",
            deps = [],
            sources = [],
            platform = Platform("armv7l", "linux"; call_abi = "eabihf", libc = "glibc", cxxstring_abi = "cxx11"),
            name = "default",
            treehash = "fa620d4b95fef06716ded7eb77525ce0420da3ab",
            download_sources = [
                JLLArtifactSource(
                    "https://github.com/JuliaBinaryWrappers/GMP_jll.jl/releases/download/GMP-v6.2.1+5/GMP.v6.2.1.armv7l-linux-gnueabihf-cxx11.tar.gz",
                    "9ef7fddb5fc28f9155b61b2dc21fde987e4783f9269b93e1de45bcb5cd18939f",
                ),
            ],
            products = [
                JLLLibraryProduct(
                    :libgmp,
                    "lib/libgmp.so",
                    [],
                    flags = [:RTLD_LAZY, :RTLD_DEEPBIND],
                ),
                JLLLibraryProduct(
                    :libgmpxx,
                    "lib/libgmpxx.so",
                    [
                        JLLLibraryDep(nothing, :libgmp),
                    ],
                    flags = [:RTLD_LAZY, :RTLD_DEEPBIND],
                ),
            ]
        ),

        JLLArtifactInfo(;
            src_version = v"6.2.1+5",
            deps = [],
            sources = [],
            platform = Platform("armv7l", "linux"; call_abi = "eabihf", libc = "musl", cxxstring_abi = "cxx03"),
            name = "default",
            treehash = "7977ae5c0f69de7f00f380c43c96c7e0881890f2",
            download_sources = [
                JLLArtifactSource(
                    "https://github.com/JuliaBinaryWrappers/GMP_jll.jl/releases/download/GMP-v6.2.1+5/GMP.v6.2.1.armv7l-linux-musleabihf-cxx03.tar.gz",
                    "fc6a924b508a45b9a8029b87905749c5d4c62c114de26d2c413cb948ba6d61eb",
                ),
            ],
            products = [
                JLLLibraryProduct(
                    :libgmp,
                    "lib/libgmp.so",
                    [],
                    flags = [:RTLD_LAZY, :RTLD_DEEPBIND],
                ),
                JLLLibraryProduct(
                    :libgmpxx,
                    "lib/libgmpxx.so",
                    [
                        JLLLibraryDep(nothing, :libgmp),
                    ],
                    flags = [:RTLD_LAZY, :RTLD_DEEPBIND],
                ),
            ]
        ),

        JLLArtifactInfo(;
            src_version = v"6.2.1+5",
            deps = [],
            sources = [],
            platform = Platform("armv7l", "linux"; call_abi = "eabihf", libc = "musl", cxxstring_abi = "cxx11"),
            name = "default",
            treehash = "4e6dc5c976cadcb5f20848e2b71e09da43d4506d",
            download_sources = [
                JLLArtifactSource(
                    "https://github.com/JuliaBinaryWrappers/GMP_jll.jl/releases/download/GMP-v6.2.1+5/GMP.v6.2.1.armv7l-linux-musleabihf-cxx11.tar.gz",
                    "b70b4940a0c7c3c2efd97da5eadf824a90d59e0aaba61699b5b478d2b290144a",
                ),
            ],
            products = [
                JLLLibraryProduct(
                    :libgmp,
                    "lib/libgmp.so",
                    [],
                    flags = [:RTLD_LAZY, :RTLD_DEEPBIND],
                ),
                JLLLibraryProduct(
                    :libgmpxx,
                    "lib/libgmpxx.so",
                    [
                        JLLLibraryDep(nothing, :libgmp),
                    ],
                    flags = [:RTLD_LAZY, :RTLD_DEEPBIND],
                ),
            ]
        ),

        JLLArtifactInfo(;
            src_version = v"6.2.1+5",
            deps = [],
            sources = [],
            platform = Platform("i686", "linux"; libc = "glibc", cxxstring_abi = "cxx03"),
            name = "default",
            treehash = "5ff7794165d9cc3bfad4852581d1fea1d992f942",
            download_sources = [
                JLLArtifactSource(
                    "https://github.com/JuliaBinaryWrappers/GMP_jll.jl/releases/download/GMP-v6.2.1+5/GMP.v6.2.1.i686-linux-gnu-cxx03.tar.gz",
                    "9832fd124db5eae1172d107b93510901b764dae189f7718fe0f1050bd2810689",
                ),
            ],
            products = [
                JLLLibraryProduct(
                    :libgmp,
                    "lib/libgmp.so",
                    [],
                    flags = [:RTLD_LAZY, :RTLD_DEEPBIND],
                ),
                JLLLibraryProduct(
                    :libgmpxx,
                    "lib/libgmpxx.so",
                    [
                        JLLLibraryDep(nothing, :libgmp),
                    ],
                    flags = [:RTLD_LAZY, :RTLD_DEEPBIND],
                ),
            ]
        ),

        JLLArtifactInfo(;
            src_version = v"6.2.1+5",
            deps = [],
            sources = [],
            platform = Platform("i686", "linux"; libc = "glibc", cxxstring_abi = "cxx11"),
            name = "default",
            treehash = "5764e6ba028d2f7e71d620a9ab6b1452bd451769",
            download_sources = [
                JLLArtifactSource(
                    "https://github.com/JuliaBinaryWrappers/GMP_jll.jl/releases/download/GMP-v6.2.1+5/GMP.v6.2.1.i686-linux-gnu-cxx11.tar.gz",
                    "c500188b6feae7715d17f36bb40a453d47f3da7bba2601c27cb59abbc1014f3f",
                ),
            ],
            products = [
                JLLLibraryProduct(
                    :libgmp,
                    "lib/libgmp.so",
                    [],
                    flags = [:RTLD_LAZY, :RTLD_DEEPBIND],
                ),
                JLLLibraryProduct(
                    :libgmpxx,
                    "lib/libgmpxx.so",
                    [
                        JLLLibraryDep(nothing, :libgmp),
                    ],
                    flags = [:RTLD_LAZY, :RTLD_DEEPBIND],
                ),
            ]
        ),

        JLLArtifactInfo(;
            src_version = v"6.2.1+5",
            deps = [],
            sources = [],
            platform = Platform("i686", "linux"; libc = "musl", cxxstring_abi = "cxx03"),
            name = "default",
            treehash = "053386407a38904d54936c7c3b8a6cf8491897d5",
            download_sources = [
                JLLArtifactSource(
                    "https://github.com/JuliaBinaryWrappers/GMP_jll.jl/releases/download/GMP-v6.2.1+5/GMP.v6.2.1.i686-linux-musl-cxx03.tar.gz",
                    "39fcf9f4ccf3ed3747c33652dac886f946c4e2c1806b99f0b6896df9482bb51f",
                ),
            ],
            products = [
                JLLLibraryProduct(
                    :libgmp,
                    "lib/libgmp.so",
                    [],
                    flags = [:RTLD_LAZY, :RTLD_DEEPBIND],
                ),
                JLLLibraryProduct(
                    :libgmpxx,
                    "lib/libgmpxx.so",
                    [
                        JLLLibraryDep(nothing, :libgmp),
                    ],
                    flags = [:RTLD_LAZY, :RTLD_DEEPBIND],
                ),
            ]
        ),

        JLLArtifactInfo(;
            src_version = v"6.2.1+5",
            deps = [],
            sources = [],
            platform = Platform("i686", "linux"; libc = "musl", cxxstring_abi = "cxx11"),
            name = "default",
            treehash = "2ddf6cc79ec510c42671f8adcbf61139c34b84c2",
            download_sources = [
                JLLArtifactSource(
                    "https://github.com/JuliaBinaryWrappers/GMP_jll.jl/releases/download/GMP-v6.2.1+5/GMP.v6.2.1.i686-linux-musl-cxx11.tar.gz",
                    "8af93d3c18e0ecb7eda27b534ddf5e21f7dfc84e677e7492312fbc7ec6d9175b",
                ),
            ],
            products = [
                JLLLibraryProduct(
                    :libgmp,
                    "lib/libgmp.so",
                    [],
                    flags = [:RTLD_LAZY, :RTLD_DEEPBIND],
                ),
                JLLLibraryProduct(
                    :libgmpxx,
                    "lib/libgmpxx.so",
                    [
                        JLLLibraryDep(nothing, :libgmp),
                    ],
                    flags = [:RTLD_LAZY, :RTLD_DEEPBIND],
                ),
            ]
        ),

        JLLArtifactInfo(;
            src_version = v"6.2.1+5",
            deps = [],
            sources = [],
            platform = Platform("i686", "windows"; cxxstring_abi = "cxx03"),
            name = "default",
            treehash = "ace373985e36ec8a51a2e4b6f619e72c39b001a4",
            download_sources = [
                JLLArtifactSource(
                    "https://github.com/JuliaBinaryWrappers/GMP_jll.jl/releases/download/GMP-v6.2.1+5/GMP.v6.2.1.i686-w64-mingw32-cxx03.tar.gz",
                    "c71f854daac4d1bbaa3118d952a81bb8e81d8e0b5efda87956cf6d8939162386",
                ),
            ],
            products = [
                JLLLibraryProduct(
                    :libgmp,
                    "bin\\libgmp-10.dll",
                    [],
                    flags = [:RTLD_LAZY, :RTLD_DEEPBIND],
                ),
                JLLLibraryProduct(
                    :libgmpxx,
                    "bin\\libgmpxx-4.dll",
                    [
                        JLLLibraryDep(nothing, :libgmp),
                    ],
                    flags = [:RTLD_LAZY, :RTLD_DEEPBIND],
                ),
            ]
        ),

        JLLArtifactInfo(;
            src_version = v"6.2.1+5",
            deps = [],
            sources = [],
            platform = Platform("i686", "windows"; cxxstring_abi = "cxx11"),
            name = "default",
            treehash = "f255f36847608dd123fe2747f01143128b5cab0d",
            download_sources = [
                JLLArtifactSource(
                    "https://github.com/JuliaBinaryWrappers/GMP_jll.jl/releases/download/GMP-v6.2.1+5/GMP.v6.2.1.i686-w64-mingw32-cxx11.tar.gz",
                    "2e1ea4b07186105b1a18adc5b1d8a351045fbebbd0a28f3c7e2041827a3af18f",
                ),
            ],
            products = [
                JLLLibraryProduct(
                    :libgmp,
                    "bin\\libgmp-10.dll",
                    [],
                    flags = [:RTLD_LAZY, :RTLD_DEEPBIND],
                ),
                JLLLibraryProduct(
                    :libgmpxx,
                    "bin\\libgmpxx-4.dll",
                    [
                        JLLLibraryDep(nothing, :libgmp),
                    ],
                    flags = [:RTLD_LAZY, :RTLD_DEEPBIND],
                ),
            ]
        ),

        JLLArtifactInfo(;
            src_version = v"6.2.1+5",
            deps = [],
            sources = [],
            platform = Platform("powerpc64le", "linux"; libc = "glibc", cxxstring_abi = "cxx03"),
            name = "default",
            treehash = "286e61e5d87b6efe1efd030878cc6d0c138c27b0",
            download_sources = [
                JLLArtifactSource(
                    "https://github.com/JuliaBinaryWrappers/GMP_jll.jl/releases/download/GMP-v6.2.1+5/GMP.v6.2.1.powerpc64le-linux-gnu-cxx03.tar.gz",
                    "b1f7536f0045a7db5cf2bbb6434b809a57d18e58b8aa36aac53b4a217f9f35fe",
                ),
            ],
            products = [
                JLLLibraryProduct(
                    :libgmp,
                    "lib/libgmp.so",
                    [],
                    flags = [:RTLD_LAZY, :RTLD_DEEPBIND],
                ),
                JLLLibraryProduct(
                    :libgmpxx,
                    "lib/libgmpxx.so",
                    [
                        JLLLibraryDep(nothing, :libgmp),
                    ],
                    flags = [:RTLD_LAZY, :RTLD_DEEPBIND],
                ),
            ]
        ),

        JLLArtifactInfo(;
            src_version = v"6.2.1+5",
            deps = [],
            sources = [],
            platform = Platform("powerpc64le", "linux"; libc = "glibc", cxxstring_abi = "cxx11"),
            name = "default",
            treehash = "c5cc9a7333a41bf9565cb58decf34c5778a832b2",
            download_sources = [
                JLLArtifactSource(
                    "https://github.com/JuliaBinaryWrappers/GMP_jll.jl/releases/download/GMP-v6.2.1+5/GMP.v6.2.1.powerpc64le-linux-gnu-cxx11.tar.gz",
                    "61b870a74f9c407b30ac82f06e9c52cded18eefb5cca54d725d7c0f312784166",
                ),
            ],
            products = [
                JLLLibraryProduct(
                    :libgmp,
                    "lib/libgmp.so",
                    [],
                    flags = [:RTLD_LAZY, :RTLD_DEEPBIND],
                ),
                JLLLibraryProduct(
                    :libgmpxx,
                    "lib/libgmpxx.so",
                    [
                        JLLLibraryDep(nothing, :libgmp),
                    ],
                    flags = [:RTLD_LAZY, :RTLD_DEEPBIND],
                ),
            ]
        ),

        JLLArtifactInfo(;
            src_version = v"6.2.1+5",
            deps = [],
            sources = [],
            platform = Platform("x86_64", "macos"; ),
            name = "default",
            treehash = "582081ef2cdfcbcec8bf7993fc25e110256424e4",
            download_sources = [
                JLLArtifactSource(
                    "https://github.com/JuliaBinaryWrappers/GMP_jll.jl/releases/download/GMP-v6.2.1+5/GMP.v6.2.1.x86_64-apple-darwin.tar.gz",
                    "0a940ce1bac4bba0c0bf4da4974e6f411ab9b33533f27f1d275414d5c37b348d",
                ),
            ],
            products = [
                JLLLibraryProduct(
                    :libgmp,
                    "lib/libgmp.10.dylib",
                    [],
                    flags = [:RTLD_LAZY, :RTLD_DEEPBIND],
                ),
                JLLLibraryProduct(
                    :libgmpxx,
                    "lib/libgmpxx.4.dylib",
                    [
                        JLLLibraryDep(nothing, :libgmp),
                    ],
                    flags = [:RTLD_LAZY, :RTLD_DEEPBIND],
                ),
            ]
        ),

        JLLArtifactInfo(;
            src_version = v"6.2.1+5",
            deps = [],
            sources = [],
            platform = Platform("x86_64", "linux"; libc = "glibc", cxxstring_abi = "cxx03"),
            name = "default",
            treehash = "adce8608805da098504a2d74d1cb3fb2877b53d8",
            download_sources = [
                JLLArtifactSource(
                    "https://github.com/JuliaBinaryWrappers/GMP_jll.jl/releases/download/GMP-v6.2.1+5/GMP.v6.2.1.x86_64-linux-gnu-cxx03.tar.gz",
                    "924a468a16f5f1d6bada463afb6481f6e2c9834e90deed0d088d688745c932d6",
                ),
            ],
            products = [
                JLLLibraryProduct(
                    :libgmp,
                    "lib/libgmp.so",
                    [],
                    flags = [:RTLD_LAZY, :RTLD_DEEPBIND],
                ),
                JLLLibraryProduct(
                    :libgmpxx,
                    "lib/libgmpxx.so",
                    [
                        JLLLibraryDep(nothing, :libgmp),
                    ],
                    flags = [:RTLD_LAZY, :RTLD_DEEPBIND],
                ),
            ]
        ),

        JLLArtifactInfo(;
            src_version = v"6.2.1+5",
            deps = [],
            sources = [],
            platform = Platform("x86_64", "linux"; libc = "glibc", cxxstring_abi = "cxx11"),
            name = "default",
            treehash = "a6912b17607ad3f04f3faaab3e3918181ffca515",
            download_sources = [
                JLLArtifactSource(
                    "https://github.com/JuliaBinaryWrappers/GMP_jll.jl/releases/download/GMP-v6.2.1+5/GMP.v6.2.1.x86_64-linux-gnu-cxx11.tar.gz",
                    "8eb67597ce901a462f7acfb634ef7fe7433011e80b8886139bf2549c3ba624a0",
                ),
            ],
            products = [
                JLLLibraryProduct(
                    :libgmp,
                    "lib/libgmp.so",
                    [],
                    flags = [:RTLD_LAZY, :RTLD_DEEPBIND],
                ),
                JLLLibraryProduct(
                    :libgmpxx,
                    "lib/libgmpxx.so",
                    [
                        JLLLibraryDep(nothing, :libgmp),
                    ],
                    flags = [:RTLD_LAZY, :RTLD_DEEPBIND],
                ),
            ]
        ),

        JLLArtifactInfo(;
            src_version = v"6.2.1+5",
            deps = [],
            sources = [],
            platform = Platform("x86_64", "linux"; sanitize = "memory", libc = "glibc", cxxstring_abi = "cxx11"),
            name = "default",
            treehash = "25e21b2dd3faf6b48c812e4d06dc8ba52404be08",
            download_sources = [
                JLLArtifactSource(
                    "https://github.com/JuliaBinaryWrappers/GMP_jll.jl/releases/download/GMP-v6.2.1+5/GMP.v6.2.1.x86_64-linux-gnu-cxx11-sanitize+memory.tar.gz",
                    "73594c84194047f9e58bc577bd58abd252b52b56c9f1759c916ab4f49ee14888",
                ),
            ],
            products = [
                JLLLibraryProduct(
                    :libgmp,
                    "lib/libgmp.so",
                    [],
                    flags = [:RTLD_LAZY, :RTLD_DEEPBIND],
                ),
                JLLLibraryProduct(
                    :libgmpxx,
                    "lib/libgmpxx.so",
                    [
                        JLLLibraryDep(nothing, :libgmp),
                    ],
                    flags = [:RTLD_LAZY, :RTLD_DEEPBIND],
                ),
            ]
        ),

        JLLArtifactInfo(;
            src_version = v"6.2.1+5",
            deps = [],
            sources = [],
            platform = Platform("x86_64", "linux"; libc = "musl", cxxstring_abi = "cxx03"),
            name = "default",
            treehash = "ec6aa9d7df206de06280addabe495b32b11b0c24",
            download_sources = [
                JLLArtifactSource(
                    "https://github.com/JuliaBinaryWrappers/GMP_jll.jl/releases/download/GMP-v6.2.1+5/GMP.v6.2.1.x86_64-linux-musl-cxx03.tar.gz",
                    "c960e056377bf1d0329140f287fc7844d63746380d674b0eb4c5936690215145",
                ),
            ],
            products = [
                JLLLibraryProduct(
                    :libgmp,
                    "lib/libgmp.so",
                    [],
                    flags = [:RTLD_LAZY, :RTLD_DEEPBIND],
                ),
                JLLLibraryProduct(
                    :libgmpxx,
                    "lib/libgmpxx.so",
                    [
                        JLLLibraryDep(nothing, :libgmp),
                    ],
                    flags = [:RTLD_LAZY, :RTLD_DEEPBIND],
                ),
            ]
        ),

        JLLArtifactInfo(;
            src_version = v"6.2.1+5",
            deps = [],
            sources = [],
            platform = Platform("x86_64", "linux"; libc = "musl", cxxstring_abi = "cxx11"),
            name = "default",
            treehash = "ca6965c5231c6d53948d281bc937aea24c88d626",
            download_sources = [
                JLLArtifactSource(
                    "https://github.com/JuliaBinaryWrappers/GMP_jll.jl/releases/download/GMP-v6.2.1+5/GMP.v6.2.1.x86_64-linux-musl-cxx11.tar.gz",
                    "ef09c9d7a265e0762585b41b02fc3f0f29132a571220fa92397607ee84482164",
                ),
            ],
            products = [
                JLLLibraryProduct(
                    :libgmp,
                    "lib/libgmp.so",
                    [],
                    flags = [:RTLD_LAZY, :RTLD_DEEPBIND],
                ),
                JLLLibraryProduct(
                    :libgmpxx,
                    "lib/libgmpxx.so",
                    [
                        JLLLibraryDep(nothing, :libgmp),
                    ],
                    flags = [:RTLD_LAZY, :RTLD_DEEPBIND],
                ),
            ]
        ),

        JLLArtifactInfo(;
            src_version = v"6.2.1+5",
            deps = [],
            sources = [],
            platform = Platform("x86_64", "freebsd"; ),
            name = "default",
            treehash = "4dca34de0b2a8e809113af39fc2f5f1ed5a4e134",
            download_sources = [
                JLLArtifactSource(
                    "https://github.com/JuliaBinaryWrappers/GMP_jll.jl/releases/download/GMP-v6.2.1+5/GMP.v6.2.1.x86_64-unknown-freebsd.tar.gz",
                    "86eff44825317379181f8951f6c42919031985fd44e3cf0522cbc56cb1bd5dc2",
                ),
            ],
            products = [
                JLLLibraryProduct(
                    :libgmp,
                    "lib/libgmp.so",
                    [],
                    flags = [:RTLD_LAZY, :RTLD_DEEPBIND],
                ),
                JLLLibraryProduct(
                    :libgmpxx,
                    "lib/libgmpxx.so",
                    [
                        JLLLibraryDep(nothing, :libgmp),
                    ],
                    flags = [:RTLD_LAZY, :RTLD_DEEPBIND],
                ),
            ]
        ),

        JLLArtifactInfo(;
            src_version = v"6.2.1+5",
            deps = [],
            sources = [],
            platform = Platform("x86_64", "windows"; cxxstring_abi = "cxx03"),
            name = "default",
            treehash = "3f7ff36928786cc1c1b477972fe1494c7828e263",
            download_sources = [
                JLLArtifactSource(
                    "https://github.com/JuliaBinaryWrappers/GMP_jll.jl/releases/download/GMP-v6.2.1+5/GMP.v6.2.1.x86_64-w64-mingw32-cxx03.tar.gz",
                    "91e282dd95a710c689170d70a0075b2a2072a254d8398567de539cc9773e4eee",
                ),
            ],
            products = [
                JLLLibraryProduct(
                    :libgmp,
                    "bin\\libgmp-10.dll",
                    [],
                    flags = [:RTLD_LAZY, :RTLD_DEEPBIND],
                ),
                JLLLibraryProduct(
                    :libgmpxx,
                    "bin\\libgmpxx-4.dll",
                    [
                        JLLLibraryDep(nothing, :libgmp),
                    ],
                    flags = [:RTLD_LAZY, :RTLD_DEEPBIND],
                ),
            ]
        ),

        JLLArtifactInfo(;
            src_version = v"6.2.1+5",
            deps = [],
            sources = [],
            platform = Platform("x86_64", "windows"; cxxstring_abi = "cxx11"),
            name = "default",
            treehash = "69f0675f7c45bae5a0190356ddf93c75fd56ee0a",
            download_sources = [
                JLLArtifactSource(
                    "https://github.com/JuliaBinaryWrappers/GMP_jll.jl/releases/download/GMP-v6.2.1+5/GMP.v6.2.1.x86_64-w64-mingw32-cxx11.tar.gz",
                    "558970156010bb77402949e898831c022cfb66c1ebe583856f85db9f9077d7b9",
                ),
            ],
            products = [
                JLLLibraryProduct(
                    :libgmp,
                    "bin\\libgmp-10.dll",
                    [],
                    flags = [:RTLD_LAZY, :RTLD_DEEPBIND],
                ),
                JLLLibraryProduct(
                    :libgmpxx,
                    "bin\\libgmpxx-4.dll",
                    [
                        JLLLibraryDep(nothing, :libgmp),
                    ],
                    flags = [:RTLD_LAZY, :RTLD_DEEPBIND],
                ),
            ]
        ),

    ]
)

