openlibm_license = JLLBuildLicense("LICENSE.md", """
## OpenLibm

OpenLibm contains code that is covered by various licenses.

The OpenLibm code derives from the FreeBSD msun and OpenBSD libm
implementations, which in turn derives from FDLIBM 5.3. As a result, it
has a number of fixes and updates that have accumulated over the years
in msun, and also optimized assembly versions of many functions. These
improvements are provided under the BSD and ISC licenses. The msun
library also includes work placed under the public domain, which is
noted in the individual files. Further work on making a standalone
OpenLibm library from msun, as part of the Julia project is covered
under the MIT license. The test files, test-double.c and test-float.c
are under the LGPL.

## Parts copyrighted by the Julia project (MIT License)

>       Copyright (c) 2011-14 The Julia Project.
>       https://github.com/JuliaMath/openlibm/graphs/contributors
>
>       Permission is hereby granted, free of charge, to any person obtaining
>       a copy of this software and associated documentation files (the
>       "Software"), to deal in the Software without restriction, including
>       without limitation the rights to use, copy, modify, merge, publish,
>       distribute, sublicense, and/or sell copies of the Software, and to
>       permit persons to whom the Software is furnished to do so, subject to
>       the following conditions:
>
>       The above copyright notice and this permission notice shall be
>       included in all copies or substantial portions of the Software.
>
>       THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND,
>       EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF
>       MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND
>       NONINFRINGEMENT. IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT HOLDERS BE
>       LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER IN AN ACTION
>       OF CONTRACT, TORT OR OTHERWISE, ARISING FROM, OUT OF OR IN CONNECTION
>       WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE.

## Parts copyrighted by Stephen L. Moshier (ISC License)

> Copyright (c) 2008 Stephen L. Moshier <steve@moshier.net>
>
> Permission to use, copy, modify, and distribute this software for any
> purpose with or without fee is hereby granted, provided that the above
> copyright notice and this permission notice appear in all copies.
>
> THE SOFTWARE IS PROVIDED "AS IS" AND THE AUTHOR DISCLAIMS ALL WARRANTIES
> WITH REGARD TO THIS SOFTWARE INCLUDING ALL IMPLIED WARRANTIES OF
> MERCHANTABILITY AND FITNESS. IN NO EVENT SHALL THE AUTHOR BE LIABLE FOR
> ANY SPECIAL, DIRECT, INDIRECT, OR CONSEQUENTIAL DAMAGES OR ANY DAMAGES
> WHATSOEVER RESULTING FROM LOSS OF USE, DATA OR PROFITS, WHETHER IN AN
> ACTION OF CONTRACT, NEGLIGENCE OR OTHER TORTIOUS ACTION, ARISING OUT OF
> OR IN CONNECTION WITH THE USE OR PERFORMANCE OF THIS SOFTWARE.

## FREEBSD MSUN (FreeBSD/2-clause BSD/Simplified BSD License)

>       Copyright 1992-2011 The FreeBSD Project. All rights reserved.
>
>       Redistribution and use in source and binary forms, with or without
>       modification, are permitted provided that the following conditions are
>       met:
>
>       1. Redistributions of source code must retain the above copyright
>       notice, this list of conditions and the following disclaimer.
>
>       2. Redistributions in binary form must reproduce the above copyright
>       notice, this list of conditions and the following disclaimer in the
>       documentation and/or other materials provided with the distribution.
>       THIS SOFTWARE IS PROVIDED BY THE FREEBSD PROJECT ``AS IS'' AND ANY
>       EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE
>       IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR
>       PURPOSE ARE DISCLAIMED. IN NO EVENT SHALL THE FREEBSD PROJECT OR
>       CONTRIBUTORS BE LIABLE FOR ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL,
>       EXEMPLARY, OR CONSEQUENTIAL DAMAGES (INCLUDING, BUT NOT LIMITED TO,
>       PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES; LOSS OF USE, DATA, OR
>       PROFITS; OR BUSINESS INTERRUPTION) HOWEVER CAUSED AND ON ANY THEORY OF
>       LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY, OR TORT (INCLUDING
>       NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT OF THE USE OF THIS
>       SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.
>
>       The views and conclusions contained in the software and documentation
>       are those of the authors and should not be interpreted as representing
>       official policies, either expressed or implied, of the FreeBSD
>       Project.

## FDLIBM

>      Copyright (C) 1993 by Sun Microsystems, Inc. All rights reserved.
>
>      Developed at SunPro, a Sun Microsystems, Inc. business.
>      Permission to use, copy, modify, and distribute this
>      software is freely granted, provided that this notice
>      is preserved.

## Tests

>   Copyright (C) 1997, 1999 Free Software Foundation, Inc.
>   This file is part of the GNU C Library.
>   Contributed by Andreas Jaeger <aj@suse.de>, 1997.
>
>   The GNU C Library is free software; you can redistribute it and/or
>   modify it under the terms of the GNU Lesser General Public
>   License as published by the Free Software Foundation; either
>   version 2.1 of the License, or (at your option) any later version.
>
>   The GNU C Library is distributed in the hope that it will be useful,
>   but WITHOUT ANY WARRANTY; without even the implied warranty of
>   MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the GNU
>   Lesser General Public License for more details.
>
>   You should have received a copy of the GNU Lesser General Public
>   License along with the GNU C Library; if not, write to the Free
>   Software Foundation, Inc., 59 Temple Place, Suite 330, Boston, MA
>   02111-1307 USA.
""")

