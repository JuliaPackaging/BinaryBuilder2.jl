# Note: This has been altered to use a new FileProduct, `terminfo`,
# instead of using `artifact_dir`, as that no longer exists, due
# to JLLs being able to be altered by preferences and no longer
# belonging to a single artifact; users should instead just use
# `FileProduct`s to get at what they want.
ncurses_init = """
if Sys.isunix()
    path = joinpath(terminfo, "share", "terminfo")
    old = get(ENV, "TERMINFO_DIRS", nothing)
    if old === nothing
        ENV["TERMINFO_DIRS"] = path
    else
        ENV["TERMINFO_DIRS"] = old * ":" * path
    end
end
"""

ncurses_license = JLLBuildLicense("LICENSE.md", """
Copyright 2018-2023,2024 Thomas E. Dickey
Copyright 1998-2017,2018 Free Software Foundation, Inc.

Permission is hereby granted, free of charge, to any person obtaining a
copy of this software and associated documentation files (the
"Software"), to deal in the Software without restriction, including
without limitation the rights to use, copy, modify, merge, publish,
distribute, distribute with modifications, sublicense, and/or sell
copies of the Software, and to permit persons to whom the Software is
furnished to do so, subject to the following conditions:

The above copyright notice and this permission notice shall be included
in all copies or substantial portions of the Software.

THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS
OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF
MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT.
IN NO EVENT SHALL THE ABOVE COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM,
DAMAGES OR OTHER LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR
OTHERWISE, ARISING FROM, OUT OF OR IN CONNECTION WITH THE SOFTWARE OR
THE USE OR OTHER DEALINGS IN THE SOFTWARE.

Except as contained in this notice, the name(s) of the above copyright
holders shall not be used in advertising or otherwise to promote the
sale, use or other dealings in this Software without prior written
authorization.

-- vile:txtmode fc=72
-- \$Id: COPYING,v 1.13 2024/01/05 21:13:17 tom Exp \$
""")

