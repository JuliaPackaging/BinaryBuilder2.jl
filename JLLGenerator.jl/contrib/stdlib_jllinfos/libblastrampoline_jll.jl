on_load_callback_def = """
const on_load_callbacks::Vector{Function} = Function[]
function libblastrampoline_on_load_callback()
    for callback in on_load_callbacks
        callback()
    end
end
"""

jll = JLLInfo(;
    name = "libblastrampoline",
    version = v"5.8.0+1",
    artifacts = [
        JLLArtifactInfo(;
            src_version = v"5.8.0+1",
            deps = [
            ],
            sources = [],
            platform = Platform("aarch64", "macos"; ),
            name = "default",
            treehash = "214e75bb92aa2acc9de8ff89f8d1aaeeba8fd26d",
            download_sources = [
                JLLArtifactSource(
                    "https://github.com/JuliaBinaryWrappers/libblastrampoline_jll.jl/releases/download/libblastrampoline-v5.8.0+1/libblastrampoline.v5.8.0.aarch64-apple-darwin.tar.gz",
                    "2b241d3105f62bfae7ce56b4d7957a4a17272e743e2e23a57ccec1ee36140aac",
                ),
            ],
            products = [
                JLLLibraryProduct(
                    :libblastrampoline,
                    "lib/libblastrampoline.5.4.0.dylib",
                    [],
                    flags = [:RTLD_LAZY, :RTLD_DEEPBIND],
                    on_load_callback = :libblastrampoline_on_load_callback,
                ),
            ],
            callback_defs = Dict(
                :libblastrampoline_on_load_callback => on_load_callback_def,
            )
        ),

        JLLArtifactInfo(;
            src_version = v"5.8.0+1",
            deps = [
            ],
            sources = [],
            platform = Platform("aarch64", "linux"; libc = "glibc"),
            name = "default",
            treehash = "5bf103922e5c4aa83ade2114f83cf2963296cf52",
            download_sources = [
                JLLArtifactSource(
                    "https://github.com/JuliaBinaryWrappers/libblastrampoline_jll.jl/releases/download/libblastrampoline-v5.8.0+1/libblastrampoline.v5.8.0.aarch64-linux-gnu.tar.gz",
                    "56fd94345251234fc363cd3dfdce6e9debb80a7da8e6528bb32132c06f6cd746",
                ),
            ],
            products = [
                JLLLibraryProduct(
                    :libblastrampoline,
                    "lib/libblastrampoline.so",
                    [],
                    flags = [:RTLD_LAZY, :RTLD_DEEPBIND],
                    on_load_callback = :libblastrampoline_on_load_callback,
                ),
            ],
            callback_defs = Dict(
                :libblastrampoline_on_load_callback => on_load_callback_def,
            )
        ),

        JLLArtifactInfo(;
            src_version = v"5.8.0+1",
            deps = [
            ],
            sources = [],
            platform = Platform("aarch64", "linux"; libc = "musl"),
            name = "default",
            treehash = "b7996a90e1235e7c1d0080e8388bf7f6066af655",
            download_sources = [
                JLLArtifactSource(
                    "https://github.com/JuliaBinaryWrappers/libblastrampoline_jll.jl/releases/download/libblastrampoline-v5.8.0+1/libblastrampoline.v5.8.0.aarch64-linux-musl.tar.gz",
                    "adc8fc5f02282d63053767e67006fd069f18f29691d674578eb5009f5471bba0",
                ),
            ],
            products = [
                JLLLibraryProduct(
                    :libblastrampoline,
                    "lib/libblastrampoline.so",
                    [],
                    flags = [:RTLD_LAZY, :RTLD_DEEPBIND],
                    on_load_callback = :libblastrampoline_on_load_callback,
                ),
            ],
            callback_defs = Dict(
                :libblastrampoline_on_load_callback => on_load_callback_def,
            )
        ),

        JLLArtifactInfo(;
            src_version = v"5.8.0+1",
            deps = [
            ],
            sources = [],
            platform = Platform("armv6l", "linux"; call_abi = "eabihf", libc = "glibc"),
            name = "default",
            treehash = "d7e5b756a45b7c7327483138a58a7cfd0e463286",
            download_sources = [
                JLLArtifactSource(
                    "https://github.com/JuliaBinaryWrappers/libblastrampoline_jll.jl/releases/download/libblastrampoline-v5.8.0+1/libblastrampoline.v5.8.0.armv6l-linux-gnueabihf.tar.gz",
                    "6a91244220eeba8044ea1a52d7fd7a5e79d81c42dd38bc6e012d995f21fce993",
                ),
            ],
            products = [
                JLLLibraryProduct(
                    :libblastrampoline,
                    "lib/libblastrampoline.so",
                    [],
                    flags = [:RTLD_LAZY, :RTLD_DEEPBIND],
                    on_load_callback = :libblastrampoline_on_load_callback,
                ),
            ],
            callback_defs = Dict(
                :libblastrampoline_on_load_callback => on_load_callback_def,
            )
        ),

        JLLArtifactInfo(;
            src_version = v"5.8.0+1",
            deps = [
            ],
            sources = [],
            platform = Platform("armv6l", "linux"; call_abi = "eabihf", libc = "musl"),
            name = "default",
            treehash = "d8813c9fde869d0bda8216cbb96a171271d7e9fa",
            download_sources = [
                JLLArtifactSource(
                    "https://github.com/JuliaBinaryWrappers/libblastrampoline_jll.jl/releases/download/libblastrampoline-v5.8.0+1/libblastrampoline.v5.8.0.armv6l-linux-musleabihf.tar.gz",
                    "f9c05c94510cb6b4b7b5d8677a8c08612f832f269e988600eb642953d9ab101d",
                ),
            ],
            products = [
                JLLLibraryProduct(
                    :libblastrampoline,
                    "lib/libblastrampoline.so",
                    [],
                    flags = [:RTLD_LAZY, :RTLD_DEEPBIND],
                    on_load_callback = :libblastrampoline_on_load_callback,
                ),
            ],
            callback_defs = Dict(
                :libblastrampoline_on_load_callback => on_load_callback_def,
            )
        ),

        JLLArtifactInfo(;
            src_version = v"5.8.0+1",
            deps = [
            ],
            sources = [],
            platform = Platform("armv7l", "linux"; call_abi = "eabihf", libc = "glibc"),
            name = "default",
            treehash = "7cc680754ba90204143ca915d94c4afb3fa9950b",
            download_sources = [
                JLLArtifactSource(
                    "https://github.com/JuliaBinaryWrappers/libblastrampoline_jll.jl/releases/download/libblastrampoline-v5.8.0+1/libblastrampoline.v5.8.0.armv7l-linux-gnueabihf.tar.gz",
                    "021e4091d9bffa1ce0282e23443655f66ca11304dadd849272df2a197d2cac11",
                ),
            ],
            products = [
                JLLLibraryProduct(
                    :libblastrampoline,
                    "lib/libblastrampoline.so",
                    [],
                    flags = [:RTLD_LAZY, :RTLD_DEEPBIND],
                    on_load_callback = :libblastrampoline_on_load_callback,
                ),
            ],
            callback_defs = Dict(
                :libblastrampoline_on_load_callback => on_load_callback_def,
            )
        ),

        JLLArtifactInfo(;
            src_version = v"5.8.0+1",
            deps = [
            ],
            sources = [],
            platform = Platform("armv7l", "linux"; call_abi = "eabihf", libc = "musl"),
            name = "default",
            treehash = "7894264c826d86c648ba92040333d5e1cd7578a7",
            download_sources = [
                JLLArtifactSource(
                    "https://github.com/JuliaBinaryWrappers/libblastrampoline_jll.jl/releases/download/libblastrampoline-v5.8.0+1/libblastrampoline.v5.8.0.armv7l-linux-musleabihf.tar.gz",
                    "b8d0e0b25a13dcf886bc322053f68530dbf0a157f3f34a5e830d898b800e0a88",
                ),
            ],
            products = [
                JLLLibraryProduct(
                    :libblastrampoline,
                    "lib/libblastrampoline.so",
                    [],
                    flags = [:RTLD_LAZY, :RTLD_DEEPBIND],
                    on_load_callback = :libblastrampoline_on_load_callback,
                ),
            ],
            callback_defs = Dict(
                :libblastrampoline_on_load_callback => on_load_callback_def,
            )
        ),

        JLLArtifactInfo(;
            src_version = v"5.8.0+1",
            deps = [
            ],
            sources = [],
            platform = Platform("i686", "linux"; libc = "glibc"),
            name = "default",
            treehash = "8ba6693c928cd0f3965fc7e6310587042b675791",
            download_sources = [
                JLLArtifactSource(
                    "https://github.com/JuliaBinaryWrappers/libblastrampoline_jll.jl/releases/download/libblastrampoline-v5.8.0+1/libblastrampoline.v5.8.0.i686-linux-gnu.tar.gz",
                    "c462722e6b0e06efc17c6b6572d95112e68648bac046c33b67ba1ce54013430c",
                ),
            ],
            products = [
                JLLLibraryProduct(
                    :libblastrampoline,
                    "lib/libblastrampoline.so",
                    [],
                    flags = [:RTLD_LAZY, :RTLD_DEEPBIND],
                    on_load_callback = :libblastrampoline_on_load_callback,
                ),
            ],
            callback_defs = Dict(
                :libblastrampoline_on_load_callback => on_load_callback_def,
            )
        ),

        JLLArtifactInfo(;
            src_version = v"5.8.0+1",
            deps = [
            ],
            sources = [],
            platform = Platform("i686", "linux"; libc = "musl"),
            name = "default",
            treehash = "2e96643d215400d8a2c15eae043f34260d07dde3",
            download_sources = [
                JLLArtifactSource(
                    "https://github.com/JuliaBinaryWrappers/libblastrampoline_jll.jl/releases/download/libblastrampoline-v5.8.0+1/libblastrampoline.v5.8.0.i686-linux-musl.tar.gz",
                    "de65657bb1e272acc38c052aaa5f4cbc2ace86b66d4bcf0cc5baa02e0e37a400",
                ),
            ],
            products = [
                JLLLibraryProduct(
                    :libblastrampoline,
                    "lib/libblastrampoline.so",
                    [],
                    flags = [:RTLD_LAZY, :RTLD_DEEPBIND],
                    on_load_callback = :libblastrampoline_on_load_callback,
                ),
            ],
            callback_defs = Dict(
                :libblastrampoline_on_load_callback => on_load_callback_def,
            )
        ),

        JLLArtifactInfo(;
            src_version = v"5.8.0+1",
            deps = [
            ],
            sources = [],
            platform = Platform("i686", "windows"; ),
            name = "default",
            treehash = "b3b9b375ee68dd458c24f6272a727e7249803c47",
            download_sources = [
                JLLArtifactSource(
                    "https://github.com/JuliaBinaryWrappers/libblastrampoline_jll.jl/releases/download/libblastrampoline-v5.8.0+1/libblastrampoline.v5.8.0.i686-w64-mingw32.tar.gz",
                    "f99622d251dd52c3443e596dfce97f6006d41e9f02d704cba198564daa22caab",
                ),
            ],
            products = [
                JLLLibraryProduct(
                    :libblastrampoline,
                    "bin\\libblastrampoline-5.dll",
                    [],
                    flags = [:RTLD_LAZY, :RTLD_DEEPBIND],
                    on_load_callback = :libblastrampoline_on_load_callback,
                ),
            ],
            callback_defs = Dict(
                :libblastrampoline_on_load_callback => on_load_callback_def,
            )
        ),

        JLLArtifactInfo(;
            src_version = v"5.8.0+1",
            deps = [
            ],
            sources = [],
            platform = Platform("powerpc64le", "linux"; libc = "glibc"),
            name = "default",
            treehash = "2f5ef045aa770869e75323f816c2a7181a11eeec",
            download_sources = [
                JLLArtifactSource(
                    "https://github.com/JuliaBinaryWrappers/libblastrampoline_jll.jl/releases/download/libblastrampoline-v5.8.0+1/libblastrampoline.v5.8.0.powerpc64le-linux-gnu.tar.gz",
                    "80bf1d98baf656e1e5e4896504fa98bbe7fb47543967f778814a1b5a26c8fe87",
                ),
            ],
            products = [
                JLLLibraryProduct(
                    :libblastrampoline,
                    "lib/libblastrampoline.so",
                    [],
                    flags = [:RTLD_LAZY, :RTLD_DEEPBIND],
                    on_load_callback = :libblastrampoline_on_load_callback,
                ),
            ],
            callback_defs = Dict(
                :libblastrampoline_on_load_callback => on_load_callback_def,
            )
        ),

        JLLArtifactInfo(;
            src_version = v"5.8.0+1",
            deps = [
            ],
            sources = [],
            platform = Platform("x86_64", "macos"; ),
            name = "default",
            treehash = "7edd68aaa4ab089d3f2900a4adfd3cfd26a98cec",
            download_sources = [
                JLLArtifactSource(
                    "https://github.com/JuliaBinaryWrappers/libblastrampoline_jll.jl/releases/download/libblastrampoline-v5.8.0+1/libblastrampoline.v5.8.0.x86_64-apple-darwin.tar.gz",
                    "9a6de330a74ebcce8decaba7f3df76058fb95371fd0afd9b2912bc8a27eebe7b",
                ),
            ],
            products = [
                JLLLibraryProduct(
                    :libblastrampoline,
                    "lib/libblastrampoline.5.4.0.dylib",
                    [],
                    flags = [:RTLD_LAZY, :RTLD_DEEPBIND],
                    on_load_callback = :libblastrampoline_on_load_callback,
                ),
            ],
            callback_defs = Dict(
                :libblastrampoline_on_load_callback => on_load_callback_def,
            )
        ),

        JLLArtifactInfo(;
            src_version = v"5.8.0+1",
            deps = [
            ],
            sources = [],
            platform = Platform("x86_64", "linux"; libc = "glibc"),
            name = "default",
            treehash = "c97215f2ba88d82cac379ca18762eb47e16a268e",
            download_sources = [
                JLLArtifactSource(
                    "https://github.com/JuliaBinaryWrappers/libblastrampoline_jll.jl/releases/download/libblastrampoline-v5.8.0+1/libblastrampoline.v5.8.0.x86_64-linux-gnu.tar.gz",
                    "f83b795b490079029d80e4856d2573b18ca3723bdf6a0d6457aff5c7de027d78",
                ),
            ],
            products = [
                JLLLibraryProduct(
                    :libblastrampoline,
                    "lib/libblastrampoline.so",
                    [],
                    flags = [:RTLD_LAZY, :RTLD_DEEPBIND],
                    on_load_callback = :libblastrampoline_on_load_callback,
                ),
            ],
            callback_defs = Dict(
                :libblastrampoline_on_load_callback => on_load_callback_def,
            )
        ),

        JLLArtifactInfo(;
            src_version = v"5.8.0+1",
            deps = [
            ],
            sources = [],
            platform = Platform("x86_64", "linux"; libc = "glibc", sanitize = "memory"),
            name = "default",
            treehash = "0da4851eeafb2356e1d9f514254106d9af1b7d98",
            download_sources = [
                JLLArtifactSource(
                    "https://github.com/JuliaBinaryWrappers/libblastrampoline_jll.jl/releases/download/libblastrampoline-v5.8.0+1/libblastrampoline.v5.8.0.x86_64-linux-gnu-sanitize+memory.tar.gz",
                    "d40143890ab8a9cc5477890ec12da62dd6345ce48da613156b7bf9a952e60586",
                ),
            ],
            products = [
                JLLLibraryProduct(
                    :libblastrampoline,
                    "lib/libblastrampoline.so",
                    [],
                    flags = [:RTLD_LAZY, :RTLD_DEEPBIND],
                    on_load_callback = :libblastrampoline_on_load_callback,
                ),
            ],
            callback_defs = Dict(
                :libblastrampoline_on_load_callback => on_load_callback_def,
            )
        ),

        JLLArtifactInfo(;
            src_version = v"5.8.0+1",
            deps = [
            ],
            sources = [],
            platform = Platform("x86_64", "linux"; libc = "musl"),
            name = "default",
            treehash = "736acd96815529338337c23d236732a873b98f4e",
            download_sources = [
                JLLArtifactSource(
                    "https://github.com/JuliaBinaryWrappers/libblastrampoline_jll.jl/releases/download/libblastrampoline-v5.8.0+1/libblastrampoline.v5.8.0.x86_64-linux-musl.tar.gz",
                    "80230e8cc1705d66d7b016ea5e3f023f065733b35730a95eb04f3a376e1d86da",
                ),
            ],
            products = [
                JLLLibraryProduct(
                    :libblastrampoline,
                    "lib/libblastrampoline.so",
                    [],
                    flags = [:RTLD_LAZY, :RTLD_DEEPBIND],
                    on_load_callback = :libblastrampoline_on_load_callback,
                ),
            ],
            callback_defs = Dict(
                :libblastrampoline_on_load_callback => on_load_callback_def,
            )
        ),

        JLLArtifactInfo(;
            src_version = v"5.8.0+1",
            deps = [
            ],
            sources = [],
            platform = Platform("x86_64", "freebsd"; ),
            name = "default",
            treehash = "23c2a2dbcc29fa71ec4a59651b5c914cfeabd100",
            download_sources = [
                JLLArtifactSource(
                    "https://github.com/JuliaBinaryWrappers/libblastrampoline_jll.jl/releases/download/libblastrampoline-v5.8.0+1/libblastrampoline.v5.8.0.x86_64-unknown-freebsd.tar.gz",
                    "130083b58cb1992b47672d6f5416b1bcf60838e545375b10c2e42f74b69c8000",
                ),
            ],
            products = [
                JLLLibraryProduct(
                    :libblastrampoline,
                    "lib/libblastrampoline.so",
                    [],
                    flags = [:RTLD_LAZY, :RTLD_DEEPBIND],
                    on_load_callback = :libblastrampoline_on_load_callback,
                ),
            ],
            callback_defs = Dict(
                :libblastrampoline_on_load_callback => on_load_callback_def,
            )
        ),

        JLLArtifactInfo(;
            src_version = v"5.8.0+1",
            deps = [
            ],
            sources = [],
            platform = Platform("x86_64", "windows"; ),
            name = "default",
            treehash = "2349ba952d6207b74ff462d9cbe1e4c1c646e211",
            download_sources = [
                JLLArtifactSource(
                    "https://github.com/JuliaBinaryWrappers/libblastrampoline_jll.jl/releases/download/libblastrampoline-v5.8.0+1/libblastrampoline.v5.8.0.x86_64-w64-mingw32.tar.gz",
                    "b247f6f3405737527ef5780b485814deeeb9a8c3e53dbf36be3811626c080efd",
                ),
            ],
            products = [
                JLLLibraryProduct(
                    :libblastrampoline,
                    "bin\\libblastrampoline-5.dll",
                    [],
                    flags = [:RTLD_LAZY, :RTLD_DEEPBIND],
                    on_load_callback = :libblastrampoline_on_load_callback,
                ),
            ],
            callback_defs = Dict(
                :libblastrampoline_on_load_callback => on_load_callback_def,
            )
        ),

    ]
)