jll = JLLInfo(;
    name = "OpenLibm",
    version = v"0.8.1+2",
    builds = [
        JLLBuildInfo(;
            src_version = v"0.8.1+2",
            deps = [
            ],
            sources = [],
            platform = Platform("aarch64", "macos"; ),
            name = "OpenLibm",
            artifact = JLLArtifactBinding(;
                treehash = "a130463c8a9be64b485b347a83695617c0de593c",
                download_sources = [
                    JLLArtifactSource(
                        "https://github.com/JuliaBinaryWrappers/OpenLibm_jll.jl/releases/download/OpenLibm-v0.8.1+2/OpenLibm.v0.8.1.aarch64-apple-darwin.tar.gz",
                        "0adce1613d2ce331f71b964d589b1896d7e7bab554eac81466bb6b1ba9bc6d3b",
                    ),
                ],
            ),
            products = [
                JLLLibraryProduct(
                    :libopenlibm,
                    "lib/libopenlibm.4.0.dylib",
                    [],
                    flags = [:RTLD_LAZY, :RTLD_DEEPBIND],
                ),
            ],
            licenses = [openlibm_license],
        ),

        JLLBuildInfo(;
            src_version = v"0.8.1+2",
            deps = [
            ],
            sources = [],
            platform = Platform("aarch64", "linux"; libc = "glibc"),
            name = "OpenLibm",
            artifact = JLLArtifactBinding(;
                treehash = "1c3dd51519cae5d65096141ef732fe6ed25e3c34",
                download_sources = [
                    JLLArtifactSource(
                        "https://github.com/JuliaBinaryWrappers/OpenLibm_jll.jl/releases/download/OpenLibm-v0.8.1+2/OpenLibm.v0.8.1.aarch64-linux-gnu.tar.gz",
                        "4ae803cabe094675aafccb590e47e0c5e682be787b9aa70d8dc97186d300016b",
                    ),
                ],
            ),
            products = [
                JLLLibraryProduct(
                    :libopenlibm,
                    "lib/libopenlibm.so",
                    [],
                    flags = [:RTLD_LAZY, :RTLD_DEEPBIND],
                ),
            ],
            licenses = [openlibm_license],
        ),

        JLLBuildInfo(;
            src_version = v"0.8.1+2",
            deps = [
            ],
            sources = [],
            platform = Platform("aarch64", "linux"; libc = "musl"),
            name = "OpenLibm",
            artifact = JLLArtifactBinding(;
                treehash = "28fc75dc6149f6a42d4ca09e53f049bbb4d0c477",
                download_sources = [
                    JLLArtifactSource(
                        "https://github.com/JuliaBinaryWrappers/OpenLibm_jll.jl/releases/download/OpenLibm-v0.8.1+2/OpenLibm.v0.8.1.aarch64-linux-musl.tar.gz",
                        "2290270da3897b30058b588b948afc0811e4e4637a18cd3965b23a0a28ecf151",
                    ),
                ],
            ),
            products = [
                JLLLibraryProduct(
                    :libopenlibm,
                    "lib/libopenlibm.so",
                    [],
                    flags = [:RTLD_LAZY, :RTLD_DEEPBIND],
                ),
            ],
            licenses = [openlibm_license],
        ),

        JLLBuildInfo(;
            src_version = v"0.8.1+2",
            deps = [
            ],
            sources = [],
            platform = Platform("armv6l", "linux"; call_abi = "eabihf", libc = "glibc"),
            name = "OpenLibm",
            artifact = JLLArtifactBinding(;
                treehash = "147adc0e10684539455a03d6fa290c63310eac61",
                download_sources = [
                    JLLArtifactSource(
                        "https://github.com/JuliaBinaryWrappers/OpenLibm_jll.jl/releases/download/OpenLibm-v0.8.1+2/OpenLibm.v0.8.1.armv6l-linux-gnueabihf.tar.gz",
                        "8b083a1502c111a2bd06b861a290999eac87b92db0e57e377c71e118b8d969d7",
                    ),
                ],
            ),
            products = [
                JLLLibraryProduct(
                    :libopenlibm,
                    "lib/libopenlibm.so",
                    [],
                    flags = [:RTLD_LAZY, :RTLD_DEEPBIND],
                ),
            ],
            licenses = [openlibm_license],
        ),

        JLLBuildInfo(;
            src_version = v"0.8.1+2",
            deps = [
            ],
            sources = [],
            platform = Platform("armv6l", "linux"; call_abi = "eabihf", libc = "musl"),
            name = "OpenLibm",
            artifact = JLLArtifactBinding(;
                treehash = "0648d6f95ffc284ce454128166ae7e8799d1a82e",
                download_sources = [
                    JLLArtifactSource(
                        "https://github.com/JuliaBinaryWrappers/OpenLibm_jll.jl/releases/download/OpenLibm-v0.8.1+2/OpenLibm.v0.8.1.armv6l-linux-musleabihf.tar.gz",
                        "5d6bce2508d3d45bec0c5ef36907e0d68461d3945a46427f7ce4cd79dde98f38",
                    ),
                ],
            ),
            products = [
                JLLLibraryProduct(
                    :libopenlibm,
                    "lib/libopenlibm.so",
                    [],
                    flags = [:RTLD_LAZY, :RTLD_DEEPBIND],
                ),
            ],
            licenses = [openlibm_license],
        ),

        JLLBuildInfo(;
            src_version = v"0.8.1+2",
            deps = [
            ],
            sources = [],
            platform = Platform("armv7l", "linux"; call_abi = "eabihf", libc = "glibc"),
            name = "OpenLibm",
            artifact = JLLArtifactBinding(;
                treehash = "147adc0e10684539455a03d6fa290c63310eac61",
                download_sources = [
                    JLLArtifactSource(
                        "https://github.com/JuliaBinaryWrappers/OpenLibm_jll.jl/releases/download/OpenLibm-v0.8.1+2/OpenLibm.v0.8.1.armv7l-linux-gnueabihf.tar.gz",
                        "8b083a1502c111a2bd06b861a290999eac87b92db0e57e377c71e118b8d969d7",
                    ),
                ],
            ),
            products = [
                JLLLibraryProduct(
                    :libopenlibm,
                    "lib/libopenlibm.so",
                    [],
                    flags = [:RTLD_LAZY, :RTLD_DEEPBIND],
                ),
            ],
            licenses = [openlibm_license],
        ),

        JLLBuildInfo(;
            src_version = v"0.8.1+2",
            deps = [
            ],
            sources = [],
            platform = Platform("armv7l", "linux"; call_abi = "eabihf", libc = "musl"),
            name = "OpenLibm",
            artifact = JLLArtifactBinding(;
                treehash = "0648d6f95ffc284ce454128166ae7e8799d1a82e",
                download_sources = [
                    JLLArtifactSource(
                        "https://github.com/JuliaBinaryWrappers/OpenLibm_jll.jl/releases/download/OpenLibm-v0.8.1+2/OpenLibm.v0.8.1.armv7l-linux-musleabihf.tar.gz",
                        "5d6bce2508d3d45bec0c5ef36907e0d68461d3945a46427f7ce4cd79dde98f38",
                    ),
                ],
            ),
            products = [
                JLLLibraryProduct(
                    :libopenlibm,
                    "lib/libopenlibm.so",
                    [],
                    flags = [:RTLD_LAZY, :RTLD_DEEPBIND],
                ),
            ],
            licenses = [openlibm_license],
        ),

        JLLBuildInfo(;
            src_version = v"0.8.1+2",
            deps = [
            ],
            sources = [],
            platform = Platform("i686", "linux"; libc = "glibc"),
            name = "OpenLibm",
            artifact = JLLArtifactBinding(;
                treehash = "4f4023d9066cd44f8f9ae74d09cde369c7b550b1",
                download_sources = [
                    JLLArtifactSource(
                        "https://github.com/JuliaBinaryWrappers/OpenLibm_jll.jl/releases/download/OpenLibm-v0.8.1+2/OpenLibm.v0.8.1.i686-linux-gnu.tar.gz",
                        "d201ad344f554ecb451d40fd607d46d589a29877279b05f8c7232b53fab42655",
                    ),
                ],
            ),
            products = [
                JLLLibraryProduct(
                    :libopenlibm,
                    "lib/libopenlibm.so",
                    [],
                    flags = [:RTLD_LAZY, :RTLD_DEEPBIND],
                ),
            ],
            licenses = [openlibm_license],
        ),

        JLLBuildInfo(;
            src_version = v"0.8.1+2",
            deps = [
            ],
            sources = [],
            platform = Platform("i686", "linux"; libc = "musl"),
            name = "OpenLibm",
            artifact = JLLArtifactBinding(;
                treehash = "e8baa31f274063f27c9c041337f451c57fc040cc",
                download_sources = [
                    JLLArtifactSource(
                        "https://github.com/JuliaBinaryWrappers/OpenLibm_jll.jl/releases/download/OpenLibm-v0.8.1+2/OpenLibm.v0.8.1.i686-linux-musl.tar.gz",
                        "de9646577541934b1eae13caf91104d991ecef1f76a196b46a03dd90908125c9",
                    ),
                ],
            ),
            products = [
                JLLLibraryProduct(
                    :libopenlibm,
                    "lib/libopenlibm.so",
                    [],
                    flags = [:RTLD_LAZY, :RTLD_DEEPBIND],
                ),
            ],
            licenses = [openlibm_license],
        ),

        JLLBuildInfo(;
            src_version = v"0.8.1+2",
            deps = [
            ],
            sources = [],
            platform = Platform("i686", "windows"; ),
            name = "OpenLibm",
            artifact = JLLArtifactBinding(;
                treehash = "e0ba67b6ee020eb9974786389e783abd8e0d20e0",
                download_sources = [
                    JLLArtifactSource(
                        "https://github.com/JuliaBinaryWrappers/OpenLibm_jll.jl/releases/download/OpenLibm-v0.8.1+2/OpenLibm.v0.8.1.i686-w64-mingw32.tar.gz",
                        "a3ae5dea34b59f5ae1fe5f735d72d7d5ea48cf67f8134d5c0113af58c75d5bb0",
                    ),
                ],
            ),
            products = [
                JLLLibraryProduct(
                    :libopenlibm,
                    "bin\\libopenlibm.dll",
                    [],
                    flags = [:RTLD_LAZY, :RTLD_DEEPBIND],
                ),
            ],
            licenses = [openlibm_license],
        ),

        JLLBuildInfo(;
            src_version = v"0.8.1+2",
            deps = [
            ],
            sources = [],
            platform = Platform("powerpc64le", "linux"; libc = "glibc"),
            name = "OpenLibm",
            artifact = JLLArtifactBinding(;
                treehash = "69b80ae25bd7c9d8ab4292ea9d168b9a25ad48b6",
                download_sources = [
                    JLLArtifactSource(
                        "https://github.com/JuliaBinaryWrappers/OpenLibm_jll.jl/releases/download/OpenLibm-v0.8.1+2/OpenLibm.v0.8.1.powerpc64le-linux-gnu.tar.gz",
                        "884461cb9037cb383fbee6e92f0e1f8c5a7f0b8420fcf5c10d3c3c060a7d2b70",
                    ),
                ],
            ),
            products = [
                JLLLibraryProduct(
                    :libopenlibm,
                    "lib/libopenlibm.so",
                    [],
                    flags = [:RTLD_LAZY, :RTLD_DEEPBIND],
                ),
            ],
            licenses = [openlibm_license],
        ),

        JLLBuildInfo(;
            src_version = v"0.8.1+2",
            deps = [
            ],
            sources = [],
            platform = Platform("x86_64", "macos"; ),
            name = "OpenLibm",
            artifact = JLLArtifactBinding(;
                treehash = "16dc90eb2af3caf72478f4225f7ee6c2e6b62de5",
                download_sources = [
                    JLLArtifactSource(
                        "https://github.com/JuliaBinaryWrappers/OpenLibm_jll.jl/releases/download/OpenLibm-v0.8.1+2/OpenLibm.v0.8.1.x86_64-apple-darwin.tar.gz",
                        "2939865cf9b41cf5401df437320a1d557ad550817cbe7b1f6bf69aadb4aa9ba8",
                    ),
                ],
            ),
            products = [
                JLLLibraryProduct(
                    :libopenlibm,
                    "lib/libopenlibm.4.0.dylib",
                    [],
                    flags = [:RTLD_LAZY, :RTLD_DEEPBIND],
                ),
            ],
            licenses = [openlibm_license],
        ),

        JLLBuildInfo(;
            src_version = v"0.8.1+2",
            deps = [
            ],
            sources = [],
            platform = Platform("x86_64", "linux"; libc = "glibc"),
            name = "OpenLibm",
            artifact = JLLArtifactBinding(;
                treehash = "d42a8f33483c3a7b209c551c9d8d65114ac70f8f",
                download_sources = [
                    JLLArtifactSource(
                        "https://github.com/JuliaBinaryWrappers/OpenLibm_jll.jl/releases/download/OpenLibm-v0.8.1+2/OpenLibm.v0.8.1.x86_64-linux-gnu.tar.gz",
                        "164a5349b6cdcce409e5277afb752b8f4a270b98229d0ab5d626848e7dbdb86e",
                    ),
                ],
            ),
            products = [
                JLLLibraryProduct(
                    :libopenlibm,
                    "lib/libopenlibm.so",
                    [],
                    flags = [:RTLD_LAZY, :RTLD_DEEPBIND],
                ),
            ],
            licenses = [openlibm_license],
        ),

        JLLBuildInfo(;
            src_version = v"0.8.1+2",
            deps = [
            ],
            sources = [],
            platform = Platform("x86_64", "linux"; libc = "glibc", sanitize = "memory"),
            name = "OpenLibm",
            artifact = JLLArtifactBinding(;
                treehash = "5459f8b39d89497e94686422475e0ba06c92386b",
                download_sources = [
                    JLLArtifactSource(
                        "https://github.com/JuliaBinaryWrappers/OpenLibm_jll.jl/releases/download/OpenLibm-v0.8.1+2/OpenLibm.v0.8.1.x86_64-linux-gnu-sanitize+memory.tar.gz",
                        "2aa99d1e51e9de1c18c8ee9d4b0a4ee3d1b6635ff1cf55f62afa27bab0d99eed",
                    ),
                ],
            ),
            products = [
                JLLLibraryProduct(
                    :libopenlibm,
                    "lib/libopenlibm.so",
                    [],
                    flags = [:RTLD_LAZY, :RTLD_DEEPBIND],
                ),
            ],
            licenses = [openlibm_license],
        ),

        JLLBuildInfo(;
            src_version = v"0.8.1+2",
            deps = [
            ],
            sources = [],
            platform = Platform("x86_64", "linux"; libc = "musl"),
            name = "OpenLibm",
            artifact = JLLArtifactBinding(;
                treehash = "37b895bd2b9931b25280d4a17e9885a44de60cca",
                download_sources = [
                    JLLArtifactSource(
                        "https://github.com/JuliaBinaryWrappers/OpenLibm_jll.jl/releases/download/OpenLibm-v0.8.1+2/OpenLibm.v0.8.1.x86_64-linux-musl.tar.gz",
                        "02e750065cd49185c9e82f75a460c3c9b58024197e30c0cafdd059fd704bf544",
                    ),
                ],
            ),
            products = [
                JLLLibraryProduct(
                    :libopenlibm,
                    "lib/libopenlibm.so",
                    [],
                    flags = [:RTLD_LAZY, :RTLD_DEEPBIND],
                ),
            ],
            licenses = [openlibm_license],
        ),

        JLLBuildInfo(;
            src_version = v"0.8.1+2",
            deps = [
            ],
            sources = [],
            platform = Platform("x86_64", "freebsd"; ),
            name = "OpenLibm",
            artifact = JLLArtifactBinding(;
                treehash = "faf87efd521a2f1ad42b3cd414e71cfd22f61afc",
                download_sources = [
                    JLLArtifactSource(
                        "https://github.com/JuliaBinaryWrappers/OpenLibm_jll.jl/releases/download/OpenLibm-v0.8.1+2/OpenLibm.v0.8.1.x86_64-unknown-freebsd.tar.gz",
                        "c0c5ec70811a2979336cb8560166acc6d9c1f8adb573b0bee967ae7787266e63",
                    ),
                ],
            ),
            products = [
                JLLLibraryProduct(
                    :libopenlibm,
                    "lib/libopenlibm.so",
                    [],
                    flags = [:RTLD_LAZY, :RTLD_DEEPBIND],
                ),
            ],
            licenses = [openlibm_license],
        ),

        JLLBuildInfo(;
            src_version = v"0.8.1+2",
            deps = [
            ],
            sources = [],
            platform = Platform("x86_64", "windows"; ),
            name = "OpenLibm",
            artifact = JLLArtifactBinding(;
                treehash = "12dbb974945a220bdb26953aed28bfe9718add03",
                download_sources = [
                    JLLArtifactSource(
                        "https://github.com/JuliaBinaryWrappers/OpenLibm_jll.jl/releases/download/OpenLibm-v0.8.1+2/OpenLibm.v0.8.1.x86_64-w64-mingw32.tar.gz",
                        "48c903b0aad4c224c242990d749e6464c2456736b89a641096f3aa814881c484",
                    ),
                ],
            ),
            products = [
                JLLLibraryProduct(
                    :libopenlibm,
                    "bin\\libopenlibm.dll",
                    [],
                    flags = [:RTLD_LAZY, :RTLD_DEEPBIND],
                ),
            ],
            licenses = [openlibm_license],
        ),

    ]
)

