libxls_license = JLLBuildLicense("LICENSE.md", """
libxls -- A multiplatform, C/C++ library for parsing Excel(TM) files.

Copyright 2004 Komarov Valery
Copyright 2006 Christophe Leitienne
Copyright 2008-2017 David Hoerl
Copyright 2013 Bob Colbert
Copyright 2013-2018 Evan Miller

The included libxls code is licensed under the BSD 2-clause license:

Redistribution and use in source and binary forms, with or without
modification, are permitted provided that the following conditions are met:

   1. Redistributions of source code must retain the above copyright notice,
   this list of conditions and the following disclaimer.

   2. Redistributions in binary form must reproduce the above copyright notice,
   this list of conditions and the following disclaimer in the documentation
   and/or other materials provided with the distribution.

THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS ''AS IS''
AND ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE
IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE ARE
DISCLAIMED. IN NO EVENT SHALL THE COPYRIGHT HOLDERS OR CONTRIBUTORS BE LIABLE
FOR ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR CONSEQUENTIAL
DAMAGES (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR
SERVICES; LOSS OF USE, DATA, OR PROFITS; OR BUSINESS INTERRUPTION) HOWEVER
CAUSED AND ON ANY THEORY OF LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY,
OR TORT (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT OF THE USE
OF THIS SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.
""")

