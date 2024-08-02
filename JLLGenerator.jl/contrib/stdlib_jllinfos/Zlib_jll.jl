zlib_license = JLLBuildLicense("LICENSE.md", """
ZLIB DATA COMPRESSION LIBRARY

zlib 1.2.13 is a general purpose data compression library.  All the code is
thread safe.  The data format used by the zlib library is described by RFCs
(Request for Comments) 1950 to 1952 in the files
http://tools.ietf.org/html/rfc1950 (zlib format), rfc1951 (deflate format) and
rfc1952 (gzip format).

All functions of the compression library are documented in the file zlib.h
(volunteer to write man pages welcome, contact zlib@gzip.org).  A usage example
of the library is given in the file test/example.c which also tests that
the library is working correctly.  Another example is given in the file
test/minigzip.c.  The compression library itself is composed of all source
files in the root directory.

To compile all files and run the test program, follow the instructions given at
the top of Makefile.in.  In short "./configure; make test", and if that goes
well, "make install" should work for most flavors of Unix.  For Windows, use
one of the special makefiles in win32/ or contrib/vstudio/ .  For VMS, use
make_vms.com.

Questions about zlib should be sent to <zlib@gzip.org>, or to Gilles Vollant
<info@winimage.com> for the Windows DLL version.  The zlib home page is
http://zlib.net/ .  Before reporting a problem, please check this site to
verify that you have the latest version of zlib; otherwise get the latest
version and check whether the problem still exists or not.

PLEASE read the zlib FAQ http://zlib.net/zlib_faq.html before asking for help.

Mark Nelson <markn@ieee.org> wrote an article about zlib for the Jan.  1997
issue of Dr.  Dobb's Journal; a copy of the article is available at
http://marknelson.us/1997/01/01/zlib-engine/ .

The changes made in version 1.2.13 are documented in the file ChangeLog.

Unsupported third party contributions are provided in directory contrib/ .

zlib is available in Java using the java.util.zip package, documented at
http://java.sun.com/developer/technicalArticles/Programming/compression/ .

A Perl interface to zlib written by Paul Marquess <pmqs@cpan.org> is available
at CPAN (Comprehensive Perl Archive Network) sites, including
http://search.cpan.org/~pmqs/IO-Compress-Zlib/ .

A Python interface to zlib written by A.M. Kuchling <amk@amk.ca> is
available in Python 1.5 and later versions, see
http://docs.python.org/library/zlib.html .

zlib is built into tcl: http://wiki.tcl.tk/4610 .

An experimental package to read and write files in .zip format, written on top
of zlib by Gilles Vollant <info@winimage.com>, is available in the
contrib/minizip directory of zlib.


Notes for some targets:

- For Windows DLL versions, please see win32/DLL_FAQ.txt

- For 64-bit Irix, deflate.c must be compiled without any optimization. With
  -O, one libpng test fails. The test works in 32 bit mode (with the -n32
  compiler flag). The compiler bug has been reported to SGI.

- zlib doesn't work with gcc 2.6.3 on a DEC 3000/300LX under OSF/1 2.1 it works
  when compiled with cc.

- On Digital Unix 4.0D (formely OSF/1) on AlphaServer, the cc option -std1 is
  necessary to get gzprintf working correctly. This is done by configure.

- zlib doesn't work on HP-UX 9.05 with some versions of /bin/cc. It works with
  other compilers. Use "make test" to check your compiler.

- gzdopen is not supported on RISCOS or BEOS.

- For PalmOs, see http://palmzlib.sourceforge.net/


Acknowledgments:

  The deflate format used by zlib was defined by Phil Katz.  The deflate and
  zlib specifications were written by L.  Peter Deutsch.  Thanks to all the
  people who reported problems and suggested various improvements in zlib; they
  are too numerous to cite here.

Copyright notice:

 (C) 1995-2022 Jean-loup Gailly and Mark Adler

  This software is provided 'as-is', without any express or implied
  warranty.  In no event will the authors be held liable for any damages
  arising from the use of this software.

  Permission is granted to anyone to use this software for any purpose,
  including commercial applications, and to alter it and redistribute it
  freely, subject to the following restrictions:

  1. The origin of this software must not be misrepresented; you must not
     claim that you wrote the original software. If you use this software
     in a product, an acknowledgment in the product documentation would be
     appreciated but is not required.
  2. Altered source versions must be plainly marked as such, and must not be
     misrepresented as being the original software.
  3. This notice may not be removed or altered from any source distribution.

  Jean-loup Gailly        Mark Adler
  jloup@gzip.org          madler@alumni.caltech.edu

If you use the zlib library in a product, we would appreciate *not* receiving
lengthy legal documents to sign.  The sources are provided for free but without
warranty of any kind.  The library has been entirely written by Jean-loup
Gailly and Mark Adler; it does not include third-party code.  We make all
contributions to and distributions of this project solely in our personal
capacity, and are not conveying any rights to any intellectual property of
any third parties.

If you redistribute modified sources, we would appreciate that you include in
the file ChangeLog history information documenting your changes.  Please read
the FAQ for more information on the distribution of modified source versions.
""")