jll = JLLInfo(;
    name = "Ncurses",
    version = v"6.4.1+0",
    builds = [
        JLLBuildInfo(;
            src_version = v"6.4.1+0",
            deps = [
            ],
            sources = [],
            platform = Platform("aarch64", "macos"; ),
            name = "Ncurses",
            artifact = JLLArtifactBinding(;
                treehash = "526dce896ac072d350ffb42a52344708cae3c27e",
                download_sources = [
                    JLLArtifactSource(
                        "https://github.com/JuliaBinaryWrappers/Ncurses_jll.jl/releases/download/Ncurses-v6.4.1+0/Ncurses.v6.4.1.aarch64-apple-darwin.tar.gz",
                        "a39458878a525e25f47d235e60531bc68a4a85b2295db2a4185716f5d7bdcd9c",
                    ),
                ],
            ),
            products = [
                JLLFileProduct(
                    :terminfo,
                    "share/terminfo",
                ),
                JLLLibraryProduct(
                    :libform,
                    "lib/libform.dylib",
                    [JLLLibraryDep(nothing, :libncurses)],
                    flags = [:RTLD_LAZY, :RTLD_DEEPBIND],
                    soname = "@rpath/libformw.6.dylib",
                ),
                JLLLibraryProduct(
                    :libmenu,
                    "lib/libmenu.dylib",
                    [JLLLibraryDep(nothing, :libncurses)],
                    flags = [:RTLD_LAZY, :RTLD_DEEPBIND],
                    soname = "@rpath/libmenuw.6.dylib",
                ),
                JLLLibraryProduct(
                    :libncurses,
                    "lib/libncurses.dylib",
                    [],
                    flags = [:RTLD_LAZY, :RTLD_DEEPBIND],
                    soname = "@rpath/libncursesw.6.dylib",
                ),
                JLLLibraryProduct(
                    :libpanel,
                    "lib/libpanel.dylib",
                    [JLLLibraryDep(nothing, :libncurses)],
                    flags = [:RTLD_LAZY, :RTLD_DEEPBIND],
                    soname = "@rpath/libpanelw.6.dylib",
                ),
            ],
            init_def = ncurses_init,
            licenses = [ncurses_license],
        ),

        JLLBuildInfo(;
            src_version = v"6.4.1+0",
            deps = [
            ],
            sources = [],
            platform = Platform("aarch64", "linux"; libc = "glibc"),
            name = "Ncurses",
            artifact = JLLArtifactBinding(;
                treehash = "b18b9a5730acdf1a6c21e015c272b276ea8c0cc7",
                download_sources = [
                    JLLArtifactSource(
                        "https://github.com/JuliaBinaryWrappers/Ncurses_jll.jl/releases/download/Ncurses-v6.4.1+0/Ncurses.v6.4.1.aarch64-linux-gnu.tar.gz",
                        "0f8253ec72d668abf9d4b18a539e3d98f50afb55cd5a1f4d715b681503b9a1e9",
                    ),
                ],
            ),
            products = [
                JLLFileProduct(
                    :terminfo,
                    "share/terminfo",
                ),
                JLLLibraryProduct(
                    :libform,
                    "lib/libform.so",
                    [JLLLibraryDep(nothing, :libncurses)],
                    flags = [:RTLD_LAZY, :RTLD_DEEPBIND],
                    soname = "libformw.so.6",
                ),
                JLLLibraryProduct(
                    :libmenu,
                    "lib/libmenu.so",
                    [JLLLibraryDep(nothing, :libncurses)],
                    flags = [:RTLD_LAZY, :RTLD_DEEPBIND],
                    soname = "libmenuw.so.6",
                ),
                JLLLibraryProduct(
                    :libncurses,
                    "lib/libncurses.so",
                    [],
                    flags = [:RTLD_LAZY, :RTLD_DEEPBIND],
                    soname = "libncursesw.so.6",
                ),
                JLLLibraryProduct(
                    :libpanel,
                    "lib/libpanel.so",
                    [JLLLibraryDep(nothing, :libncurses)],
                    flags = [:RTLD_LAZY, :RTLD_DEEPBIND],
                    soname = "libpanelw.so.6",
                ),
            ],
            init_def = ncurses_init,
            licenses = [ncurses_license],
        ),

        JLLBuildInfo(;
            src_version = v"6.4.1+0",
            deps = [
            ],
            sources = [],
            platform = Platform("aarch64", "linux"; libc = "musl"),
            name = "Ncurses",
            artifact = JLLArtifactBinding(;
                treehash = "8a9d394d12530b5ccb49c17511db28f3aaae40b5",
                download_sources = [
                    JLLArtifactSource(
                        "https://github.com/JuliaBinaryWrappers/Ncurses_jll.jl/releases/download/Ncurses-v6.4.1+0/Ncurses.v6.4.1.aarch64-linux-musl.tar.gz",
                        "8b437db85a4986994bd59f7ba285675993fbb684bf7a40f41ddd59c76487d97e",
                    ),
                ],
            ),
            products = [
                JLLFileProduct(
                    :terminfo,
                    "share/terminfo",
                ),
                JLLLibraryProduct(
                    :libform,
                    "lib/libform.so",
                    [JLLLibraryDep(nothing, :libncurses)],
                    flags = [:RTLD_LAZY, :RTLD_DEEPBIND],
                    soname = "libformw.so.6",
                ),
                JLLLibraryProduct(
                    :libmenu,
                    "lib/libmenu.so",
                    [JLLLibraryDep(nothing, :libncurses)],
                    flags = [:RTLD_LAZY, :RTLD_DEEPBIND],
                    soname = "libmenuw.so.6",
                ),
                JLLLibraryProduct(
                    :libncurses,
                    "lib/libncurses.so",
                    [],
                    flags = [:RTLD_LAZY, :RTLD_DEEPBIND],
                    soname = "libncursesw.so.6",
                ),
                JLLLibraryProduct(
                    :libpanel,
                    "lib/libpanel.so",
                    [JLLLibraryDep(nothing, :libncurses)],
                    flags = [:RTLD_LAZY, :RTLD_DEEPBIND],
                    soname = "libpanelw.so.6",
                ),
            ],
            init_def = ncurses_init,
            licenses = [ncurses_license],
        ),

        JLLBuildInfo(;
            src_version = v"6.4.1+0",
            deps = [
            ],
            sources = [],
            platform = Platform("armv6l", "linux"; call_abi = "eabihf", libc = "glibc"),
            name = "Ncurses",
            artifact = JLLArtifactBinding(;
                treehash = "953e2f93ebc878ad8a88cae830fefb68fb8b690f",
                download_sources = [
                    JLLArtifactSource(
                        "https://github.com/JuliaBinaryWrappers/Ncurses_jll.jl/releases/download/Ncurses-v6.4.1+0/Ncurses.v6.4.1.armv6l-linux-gnueabihf.tar.gz",
                        "c32be8a39d20e29151b829ed0e5acb3b984c6d8bda26f17cb4466a6a810aced1",
                    ),
                ],
            ),
            products = [
                JLLFileProduct(
                    :terminfo,
                    "share/terminfo",
                ),
                JLLLibraryProduct(
                    :libform,
                    "lib/libform.so",
                    [JLLLibraryDep(nothing, :libncurses)],
                    flags = [:RTLD_LAZY, :RTLD_DEEPBIND],
                    soname = "libformw.so.6",
                ),
                JLLLibraryProduct(
                    :libmenu,
                    "lib/libmenu.so",
                    [JLLLibraryDep(nothing, :libncurses)],
                    flags = [:RTLD_LAZY, :RTLD_DEEPBIND],
                    soname = "libmenuw.so.6",
                ),
                JLLLibraryProduct(
                    :libncurses,
                    "lib/libncurses.so",
                    [],
                    flags = [:RTLD_LAZY, :RTLD_DEEPBIND],
                    soname = "libncursesw.so.6",
                ),
                JLLLibraryProduct(
                    :libpanel,
                    "lib/libpanel.so",
                    [JLLLibraryDep(nothing, :libncurses)],
                    flags = [:RTLD_LAZY, :RTLD_DEEPBIND],
                    soname = "libpanelw.so.6",
                ),
            ],
            init_def = ncurses_init,
            licenses = [ncurses_license],
        ),

        JLLBuildInfo(;
            src_version = v"6.4.1+0",
            deps = [
            ],
            sources = [],
            platform = Platform("armv6l", "linux"; call_abi = "eabihf", libc = "musl"),
            name = "Ncurses",
            artifact = JLLArtifactBinding(;
                treehash = "f89d7d066628a23330c8de05e32b44e2c1dc7d11",
                download_sources = [
                    JLLArtifactSource(
                        "https://github.com/JuliaBinaryWrappers/Ncurses_jll.jl/releases/download/Ncurses-v6.4.1+0/Ncurses.v6.4.1.armv6l-linux-musleabihf.tar.gz",
                        "c0a7c89d70194fa6dea258f03d17ab5a6049fc05cb147bd929a2813335e5e2ba",
                    ),
                ],
            ),
            products = [
                JLLFileProduct(
                    :terminfo,
                    "share/terminfo",
                ),
                JLLLibraryProduct(
                    :libform,
                    "lib/libform.so",
                    [JLLLibraryDep(nothing, :libncurses)],
                    flags = [:RTLD_LAZY, :RTLD_DEEPBIND],
                    soname = "libformw.so.6",
                ),
                JLLLibraryProduct(
                    :libmenu,
                    "lib/libmenu.so",
                    [JLLLibraryDep(nothing, :libncurses)],
                    flags = [:RTLD_LAZY, :RTLD_DEEPBIND],
                    soname = "libmenuw.so.6",
                ),
                JLLLibraryProduct(
                    :libncurses,
                    "lib/libncurses.so",
                    [],
                    flags = [:RTLD_LAZY, :RTLD_DEEPBIND],
                    soname = "libncursesw.so.6",
                ),
                JLLLibraryProduct(
                    :libpanel,
                    "lib/libpanel.so",
                    [JLLLibraryDep(nothing, :libncurses)],
                    flags = [:RTLD_LAZY, :RTLD_DEEPBIND],
                    soname = "libpanelw.so.6",
                ),
            ],
            init_def = ncurses_init,
            licenses = [ncurses_license],
        ),

        JLLBuildInfo(;
            src_version = v"6.4.1+0",
            deps = [
            ],
            sources = [],
            platform = Platform("armv7l", "linux"; call_abi = "eabihf", libc = "glibc"),
            name = "Ncurses",
            artifact = JLLArtifactBinding(;
                treehash = "c2811457c8fc9e81e467708b34ff4515eccb8395",
                download_sources = [
                    JLLArtifactSource(
                        "https://github.com/JuliaBinaryWrappers/Ncurses_jll.jl/releases/download/Ncurses-v6.4.1+0/Ncurses.v6.4.1.armv7l-linux-gnueabihf.tar.gz",
                        "1de0253e83f49dfbe6bd9d79b15458708a3f3af157672fc08133cbac1df79bbe",
                    ),
                ],
            ),
            products = [
                JLLFileProduct(
                    :terminfo,
                    "share/terminfo",
                ),
                JLLLibraryProduct(
                    :libform,
                    "lib/libform.so",
                    [JLLLibraryDep(nothing, :libncurses)],
                    flags = [:RTLD_LAZY, :RTLD_DEEPBIND],
                    soname = "libformw.so.6",
                ),
                JLLLibraryProduct(
                    :libmenu,
                    "lib/libmenu.so",
                    [JLLLibraryDep(nothing, :libncurses)],
                    flags = [:RTLD_LAZY, :RTLD_DEEPBIND],
                    soname = "libmenuw.so.6",
                ),
                JLLLibraryProduct(
                    :libncurses,
                    "lib/libncurses.so",
                    [],
                    flags = [:RTLD_LAZY, :RTLD_DEEPBIND],
                    soname = "libncursesw.so.6",
                ),
                JLLLibraryProduct(
                    :libpanel,
                    "lib/libpanel.so",
                    [JLLLibraryDep(nothing, :libncurses)],
                    flags = [:RTLD_LAZY, :RTLD_DEEPBIND],
                    soname = "libpanelw.so.6",
                ),
            ],
            init_def = ncurses_init,
            licenses = [ncurses_license],
        ),

        JLLBuildInfo(;
            src_version = v"6.4.1+0",
            deps = [
            ],
            sources = [],
            platform = Platform("armv7l", "linux"; call_abi = "eabihf", libc = "musl"),
            name = "Ncurses",
            artifact = JLLArtifactBinding(;
                treehash = "1f666090cf2ca53aa7bf86801eb9c3ab9de289d8",
                download_sources = [
                    JLLArtifactSource(
                        "https://github.com/JuliaBinaryWrappers/Ncurses_jll.jl/releases/download/Ncurses-v6.4.1+0/Ncurses.v6.4.1.armv7l-linux-musleabihf.tar.gz",
                        "6c208d8c5a78f6181aa200a76729e776e32c5b7561abe8791f3a76af29a7929b",
                    ),
                ],
            ),
            products = [
                JLLFileProduct(
                    :terminfo,
                    "share/terminfo",
                ),
                JLLLibraryProduct(
                    :libform,
                    "lib/libform.so",
                    [JLLLibraryDep(nothing, :libncurses)],
                    flags = [:RTLD_LAZY, :RTLD_DEEPBIND],
                    soname = "libformw.so.6",
                ),
                JLLLibraryProduct(
                    :libmenu,
                    "lib/libmenu.so",
                    [JLLLibraryDep(nothing, :libncurses)],
                    flags = [:RTLD_LAZY, :RTLD_DEEPBIND],
                    soname = "libmenuw.so.6",
                ),
                JLLLibraryProduct(
                    :libncurses,
                    "lib/libncurses.so",
                    [],
                    flags = [:RTLD_LAZY, :RTLD_DEEPBIND],
                    soname = "libncursesw.so.6",
                ),
                JLLLibraryProduct(
                    :libpanel,
                    "lib/libpanel.so",
                    [JLLLibraryDep(nothing, :libncurses)],
                    flags = [:RTLD_LAZY, :RTLD_DEEPBIND],
                    soname = "libpanelw.so.6",
                ),
            ],
            init_def = ncurses_init,
            licenses = [ncurses_license],
        ),

        JLLBuildInfo(;
            src_version = v"6.4.1+0",
            deps = [
            ],
            sources = [],
            platform = Platform("i686", "linux"; libc = "glibc"),
            name = "Ncurses",
            artifact = JLLArtifactBinding(;
                treehash = "a90a3d50e868f09de1f6ec4e73bd17dd530b88fc",
                download_sources = [
                    JLLArtifactSource(
                        "https://github.com/JuliaBinaryWrappers/Ncurses_jll.jl/releases/download/Ncurses-v6.4.1+0/Ncurses.v6.4.1.i686-linux-gnu.tar.gz",
                        "e1de883fabb174ed3ffb43a808bf57d523ef83c0da7bb878dda50960157aed0b",
                    ),
                ],
            ),
            products = [
                JLLFileProduct(
                    :terminfo,
                    "share/terminfo",
                ),
                JLLLibraryProduct(
                    :libform,
                    "lib/libform.so",
                    [JLLLibraryDep(nothing, :libncurses)],
                    flags = [:RTLD_LAZY, :RTLD_DEEPBIND],
                    soname = "libformw.so.6",
                ),
                JLLLibraryProduct(
                    :libmenu,
                    "lib/libmenu.so",
                    [JLLLibraryDep(nothing, :libncurses)],
                    flags = [:RTLD_LAZY, :RTLD_DEEPBIND],
                    soname = "libmenuw.so.6",
                ),
                JLLLibraryProduct(
                    :libncurses,
                    "lib/libncurses.so",
                    [],
                    flags = [:RTLD_LAZY, :RTLD_DEEPBIND],
                    soname = "libncursesw.so.6",
                ),
                JLLLibraryProduct(
                    :libpanel,
                    "lib/libpanel.so",
                    [JLLLibraryDep(nothing, :libncurses)],
                    flags = [:RTLD_LAZY, :RTLD_DEEPBIND],
                    soname = "libpanelw.so.6",
                ),
            ],
            init_def = ncurses_init,
            licenses = [ncurses_license],
        ),

        JLLBuildInfo(;
            src_version = v"6.4.1+0",
            deps = [
            ],
            sources = [],
            platform = Platform("i686", "linux"; libc = "musl"),
            name = "Ncurses",
            artifact = JLLArtifactBinding(;
                treehash = "69a3c5614eb68320b8b9aa7d1c188e744ef0b061",
                download_sources = [
                    JLLArtifactSource(
                        "https://github.com/JuliaBinaryWrappers/Ncurses_jll.jl/releases/download/Ncurses-v6.4.1+0/Ncurses.v6.4.1.i686-linux-musl.tar.gz",
                        "2967b82aa373b3ed0bf149916bbb40b65db6b4c5f2758370397cb1d7d9efc1f1",
                    ),
                ],
            ),
            products = [
                JLLFileProduct(
                    :terminfo,
                    "share/terminfo",
                ),
                JLLLibraryProduct(
                    :libform,
                    "lib/libform.so",
                    [JLLLibraryDep(nothing, :libncurses)],
                    flags = [:RTLD_LAZY, :RTLD_DEEPBIND],
                    soname = "libformw.so.6",
                ),
                JLLLibraryProduct(
                    :libmenu,
                    "lib/libmenu.so",
                    [JLLLibraryDep(nothing, :libncurses)],
                    flags = [:RTLD_LAZY, :RTLD_DEEPBIND],
                    soname = "libmenuw.so.6",
                ),
                JLLLibraryProduct(
                    :libncurses,
                    "lib/libncurses.so",
                    [],
                    flags = [:RTLD_LAZY, :RTLD_DEEPBIND],
                    soname = "libncursesw.so.6",
                ),
                JLLLibraryProduct(
                    :libpanel,
                    "lib/libpanel.so",
                    [JLLLibraryDep(nothing, :libncurses)],
                    flags = [:RTLD_LAZY, :RTLD_DEEPBIND],
                    soname = "libpanelw.so.6",
                ),
            ],
            init_def = ncurses_init,
            licenses = [ncurses_license],
        ),

        JLLBuildInfo(;
            src_version = v"6.4.1+0",
            deps = [
            ],
            sources = [],
            platform = Platform("i686", "windows"; ),
            name = "Ncurses",
            artifact = JLLArtifactBinding(;
                treehash = "471a7dd439235b7d9bac3d5540c70e2dbc049b97",
                download_sources = [
                    JLLArtifactSource(
                        "https://github.com/JuliaBinaryWrappers/Ncurses_jll.jl/releases/download/Ncurses-v6.4.1+0/Ncurses.v6.4.1.i686-w64-mingw32.tar.gz",
                        "c548feb697c45902f49615c9774ddc51e9c2396c0ed7dbd26d501bd14927155b",
                    ),
                ],
            ),
            products = [
                JLLFileProduct(
                    :terminfo,
                    "share/terminfo",
                ),
                JLLLibraryProduct(
                    :libform,
                    "bin\\libform6.dll",
                    [JLLLibraryDep(nothing, :libncurses)],
                    flags = [:RTLD_LAZY, :RTLD_DEEPBIND],
                    soname = "libform6.dll",
                ),
                JLLLibraryProduct(
                    :libmenu,
                    "bin\\libmenu6.dll",
                    [JLLLibraryDep(nothing, :libncurses)],
                    flags = [:RTLD_LAZY, :RTLD_DEEPBIND],
                    soname = "libmenu6.dll",
                ),
                JLLLibraryProduct(
                    :libncurses,
                    "bin\\libncurses6.dll",
                    [],
                    flags = [:RTLD_LAZY, :RTLD_DEEPBIND],
                    soname = "libncurses6.dll",
                ),
                JLLLibraryProduct(
                    :libpanel,
                    "bin\\libpanel6.dll",
                    [JLLLibraryDep(nothing, :libncurses)],
                    flags = [:RTLD_LAZY, :RTLD_DEEPBIND],
                    soname = "libpanel6.dll",
                ),
            ],
            init_def = ncurses_init,
            licenses = [ncurses_license],
        ),

        JLLBuildInfo(;
            src_version = v"6.4.1+0",
            deps = [
            ],
            sources = [],
            platform = Platform("powerpc64le", "linux"; libc = "glibc"),
            name = "Ncurses",
            artifact = JLLArtifactBinding(;
                treehash = "ec1f907eb14042b159d84e0c1a6963a169fe2a59",
                download_sources = [
                    JLLArtifactSource(
                        "https://github.com/JuliaBinaryWrappers/Ncurses_jll.jl/releases/download/Ncurses-v6.4.1+0/Ncurses.v6.4.1.powerpc64le-linux-gnu.tar.gz",
                        "5a72e42f3b563146ecc142749731b8e9cbf79ff7877d2e1bf5e8bba496ff1b77",
                    ),
                ],
            ),
            products = [
                JLLFileProduct(
                    :terminfo,
                    "share/terminfo",
                ),
                JLLLibraryProduct(
                    :libform,
                    "lib/libform.so",
                    [JLLLibraryDep(nothing, :libncurses)],
                    flags = [:RTLD_LAZY, :RTLD_DEEPBIND],
                    soname = "libformw.so.6",
                ),
                JLLLibraryProduct(
                    :libmenu,
                    "lib/libmenu.so",
                    [JLLLibraryDep(nothing, :libncurses)],
                    flags = [:RTLD_LAZY, :RTLD_DEEPBIND],
                    soname = "libmenuw.so.6",
                ),
                JLLLibraryProduct(
                    :libncurses,
                    "lib/libncurses.so",
                    [],
                    flags = [:RTLD_LAZY, :RTLD_DEEPBIND],
                    soname = "libncursesw.so.6",
                ),
                JLLLibraryProduct(
                    :libpanel,
                    "lib/libpanel.so",
                    [JLLLibraryDep(nothing, :libncurses)],
                    flags = [:RTLD_LAZY, :RTLD_DEEPBIND],
                    soname = "libpanelw.so.6",
                ),
            ],
            init_def = ncurses_init,
            licenses = [ncurses_license],
        ),

        JLLBuildInfo(;
            src_version = v"6.4.1+0",
            deps = [
            ],
            sources = [],
            platform = Platform("x86_64", "macos"; ),
            name = "Ncurses",
            artifact = JLLArtifactBinding(;
                treehash = "9c72d8035eb6b79b864e167e30ddb827cf4f24f6",
                download_sources = [
                    JLLArtifactSource(
                        "https://github.com/JuliaBinaryWrappers/Ncurses_jll.jl/releases/download/Ncurses-v6.4.1+0/Ncurses.v6.4.1.x86_64-apple-darwin.tar.gz",
                        "63a4bc6f9bb2c68e81095fbcbad3b66923bbb28229eb558acdf8dc6774c0b4f4",
                    ),
                ],
            ),
            products = [
                JLLFileProduct(
                    :terminfo,
                    "share/terminfo",
                ),
                JLLLibraryProduct(
                    :libform,
                    "lib/libform.dylib",
                    [JLLLibraryDep(nothing, :libncurses)],
                    flags = [:RTLD_LAZY, :RTLD_DEEPBIND],
                    soname = "@rpath/libformw.6.dylib",
                ),
                JLLLibraryProduct(
                    :libmenu,
                    "lib/libmenu.dylib",
                    [JLLLibraryDep(nothing, :libncurses)],
                    flags = [:RTLD_LAZY, :RTLD_DEEPBIND],
                    soname = "@rpath/libmenuw.6.dylib",
                ),
                JLLLibraryProduct(
                    :libncurses,
                    "lib/libncurses.dylib",
                    [],
                    flags = [:RTLD_LAZY, :RTLD_DEEPBIND],
                    soname = "@rpath/libncursesw.6.dylib",
                ),
                JLLLibraryProduct(
                    :libpanel,
                    "lib/libpanel.dylib",
                    [JLLLibraryDep(nothing, :libncurses)],
                    flags = [:RTLD_LAZY, :RTLD_DEEPBIND],
                    soname = "@rpath/libpanelw.6.dylib",
                ),
            ],
            init_def = ncurses_init,
            licenses = [ncurses_license],
        ),

        JLLBuildInfo(;
            src_version = v"6.4.1+0",
            deps = [
            ],
            sources = [],
            platform = Platform("x86_64", "linux"; libc = "glibc"),
            name = "Ncurses",
            artifact = JLLArtifactBinding(;
                treehash = "842b011fd9789c15a0e0bc719a3f09f0e27dfb8f",
                download_sources = [
                    JLLArtifactSource(
                        "https://github.com/JuliaBinaryWrappers/Ncurses_jll.jl/releases/download/Ncurses-v6.4.1+0/Ncurses.v6.4.1.x86_64-linux-gnu.tar.gz",
                        "88b6432e2dbcd9e0583093f8a04b6bb56127ff00e98fa5c44e1833479cd052db",
                    ),
                ],
            ),
            products = [
                JLLFileProduct(
                    :terminfo,
                    "share/terminfo",
                ),
                JLLLibraryProduct(
                    :libform,
                    "lib/libform.so",
                    [JLLLibraryDep(nothing, :libncurses)],
                    flags = [:RTLD_LAZY, :RTLD_DEEPBIND],
                    soname = "libformw.so.6",
                ),
                JLLLibraryProduct(
                    :libmenu,
                    "lib/libmenu.so",
                    [JLLLibraryDep(nothing, :libncurses)],
                    flags = [:RTLD_LAZY, :RTLD_DEEPBIND],
                    soname = "libmenuw.so.6",
                ),
                JLLLibraryProduct(
                    :libncurses,
                    "lib/libncurses.so",
                    [],
                    flags = [:RTLD_LAZY, :RTLD_DEEPBIND],
                    soname = "libncursesw.so.6",
                ),
                JLLLibraryProduct(
                    :libpanel,
                    "lib/libpanel.so",
                    [JLLLibraryDep(nothing, :libncurses)],
                    flags = [:RTLD_LAZY, :RTLD_DEEPBIND],
                    soname = "libpanelw.so.6",
                ),
            ],
            init_def = ncurses_init,
            licenses = [ncurses_license],
        ),

        JLLBuildInfo(;
            src_version = v"6.4.1+0",
            deps = [
            ],
            sources = [],
            platform = Platform("x86_64", "linux"; libc = "musl"),
            name = "Ncurses",
            artifact = JLLArtifactBinding(;
                treehash = "8ae93fbe12b583b9f7e47162524da045992916e2",
                download_sources = [
                    JLLArtifactSource(
                        "https://github.com/JuliaBinaryWrappers/Ncurses_jll.jl/releases/download/Ncurses-v6.4.1+0/Ncurses.v6.4.1.x86_64-linux-musl.tar.gz",
                        "9c2240ab67abab916e54f617e9140248f7a9a7dac3912c07ecad32b911c7f817",
                    ),
                ],
            ),
            products = [
                JLLFileProduct(
                    :terminfo,
                    "share/terminfo",
                ),
                JLLLibraryProduct(
                    :libform,
                    "lib/libform.so",
                    [JLLLibraryDep(nothing, :libncurses)],
                    flags = [:RTLD_LAZY, :RTLD_DEEPBIND],
                    soname = "libformw.so.6",
                ),
                JLLLibraryProduct(
                    :libmenu,
                    "lib/libmenu.so",
                    [JLLLibraryDep(nothing, :libncurses)],
                    flags = [:RTLD_LAZY, :RTLD_DEEPBIND],
                    soname = "libmenuw.so.6",
                ),
                JLLLibraryProduct(
                    :libncurses,
                    "lib/libncurses.so",
                    [],
                    flags = [:RTLD_LAZY, :RTLD_DEEPBIND],
                    soname = "libncursesw.so.6",
                ),
                JLLLibraryProduct(
                    :libpanel,
                    "lib/libpanel.so",
                    [JLLLibraryDep(nothing, :libncurses)],
                    flags = [:RTLD_LAZY, :RTLD_DEEPBIND],
                    soname = "libpanelw.so.6",
                ),
            ],
            init_def = ncurses_init,
            licenses = [ncurses_license],
        ),

        JLLBuildInfo(;
            src_version = v"6.4.1+0",
            deps = [
            ],
            sources = [],
            platform = Platform("x86_64", "freebsd"; ),
            name = "Ncurses",
            artifact = JLLArtifactBinding(;
                treehash = "f3469d2c268ce5203bbe1c79f978f6869a777c43",
                download_sources = [
                    JLLArtifactSource(
                        "https://github.com/JuliaBinaryWrappers/Ncurses_jll.jl/releases/download/Ncurses-v6.4.1+0/Ncurses.v6.4.1.x86_64-unknown-freebsd.tar.gz",
                        "0d82db57e8c969c3775a6239ac32bf976a92bc0b9a62d71578b6805615cb1444",
                    ),
                ],
            ),
            products = [
                JLLFileProduct(
                    :terminfo,
                    "share/terminfo",
                ),
                JLLLibraryProduct(
                    :libform,
                    "lib/libform.so",
                    [JLLLibraryDep(nothing, :libncurses)],
                    flags = [:RTLD_LAZY, :RTLD_DEEPBIND],
                    soname = "libformw.so.6",
                ),
                JLLLibraryProduct(
                    :libmenu,
                    "lib/libmenu.so",
                    [JLLLibraryDep(nothing, :libncurses)],
                    flags = [:RTLD_LAZY, :RTLD_DEEPBIND],
                    soname = "libmenuw.so.6",
                ),
                JLLLibraryProduct(
                    :libncurses,
                    "lib/libncurses.so",
                    [],
                    flags = [:RTLD_LAZY, :RTLD_DEEPBIND],
                    soname = "libncursesw.so.6",
                ),
                JLLLibraryProduct(
                    :libpanel,
                    "lib/libpanel.so",
                    [JLLLibraryDep(nothing, :libncurses)],
                    flags = [:RTLD_LAZY, :RTLD_DEEPBIND],
                    soname = "libpanelw.so.6",
                ),
            ],
            init_def = ncurses_init,
            licenses = [ncurses_license],
        ),

        JLLBuildInfo(;
            src_version = v"6.4.1+0",
            deps = [
            ],
            sources = [],
            platform = Platform("x86_64", "windows"; ),
            name = "Ncurses",
            artifact = JLLArtifactBinding(;
                treehash = "95ad300678b9c9750e9b6892091d70bf3274ca30",
                download_sources = [
                    JLLArtifactSource(
                        "https://github.com/JuliaBinaryWrappers/Ncurses_jll.jl/releases/download/Ncurses-v6.4.1+0/Ncurses.v6.4.1.x86_64-w64-mingw32.tar.gz",
                        "d13e28365546e4de26fe8bf9ae3e12891083a033ce581dc5c91763c1dec52dfc",
                    ),
                ],
            ),
            products = [
                JLLFileProduct(
                    :terminfo,
                    "share/terminfo",
                ),
                JLLLibraryProduct(
                    :libform,
                    "bin\\libform6.dll",
                    [JLLLibraryDep(nothing, :libncurses)],
                    flags = [:RTLD_LAZY, :RTLD_DEEPBIND],
                    soname = "libform6.dll",
                ),
                JLLLibraryProduct(
                    :libmenu,
                    "bin\\libmenu6.dll",
                    [JLLLibraryDep(nothing, :libncurses)],
                    flags = [:RTLD_LAZY, :RTLD_DEEPBIND],
                    soname = "libmenu6.dll",
                ),
                JLLLibraryProduct(
                    :libncurses,
                    "bin\\libncurses6.dll",
                    [],
                    flags = [:RTLD_LAZY, :RTLD_DEEPBIND],
                    soname = "libncurses6.dll",
                ),
                JLLLibraryProduct(
                    :libpanel,
                    "bin\\libpanel6.dll",
                    [JLLLibraryDep(nothing, :libncurses)],
                    flags = [:RTLD_LAZY, :RTLD_DEEPBIND],
                    soname = "libpanel6.dll",
                ),
            ],
            init_def = ncurses_init,
            licenses = [ncurses_license],
        ),

    ]
)