jll = JLLInfo(;
    name = "libxls",
    version = v"1.6.2+0",
    builds = [
        JLLBuildInfo(;
            src_version = v"1.6.2+0",
            deps = [
            ],
            sources = [],
            platform = Platform("aarch64", "macos"; ),
            name = "libxls",
            artifact = JLLArtifactBinding(;
                treehash = "ca0e731d11c697f06d61948cd9af297f2ecb6c0d",
                download_sources = [
                    JLLArtifactSource(
                        "https://github.com/JuliaBinaryWrappers/libxls_jll.jl/releases/download/libxls-v1.6.2+0/libxls.v1.6.2.aarch64-apple-darwin.tar.gz",
                        "5ffb900e8a470e9b3cc738a86ad45e7cc13014dec134e37104f868e90721c345",
                    ),
                ],
            ),
            products = [
                JLLLibraryProduct(
                    :libxlsreader,
                    "lib/libxlsreader.8.dylib",
                    [],
                    flags = [:RTLD_LAZY, :RTLD_DEEPBIND],
                ),
            ],
            licenses = [libxls_license],
        ),

        JLLBuildInfo(;
            src_version = v"1.6.2+0",
            deps = [
            ],
            sources = [],
            platform = Platform("aarch64", "linux"; libc = "glibc"),
            name = "libxls",
            artifact = JLLArtifactBinding(;
                treehash = "ecf6799c4dbfcad10ca6f6655b6335c4ccbfb370",
                download_sources = [
                    JLLArtifactSource(
                        "https://github.com/JuliaBinaryWrappers/libxls_jll.jl/releases/download/libxls-v1.6.2+0/libxls.v1.6.2.aarch64-linux-gnu.tar.gz",
                        "175bec3beeb484dea797483e25854a25a8c8b12554a0c36515d6cb72613b14ff",
                    ),
                ],
            ),
            products = [
                JLLLibraryProduct(
                    :libxlsreader,
                    "lib/libxlsreader.so",
                    [],
                    flags = [:RTLD_LAZY, :RTLD_DEEPBIND],
                ),
            ],
            licenses = [libxls_license],
        ),

        JLLBuildInfo(;
            src_version = v"1.6.2+0",
            deps = [
            ],
            sources = [],
            platform = Platform("aarch64", "linux"; libc = "musl"),
            name = "libxls",
            artifact = JLLArtifactBinding(;
                treehash = "555de5c17a0813b57f3ad5ab12dea8f3f63f1a90",
                download_sources = [
                    JLLArtifactSource(
                        "https://github.com/JuliaBinaryWrappers/libxls_jll.jl/releases/download/libxls-v1.6.2+0/libxls.v1.6.2.aarch64-linux-musl.tar.gz",
                        "e6ddc16d4bcaafc55eb807e156f7f6fa5dd2c796e608b262c4d82e328725a1aa",
                    ),
                ],
            ),
            products = [
                JLLLibraryProduct(
                    :libxlsreader,
                    "lib/libxlsreader.so",
                    [],
                    flags = [:RTLD_LAZY, :RTLD_DEEPBIND],
                ),
            ],
            licenses = [libxls_license],
        ),

        JLLBuildInfo(;
            src_version = v"1.6.2+0",
            deps = [
            ],
            sources = [],
            platform = Platform("armv6l", "linux"; call_abi = "eabihf", libc = "glibc"),
            name = "libxls",
            artifact = JLLArtifactBinding(;
                treehash = "f1b8cd59ff0509c3618a319f14c93f56ebb1bd3b",
                download_sources = [
                    JLLArtifactSource(
                        "https://github.com/JuliaBinaryWrappers/libxls_jll.jl/releases/download/libxls-v1.6.2+0/libxls.v1.6.2.armv6l-linux-gnueabihf.tar.gz",
                        "b99bfbddaf61301ee95ac332b174355c392f18ece889b9c1dd6bd93fe25692ed",
                    ),
                ],
            ),
            products = [
                JLLLibraryProduct(
                    :libxlsreader,
                    "lib/libxlsreader.so",
                    [],
                    flags = [:RTLD_LAZY, :RTLD_DEEPBIND],
                ),
            ],
            licenses = [libxls_license],
        ),

        JLLBuildInfo(;
            src_version = v"1.6.2+0",
            deps = [
            ],
            sources = [],
            platform = Platform("armv6l", "linux"; call_abi = "eabihf", libc = "musl"),
            name = "libxls",
            artifact = JLLArtifactBinding(;
                treehash = "e5de098bf4020d8cd76cc023bb722f483f14660a",
                download_sources = [
                    JLLArtifactSource(
                        "https://github.com/JuliaBinaryWrappers/libxls_jll.jl/releases/download/libxls-v1.6.2+0/libxls.v1.6.2.armv6l-linux-musleabihf.tar.gz",
                        "55bd00171a979baf8c3c57b2292236c0d089825361f28a342d06d8f5fb237180",
                    ),
                ],
            ),
            products = [
                JLLLibraryProduct(
                    :libxlsreader,
                    "lib/libxlsreader.so",
                    [],
                    flags = [:RTLD_LAZY, :RTLD_DEEPBIND],
                ),
            ],
            licenses = [libxls_license],
        ),

        JLLBuildInfo(;
            src_version = v"1.6.2+0",
            deps = [
            ],
            sources = [],
            platform = Platform("armv7l", "linux"; call_abi = "eabihf", libc = "glibc"),
            name = "libxls",
            artifact = JLLArtifactBinding(;
                treehash = "8362e295bdba1aec088d591ce4484012721fc62f",
                download_sources = [
                    JLLArtifactSource(
                        "https://github.com/JuliaBinaryWrappers/libxls_jll.jl/releases/download/libxls-v1.6.2+0/libxls.v1.6.2.armv7l-linux-gnueabihf.tar.gz",
                        "50a3e830e9bde9ac2cacb236e9c7a3baed1099ece204913c322026c10941c00f",
                    ),
                ],
            ),
            products = [
                JLLLibraryProduct(
                    :libxlsreader,
                    "lib/libxlsreader.so",
                    [],
                    flags = [:RTLD_LAZY, :RTLD_DEEPBIND],
                ),
            ],
            licenses = [libxls_license],
        ),

        JLLBuildInfo(;
            src_version = v"1.6.2+0",
            deps = [
            ],
            sources = [],
            platform = Platform("armv7l", "linux"; call_abi = "eabihf", libc = "musl"),
            name = "libxls",
            artifact = JLLArtifactBinding(;
                treehash = "6edaa28fbd260338d738c82f230f1b4664379c53",
                download_sources = [
                    JLLArtifactSource(
                        "https://github.com/JuliaBinaryWrappers/libxls_jll.jl/releases/download/libxls-v1.6.2+0/libxls.v1.6.2.armv7l-linux-musleabihf.tar.gz",
                        "8451324ae136c297c9a098b0de14c7c701c267d852d01d93abd5afd9a3ff7c30",
                    ),
                ],
            ),
            products = [
                JLLLibraryProduct(
                    :libxlsreader,
                    "lib/libxlsreader.so",
                    [],
                    flags = [:RTLD_LAZY, :RTLD_DEEPBIND],
                ),
            ],
            licenses = [libxls_license],
        ),

        JLLBuildInfo(;
            src_version = v"1.6.2+0",
            deps = [
            ],
            sources = [],
            platform = Platform("i686", "linux"; libc = "glibc"),
            name = "libxls",
            artifact = JLLArtifactBinding(;
                treehash = "14869e668267499762a15b057547a4a52e6d039b",
                download_sources = [
                    JLLArtifactSource(
                        "https://github.com/JuliaBinaryWrappers/libxls_jll.jl/releases/download/libxls-v1.6.2+0/libxls.v1.6.2.i686-linux-gnu.tar.gz",
                        "180a5b8fb56e989b8779f873f44ed62a3ade9df7ec4cff28d1691f8eef776145",
                    ),
                ],
            ),
            products = [
                JLLLibraryProduct(
                    :libxlsreader,
                    "lib/libxlsreader.so",
                    [],
                    flags = [:RTLD_LAZY, :RTLD_DEEPBIND],
                ),
            ],
            licenses = [libxls_license],
        ),

        JLLBuildInfo(;
            src_version = v"1.6.2+0",
            deps = [
            ],
            sources = [],
            platform = Platform("i686", "linux"; libc = "musl"),
            name = "libxls",
            artifact = JLLArtifactBinding(;
                treehash = "0e16e7c0b90fd5c7cff75d55ae2a3070f8b409fb",
                download_sources = [
                    JLLArtifactSource(
                        "https://github.com/JuliaBinaryWrappers/libxls_jll.jl/releases/download/libxls-v1.6.2+0/libxls.v1.6.2.i686-linux-musl.tar.gz",
                        "6b49d0cb1e9338c6fc682d3b71ca93ab553fc76903d955d94c50fab9b2c54a42",
                    ),
                ],
            ),
            products = [
                JLLLibraryProduct(
                    :libxlsreader,
                    "lib/libxlsreader.so",
                    [],
                    flags = [:RTLD_LAZY, :RTLD_DEEPBIND],
                ),
            ],
            licenses = [libxls_license],
        ),

        JLLBuildInfo(;
            src_version = v"1.6.2+0",
            deps = [
            ],
            sources = [],
            platform = Platform("i686", "windows"; ),
            name = "libxls",
            artifact = JLLArtifactBinding(;
                treehash = "b47600e2aca1f117c89bad97d34a620bd6ee5e30",
                download_sources = [
                    JLLArtifactSource(
                        "https://github.com/JuliaBinaryWrappers/libxls_jll.jl/releases/download/libxls-v1.6.2+0/libxls.v1.6.2.i686-w64-mingw32.tar.gz",
                        "05590f7a7816a1121e7238cdea84aa403f8e1dd4b682a778fe6a7e32ef5831ec",
                    ),
                ],
            ),
            products = [
                JLLLibraryProduct(
                    :libxlsreader,
                    "bin\\libxlsreader-8.dll",
                    [],
                    flags = [:RTLD_LAZY, :RTLD_DEEPBIND],
                ),
            ],
            licenses = [libxls_license],
        ),

        JLLBuildInfo(;
            src_version = v"1.6.2+0",
            deps = [
            ],
            sources = [],
            platform = Platform("powerpc64le", "linux"; libc = "glibc"),
            name = "libxls",
            artifact = JLLArtifactBinding(;
                treehash = "567a073095e773e1a49016aa4e1aab6538f7e6ba",
                download_sources = [
                    JLLArtifactSource(
                        "https://github.com/JuliaBinaryWrappers/libxls_jll.jl/releases/download/libxls-v1.6.2+0/libxls.v1.6.2.powerpc64le-linux-gnu.tar.gz",
                        "f62490f1a2cec48e4ca866f6ecb5ec94d0a0d39c15ea7411c213ed23ff93002c",
                    ),
                ],
            ),
            products = [
                JLLLibraryProduct(
                    :libxlsreader,
                    "lib/libxlsreader.so",
                    [],
                    flags = [:RTLD_LAZY, :RTLD_DEEPBIND],
                ),
            ],
            licenses = [libxls_license],
        ),

        JLLBuildInfo(;
            src_version = v"1.6.2+0",
            deps = [
            ],
            sources = [],
            platform = Platform("x86_64", "macos"; ),
            name = "libxls",
            artifact = JLLArtifactBinding(;
                treehash = "a795cb1add116aee2fd76f8ca7cccaae188c11ae",
                download_sources = [
                    JLLArtifactSource(
                        "https://github.com/JuliaBinaryWrappers/libxls_jll.jl/releases/download/libxls-v1.6.2+0/libxls.v1.6.2.x86_64-apple-darwin.tar.gz",
                        "f721c90b442d240477bca4dd66686fba62830e718b1bb3654ca8c454476da8da",
                    ),
                ],
            ),
            products = [
                JLLLibraryProduct(
                    :libxlsreader,
                    "lib/libxlsreader.8.dylib",
                    [],
                    flags = [:RTLD_LAZY, :RTLD_DEEPBIND],
                ),
            ],
            licenses = [libxls_license],
        ),

        JLLBuildInfo(;
            src_version = v"1.6.2+0",
            deps = [
            ],
            sources = [],
            platform = Platform("x86_64", "linux"; libc = "glibc"),
            name = "libxls",
            artifact = JLLArtifactBinding(;
                treehash = "dd3c443db40273362a1f2811f34e422c3d9d3ae3",
                download_sources = [
                    JLLArtifactSource(
                        "https://github.com/JuliaBinaryWrappers/libxls_jll.jl/releases/download/libxls-v1.6.2+0/libxls.v1.6.2.x86_64-linux-gnu.tar.gz",
                        "1662f387f96a49ae9634ae2cd93ec6f3ca532fb0e5c9c6fb8f305fd4ab6f4d77",
                    ),
                ],
            ),
            products = [
                JLLLibraryProduct(
                    :libxlsreader,
                    "lib/libxlsreader.so",
                    [],
                    flags = [:RTLD_LAZY, :RTLD_DEEPBIND],
                ),
            ],
            licenses = [libxls_license],
        ),

        JLLBuildInfo(;
            src_version = v"1.6.2+0",
            deps = [
            ],
            sources = [],
            platform = Platform("x86_64", "linux"; libc = "musl"),
            name = "libxls",
            artifact = JLLArtifactBinding(;
                treehash = "251ea23d94e2436fea92e854addb6734f4f28561",
                download_sources = [
                    JLLArtifactSource(
                        "https://github.com/JuliaBinaryWrappers/libxls_jll.jl/releases/download/libxls-v1.6.2+0/libxls.v1.6.2.x86_64-linux-musl.tar.gz",
                        "26b15278559392729d22c2419b021b14a99aa10f2f94d946577aebafbefa91f1",
                    ),
                ],
            ),
            products = [
                JLLLibraryProduct(
                    :libxlsreader,
                    "lib/libxlsreader.so",
                    [],
                    flags = [:RTLD_LAZY, :RTLD_DEEPBIND],
                ),
            ],
            licenses = [libxls_license],
        ),

        JLLBuildInfo(;
            src_version = v"1.6.2+0",
            deps = [
            ],
            sources = [],
            platform = Platform("x86_64", "freebsd"; ),
            name = "libxls",
            artifact = JLLArtifactBinding(;
                treehash = "1c306f5bc10ff335763e20f1aeebc529742945a0",
                download_sources = [
                    JLLArtifactSource(
                        "https://github.com/JuliaBinaryWrappers/libxls_jll.jl/releases/download/libxls-v1.6.2+0/libxls.v1.6.2.x86_64-unknown-freebsd.tar.gz",
                        "69af7d8fdd45cd189bf7fff2485a427a2523a5c4966410544902958305c826db",
                    ),
                ],
            ),
            products = [
                JLLLibraryProduct(
                    :libxlsreader,
                    "lib/libxlsreader.so",
                    [],
                    flags = [:RTLD_LAZY, :RTLD_DEEPBIND],
                ),
            ],
            licenses = [libxls_license],
        ),

        JLLBuildInfo(;
            src_version = v"1.6.2+0",
            deps = [
            ],
            sources = [],
            platform = Platform("x86_64", "windows"; ),
            name = "libxls",
            artifact = JLLArtifactBinding(;
                treehash = "d82ca131d7feae54dcd0b39d7536bd12fedc9042",
                download_sources = [
                    JLLArtifactSource(
                        "https://github.com/JuliaBinaryWrappers/libxls_jll.jl/releases/download/libxls-v1.6.2+0/libxls.v1.6.2.x86_64-w64-mingw32.tar.gz",
                        "a17edc11281d16fd375637b269cec62f08ebde8e145693b2cf4e0a0a22296be8",
                    ),
                ],
            ),
            products = [
                JLLLibraryProduct(
                    :libxlsreader,
                    "bin\\libxlsreader-8.dll",
                    [],
                    flags = [:RTLD_LAZY, :RTLD_DEEPBIND],
                ),
            ],
            licenses = [libxls_license],
        ),

    ]
)