jll = JLLInfo(;
    name = "Zlib",
    version = v"1.2.13+1",
    builds = [
        JLLBuildInfo(;
            src_version = v"1.2.13+1",
            platform = Platform("aarch64", "macos"; ),
            name = "Zlib",
            artifact = JLLArtifactBinding(;
                treehash = "825258bf554943dc116bd0699dad3ebd57004efc",
                download_sources = [
                    JLLArtifactSource(
                        "https://github.com/JuliaBinaryWrappers/Zlib_jll.jl/releases/download/Zlib-v1.2.13+1/Zlib.v1.2.13.aarch64-apple-darwin.tar.gz",
                        "c3cd33a20f082b947fa4175c60545d5d4a6bc360f0175597bca87be9028b15b1",
                    ),
                ],
            ),
            products = [
                JLLLibraryProduct(
                    :libz,
                    "lib/libz.1.2.13.dylib",
                    [],
                    flags = [:RTLD_LAZY, :RTLD_DEEPBIND],
                ),
            ],
            licenses = [zlib_license],
        ),

        JLLBuildInfo(;
            src_version = v"1.2.13+1",
            platform = Platform("aarch64", "linux"; libc = "glibc"),
            name = "Zlib",
            artifact = JLLArtifactBinding(;
                treehash = "0c6c284985577758b3a339c6215c9d4e3d71420e",
                download_sources = [
                    JLLArtifactSource(
                        "https://github.com/JuliaBinaryWrappers/Zlib_jll.jl/releases/download/Zlib-v1.2.13+1/Zlib.v1.2.13.aarch64-linux-gnu.tar.gz",
                        "bf861aa618865fb20ca228c42370ca6bd6aefeb5291954f7c4cbd28b0c9a5a27",
                    ),
                ],
            ),
            products = [
                JLLLibraryProduct(
                    :libz,
                    "lib/libz.so",
                    [],
                    flags = [:RTLD_LAZY, :RTLD_DEEPBIND],
                ),
            ],
            licenses = [zlib_license],
        ),

        JLLBuildInfo(;
            src_version = v"1.2.13+1",
            platform = Platform("aarch64", "linux"; libc = "musl"),
            name = "Zlib",
            artifact = JLLArtifactBinding(;
                treehash = "377fed6108dca72651d7cb705a0aee7ce28d4a5b",
                download_sources = [
                    JLLArtifactSource(
                        "https://github.com/JuliaBinaryWrappers/Zlib_jll.jl/releases/download/Zlib-v1.2.13+1/Zlib.v1.2.13.aarch64-linux-musl.tar.gz",
                        "c251e8d40c756adc41abb5e1f1a6e8663c42d491ad2de87ad8e3a0901c425a52",
                    ),
                ],
            ),
            products = [
                JLLLibraryProduct(
                    :libz,
                    "lib/libz.so",
                    [],
                    flags = [:RTLD_LAZY, :RTLD_DEEPBIND],
                ),
            ],
            licenses = [zlib_license],
        ),

        JLLBuildInfo(;
            src_version = v"1.2.13+1",
            platform = Platform("armv6l", "linux"; call_abi = "eabihf", libc = "glibc"),
            name = "Zlib",
            artifact = JLLArtifactBinding(;
                treehash = "35c69c6c920abe3002f30d4df499e3cd958aee09",
                download_sources = [
                    JLLArtifactSource(
                        "https://github.com/JuliaBinaryWrappers/Zlib_jll.jl/releases/download/Zlib-v1.2.13+1/Zlib.v1.2.13.armv6l-linux-gnueabihf.tar.gz",
                        "30dd6a144a1281885119a105393c3c49c96db84bf9e5f64ec8bd5ecd329313f8",
                    ),
                ],
            ),
            products = [
                JLLLibraryProduct(
                    :libz,
                    "lib/libz.so",
                    [],
                    flags = [:RTLD_LAZY, :RTLD_DEEPBIND],
                ),
            ],
            licenses = [zlib_license],
        ),

        JLLBuildInfo(;
            src_version = v"1.2.13+1",
            platform = Platform("armv6l", "linux"; call_abi = "eabihf", libc = "musl"),
            name = "Zlib",
            artifact = JLLArtifactBinding(;
                treehash = "7019cf5e79d3147cb132d70e5e599c03ecedb8c4",
                download_sources = [
                    JLLArtifactSource(
                        "https://github.com/JuliaBinaryWrappers/Zlib_jll.jl/releases/download/Zlib-v1.2.13+1/Zlib.v1.2.13.armv6l-linux-musleabihf.tar.gz",
                        "89fdae8a411f5d6b009d4efc2f1328941b50b4ea8610367ed15a2b20a044b65c",
                    ),
                ],
            ),
            products = [
                JLLLibraryProduct(
                    :libz,
                    "lib/libz.so",
                    [],
                    flags = [:RTLD_LAZY, :RTLD_DEEPBIND],
                ),
            ],
            licenses = [zlib_license],
        ),

        JLLBuildInfo(;
            src_version = v"1.2.13+1",
            platform = Platform("armv7l", "linux"; call_abi = "eabihf", libc = "glibc"),
            name = "Zlib",
            artifact = JLLArtifactBinding(;
                treehash = "68112b5a8529eb286600242e0bb0b4660dc0f69e",
                download_sources = [
                    JLLArtifactSource(
                        "https://github.com/JuliaBinaryWrappers/Zlib_jll.jl/releases/download/Zlib-v1.2.13+1/Zlib.v1.2.13.armv7l-linux-gnueabihf.tar.gz",
                        "d318ba13608b9bce234176c693d465f78dcefc3f0edea6558ecd2041349a8a2e",
                    ),
                ],
            ),
            products = [
                JLLLibraryProduct(
                    :libz,
                    "lib/libz.so",
                    [],
                    flags = [:RTLD_LAZY, :RTLD_DEEPBIND],
                ),
            ],
            licenses = [zlib_license],
        ),

        JLLBuildInfo(;
            src_version = v"1.2.13+1",
            platform = Platform("armv7l", "linux"; call_abi = "eabihf", libc = "musl"),
            name = "Zlib",
            artifact = JLLArtifactBinding(;
                treehash = "9d727d53f99aee4faed3c3447ef080c0a4584a7c",
                download_sources = [
                    JLLArtifactSource(
                        "https://github.com/JuliaBinaryWrappers/Zlib_jll.jl/releases/download/Zlib-v1.2.13+1/Zlib.v1.2.13.armv7l-linux-musleabihf.tar.gz",
                        "e039a7ff167a02fcf2aa66544c39120c15250405259053cb4fade13b647b36a5",
                    ),
                ],
            ),
            products = [
                JLLLibraryProduct(
                    :libz,
                    "lib/libz.so",
                    [],
                    flags = [:RTLD_LAZY, :RTLD_DEEPBIND],
                ),
            ],
            licenses = [zlib_license],
        ),

        JLLBuildInfo(;
            src_version = v"1.2.13+1",
            platform = Platform("i686", "linux"; libc = "glibc"),
            name = "Zlib",
            artifact = JLLArtifactBinding(;
                treehash = "e2c7906256e3799bbbed63fd4b722c13d91acc77",
                download_sources = [
                    JLLArtifactSource(
                        "https://github.com/JuliaBinaryWrappers/Zlib_jll.jl/releases/download/Zlib-v1.2.13+1/Zlib.v1.2.13.i686-linux-gnu.tar.gz",
                        "66404bf2b409f52a01a76e13e9903e5946ef73b8198889caf9d832d4c4c710fe",
                    ),
                ],
            ),
            products = [
                JLLLibraryProduct(
                    :libz,
                    "lib/libz.so",
                    [],
                    flags = [:RTLD_LAZY, :RTLD_DEEPBIND],
                ),
            ],
            licenses = [zlib_license],
        ),

        JLLBuildInfo(;
            src_version = v"1.2.13+1",
            platform = Platform("i686", "linux"; libc = "musl"),
            name = "Zlib",
            artifact = JLLArtifactBinding(;
                treehash = "36f4a2f291c7d540502d2c582df637a07860a2ae",
                download_sources = [
                    JLLArtifactSource(
                        "https://github.com/JuliaBinaryWrappers/Zlib_jll.jl/releases/download/Zlib-v1.2.13+1/Zlib.v1.2.13.i686-linux-musl.tar.gz",
                        "d9fd0bdaeb13217abcd26ce6ceaeac7dd6afd85c84eb727c368b6cbaa3f2968c",
                    ),
                ],
            ),
            products = [
                JLLLibraryProduct(
                    :libz,
                    "lib/libz.so",
                    [],
                    flags = [:RTLD_LAZY, :RTLD_DEEPBIND],
                ),
            ],
            licenses = [zlib_license],
        ),

        JLLBuildInfo(;
            src_version = v"1.2.13+1",
            platform = Platform("i686", "windows"; ),
            name = "Zlib",
            artifact = JLLArtifactBinding(;
                treehash = "8c6b8a1d5c1031889f6cbcdd6325df407ad53822",
                download_sources = [
                    JLLArtifactSource(
                        "https://github.com/JuliaBinaryWrappers/Zlib_jll.jl/releases/download/Zlib-v1.2.13+1/Zlib.v1.2.13.i686-w64-mingw32.tar.gz",
                        "ca139fdf7507ef95631ce465fcba7cf12e9a87ffda58383e5b66d717b51641c6",
                    ),
                ],
            ),
            products = [
                JLLLibraryProduct(
                    :libz,
                    "bin\\libz.dll",
                    [],
                    flags = [:RTLD_LAZY, :RTLD_DEEPBIND],
                ),
            ],
            licenses = [zlib_license],
        ),

        JLLBuildInfo(;
            src_version = v"1.2.13+1",
            platform = Platform("powerpc64le", "linux"; libc = "glibc"),
            name = "Zlib",
            artifact = JLLArtifactBinding(;
                treehash = "10ba2029939134fccc5399818565bdff411ccaf5",
                download_sources = [
                    JLLArtifactSource(
                        "https://github.com/JuliaBinaryWrappers/Zlib_jll.jl/releases/download/Zlib-v1.2.13+1/Zlib.v1.2.13.powerpc64le-linux-gnu.tar.gz",
                        "e73e8d611ac5c850b796dfb637ac31e5b9ef2e9b9c7e2c93f504c74987f50ad9",
                    ),
                ],
            ),
            products = [
                JLLLibraryProduct(
                    :libz,
                    "lib/libz.so",
                    [],
                    flags = [:RTLD_LAZY, :RTLD_DEEPBIND],
                ),
            ],
            licenses = [zlib_license],
        ),

        JLLBuildInfo(;
            src_version = v"1.2.13+1",
            platform = Platform("x86_64", "macos"; ),
            name = "Zlib",
            artifact = JLLArtifactBinding(;
                treehash = "0d1569be418e930c068521e8a1a43b09640f5ad6",
                download_sources = [
                    JLLArtifactSource(
                        "https://github.com/JuliaBinaryWrappers/Zlib_jll.jl/releases/download/Zlib-v1.2.13+1/Zlib.v1.2.13.x86_64-apple-darwin.tar.gz",
                        "0399ce8b71d45668e2752555ab2898bfae9ebcf5ad16ef2ff813d5ae7ca9487a",
                    ),
                ],
            ),
            products = [
                JLLLibraryProduct(
                    :libz,
                    "lib/libz.1.2.13.dylib",
                    [],
                    flags = [:RTLD_LAZY, :RTLD_DEEPBIND],
                ),
            ],
            licenses = [zlib_license],
        ),

        JLLBuildInfo(;
            src_version = v"1.2.13+1",
            platform = Platform("x86_64", "linux"; libc = "glibc"),
            name = "Zlib",
            artifact = JLLArtifactBinding(;
                treehash = "66cb477c2221860067abc2197baece8d67be5bb6",
                download_sources = [
                    JLLArtifactSource(
                        "https://github.com/JuliaBinaryWrappers/Zlib_jll.jl/releases/download/Zlib-v1.2.13+1/Zlib.v1.2.13.x86_64-linux-gnu.tar.gz",
                        "46678eabc97358858872a85192903f427288f9ea814bddc6b3e81a8681b63da4",
                    ),
                ],
            ),
            products = [
                JLLLibraryProduct(
                    :libz,
                    "lib/libz.so",
                    [],
                    flags = [:RTLD_LAZY, :RTLD_DEEPBIND],
                ),
            ],
            licenses = [zlib_license],
        ),

        JLLBuildInfo(;
            src_version = v"1.2.13+1",
            platform = Platform("x86_64", "linux"; libc = "glibc", sanitize = "memory"),
            name = "Zlib",
            artifact = JLLArtifactBinding(;
                treehash = "b86177a36c8ba482120ab766b6670177dffd72f3",
                download_sources = [
                    JLLArtifactSource(
                        "https://github.com/JuliaBinaryWrappers/Zlib_jll.jl/releases/download/Zlib-v1.2.13+1/Zlib.v1.2.13.x86_64-linux-gnu-sanitize+memory.tar.gz",
                        "cfa0801e82c621511ad0ca0b8594fe19211198c3144fd2c87aadd48b66d5d106",
                    ),
                ],
            ),
            products = [
                JLLLibraryProduct(
                    :libz,
                    "lib/libz.so",
                    [],
                    flags = [:RTLD_LAZY, :RTLD_DEEPBIND],
                ),
            ],
            licenses = [zlib_license],
        ),

        JLLBuildInfo(;
            src_version = v"1.2.13+1",
            platform = Platform("x86_64", "linux"; libc = "musl"),
            name = "Zlib",
            artifact = JLLArtifactBinding(;
                treehash = "d4212eaa51b38b228b3238013323a612428c2f81",
                download_sources = [
                    JLLArtifactSource(
                        "https://github.com/JuliaBinaryWrappers/Zlib_jll.jl/releases/download/Zlib-v1.2.13+1/Zlib.v1.2.13.x86_64-linux-musl.tar.gz",
                        "9878bc6a6ca7c5386de0af7e65be232929da00dd5cb279b89331ac8c28e68946",
                    ),
                ],
            ),
            products = [
                JLLLibraryProduct(
                    :libz,
                    "lib/libz.so",
                    [],
                    flags = [:RTLD_LAZY, :RTLD_DEEPBIND],
                ),
            ],
            licenses = [zlib_license],
        ),

        JLLBuildInfo(;
            src_version = v"1.2.13+1",
            platform = Platform("x86_64", "freebsd"; ),
            name = "Zlib",
            artifact = JLLArtifactBinding(;
                treehash = "aae30f22ece1dd1f6979276b823e1464413adea7",
                download_sources = [
                    JLLArtifactSource(
                        "https://github.com/JuliaBinaryWrappers/Zlib_jll.jl/releases/download/Zlib-v1.2.13+1/Zlib.v1.2.13.x86_64-unknown-freebsd.tar.gz",
                        "7eb2cda854c53bb3d343c72433bf77259bdeae434984f88deb79d4f1d64ff53d",
                    ),
                ],
            ),
            products = [
                JLLLibraryProduct(
                    :libz,
                    "lib/libz.so",
                    [],
                    flags = [:RTLD_LAZY, :RTLD_DEEPBIND],
                ),
            ],
            licenses = [zlib_license],
        ),

        JLLBuildInfo(;
            src_version = v"1.2.13+1",
            platform = Platform("x86_64", "windows"; ),
            name = "Zlib",
            artifact = JLLArtifactBinding(;
                treehash = "33c83c4294a01e0aa19e68915605cf649b379c4b",
                download_sources = [
                    JLLArtifactSource(
                        "https://github.com/JuliaBinaryWrappers/Zlib_jll.jl/releases/download/Zlib-v1.2.13+1/Zlib.v1.2.13.x86_64-w64-mingw32.tar.gz",
                        "94e6f53f78af66a9d9f25e47a6038640f803980cfc6d5a0dcbb6521a0748283a",
                    ),
                ],
            ),
            products = [
                JLLLibraryProduct(
                    :libz,
                    "bin\\libz.dll",
                    [],
                    flags = [:RTLD_LAZY, :RTLD_DEEPBIND],
                ),
            ],
            licenses = [zlib_license],
        ),

    ]
)

