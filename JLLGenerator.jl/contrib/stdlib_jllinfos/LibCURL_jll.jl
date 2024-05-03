libcurl_on_load_callback_def = """
function libcurl_on_load_callback()
    @assert ccall(dlsym(libcurl, :curl_global_init), UInt32, (Clong,), 0x03) == 0
end
"""

jll = JLLInfo(;
    name = "LibCURL",
    version = v"8.0.1+1",
    artifacts = [
        JLLArtifactInfo(;
            src_version = v"8.0.1+1",
            deps = [
                JLLPackageDependency(
                    "LibSSH2_jll",
                    Base.UUID("29816b5a-b9ab-546f-933c-edad1886dfa8"),
                    "*",
                ),
                JLLPackageDependency(
                    "nghttp2_jll",
                    Base.UUID("8e850ede-7688-5339-a07c-302acd2aaf8d"),
                    "*",
                ),
                JLLPackageDependency(
                    "MbedTLS_jll",
                    Base.UUID("c8ffd9c3-330d-5841-b78e-0817d7145fa1"),
                    "~2.28.0",
                ),
                JLLPackageDependency(
                    "Zlib_jll",
                    Base.UUID("83775a58-1f1d-513f-b197-d71354ab007a"),
                    "*",
                ),
            ],
            sources = [],
            platform = Platform("aarch64", "macos"; ),
            name = "default",
            treehash = "e70670e057ab801f4b4b2b5f3cdd35f6a806bdc2",
            download_sources = [
                JLLArtifactSource(
                    "https://github.com/JuliaBinaryWrappers/LibCURL_jll.jl/releases/download/LibCURL-v8.0.1+1/LibCURL.v8.0.1.aarch64-apple-darwin.tar.gz",
                    "330e60e2c8b01e7c409c5fe0f260030ff1a6e2c1dee5b9599c36af21d78c5cfb",
                ),
            ],
            products = [
                JLLLibraryProduct(
                    :libcurl,
                    "lib/libcurl.4.dylib",
                    [
                        JLLLibraryDep(:nghttp2_jll, :libnghttp),
                        JLLLibraryDep(:LibSSH2_jll, :libssh2),
                        JLLLibraryDep(:MbedTLS_jll, :libmbedtls),
                        JLLLibraryDep(:MbedTLS_jll, :libmbedx509),
                        JLLLibraryDep(:MbedTLS_jll, :libmedcrypto),
                    ],
                    flags = [:RTLD_LAZY, :RTLD_DEEPBIND],
                    on_load_callback = :libcurl_on_load_callback_def,
                ),
            ],
            callback_defs = Dict(
                :libcurl_on_load_callback_def => libcurl_on_load_callback_def,
            )
        ),

        JLLArtifactInfo(;
            src_version = v"8.0.1+1",
            deps = [
                JLLPackageDependency(
                    "LibSSH2_jll",
                    Base.UUID("29816b5a-b9ab-546f-933c-edad1886dfa8"),
                    "*",
                ),
                JLLPackageDependency(
                    "nghttp2_jll",
                    Base.UUID("8e850ede-7688-5339-a07c-302acd2aaf8d"),
                    "*",
                ),
                JLLPackageDependency(
                    "MbedTLS_jll",
                    Base.UUID("c8ffd9c3-330d-5841-b78e-0817d7145fa1"),
                    "~2.28.0",
                ),
                JLLPackageDependency(
                    "Zlib_jll",
                    Base.UUID("83775a58-1f1d-513f-b197-d71354ab007a"),
                    "*",
                ),
            ],
            sources = [],
            platform = Platform("aarch64", "linux"; libc = "glibc"),
            name = "default",
            treehash = "311144249b9cf6e9015f9eafc261fd69b76015fe",
            download_sources = [
                JLLArtifactSource(
                    "https://github.com/JuliaBinaryWrappers/LibCURL_jll.jl/releases/download/LibCURL-v8.0.1+1/LibCURL.v8.0.1.aarch64-linux-gnu.tar.gz",
                    "4bc7de5dd7f02076fe5ac0e5aba06978ff2e189bf7844fc17464fea44e97c851",
                ),
            ],
            products = [
                JLLLibraryProduct(
                    :libcurl,
                    "lib/libcurl.so",
                    [
                        JLLLibraryDep(:nghttp2_jll, :libnghttp),
                        JLLLibraryDep(:LibSSH2_jll, :libssh2),
                        JLLLibraryDep(:MbedTLS_jll, :libmbedtls),
                        JLLLibraryDep(:MbedTLS_jll, :libmbedx509),
                        JLLLibraryDep(:MbedTLS_jll, :libmedcrypto),
                    ],
                    flags = [:RTLD_LAZY, :RTLD_DEEPBIND],
                    on_load_callback = :libcurl_on_load_callback_def,
                ),
            ],
            callback_defs = Dict(
                :libcurl_on_load_callback_def => libcurl_on_load_callback_def,
            )
        ),

        JLLArtifactInfo(;
            src_version = v"8.0.1+1",
            deps = [
                JLLPackageDependency(
                    "LibSSH2_jll",
                    Base.UUID("29816b5a-b9ab-546f-933c-edad1886dfa8"),
                    "*",
                ),
                JLLPackageDependency(
                    "nghttp2_jll",
                    Base.UUID("8e850ede-7688-5339-a07c-302acd2aaf8d"),
                    "*",
                ),
                JLLPackageDependency(
                    "MbedTLS_jll",
                    Base.UUID("c8ffd9c3-330d-5841-b78e-0817d7145fa1"),
                    "~2.28.0",
                ),
                JLLPackageDependency(
                    "Zlib_jll",
                    Base.UUID("83775a58-1f1d-513f-b197-d71354ab007a"),
                    "*",
                ),
            ],
            sources = [],
            platform = Platform("aarch64", "linux"; libc = "musl"),
            name = "default",
            treehash = "e08cacbd11c47df5ff670b76c323fd0a48f83590",
            download_sources = [
                JLLArtifactSource(
                    "https://github.com/JuliaBinaryWrappers/LibCURL_jll.jl/releases/download/LibCURL-v8.0.1+1/LibCURL.v8.0.1.aarch64-linux-musl.tar.gz",
                    "a70e6e84807c68a157fc85ff8c2aaacaa9e337185a602132d04e415dac4c8625",
                ),
            ],
            products = [
                JLLLibraryProduct(
                    :libcurl,
                    "lib/libcurl.so",
                    [
                        JLLLibraryDep(:nghttp2_jll, :libnghttp),
                        JLLLibraryDep(:LibSSH2_jll, :libssh2),
                        JLLLibraryDep(:MbedTLS_jll, :libmbedtls),
                        JLLLibraryDep(:MbedTLS_jll, :libmbedx509),
                        JLLLibraryDep(:MbedTLS_jll, :libmedcrypto),
                    ],
                    flags = [:RTLD_LAZY, :RTLD_DEEPBIND],
                    on_load_callback = :libcurl_on_load_callback_def,
                ),
            ],
            callback_defs = Dict(
                :libcurl_on_load_callback_def => libcurl_on_load_callback_def,
            )
        ),

        JLLArtifactInfo(;
            src_version = v"8.0.1+1",
            deps = [
                JLLPackageDependency(
                    "LibSSH2_jll",
                    Base.UUID("29816b5a-b9ab-546f-933c-edad1886dfa8"),
                    "*",
                ),
                JLLPackageDependency(
                    "nghttp2_jll",
                    Base.UUID("8e850ede-7688-5339-a07c-302acd2aaf8d"),
                    "*",
                ),
                JLLPackageDependency(
                    "MbedTLS_jll",
                    Base.UUID("c8ffd9c3-330d-5841-b78e-0817d7145fa1"),
                    "~2.28.0",
                ),
                JLLPackageDependency(
                    "Zlib_jll",
                    Base.UUID("83775a58-1f1d-513f-b197-d71354ab007a"),
                    "*",
                ),
            ],
            sources = [],
            platform = Platform("armv6l", "linux"; call_abi = "eabihf", libc = "glibc"),
            name = "default",
            treehash = "af18d17c5a83110e76c78b78fcf70a59d26743cf",
            download_sources = [
                JLLArtifactSource(
                    "https://github.com/JuliaBinaryWrappers/LibCURL_jll.jl/releases/download/LibCURL-v8.0.1+1/LibCURL.v8.0.1.armv6l-linux-gnueabihf.tar.gz",
                    "6a610a839126a7acf515802701668d279d3af2244423489c2961827719766f0e",
                ),
            ],
            products = [
                JLLLibraryProduct(
                    :libcurl,
                    "lib/libcurl.so",
                    [
                        JLLLibraryDep(:nghttp2_jll, :libnghttp),
                        JLLLibraryDep(:LibSSH2_jll, :libssh2),
                        JLLLibraryDep(:MbedTLS_jll, :libmbedtls),
                        JLLLibraryDep(:MbedTLS_jll, :libmbedx509),
                        JLLLibraryDep(:MbedTLS_jll, :libmedcrypto),
                    ],
                    flags = [:RTLD_LAZY, :RTLD_DEEPBIND],
                    on_load_callback = :libcurl_on_load_callback_def,
                ),
            ],
            callback_defs = Dict(
                :libcurl_on_load_callback_def => libcurl_on_load_callback_def,
            )
        ),

        JLLArtifactInfo(;
            src_version = v"8.0.1+1",
            deps = [
                JLLPackageDependency(
                    "LibSSH2_jll",
                    Base.UUID("29816b5a-b9ab-546f-933c-edad1886dfa8"),
                    "*",
                ),
                JLLPackageDependency(
                    "nghttp2_jll",
                    Base.UUID("8e850ede-7688-5339-a07c-302acd2aaf8d"),
                    "*",
                ),
                JLLPackageDependency(
                    "MbedTLS_jll",
                    Base.UUID("c8ffd9c3-330d-5841-b78e-0817d7145fa1"),
                    "~2.28.0",
                ),
                JLLPackageDependency(
                    "Zlib_jll",
                    Base.UUID("83775a58-1f1d-513f-b197-d71354ab007a"),
                    "*",
                ),
            ],
            sources = [],
            platform = Platform("armv6l", "linux"; call_abi = "eabihf", libc = "musl"),
            name = "default",
            treehash = "4a6f57148752a63a6d5d80ed557cac8a309089c8",
            download_sources = [
                JLLArtifactSource(
                    "https://github.com/JuliaBinaryWrappers/LibCURL_jll.jl/releases/download/LibCURL-v8.0.1+1/LibCURL.v8.0.1.armv6l-linux-musleabihf.tar.gz",
                    "4884d52824e46d607ca52b02d0bb4aca96dbb1850a77ed9d58b8196c56496f7f",
                ),
            ],
            products = [
                JLLLibraryProduct(
                    :libcurl,
                    "lib/libcurl.so",
                    [
                        JLLLibraryDep(:nghttp2_jll, :libnghttp),
                        JLLLibraryDep(:LibSSH2_jll, :libssh2),
                        JLLLibraryDep(:MbedTLS_jll, :libmbedtls),
                        JLLLibraryDep(:MbedTLS_jll, :libmbedx509),
                        JLLLibraryDep(:MbedTLS_jll, :libmedcrypto),
                    ],
                    flags = [:RTLD_LAZY, :RTLD_DEEPBIND],
                    on_load_callback = :libcurl_on_load_callback_def,
                ),
            ],
            callback_defs = Dict(
                :libcurl_on_load_callback_def => libcurl_on_load_callback_def,
            )
        ),

        JLLArtifactInfo(;
            src_version = v"8.0.1+1",
            deps = [
                JLLPackageDependency(
                    "LibSSH2_jll",
                    Base.UUID("29816b5a-b9ab-546f-933c-edad1886dfa8"),
                    "*",
                ),
                JLLPackageDependency(
                    "nghttp2_jll",
                    Base.UUID("8e850ede-7688-5339-a07c-302acd2aaf8d"),
                    "*",
                ),
                JLLPackageDependency(
                    "MbedTLS_jll",
                    Base.UUID("c8ffd9c3-330d-5841-b78e-0817d7145fa1"),
                    "~2.28.0",
                ),
                JLLPackageDependency(
                    "Zlib_jll",
                    Base.UUID("83775a58-1f1d-513f-b197-d71354ab007a"),
                    "*",
                ),
            ],
            sources = [],
            platform = Platform("armv7l", "linux"; call_abi = "eabihf", libc = "glibc"),
            name = "default",
            treehash = "3d2f1b4c4dc9287bd47427687cd272bc1c0faf3d",
            download_sources = [
                JLLArtifactSource(
                    "https://github.com/JuliaBinaryWrappers/LibCURL_jll.jl/releases/download/LibCURL-v8.0.1+1/LibCURL.v8.0.1.armv7l-linux-gnueabihf.tar.gz",
                    "774f38f7b04733a3121c933e33f8260db0d96e885fb01bf2f6859c7ec3217eb1",
                ),
            ],
            products = [
                JLLLibraryProduct(
                    :libcurl,
                    "lib/libcurl.so",
                    [
                        JLLLibraryDep(:nghttp2_jll, :libnghttp),
                        JLLLibraryDep(:LibSSH2_jll, :libssh2),
                        JLLLibraryDep(:MbedTLS_jll, :libmbedtls),
                        JLLLibraryDep(:MbedTLS_jll, :libmbedx509),
                        JLLLibraryDep(:MbedTLS_jll, :libmedcrypto),
                    ],
                    flags = [:RTLD_LAZY, :RTLD_DEEPBIND],
                    on_load_callback = :libcurl_on_load_callback_def,
                ),
            ],
            callback_defs = Dict(
                :libcurl_on_load_callback_def => libcurl_on_load_callback_def,
            )
        ),

        JLLArtifactInfo(;
            src_version = v"8.0.1+1",
            deps = [
                JLLPackageDependency(
                    "LibSSH2_jll",
                    Base.UUID("29816b5a-b9ab-546f-933c-edad1886dfa8"),
                    "*",
                ),
                JLLPackageDependency(
                    "nghttp2_jll",
                    Base.UUID("8e850ede-7688-5339-a07c-302acd2aaf8d"),
                    "*",
                ),
                JLLPackageDependency(
                    "MbedTLS_jll",
                    Base.UUID("c8ffd9c3-330d-5841-b78e-0817d7145fa1"),
                    "~2.28.0",
                ),
                JLLPackageDependency(
                    "Zlib_jll",
                    Base.UUID("83775a58-1f1d-513f-b197-d71354ab007a"),
                    "*",
                ),
            ],
            sources = [],
            platform = Platform("armv7l", "linux"; call_abi = "eabihf", libc = "musl"),
            name = "default",
            treehash = "678ae8af80f210ec4d159008ad74e5f79670fca2",
            download_sources = [
                JLLArtifactSource(
                    "https://github.com/JuliaBinaryWrappers/LibCURL_jll.jl/releases/download/LibCURL-v8.0.1+1/LibCURL.v8.0.1.armv7l-linux-musleabihf.tar.gz",
                    "80dee16bb6ae7e5268bb3e78ef49552a6a051870d64b5f6892b048818c375e5d",
                ),
            ],
            products = [
                JLLLibraryProduct(
                    :libcurl,
                    "lib/libcurl.so",
                    [
                        JLLLibraryDep(:nghttp2_jll, :libnghttp),
                        JLLLibraryDep(:LibSSH2_jll, :libssh2),
                        JLLLibraryDep(:MbedTLS_jll, :libmbedtls),
                        JLLLibraryDep(:MbedTLS_jll, :libmbedx509),
                        JLLLibraryDep(:MbedTLS_jll, :libmedcrypto),
                    ],
                    flags = [:RTLD_LAZY, :RTLD_DEEPBIND],
                    on_load_callback = :libcurl_on_load_callback_def,
                ),
            ],
            callback_defs = Dict(
                :libcurl_on_load_callback_def => libcurl_on_load_callback_def,
            )
        ),

        JLLArtifactInfo(;
            src_version = v"8.0.1+1",
            deps = [
                JLLPackageDependency(
                    "LibSSH2_jll",
                    Base.UUID("29816b5a-b9ab-546f-933c-edad1886dfa8"),
                    "*",
                ),
                JLLPackageDependency(
                    "nghttp2_jll",
                    Base.UUID("8e850ede-7688-5339-a07c-302acd2aaf8d"),
                    "*",
                ),
                JLLPackageDependency(
                    "MbedTLS_jll",
                    Base.UUID("c8ffd9c3-330d-5841-b78e-0817d7145fa1"),
                    "~2.28.0",
                ),
                JLLPackageDependency(
                    "Zlib_jll",
                    Base.UUID("83775a58-1f1d-513f-b197-d71354ab007a"),
                    "*",
                ),
            ],
            sources = [],
            platform = Platform("i686", "linux"; libc = "glibc"),
            name = "default",
            treehash = "bce914efe5ec8354ba669636c23cc27d5ccb41ec",
            download_sources = [
                JLLArtifactSource(
                    "https://github.com/JuliaBinaryWrappers/LibCURL_jll.jl/releases/download/LibCURL-v8.0.1+1/LibCURL.v8.0.1.i686-linux-gnu.tar.gz",
                    "e0cfb59a692801f729ec21f4bfde7f0b57ce4348877197ad593871254392ee88",
                ),
            ],
            products = [
                JLLLibraryProduct(
                    :libcurl,
                    "lib/libcurl.so",
                    [
                        JLLLibraryDep(:nghttp2_jll, :libnghttp),
                        JLLLibraryDep(:LibSSH2_jll, :libssh2),
                        JLLLibraryDep(:MbedTLS_jll, :libmbedtls),
                        JLLLibraryDep(:MbedTLS_jll, :libmbedx509),
                        JLLLibraryDep(:MbedTLS_jll, :libmedcrypto),
                    ],
                    flags = [:RTLD_LAZY, :RTLD_DEEPBIND],
                    on_load_callback = :libcurl_on_load_callback_def,
                ),
            ],
            callback_defs = Dict(
                :libcurl_on_load_callback_def => libcurl_on_load_callback_def,
            )
        ),

        JLLArtifactInfo(;
            src_version = v"8.0.1+1",
            deps = [
                JLLPackageDependency(
                    "LibSSH2_jll",
                    Base.UUID("29816b5a-b9ab-546f-933c-edad1886dfa8"),
                    "*",
                ),
                JLLPackageDependency(
                    "nghttp2_jll",
                    Base.UUID("8e850ede-7688-5339-a07c-302acd2aaf8d"),
                    "*",
                ),
                JLLPackageDependency(
                    "MbedTLS_jll",
                    Base.UUID("c8ffd9c3-330d-5841-b78e-0817d7145fa1"),
                    "~2.28.0",
                ),
                JLLPackageDependency(
                    "Zlib_jll",
                    Base.UUID("83775a58-1f1d-513f-b197-d71354ab007a"),
                    "*",
                ),
            ],
            sources = [],
            platform = Platform("i686", "linux"; libc = "musl"),
            name = "default",
            treehash = "ddddb272c9de3df38d1ea680d7306c1dba515ff4",
            download_sources = [
                JLLArtifactSource(
                    "https://github.com/JuliaBinaryWrappers/LibCURL_jll.jl/releases/download/LibCURL-v8.0.1+1/LibCURL.v8.0.1.i686-linux-musl.tar.gz",
                    "0f7f8ef96998834666fcdcac09ed50a61e6bcea3b99f1129022c4d7d731e6909",
                ),
            ],
            products = [
                JLLLibraryProduct(
                    :libcurl,
                    "lib/libcurl.so",
                    [
                        JLLLibraryDep(:nghttp2_jll, :libnghttp),
                        JLLLibraryDep(:LibSSH2_jll, :libssh2),
                        JLLLibraryDep(:MbedTLS_jll, :libmbedtls),
                        JLLLibraryDep(:MbedTLS_jll, :libmbedx509),
                        JLLLibraryDep(:MbedTLS_jll, :libmedcrypto),
                    ],
                    flags = [:RTLD_LAZY, :RTLD_DEEPBIND],
                    on_load_callback = :libcurl_on_load_callback_def,
                ),
            ],
            callback_defs = Dict(
                :libcurl_on_load_callback_def => libcurl_on_load_callback_def,
            )
        ),

        JLLArtifactInfo(;
            src_version = v"8.0.1+1",
            deps = [
                JLLPackageDependency(
                    "LibSSH2_jll",
                    Base.UUID("29816b5a-b9ab-546f-933c-edad1886dfa8"),
                    "*",
                ),
                JLLPackageDependency(
                    "nghttp2_jll",
                    Base.UUID("8e850ede-7688-5339-a07c-302acd2aaf8d"),
                    "*",
                ),
                JLLPackageDependency(
                    "MbedTLS_jll",
                    Base.UUID("c8ffd9c3-330d-5841-b78e-0817d7145fa1"),
                    "~2.28.0",
                ),
                JLLPackageDependency(
                    "Zlib_jll",
                    Base.UUID("83775a58-1f1d-513f-b197-d71354ab007a"),
                    "*",
                ),
            ],
            sources = [],
            platform = Platform("i686", "windows"; ),
            name = "default",
            treehash = "b85bf633623a55692571d90e7097b1373bbcc1bf",
            download_sources = [
                JLLArtifactSource(
                    "https://github.com/JuliaBinaryWrappers/LibCURL_jll.jl/releases/download/LibCURL-v8.0.1+1/LibCURL.v8.0.1.i686-w64-mingw32.tar.gz",
                    "b7eb8260b3b25ff0bcecf30fe489ae26dd56b21375396181c76b899ef091d91e",
                ),
            ],
            products = [
                JLLLibraryProduct(
                    :libcurl,
                    "bin\\libcurl-4.dll",
                    [
                        JLLLibraryDep(:nghttp2_jll, :libnghttp),
                        JLLLibraryDep(:LibSSH2_jll, :libssh2),
                        JLLLibraryDep(:MbedTLS_jll, :libmbedtls),
                        JLLLibraryDep(:MbedTLS_jll, :libmbedx509),
                        JLLLibraryDep(:MbedTLS_jll, :libmedcrypto),
                    ],
                    flags = [:RTLD_LAZY, :RTLD_DEEPBIND],
                    on_load_callback = :libcurl_on_load_callback_def,
                ),
            ],
            callback_defs = Dict(
                :libcurl_on_load_callback_def => libcurl_on_load_callback_def,
            )
        ),

        JLLArtifactInfo(;
            src_version = v"8.0.1+1",
            deps = [
                JLLPackageDependency(
                    "LibSSH2_jll",
                    Base.UUID("29816b5a-b9ab-546f-933c-edad1886dfa8"),
                    "*",
                ),
                JLLPackageDependency(
                    "nghttp2_jll",
                    Base.UUID("8e850ede-7688-5339-a07c-302acd2aaf8d"),
                    "*",
                ),
                JLLPackageDependency(
                    "MbedTLS_jll",
                    Base.UUID("c8ffd9c3-330d-5841-b78e-0817d7145fa1"),
                    "~2.28.0",
                ),
                JLLPackageDependency(
                    "Zlib_jll",
                    Base.UUID("83775a58-1f1d-513f-b197-d71354ab007a"),
                    "*",
                ),
            ],
            sources = [],
            platform = Platform("powerpc64le", "linux"; libc = "glibc"),
            name = "default",
            treehash = "2d2352ca81fca3ad4d12f9a7f42ea54d05196082",
            download_sources = [
                JLLArtifactSource(
                    "https://github.com/JuliaBinaryWrappers/LibCURL_jll.jl/releases/download/LibCURL-v8.0.1+1/LibCURL.v8.0.1.powerpc64le-linux-gnu.tar.gz",
                    "3c0a4af6f4b46928a5a53a545a8eef8b65389e7f17f1f7d862e1ce6519066102",
                ),
            ],
            products = [
                JLLLibraryProduct(
                    :libcurl,
                    "lib/libcurl.so",
                    [
                        JLLLibraryDep(:nghttp2_jll, :libnghttp),
                        JLLLibraryDep(:LibSSH2_jll, :libssh2),
                        JLLLibraryDep(:MbedTLS_jll, :libmbedtls),
                        JLLLibraryDep(:MbedTLS_jll, :libmbedx509),
                        JLLLibraryDep(:MbedTLS_jll, :libmedcrypto),
                    ],
                    flags = [:RTLD_LAZY, :RTLD_DEEPBIND],
                    on_load_callback = :libcurl_on_load_callback_def,
                ),
            ],
            callback_defs = Dict(
                :libcurl_on_load_callback_def => libcurl_on_load_callback_def,
            )
        ),

        JLLArtifactInfo(;
            src_version = v"8.0.1+1",
            deps = [
                JLLPackageDependency(
                    "LibSSH2_jll",
                    Base.UUID("29816b5a-b9ab-546f-933c-edad1886dfa8"),
                    "*",
                ),
                JLLPackageDependency(
                    "nghttp2_jll",
                    Base.UUID("8e850ede-7688-5339-a07c-302acd2aaf8d"),
                    "*",
                ),
                JLLPackageDependency(
                    "MbedTLS_jll",
                    Base.UUID("c8ffd9c3-330d-5841-b78e-0817d7145fa1"),
                    "~2.28.0",
                ),
                JLLPackageDependency(
                    "Zlib_jll",
                    Base.UUID("83775a58-1f1d-513f-b197-d71354ab007a"),
                    "*",
                ),
            ],
            sources = [],
            platform = Platform("x86_64", "macos"; ),
            name = "default",
            treehash = "6a5d5c8b2943a8242fe6c492c85df3abad8e75f4",
            download_sources = [
                JLLArtifactSource(
                    "https://github.com/JuliaBinaryWrappers/LibCURL_jll.jl/releases/download/LibCURL-v8.0.1+1/LibCURL.v8.0.1.x86_64-apple-darwin.tar.gz",
                    "b8949f7c0a282f343971654d5b141329a17145e827f4af48727821ffaf1bb502",
                ),
            ],
            products = [
                JLLLibraryProduct(
                    :libcurl,
                    "lib/libcurl.4.dylib",
                    [
                        JLLLibraryDep(:nghttp2_jll, :libnghttp),
                        JLLLibraryDep(:LibSSH2_jll, :libssh2),
                        JLLLibraryDep(:MbedTLS_jll, :libmbedtls),
                        JLLLibraryDep(:MbedTLS_jll, :libmbedx509),
                        JLLLibraryDep(:MbedTLS_jll, :libmedcrypto),
                    ],
                    flags = [:RTLD_LAZY, :RTLD_DEEPBIND],
                    on_load_callback = :libcurl_on_load_callback_def,
                ),
            ],
            callback_defs = Dict(
                :libcurl_on_load_callback_def => libcurl_on_load_callback_def,
            )
        ),

        JLLArtifactInfo(;
            src_version = v"8.0.1+1",
            deps = [
                JLLPackageDependency(
                    "LibSSH2_jll",
                    Base.UUID("29816b5a-b9ab-546f-933c-edad1886dfa8"),
                    "*",
                ),
                JLLPackageDependency(
                    "nghttp2_jll",
                    Base.UUID("8e850ede-7688-5339-a07c-302acd2aaf8d"),
                    "*",
                ),
                JLLPackageDependency(
                    "MbedTLS_jll",
                    Base.UUID("c8ffd9c3-330d-5841-b78e-0817d7145fa1"),
                    "~2.28.0",
                ),
                JLLPackageDependency(
                    "Zlib_jll",
                    Base.UUID("83775a58-1f1d-513f-b197-d71354ab007a"),
                    "*",
                ),
            ],
            sources = [],
            platform = Platform("x86_64", "linux"; libc = "glibc"),
            name = "default",
            treehash = "c68662631ad1829a37c2709c6c9aed05ba388c44",
            download_sources = [
                JLLArtifactSource(
                    "https://github.com/JuliaBinaryWrappers/LibCURL_jll.jl/releases/download/LibCURL-v8.0.1+1/LibCURL.v8.0.1.x86_64-linux-gnu.tar.gz",
                    "9f411d33e71bc92016f4f58ff7d60588e765e3e6cb704df50ad778a6ad976844",
                ),
            ],
            products = [
                JLLLibraryProduct(
                    :libcurl,
                    "lib/libcurl.so",
                    [
                        JLLLibraryDep(:nghttp2_jll, :libnghttp),
                        JLLLibraryDep(:LibSSH2_jll, :libssh2),
                        JLLLibraryDep(:MbedTLS_jll, :libmbedtls),
                        JLLLibraryDep(:MbedTLS_jll, :libmbedx509),
                        JLLLibraryDep(:MbedTLS_jll, :libmedcrypto),
                    ],
                    flags = [:RTLD_LAZY, :RTLD_DEEPBIND],
                    on_load_callback = :libcurl_on_load_callback_def,
                ),
            ],
            callback_defs = Dict(
                :libcurl_on_load_callback_def => libcurl_on_load_callback_def,
            )
        ),

        JLLArtifactInfo(;
            src_version = v"8.0.1+1",
            deps = [
                JLLPackageDependency(
                    "LibSSH2_jll",
                    Base.UUID("29816b5a-b9ab-546f-933c-edad1886dfa8"),
                    "*",
                ),
                JLLPackageDependency(
                    "nghttp2_jll",
                    Base.UUID("8e850ede-7688-5339-a07c-302acd2aaf8d"),
                    "*",
                ),
                JLLPackageDependency(
                    "MbedTLS_jll",
                    Base.UUID("c8ffd9c3-330d-5841-b78e-0817d7145fa1"),
                    "~2.28.0",
                ),
                JLLPackageDependency(
                    "Zlib_jll",
                    Base.UUID("83775a58-1f1d-513f-b197-d71354ab007a"),
                    "*",
                ),
            ],
            sources = [],
            platform = Platform("x86_64", "linux"; libc = "glibc", sanitize = "memory"),
            name = "default",
            treehash = "38f658ddddf783f6bbd67cbf3b9872e208e58653",
            download_sources = [
                JLLArtifactSource(
                    "https://github.com/JuliaBinaryWrappers/LibCURL_jll.jl/releases/download/LibCURL-v8.0.1+1/LibCURL.v8.0.1.x86_64-linux-gnu-sanitize+memory.tar.gz",
                    "3cbe5d15ef5d426b630582f3816c6d4d76b9456c5e7705f58c102087aeaeee34",
                ),
            ],
            products = [
                JLLLibraryProduct(
                    :libcurl,
                    "lib/libcurl.so",
                    [
                        JLLLibraryDep(:nghttp2_jll, :libnghttp),
                        JLLLibraryDep(:LibSSH2_jll, :libssh2),
                        JLLLibraryDep(:MbedTLS_jll, :libmbedtls),
                        JLLLibraryDep(:MbedTLS_jll, :libmbedx509),
                        JLLLibraryDep(:MbedTLS_jll, :libmedcrypto),
                    ],
                    flags = [:RTLD_LAZY, :RTLD_DEEPBIND],
                    on_load_callback = :libcurl_on_load_callback_def,
                ),
            ],
            callback_defs = Dict(
                :libcurl_on_load_callback_def => libcurl_on_load_callback_def,
            )
        ),

        JLLArtifactInfo(;
            src_version = v"8.0.1+1",
            deps = [
                JLLPackageDependency(
                    "LibSSH2_jll",
                    Base.UUID("29816b5a-b9ab-546f-933c-edad1886dfa8"),
                    "*",
                ),
                JLLPackageDependency(
                    "nghttp2_jll",
                    Base.UUID("8e850ede-7688-5339-a07c-302acd2aaf8d"),
                    "*",
                ),
                JLLPackageDependency(
                    "MbedTLS_jll",
                    Base.UUID("c8ffd9c3-330d-5841-b78e-0817d7145fa1"),
                    "~2.28.0",
                ),
                JLLPackageDependency(
                    "Zlib_jll",
                    Base.UUID("83775a58-1f1d-513f-b197-d71354ab007a"),
                    "*",
                ),
            ],
            sources = [],
            platform = Platform("x86_64", "linux"; libc = "musl"),
            name = "default",
            treehash = "30ac24db76af38b67374eeca9cacb626ed3ec49d",
            download_sources = [
                JLLArtifactSource(
                    "https://github.com/JuliaBinaryWrappers/LibCURL_jll.jl/releases/download/LibCURL-v8.0.1+1/LibCURL.v8.0.1.x86_64-linux-musl.tar.gz",
                    "6b125aeacd305bae8c59b021e936adcd67fd471cd69e1c58d08a5ad7a8a826bb",
                ),
            ],
            products = [
                JLLLibraryProduct(
                    :libcurl,
                    "lib/libcurl.so",
                    [
                        JLLLibraryDep(:nghttp2_jll, :libnghttp),
                        JLLLibraryDep(:LibSSH2_jll, :libssh2),
                        JLLLibraryDep(:MbedTLS_jll, :libmbedtls),
                        JLLLibraryDep(:MbedTLS_jll, :libmbedx509),
                        JLLLibraryDep(:MbedTLS_jll, :libmedcrypto),
                    ],
                    flags = [:RTLD_LAZY, :RTLD_DEEPBIND],
                    on_load_callback = :libcurl_on_load_callback_def,
                ),
            ],
            callback_defs = Dict(
                :libcurl_on_load_callback_def => libcurl_on_load_callback_def,
            )
        ),

        JLLArtifactInfo(;
            src_version = v"8.0.1+1",
            deps = [
                JLLPackageDependency(
                    "LibSSH2_jll",
                    Base.UUID("29816b5a-b9ab-546f-933c-edad1886dfa8"),
                    "*",
                ),
                JLLPackageDependency(
                    "nghttp2_jll",
                    Base.UUID("8e850ede-7688-5339-a07c-302acd2aaf8d"),
                    "*",
                ),
                JLLPackageDependency(
                    "MbedTLS_jll",
                    Base.UUID("c8ffd9c3-330d-5841-b78e-0817d7145fa1"),
                    "~2.28.0",
                ),
                JLLPackageDependency(
                    "Zlib_jll",
                    Base.UUID("83775a58-1f1d-513f-b197-d71354ab007a"),
                    "*",
                ),
            ],
            sources = [],
            platform = Platform("x86_64", "freebsd"; ),
            name = "default",
            treehash = "de5dbc5dd3d1ef4b16c8465a6ed4055f97f3eb65",
            download_sources = [
                JLLArtifactSource(
                    "https://github.com/JuliaBinaryWrappers/LibCURL_jll.jl/releases/download/LibCURL-v8.0.1+1/LibCURL.v8.0.1.x86_64-unknown-freebsd.tar.gz",
                    "0cd062fa57a6c04a09ad0c8382bdf45f677b25d2e32f77e7a6fe95838f0b92cf",
                ),
            ],
            products = [
                JLLLibraryProduct(
                    :libcurl,
                    "lib/libcurl.so",
                    [
                        JLLLibraryDep(:nghttp2_jll, :libnghttp),
                        JLLLibraryDep(:LibSSH2_jll, :libssh2),
                        JLLLibraryDep(:MbedTLS_jll, :libmbedtls),
                        JLLLibraryDep(:MbedTLS_jll, :libmbedx509),
                        JLLLibraryDep(:MbedTLS_jll, :libmedcrypto),
                    ],
                    flags = [:RTLD_LAZY, :RTLD_DEEPBIND],
                    on_load_callback = :libcurl_on_load_callback_def,
                ),
            ],
            callback_defs = Dict(
                :libcurl_on_load_callback_def => libcurl_on_load_callback_def,
            )
        ),

        JLLArtifactInfo(;
            src_version = v"8.0.1+1",
            deps = [
                JLLPackageDependency(
                    "LibSSH2_jll",
                    Base.UUID("29816b5a-b9ab-546f-933c-edad1886dfa8"),
                    "*",
                ),
                JLLPackageDependency(
                    "nghttp2_jll",
                    Base.UUID("8e850ede-7688-5339-a07c-302acd2aaf8d"),
                    "*",
                ),
                JLLPackageDependency(
                    "MbedTLS_jll",
                    Base.UUID("c8ffd9c3-330d-5841-b78e-0817d7145fa1"),
                    "~2.28.0",
                ),
                JLLPackageDependency(
                    "Zlib_jll",
                    Base.UUID("83775a58-1f1d-513f-b197-d71354ab007a"),
                    "*",
                ),
            ],
            sources = [],
            platform = Platform("x86_64", "windows"; ),
            name = "default",
            treehash = "da016779d9fa3762a8d6658c1e475152519edc82",
            download_sources = [
                JLLArtifactSource(
                    "https://github.com/JuliaBinaryWrappers/LibCURL_jll.jl/releases/download/LibCURL-v8.0.1+1/LibCURL.v8.0.1.x86_64-w64-mingw32.tar.gz",
                    "751c812048bf29af3527e3bb0fb448217235e96086828ff8145689c5e724e4db",
                ),
            ],
            products = [
                JLLLibraryProduct(
                    :libcurl,
                    "bin\\libcurl-4.dll",
                    [
                        JLLLibraryDep(:nghttp2_jll, :libnghttp),
                        JLLLibraryDep(:LibSSH2_jll, :libssh2),
                        JLLLibraryDep(:MbedTLS_jll, :libmbedtls),
                        JLLLibraryDep(:MbedTLS_jll, :libmbedx509),
                        JLLLibraryDep(:MbedTLS_jll, :libmedcrypto),
                    ],
                    flags = [:RTLD_LAZY, :RTLD_DEEPBIND],
                    on_load_callback = :libcurl_on_load_callback_def,
                ),
            ],
            callback_defs = Dict(
                :libcurl_on_load_callback_def => libcurl_on_load_callback_def,
            )
        ),

    ]
)

