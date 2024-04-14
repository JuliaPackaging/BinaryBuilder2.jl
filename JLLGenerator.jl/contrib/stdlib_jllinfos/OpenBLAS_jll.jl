openblas_init_block = """
# make sure OpenBLAS does not set CPU affinity (#1070, #9639)
if !haskey(ENV, "OPENBLAS_MAIN_FREE")
    ENV["OPENBLAS_MAIN_FREE"] = "1"
end

# Ensure that OpenBLAS does not grab a huge amount of memory at first,
# since it instantly allocates scratch buffer space for the number of
# threads it thinks it needs to use.
# X-ref: https://github.com/xianyi/OpenBLAS/blob/c43ec53bdd00d9423fc609d7b7ecb35e7bf41b85/README.md#setting-the-number-of-threads-using-environment-variables
# X-ref: https://github.com/JuliaLang/julia/issues/45434
if !haskey(ENV, "OPENBLAS_NUM_THREADS") &&
    !haskey(ENV, "GOTO_NUM_THREADS") &&
    !haskey(ENV, "OMP_NUM_THREADS")
    # We set this to `1` here, and then LinearAlgebra will update
    # to the true value in its `__init__()` function.
    ENV["OPENBLAS_DEFAULT_NUM_THREADS"] = "1"
end
"""

jll = JLLInfo(;
    name = "OpenBLAS",
    version = v"0.3.23+2",
    artifacts = [
        JLLArtifactInfo(;
            src_version = v"0.3.23+2",
            deps = [
                JLLPackageDependency(
                    "CompilerSupportLibraries_jll",
                    Base.UUID("e66e0078-7015-5450-92f7-15fbd957f2ae"),
                    "*",
                ),
            ],
            sources = [],
            platform = Platform("aarch64", "macos"; libgfortran_version = "5.0.0"),
            name = "default",
            treehash = "08bb912954265e65731f7d220386133a215ca1aa",
            download_sources = [
                JLLArtifactSource(
                    "https://github.com/JuliaBinaryWrappers/OpenBLAS_jll.jl/releases/download/OpenBLAS-v0.3.23+2/OpenBLAS.v0.3.23.aarch64-apple-darwin-libgfortran5.tar.gz",
                    "cd791498fa22af7aaf9442c9d3e17efa0d1c8ad2f5d4ffe1753783c21294975d",
                ),
            ],
            products = [
                JLLLibraryProduct(
                    :libopenblas,
                    "lib/libopenblas64_.0.3.23.dylib",
                    [JLLLibraryDep(:CompilerSupportLibraries_jll, :libgfortran)],
                    [:RTLD_LAZY, :RTLD_DEEPBIND],
                ),
            ],
            init_def = openblas_init_block,
        ),

        JLLArtifactInfo(;
            src_version = v"0.3.23+2",
            deps = [
                JLLPackageDependency(
                    "CompilerSupportLibraries_jll",
                    Base.UUID("e66e0078-7015-5450-92f7-15fbd957f2ae"),
                    "*",
                ),
            ],
            sources = [],
            platform = Platform("aarch64", "linux"; libgfortran_version = "3.0.0", libc = "glibc"),
            name = "default",
            treehash = "79d497b65820e0df62db0af5fe54a54a8066cb06",
            download_sources = [
                JLLArtifactSource(
                    "https://github.com/JuliaBinaryWrappers/OpenBLAS_jll.jl/releases/download/OpenBLAS-v0.3.23+2/OpenBLAS.v0.3.23.aarch64-linux-gnu-libgfortran3.tar.gz",
                    "2f1df1589ec64b21c1b41541fd4edfbb9e6e51436f289052b7b9fbef0c120c67",
                ),
            ],
            products = [
                JLLLibraryProduct(
                    :libopenblas,
                    "lib/libopenblas64_.so",
                    [JLLLibraryDep(:CompilerSupportLibraries_jll, :libgfortran)],
                    [:RTLD_LAZY, :RTLD_DEEPBIND],
                ),
            ],
            init_def = openblas_init_block,
        ),

        JLLArtifactInfo(;
            src_version = v"0.3.23+2",
            deps = [
                JLLPackageDependency(
                    "CompilerSupportLibraries_jll",
                    Base.UUID("e66e0078-7015-5450-92f7-15fbd957f2ae"),
                    "*",
                ),
            ],
            sources = [],
            platform = Platform("aarch64", "linux"; libgfortran_version = "4.0.0", libc = "glibc"),
            name = "default",
            treehash = "48e9551fa711e9bcadc7ac309ea2c2effad9900e",
            download_sources = [
                JLLArtifactSource(
                    "https://github.com/JuliaBinaryWrappers/OpenBLAS_jll.jl/releases/download/OpenBLAS-v0.3.23+2/OpenBLAS.v0.3.23.aarch64-linux-gnu-libgfortran4.tar.gz",
                    "0f104e710adb07112d55fef4e82e779e601584f628e4aa02eb29f4feda92c2c7",
                ),
            ],
            products = [
                JLLLibraryProduct(
                    :libopenblas,
                    "lib/libopenblas64_.so",
                    [JLLLibraryDep(:CompilerSupportLibraries_jll, :libgfortran)],
                    [:RTLD_LAZY, :RTLD_DEEPBIND],
                ),
            ],
            init_def = openblas_init_block,
        ),

        JLLArtifactInfo(;
            src_version = v"0.3.23+2",
            deps = [
                JLLPackageDependency(
                    "CompilerSupportLibraries_jll",
                    Base.UUID("e66e0078-7015-5450-92f7-15fbd957f2ae"),
                    "*",
                ),
            ],
            sources = [],
            platform = Platform("aarch64", "linux"; libgfortran_version = "5.0.0", libc = "glibc"),
            name = "default",
            treehash = "1298e6728305b4bed84f5ec6aa14378e2f7fb73e",
            download_sources = [
                JLLArtifactSource(
                    "https://github.com/JuliaBinaryWrappers/OpenBLAS_jll.jl/releases/download/OpenBLAS-v0.3.23+2/OpenBLAS.v0.3.23.aarch64-linux-gnu-libgfortran5.tar.gz",
                    "ca3bdea9b55a6175da037f0a08009301b19661ccbd45b24d960b435d00c34567",
                ),
            ],
            products = [
                JLLLibraryProduct(
                    :libopenblas,
                    "lib/libopenblas64_.so",
                    [JLLLibraryDep(:CompilerSupportLibraries_jll, :libgfortran)],
                    [:RTLD_LAZY, :RTLD_DEEPBIND],
                ),
            ],
            init_def = openblas_init_block,
        ),

        JLLArtifactInfo(;
            src_version = v"0.3.23+2",
            deps = [
                JLLPackageDependency(
                    "CompilerSupportLibraries_jll",
                    Base.UUID("e66e0078-7015-5450-92f7-15fbd957f2ae"),
                    "*",
                ),
            ],
            sources = [],
            platform = Platform("aarch64", "linux"; libgfortran_version = "3.0.0", libc = "musl"),
            name = "default",
            treehash = "5d672c3fef0eac9165b89d224ab07dc6e259b757",
            download_sources = [
                JLLArtifactSource(
                    "https://github.com/JuliaBinaryWrappers/OpenBLAS_jll.jl/releases/download/OpenBLAS-v0.3.23+2/OpenBLAS.v0.3.23.aarch64-linux-musl-libgfortran3.tar.gz",
                    "635751c8f0141beaef720077c1cd4029392d49b122c46853548e206503fc99ac",
                ),
            ],
            products = [
                JLLLibraryProduct(
                    :libopenblas,
                    "lib/libopenblas64_.so",
                    [JLLLibraryDep(:CompilerSupportLibraries_jll, :libgfortran)],
                    [:RTLD_LAZY, :RTLD_DEEPBIND],
                ),
            ],
            init_def = openblas_init_block,
        ),

        JLLArtifactInfo(;
            src_version = v"0.3.23+2",
            deps = [
                JLLPackageDependency(
                    "CompilerSupportLibraries_jll",
                    Base.UUID("e66e0078-7015-5450-92f7-15fbd957f2ae"),
                    "*",
                ),
            ],
            sources = [],
            platform = Platform("aarch64", "linux"; libgfortran_version = "4.0.0", libc = "musl"),
            name = "default",
            treehash = "80c983af4b458bbcf2d2e0758e6b13aa0dadb314",
            download_sources = [
                JLLArtifactSource(
                    "https://github.com/JuliaBinaryWrappers/OpenBLAS_jll.jl/releases/download/OpenBLAS-v0.3.23+2/OpenBLAS.v0.3.23.aarch64-linux-musl-libgfortran4.tar.gz",
                    "de0ba0436c831a1f98eb10e93aebcf2c297a77267d43697268ebf73eec893233",
                ),
            ],
            products = [
                JLLLibraryProduct(
                    :libopenblas,
                    "lib/libopenblas64_.so",
                    [JLLLibraryDep(:CompilerSupportLibraries_jll, :libgfortran)],
                    [:RTLD_LAZY, :RTLD_DEEPBIND],
                ),
            ],
            init_def = openblas_init_block,
        ),

        JLLArtifactInfo(;
            src_version = v"0.3.23+2",
            deps = [
                JLLPackageDependency(
                    "CompilerSupportLibraries_jll",
                    Base.UUID("e66e0078-7015-5450-92f7-15fbd957f2ae"),
                    "*",
                ),
            ],
            sources = [],
            platform = Platform("aarch64", "linux"; libgfortran_version = "5.0.0", libc = "musl"),
            name = "default",
            treehash = "51f27f4ad0dc1be799bcf2aa520646fd00335820",
            download_sources = [
                JLLArtifactSource(
                    "https://github.com/JuliaBinaryWrappers/OpenBLAS_jll.jl/releases/download/OpenBLAS-v0.3.23+2/OpenBLAS.v0.3.23.aarch64-linux-musl-libgfortran5.tar.gz",
                    "ecdff02f3b329e1b91e4885dfbab850e56998c3e534cae272bcdb93fe5dacde5",
                ),
            ],
            products = [
                JLLLibraryProduct(
                    :libopenblas,
                    "lib/libopenblas64_.so",
                    [JLLLibraryDep(:CompilerSupportLibraries_jll, :libgfortran)],
                    [:RTLD_LAZY, :RTLD_DEEPBIND],
                ),
            ],
            init_def = openblas_init_block,
        ),

        JLLArtifactInfo(;
            src_version = v"0.3.23+2",
            deps = [
                JLLPackageDependency(
                    "CompilerSupportLibraries_jll",
                    Base.UUID("e66e0078-7015-5450-92f7-15fbd957f2ae"),
                    "*",
                ),
            ],
            sources = [],
            platform = Platform("armv6l", "linux"; libgfortran_version = "3.0.0", call_abi = "eabihf", libc = "glibc"),
            name = "default",
            treehash = "734921d630dba4eeaba4ee1d66d19a90aea9895d",
            download_sources = [
                JLLArtifactSource(
                    "https://github.com/JuliaBinaryWrappers/OpenBLAS_jll.jl/releases/download/OpenBLAS-v0.3.23+2/OpenBLAS.v0.3.23.armv6l-linux-gnueabihf-libgfortran3.tar.gz",
                    "893b4cee77633ae9358afadc6833eb4996439dc95df7b657f73f72d94f949443",
                ),
            ],
            products = [
                JLLLibraryProduct(
                    :libopenblas,
                    "lib/libopenblas.so",
                    [JLLLibraryDep(:CompilerSupportLibraries_jll, :libgfortran)],
                    [:RTLD_LAZY, :RTLD_DEEPBIND],
                ),
            ],
            init_def = openblas_init_block,
        ),

        JLLArtifactInfo(;
            src_version = v"0.3.23+2",
            deps = [
                JLLPackageDependency(
                    "CompilerSupportLibraries_jll",
                    Base.UUID("e66e0078-7015-5450-92f7-15fbd957f2ae"),
                    "*",
                ),
            ],
            sources = [],
            platform = Platform("armv6l", "linux"; libgfortran_version = "4.0.0", call_abi = "eabihf", libc = "glibc"),
            name = "default",
            treehash = "3ec245929162506d599471c689ccacf54291ff6d",
            download_sources = [
                JLLArtifactSource(
                    "https://github.com/JuliaBinaryWrappers/OpenBLAS_jll.jl/releases/download/OpenBLAS-v0.3.23+2/OpenBLAS.v0.3.23.armv6l-linux-gnueabihf-libgfortran4.tar.gz",
                    "672c23ef33f35c084242d41169ecdf59a2ba95697f02adc4100844b20f1accfd",
                ),
            ],
            products = [
                JLLLibraryProduct(
                    :libopenblas,
                    "lib/libopenblas.so",
                    [JLLLibraryDep(:CompilerSupportLibraries_jll, :libgfortran)],
                    [:RTLD_LAZY, :RTLD_DEEPBIND],
                ),
            ],
            init_def = openblas_init_block,
        ),

        JLLArtifactInfo(;
            src_version = v"0.3.23+2",
            deps = [
                JLLPackageDependency(
                    "CompilerSupportLibraries_jll",
                    Base.UUID("e66e0078-7015-5450-92f7-15fbd957f2ae"),
                    "*",
                ),
            ],
            sources = [],
            platform = Platform("armv6l", "linux"; libgfortran_version = "5.0.0", call_abi = "eabihf", libc = "glibc"),
            name = "default",
            treehash = "20899f92b0198109d469e7796a6b625b7f0cd966",
            download_sources = [
                JLLArtifactSource(
                    "https://github.com/JuliaBinaryWrappers/OpenBLAS_jll.jl/releases/download/OpenBLAS-v0.3.23+2/OpenBLAS.v0.3.23.armv6l-linux-gnueabihf-libgfortran5.tar.gz",
                    "57bac284ee2e012e7bca25a858637011aa0f57f8bd4fdbac0c2b69810bdb681b",
                ),
            ],
            products = [
                JLLLibraryProduct(
                    :libopenblas,
                    "lib/libopenblas.so",
                    [JLLLibraryDep(:CompilerSupportLibraries_jll, :libgfortran)],
                    [:RTLD_LAZY, :RTLD_DEEPBIND],
                ),
            ],
            init_def = openblas_init_block,
        ),

        JLLArtifactInfo(;
            src_version = v"0.3.23+2",
            deps = [
                JLLPackageDependency(
                    "CompilerSupportLibraries_jll",
                    Base.UUID("e66e0078-7015-5450-92f7-15fbd957f2ae"),
                    "*",
                ),
            ],
            sources = [],
            platform = Platform("armv6l", "linux"; libgfortran_version = "3.0.0", call_abi = "eabihf", libc = "musl"),
            name = "default",
            treehash = "6a42a2660643f0c590a4d0cda7f8bc4bfdfd0ccf",
            download_sources = [
                JLLArtifactSource(
                    "https://github.com/JuliaBinaryWrappers/OpenBLAS_jll.jl/releases/download/OpenBLAS-v0.3.23+2/OpenBLAS.v0.3.23.armv6l-linux-musleabihf-libgfortran3.tar.gz",
                    "c945c735d72517b697c4937f662985dddc53d59cc4067c5b1580c80eaca438da",
                ),
            ],
            products = [
                JLLLibraryProduct(
                    :libopenblas,
                    "lib/libopenblas.so",
                    [JLLLibraryDep(:CompilerSupportLibraries_jll, :libgfortran)],
                    [:RTLD_LAZY, :RTLD_DEEPBIND],
                ),
            ],
            init_def = openblas_init_block,
        ),

        JLLArtifactInfo(;
            src_version = v"0.3.23+2",
            deps = [
                JLLPackageDependency(
                    "CompilerSupportLibraries_jll",
                    Base.UUID("e66e0078-7015-5450-92f7-15fbd957f2ae"),
                    "*",
                ),
            ],
            sources = [],
            platform = Platform("armv6l", "linux"; libgfortran_version = "4.0.0", call_abi = "eabihf", libc = "musl"),
            name = "default",
            treehash = "9faec1d75fcda4c6b90abc68c4c92c63d8a2aed6",
            download_sources = [
                JLLArtifactSource(
                    "https://github.com/JuliaBinaryWrappers/OpenBLAS_jll.jl/releases/download/OpenBLAS-v0.3.23+2/OpenBLAS.v0.3.23.armv6l-linux-musleabihf-libgfortran4.tar.gz",
                    "f6f9a073096bbc4b047437c008e1795ffb74030dc9ded219700e35f448d28e83",
                ),
            ],
            products = [
                JLLLibraryProduct(
                    :libopenblas,
                    "lib/libopenblas.so",
                    [JLLLibraryDep(:CompilerSupportLibraries_jll, :libgfortran)],
                    [:RTLD_LAZY, :RTLD_DEEPBIND],
                ),
            ],
            init_def = openblas_init_block,
        ),

        JLLArtifactInfo(;
            src_version = v"0.3.23+2",
            deps = [
                JLLPackageDependency(
                    "CompilerSupportLibraries_jll",
                    Base.UUID("e66e0078-7015-5450-92f7-15fbd957f2ae"),
                    "*",
                ),
            ],
            sources = [],
            platform = Platform("armv6l", "linux"; libgfortran_version = "5.0.0", call_abi = "eabihf", libc = "musl"),
            name = "default",
            treehash = "3aa0ce59e4cd25195510b4541243f4ab6d53fd11",
            download_sources = [
                JLLArtifactSource(
                    "https://github.com/JuliaBinaryWrappers/OpenBLAS_jll.jl/releases/download/OpenBLAS-v0.3.23+2/OpenBLAS.v0.3.23.armv6l-linux-musleabihf-libgfortran5.tar.gz",
                    "9d692693b1c6d20057778a2d8e15f68099aaa999197bb042822dcdd724110718",
                ),
            ],
            products = [
                JLLLibraryProduct(
                    :libopenblas,
                    "lib/libopenblas.so",
                    [JLLLibraryDep(:CompilerSupportLibraries_jll, :libgfortran)],
                    [:RTLD_LAZY, :RTLD_DEEPBIND],
                ),
            ],
            init_def = openblas_init_block,
        ),

        JLLArtifactInfo(;
            src_version = v"0.3.23+2",
            deps = [
                JLLPackageDependency(
                    "CompilerSupportLibraries_jll",
                    Base.UUID("e66e0078-7015-5450-92f7-15fbd957f2ae"),
                    "*",
                ),
            ],
            sources = [],
            platform = Platform("armv7l", "linux"; libgfortran_version = "3.0.0", call_abi = "eabihf", libc = "glibc"),
            name = "default",
            treehash = "734921d630dba4eeaba4ee1d66d19a90aea9895d",
            download_sources = [
                JLLArtifactSource(
                    "https://github.com/JuliaBinaryWrappers/OpenBLAS_jll.jl/releases/download/OpenBLAS-v0.3.23+2/OpenBLAS.v0.3.23.armv7l-linux-gnueabihf-libgfortran3.tar.gz",
                    "893b4cee77633ae9358afadc6833eb4996439dc95df7b657f73f72d94f949443",
                ),
            ],
            products = [
                JLLLibraryProduct(
                    :libopenblas,
                    "lib/libopenblas.so",
                    [JLLLibraryDep(:CompilerSupportLibraries_jll, :libgfortran)],
                    [:RTLD_LAZY, :RTLD_DEEPBIND],
                ),
            ],
            init_def = openblas_init_block,
        ),

        JLLArtifactInfo(;
            src_version = v"0.3.23+2",
            deps = [
                JLLPackageDependency(
                    "CompilerSupportLibraries_jll",
                    Base.UUID("e66e0078-7015-5450-92f7-15fbd957f2ae"),
                    "*",
                ),
            ],
            sources = [],
            platform = Platform("armv7l", "linux"; libgfortran_version = "4.0.0", call_abi = "eabihf", libc = "glibc"),
            name = "default",
            treehash = "3ec245929162506d599471c689ccacf54291ff6d",
            download_sources = [
                JLLArtifactSource(
                    "https://github.com/JuliaBinaryWrappers/OpenBLAS_jll.jl/releases/download/OpenBLAS-v0.3.23+2/OpenBLAS.v0.3.23.armv7l-linux-gnueabihf-libgfortran4.tar.gz",
                    "672c23ef33f35c084242d41169ecdf59a2ba95697f02adc4100844b20f1accfd",
                ),
            ],
            products = [
                JLLLibraryProduct(
                    :libopenblas,
                    "lib/libopenblas.so",
                    [JLLLibraryDep(:CompilerSupportLibraries_jll, :libgfortran)],
                    [:RTLD_LAZY, :RTLD_DEEPBIND],
                ),
            ],
            init_def = openblas_init_block,
        ),

        JLLArtifactInfo(;
            src_version = v"0.3.23+2",
            deps = [
                JLLPackageDependency(
                    "CompilerSupportLibraries_jll",
                    Base.UUID("e66e0078-7015-5450-92f7-15fbd957f2ae"),
                    "*",
                ),
            ],
            sources = [],
            platform = Platform("armv7l", "linux"; libgfortran_version = "5.0.0", call_abi = "eabihf", libc = "glibc"),
            name = "default",
            treehash = "20899f92b0198109d469e7796a6b625b7f0cd966",
            download_sources = [
                JLLArtifactSource(
                    "https://github.com/JuliaBinaryWrappers/OpenBLAS_jll.jl/releases/download/OpenBLAS-v0.3.23+2/OpenBLAS.v0.3.23.armv7l-linux-gnueabihf-libgfortran5.tar.gz",
                    "57bac284ee2e012e7bca25a858637011aa0f57f8bd4fdbac0c2b69810bdb681b",
                ),
            ],
            products = [
                JLLLibraryProduct(
                    :libopenblas,
                    "lib/libopenblas.so",
                    [JLLLibraryDep(:CompilerSupportLibraries_jll, :libgfortran)],
                    [:RTLD_LAZY, :RTLD_DEEPBIND],
                ),
            ],
            init_def = openblas_init_block,
        ),

        JLLArtifactInfo(;
            src_version = v"0.3.23+2",
            deps = [
                JLLPackageDependency(
                    "CompilerSupportLibraries_jll",
                    Base.UUID("e66e0078-7015-5450-92f7-15fbd957f2ae"),
                    "*",
                ),
            ],
            sources = [],
            platform = Platform("armv7l", "linux"; libgfortran_version = "3.0.0", call_abi = "eabihf", libc = "musl"),
            name = "default",
            treehash = "6a42a2660643f0c590a4d0cda7f8bc4bfdfd0ccf",
            download_sources = [
                JLLArtifactSource(
                    "https://github.com/JuliaBinaryWrappers/OpenBLAS_jll.jl/releases/download/OpenBLAS-v0.3.23+2/OpenBLAS.v0.3.23.armv7l-linux-musleabihf-libgfortran3.tar.gz",
                    "c945c735d72517b697c4937f662985dddc53d59cc4067c5b1580c80eaca438da",
                ),
            ],
            products = [
                JLLLibraryProduct(
                    :libopenblas,
                    "lib/libopenblas.so",
                    [JLLLibraryDep(:CompilerSupportLibraries_jll, :libgfortran)],
                    [:RTLD_LAZY, :RTLD_DEEPBIND],
                ),
            ],
            init_def = openblas_init_block,
        ),

        JLLArtifactInfo(;
            src_version = v"0.3.23+2",
            deps = [
                JLLPackageDependency(
                    "CompilerSupportLibraries_jll",
                    Base.UUID("e66e0078-7015-5450-92f7-15fbd957f2ae"),
                    "*",
                ),
            ],
            sources = [],
            platform = Platform("armv7l", "linux"; libgfortran_version = "4.0.0", call_abi = "eabihf", libc = "musl"),
            name = "default",
            treehash = "9faec1d75fcda4c6b90abc68c4c92c63d8a2aed6",
            download_sources = [
                JLLArtifactSource(
                    "https://github.com/JuliaBinaryWrappers/OpenBLAS_jll.jl/releases/download/OpenBLAS-v0.3.23+2/OpenBLAS.v0.3.23.armv7l-linux-musleabihf-libgfortran4.tar.gz",
                    "f6f9a073096bbc4b047437c008e1795ffb74030dc9ded219700e35f448d28e83",
                ),
            ],
            products = [
                JLLLibraryProduct(
                    :libopenblas,
                    "lib/libopenblas.so",
                    [JLLLibraryDep(:CompilerSupportLibraries_jll, :libgfortran)],
                    [:RTLD_LAZY, :RTLD_DEEPBIND],
                ),
            ],
            init_def = openblas_init_block,
        ),

        JLLArtifactInfo(;
            src_version = v"0.3.23+2",
            deps = [
                JLLPackageDependency(
                    "CompilerSupportLibraries_jll",
                    Base.UUID("e66e0078-7015-5450-92f7-15fbd957f2ae"),
                    "*",
                ),
            ],
            sources = [],
            platform = Platform("armv7l", "linux"; libgfortran_version = "5.0.0", call_abi = "eabihf", libc = "musl"),
            name = "default",
            treehash = "3aa0ce59e4cd25195510b4541243f4ab6d53fd11",
            download_sources = [
                JLLArtifactSource(
                    "https://github.com/JuliaBinaryWrappers/OpenBLAS_jll.jl/releases/download/OpenBLAS-v0.3.23+2/OpenBLAS.v0.3.23.armv7l-linux-musleabihf-libgfortran5.tar.gz",
                    "9d692693b1c6d20057778a2d8e15f68099aaa999197bb042822dcdd724110718",
                ),
            ],
            products = [
                JLLLibraryProduct(
                    :libopenblas,
                    "lib/libopenblas.so",
                    [JLLLibraryDep(:CompilerSupportLibraries_jll, :libgfortran)],
                    [:RTLD_LAZY, :RTLD_DEEPBIND],
                ),
            ],
            init_def = openblas_init_block,
        ),

        JLLArtifactInfo(;
            src_version = v"0.3.23+2",
            deps = [
                JLLPackageDependency(
                    "CompilerSupportLibraries_jll",
                    Base.UUID("e66e0078-7015-5450-92f7-15fbd957f2ae"),
                    "*",
                ),
            ],
            sources = [],
            platform = Platform("i686", "linux"; libgfortran_version = "3.0.0", libc = "glibc"),
            name = "default",
            treehash = "6ccfe61e001e9e8670122ed3dd53ddedaee34a80",
            download_sources = [
                JLLArtifactSource(
                    "https://github.com/JuliaBinaryWrappers/OpenBLAS_jll.jl/releases/download/OpenBLAS-v0.3.23+2/OpenBLAS.v0.3.23.i686-linux-gnu-libgfortran3.tar.gz",
                    "87ebeb59964daf01ebdc47bccf3a29098f30d06ad6899243b8bf03a6c52b951c",
                ),
            ],
            products = [
                JLLLibraryProduct(
                    :libopenblas,
                    "lib/libopenblas.so",
                    [JLLLibraryDep(:CompilerSupportLibraries_jll, :libgfortran)],
                    [:RTLD_LAZY, :RTLD_DEEPBIND],
                ),
            ],
            init_def = openblas_init_block,
        ),

        JLLArtifactInfo(;
            src_version = v"0.3.23+2",
            deps = [
                JLLPackageDependency(
                    "CompilerSupportLibraries_jll",
                    Base.UUID("e66e0078-7015-5450-92f7-15fbd957f2ae"),
                    "*",
                ),
            ],
            sources = [],
            platform = Platform("i686", "linux"; libgfortran_version = "4.0.0", libc = "glibc"),
            name = "default",
            treehash = "ae73d3ab5b6936682cb3cb0de2c5d50ca179fae5",
            download_sources = [
                JLLArtifactSource(
                    "https://github.com/JuliaBinaryWrappers/OpenBLAS_jll.jl/releases/download/OpenBLAS-v0.3.23+2/OpenBLAS.v0.3.23.i686-linux-gnu-libgfortran4.tar.gz",
                    "de11d5d47e425024aab5980ac7392b9bf63188ad5b7269bdcdcb9eee6e757045",
                ),
            ],
            products = [
                JLLLibraryProduct(
                    :libopenblas,
                    "lib/libopenblas.so",
                    [JLLLibraryDep(:CompilerSupportLibraries_jll, :libgfortran)],
                    [:RTLD_LAZY, :RTLD_DEEPBIND],
                ),
            ],
            init_def = openblas_init_block,
        ),

        JLLArtifactInfo(;
            src_version = v"0.3.23+2",
            deps = [
                JLLPackageDependency(
                    "CompilerSupportLibraries_jll",
                    Base.UUID("e66e0078-7015-5450-92f7-15fbd957f2ae"),
                    "*",
                ),
            ],
            sources = [],
            platform = Platform("i686", "linux"; libgfortran_version = "5.0.0", libc = "glibc"),
            name = "default",
            treehash = "f6a54add7606913840bec00b64ff603f1cc17faf",
            download_sources = [
                JLLArtifactSource(
                    "https://github.com/JuliaBinaryWrappers/OpenBLAS_jll.jl/releases/download/OpenBLAS-v0.3.23+2/OpenBLAS.v0.3.23.i686-linux-gnu-libgfortran5.tar.gz",
                    "987a1cc137f5d6a548a7bdb54919ed01c45e8019f16113e2b5772436312f321b",
                ),
            ],
            products = [
                JLLLibraryProduct(
                    :libopenblas,
                    "lib/libopenblas.so",
                    [JLLLibraryDep(:CompilerSupportLibraries_jll, :libgfortran)],
                    [:RTLD_LAZY, :RTLD_DEEPBIND],
                ),
            ],
            init_def = openblas_init_block,
        ),

        JLLArtifactInfo(;
            src_version = v"0.3.23+2",
            deps = [
                JLLPackageDependency(
                    "CompilerSupportLibraries_jll",
                    Base.UUID("e66e0078-7015-5450-92f7-15fbd957f2ae"),
                    "*",
                ),
            ],
            sources = [],
            platform = Platform("i686", "linux"; libgfortran_version = "3.0.0", libc = "musl"),
            name = "default",
            treehash = "bdb6990376ba7364973a88b2c43b5e188bed23c7",
            download_sources = [
                JLLArtifactSource(
                    "https://github.com/JuliaBinaryWrappers/OpenBLAS_jll.jl/releases/download/OpenBLAS-v0.3.23+2/OpenBLAS.v0.3.23.i686-linux-musl-libgfortran3.tar.gz",
                    "9c88b93be47e639e66ffbd37363de9ccd1cde9ac2c3903600ff4ee85bb7ad04f",
                ),
            ],
            products = [
                JLLLibraryProduct(
                    :libopenblas,
                    "lib/libopenblas.so",
                    [JLLLibraryDep(:CompilerSupportLibraries_jll, :libgfortran)],
                    [:RTLD_LAZY, :RTLD_DEEPBIND],
                ),
            ],
            init_def = openblas_init_block,
        ),

        JLLArtifactInfo(;
            src_version = v"0.3.23+2",
            deps = [
                JLLPackageDependency(
                    "CompilerSupportLibraries_jll",
                    Base.UUID("e66e0078-7015-5450-92f7-15fbd957f2ae"),
                    "*",
                ),
            ],
            sources = [],
            platform = Platform("i686", "linux"; libgfortran_version = "4.0.0", libc = "musl"),
            name = "default",
            treehash = "712cfee4c29a2f867d2af1a08a81be10e8ad9f74",
            download_sources = [
                JLLArtifactSource(
                    "https://github.com/JuliaBinaryWrappers/OpenBLAS_jll.jl/releases/download/OpenBLAS-v0.3.23+2/OpenBLAS.v0.3.23.i686-linux-musl-libgfortran4.tar.gz",
                    "2bb92abfa72c457f6a935678d3bb476c1bf1d08b93785c5976d782dd6bbbe85e",
                ),
            ],
            products = [
                JLLLibraryProduct(
                    :libopenblas,
                    "lib/libopenblas.so",
                    [JLLLibraryDep(:CompilerSupportLibraries_jll, :libgfortran)],
                    [:RTLD_LAZY, :RTLD_DEEPBIND],
                ),
            ],
            init_def = openblas_init_block,
        ),

        JLLArtifactInfo(;
            src_version = v"0.3.23+2",
            deps = [
                JLLPackageDependency(
                    "CompilerSupportLibraries_jll",
                    Base.UUID("e66e0078-7015-5450-92f7-15fbd957f2ae"),
                    "*",
                ),
            ],
            sources = [],
            platform = Platform("i686", "linux"; libgfortran_version = "5.0.0", libc = "musl"),
            name = "default",
            treehash = "c518c0e87c036b2bcb192dda2e004314131364a5",
            download_sources = [
                JLLArtifactSource(
                    "https://github.com/JuliaBinaryWrappers/OpenBLAS_jll.jl/releases/download/OpenBLAS-v0.3.23+2/OpenBLAS.v0.3.23.i686-linux-musl-libgfortran5.tar.gz",
                    "8214fe3ab3c706725c86668a134a4aa58fbd7dd29b20366fc87298561e392b1a",
                ),
            ],
            products = [
                JLLLibraryProduct(
                    :libopenblas,
                    "lib/libopenblas.so",
                    [JLLLibraryDep(:CompilerSupportLibraries_jll, :libgfortran)],
                    [:RTLD_LAZY, :RTLD_DEEPBIND],
                ),
            ],
            init_def = openblas_init_block,
        ),

        JLLArtifactInfo(;
            src_version = v"0.3.23+2",
            deps = [
                JLLPackageDependency(
                    "CompilerSupportLibraries_jll",
                    Base.UUID("e66e0078-7015-5450-92f7-15fbd957f2ae"),
                    "*",
                ),
            ],
            sources = [],
            platform = Platform("i686", "windows"; libgfortran_version = "3.0.0"),
            name = "default",
            treehash = "bbc61a2e5f3298a8ce0c05e23e9797477d304949",
            download_sources = [
                JLLArtifactSource(
                    "https://github.com/JuliaBinaryWrappers/OpenBLAS_jll.jl/releases/download/OpenBLAS-v0.3.23+2/OpenBLAS.v0.3.23.i686-w64-mingw32-libgfortran3.tar.gz",
                    "b86201e0d93b78ba7fb412d919048e6e0ecb039816035898777fd5b288d13e52",
                ),
            ],
            products = [
                JLLLibraryProduct(
                    :libopenblas,
                    "bin\\libopenblas.dll",
                    [JLLLibraryDep(:CompilerSupportLibraries_jll, :libgfortran)],
                    [:RTLD_LAZY, :RTLD_DEEPBIND],
                ),
            ],
            init_def = openblas_init_block,
        ),

        JLLArtifactInfo(;
            src_version = v"0.3.23+2",
            deps = [
                JLLPackageDependency(
                    "CompilerSupportLibraries_jll",
                    Base.UUID("e66e0078-7015-5450-92f7-15fbd957f2ae"),
                    "*",
                ),
            ],
            sources = [],
            platform = Platform("i686", "windows"; libgfortran_version = "4.0.0"),
            name = "default",
            treehash = "ba460ada05eac6d5544b2a7d2ea06c65241ce45b",
            download_sources = [
                JLLArtifactSource(
                    "https://github.com/JuliaBinaryWrappers/OpenBLAS_jll.jl/releases/download/OpenBLAS-v0.3.23+2/OpenBLAS.v0.3.23.i686-w64-mingw32-libgfortran4.tar.gz",
                    "fbcf5e8ebef0771544adfc07527e22e7189d45bbcd924c2adafdc98e238c6963",
                ),
            ],
            products = [
                JLLLibraryProduct(
                    :libopenblas,
                    "bin\\libopenblas.dll",
                    [JLLLibraryDep(:CompilerSupportLibraries_jll, :libgfortran)],
                    [:RTLD_LAZY, :RTLD_DEEPBIND],
                ),
            ],
            init_def = openblas_init_block,
        ),

        JLLArtifactInfo(;
            src_version = v"0.3.23+2",
            deps = [
                JLLPackageDependency(
                    "CompilerSupportLibraries_jll",
                    Base.UUID("e66e0078-7015-5450-92f7-15fbd957f2ae"),
                    "*",
                ),
            ],
            sources = [],
            platform = Platform("i686", "windows"; libgfortran_version = "5.0.0"),
            name = "default",
            treehash = "889ce291d838b51d3edf04583796525f1781b7a4",
            download_sources = [
                JLLArtifactSource(
                    "https://github.com/JuliaBinaryWrappers/OpenBLAS_jll.jl/releases/download/OpenBLAS-v0.3.23+2/OpenBLAS.v0.3.23.i686-w64-mingw32-libgfortran5.tar.gz",
                    "1417cd14a87f0f067db41ba5be22ab9d577a2b22964af2010eac9bc2d16ebc08",
                ),
            ],
            products = [
                JLLLibraryProduct(
                    :libopenblas,
                    "bin\\libopenblas.dll",
                    [JLLLibraryDep(:CompilerSupportLibraries_jll, :libgfortran)],
                    [:RTLD_LAZY, :RTLD_DEEPBIND],
                ),
            ],
            init_def = openblas_init_block,
        ),

        JLLArtifactInfo(;
            src_version = v"0.3.23+2",
            deps = [
                JLLPackageDependency(
                    "CompilerSupportLibraries_jll",
                    Base.UUID("e66e0078-7015-5450-92f7-15fbd957f2ae"),
                    "*",
                ),
            ],
            sources = [],
            platform = Platform("powerpc64le", "linux"; libgfortran_version = "3.0.0", libc = "glibc"),
            name = "default",
            treehash = "1cfe4d0db216203e85c271ae61b9c325e9a77570",
            download_sources = [
                JLLArtifactSource(
                    "https://github.com/JuliaBinaryWrappers/OpenBLAS_jll.jl/releases/download/OpenBLAS-v0.3.23+2/OpenBLAS.v0.3.23.powerpc64le-linux-gnu-libgfortran3.tar.gz",
                    "68b17c92ebfb2bec7e2e724aa6a972399b4f41f1af9be3c0eb1fb0276fb2a7dc",
                ),
            ],
            products = [
                JLLLibraryProduct(
                    :libopenblas,
                    "lib/libopenblas64_.so",
                    [JLLLibraryDep(:CompilerSupportLibraries_jll, :libgfortran)],
                    [:RTLD_LAZY, :RTLD_DEEPBIND],
                ),
            ],
            init_def = openblas_init_block,
        ),

        JLLArtifactInfo(;
            src_version = v"0.3.23+2",
            deps = [
                JLLPackageDependency(
                    "CompilerSupportLibraries_jll",
                    Base.UUID("e66e0078-7015-5450-92f7-15fbd957f2ae"),
                    "*",
                ),
            ],
            sources = [],
            platform = Platform("powerpc64le", "linux"; libgfortran_version = "4.0.0", libc = "glibc"),
            name = "default",
            treehash = "3c33242559090f13482caa3e03fd18da72cc33f9",
            download_sources = [
                JLLArtifactSource(
                    "https://github.com/JuliaBinaryWrappers/OpenBLAS_jll.jl/releases/download/OpenBLAS-v0.3.23+2/OpenBLAS.v0.3.23.powerpc64le-linux-gnu-libgfortran4.tar.gz",
                    "acc41543ac8b716b15f44b1cdf64098ebbb764f91e59aedee649ad8394cd5169",
                ),
            ],
            products = [
                JLLLibraryProduct(
                    :libopenblas,
                    "lib/libopenblas64_.so",
                    [JLLLibraryDep(:CompilerSupportLibraries_jll, :libgfortran)],
                    [:RTLD_LAZY, :RTLD_DEEPBIND],
                ),
            ],
            init_def = openblas_init_block,
        ),

        JLLArtifactInfo(;
            src_version = v"0.3.23+2",
            deps = [
                JLLPackageDependency(
                    "CompilerSupportLibraries_jll",
                    Base.UUID("e66e0078-7015-5450-92f7-15fbd957f2ae"),
                    "*",
                ),
            ],
            sources = [],
            platform = Platform("powerpc64le", "linux"; libgfortran_version = "5.0.0", libc = "glibc"),
            name = "default",
            treehash = "8866e41c2a8b1e02e4529c74edd8d0f5b9409d32",
            download_sources = [
                JLLArtifactSource(
                    "https://github.com/JuliaBinaryWrappers/OpenBLAS_jll.jl/releases/download/OpenBLAS-v0.3.23+2/OpenBLAS.v0.3.23.powerpc64le-linux-gnu-libgfortran5.tar.gz",
                    "3de8c98cb65b1142bdbc578ba66f9333772de5296c37bfab1e88d01b47b4e6ca",
                ),
            ],
            products = [
                JLLLibraryProduct(
                    :libopenblas,
                    "lib/libopenblas64_.so",
                    [JLLLibraryDep(:CompilerSupportLibraries_jll, :libgfortran)],
                    [:RTLD_LAZY, :RTLD_DEEPBIND],
                ),
            ],
            init_def = openblas_init_block,
        ),

        JLLArtifactInfo(;
            src_version = v"0.3.23+2",
            deps = [
                JLLPackageDependency(
                    "CompilerSupportLibraries_jll",
                    Base.UUID("e66e0078-7015-5450-92f7-15fbd957f2ae"),
                    "*",
                ),
            ],
            sources = [],
            platform = Platform("x86_64", "macos"; libgfortran_version = "3.0.0"),
            name = "default",
            treehash = "8dbce3eb85463819a1d393413668d055f99a5585",
            download_sources = [
                JLLArtifactSource(
                    "https://github.com/JuliaBinaryWrappers/OpenBLAS_jll.jl/releases/download/OpenBLAS-v0.3.23+2/OpenBLAS.v0.3.23.x86_64-apple-darwin-libgfortran3.tar.gz",
                    "f46a067a8442af00d2a99281298a312cd339cc840356413568c30ed7c7d43f8c",
                ),
            ],
            products = [
                JLLLibraryProduct(
                    :libopenblas,
                    "lib/libopenblas64_.0.3.23.dylib",
                    [JLLLibraryDep(:CompilerSupportLibraries_jll, :libgfortran)],
                    [:RTLD_LAZY, :RTLD_DEEPBIND],
                ),
            ],
            init_def = openblas_init_block,
        ),

        JLLArtifactInfo(;
            src_version = v"0.3.23+2",
            deps = [
                JLLPackageDependency(
                    "CompilerSupportLibraries_jll",
                    Base.UUID("e66e0078-7015-5450-92f7-15fbd957f2ae"),
                    "*",
                ),
            ],
            sources = [],
            platform = Platform("x86_64", "macos"; libgfortran_version = "4.0.0"),
            name = "default",
            treehash = "79b6db7b5c21fbe4601f1f2ae1c3eff18a516e5b",
            download_sources = [
                JLLArtifactSource(
                    "https://github.com/JuliaBinaryWrappers/OpenBLAS_jll.jl/releases/download/OpenBLAS-v0.3.23+2/OpenBLAS.v0.3.23.x86_64-apple-darwin-libgfortran4.tar.gz",
                    "8b3fa6588ce24651246f88c16fa7ac2a8ac49b1aae748c14fd12139c189fa562",
                ),
            ],
            products = [
                JLLLibraryProduct(
                    :libopenblas,
                    "lib/libopenblas64_.0.3.23.dylib",
                    [JLLLibraryDep(:CompilerSupportLibraries_jll, :libgfortran)],
                    [:RTLD_LAZY, :RTLD_DEEPBIND],
                ),
            ],
            init_def = openblas_init_block,
        ),

        JLLArtifactInfo(;
            src_version = v"0.3.23+2",
            deps = [
                JLLPackageDependency(
                    "CompilerSupportLibraries_jll",
                    Base.UUID("e66e0078-7015-5450-92f7-15fbd957f2ae"),
                    "*",
                ),
            ],
            sources = [],
            platform = Platform("x86_64", "macos"; libgfortran_version = "5.0.0"),
            name = "default",
            treehash = "a5ed6a23544222351d4413b0a6080e16c0f792b7",
            download_sources = [
                JLLArtifactSource(
                    "https://github.com/JuliaBinaryWrappers/OpenBLAS_jll.jl/releases/download/OpenBLAS-v0.3.23+2/OpenBLAS.v0.3.23.x86_64-apple-darwin-libgfortran5.tar.gz",
                    "eb60f2b0fcb565a2bcb7ca8ffb5061937dd3394bb651f6ee665da8a786ed89bd",
                ),
            ],
            products = [
                JLLLibraryProduct(
                    :libopenblas,
                    "lib/libopenblas64_.0.3.23.dylib",
                    [JLLLibraryDep(:CompilerSupportLibraries_jll, :libgfortran)],
                    [:RTLD_LAZY, :RTLD_DEEPBIND],
                ),
            ],
            init_def = openblas_init_block,
        ),

        JLLArtifactInfo(;
            src_version = v"0.3.23+2",
            deps = [
                JLLPackageDependency(
                    "CompilerSupportLibraries_jll",
                    Base.UUID("e66e0078-7015-5450-92f7-15fbd957f2ae"),
                    "*",
                ),
            ],
            sources = [],
            platform = Platform("x86_64", "linux"; libgfortran_version = "3.0.0", libc = "glibc"),
            name = "default",
            treehash = "d51d1ba68dd99afb395ae0ee6d5334a64e0fda79",
            download_sources = [
                JLLArtifactSource(
                    "https://github.com/JuliaBinaryWrappers/OpenBLAS_jll.jl/releases/download/OpenBLAS-v0.3.23+2/OpenBLAS.v0.3.23.x86_64-linux-gnu-libgfortran3.tar.gz",
                    "7977deb68af51378ed6fc7264ef62d4e4b4e61cf5bfb71d0639184ef5564b39f",
                ),
            ],
            products = [
                JLLLibraryProduct(
                    :libopenblas,
                    "lib/libopenblas64_.so",
                    [JLLLibraryDep(:CompilerSupportLibraries_jll, :libgfortran)],
                    [:RTLD_LAZY, :RTLD_DEEPBIND],
                ),
            ],
            init_def = openblas_init_block,
        ),

        JLLArtifactInfo(;
            src_version = v"0.3.23+2",
            deps = [
                JLLPackageDependency(
                    "CompilerSupportLibraries_jll",
                    Base.UUID("e66e0078-7015-5450-92f7-15fbd957f2ae"),
                    "*",
                ),
            ],
            sources = [],
            platform = Platform("x86_64", "linux"; libgfortran_version = "4.0.0", libc = "glibc"),
            name = "default",
            treehash = "10f9c071f0c6b6c0797961b21a6c957f1fa93d68",
            download_sources = [
                JLLArtifactSource(
                    "https://github.com/JuliaBinaryWrappers/OpenBLAS_jll.jl/releases/download/OpenBLAS-v0.3.23+2/OpenBLAS.v0.3.23.x86_64-linux-gnu-libgfortran4.tar.gz",
                    "42357b34e7bb2ec359ca363cf24b35281e711911da2cb08c857ea12f8bf6e25c",
                ),
            ],
            products = [
                JLLLibraryProduct(
                    :libopenblas,
                    "lib/libopenblas64_.so",
                    [JLLLibraryDep(:CompilerSupportLibraries_jll, :libgfortran)],
                    [:RTLD_LAZY, :RTLD_DEEPBIND],
                ),
            ],
            init_def = openblas_init_block,
        ),

        JLLArtifactInfo(;
            src_version = v"0.3.23+2",
            deps = [
                JLLPackageDependency(
                    "CompilerSupportLibraries_jll",
                    Base.UUID("e66e0078-7015-5450-92f7-15fbd957f2ae"),
                    "*",
                ),
            ],
            sources = [],
            platform = Platform("x86_64", "linux"; libgfortran_version = "5.0.0", libc = "glibc"),
            name = "default",
            treehash = "0e3ffacf210dfeed0eb4bc9d7f7a1a99e8c4c284",
            download_sources = [
                JLLArtifactSource(
                    "https://github.com/JuliaBinaryWrappers/OpenBLAS_jll.jl/releases/download/OpenBLAS-v0.3.23+2/OpenBLAS.v0.3.23.x86_64-linux-gnu-libgfortran5.tar.gz",
                    "a80625e6f2762c8d11937436900c5308314ad5255f122f1a112c211d639fd6a0",
                ),
            ],
            products = [
                JLLLibraryProduct(
                    :libopenblas,
                    "lib/libopenblas64_.so",
                    [JLLLibraryDep(:CompilerSupportLibraries_jll, :libgfortran)],
                    [:RTLD_LAZY, :RTLD_DEEPBIND],
                ),
            ],
            init_def = openblas_init_block,
        ),

        JLLArtifactInfo(;
            src_version = v"0.3.23+2",
            deps = [
                JLLPackageDependency(
                    "CompilerSupportLibraries_jll",
                    Base.UUID("e66e0078-7015-5450-92f7-15fbd957f2ae"),
                    "*",
                ),
            ],
            sources = [],
            platform = Platform("x86_64", "linux"; libc = "glibc", sanitize = "memory"),
            name = "default",
            treehash = "b3b43fae93bb19c932a4f98594e94a03610ae750",
            download_sources = [
                JLLArtifactSource(
                    "https://github.com/JuliaBinaryWrappers/OpenBLAS_jll.jl/releases/download/OpenBLAS-v0.3.23+2/OpenBLAS.v0.3.23.x86_64-linux-gnu-sanitize+memory.tar.gz",
                    "92de95997cf349636d1ad343857243a2af758ff93a686608807c5f11033d96dd",
                ),
            ],
            products = [
                JLLLibraryProduct(
                    :libopenblas,
                    "lib/libopenblas64_.so",
                    [JLLLibraryDep(:CompilerSupportLibraries_jll, :libgfortran)],
                    [:RTLD_LAZY, :RTLD_DEEPBIND],
                ),
            ],
            init_def = openblas_init_block,
        ),

        JLLArtifactInfo(;
            src_version = v"0.3.23+2",
            deps = [
                JLLPackageDependency(
                    "CompilerSupportLibraries_jll",
                    Base.UUID("e66e0078-7015-5450-92f7-15fbd957f2ae"),
                    "*",
                ),
            ],
            sources = [],
            platform = Platform("x86_64", "linux"; libgfortran_version = "3.0.0", libc = "musl"),
            name = "default",
            treehash = "45306bc695605d56b6b985981ae2be764b7fd2d5",
            download_sources = [
                JLLArtifactSource(
                    "https://github.com/JuliaBinaryWrappers/OpenBLAS_jll.jl/releases/download/OpenBLAS-v0.3.23+2/OpenBLAS.v0.3.23.x86_64-linux-musl-libgfortran3.tar.gz",
                    "3af2bf64c4b5ba8f40a807db9d6ccd4996d28ea5f6acfb18869a4e9e9b349fa4",
                ),
            ],
            products = [
                JLLLibraryProduct(
                    :libopenblas,
                    "lib/libopenblas64_.so",
                    [JLLLibraryDep(:CompilerSupportLibraries_jll, :libgfortran)],
                    [:RTLD_LAZY, :RTLD_DEEPBIND],
                ),
            ],
            init_def = openblas_init_block,
        ),

        JLLArtifactInfo(;
            src_version = v"0.3.23+2",
            deps = [
                JLLPackageDependency(
                    "CompilerSupportLibraries_jll",
                    Base.UUID("e66e0078-7015-5450-92f7-15fbd957f2ae"),
                    "*",
                ),
            ],
            sources = [],
            platform = Platform("x86_64", "linux"; libgfortran_version = "4.0.0", libc = "musl"),
            name = "default",
            treehash = "1f4aca94e9a94eb32df298473758b9ba9d6e4805",
            download_sources = [
                JLLArtifactSource(
                    "https://github.com/JuliaBinaryWrappers/OpenBLAS_jll.jl/releases/download/OpenBLAS-v0.3.23+2/OpenBLAS.v0.3.23.x86_64-linux-musl-libgfortran4.tar.gz",
                    "e6ee56b785a2f3b8f26bdb266932d867cc6c2eddd0287a46d0f6e3ccae610047",
                ),
            ],
            products = [
                JLLLibraryProduct(
                    :libopenblas,
                    "lib/libopenblas64_.so",
                    [JLLLibraryDep(:CompilerSupportLibraries_jll, :libgfortran)],
                    [:RTLD_LAZY, :RTLD_DEEPBIND],
                ),
            ],
            init_def = openblas_init_block,
        ),

        JLLArtifactInfo(;
            src_version = v"0.3.23+2",
            deps = [
                JLLPackageDependency(
                    "CompilerSupportLibraries_jll",
                    Base.UUID("e66e0078-7015-5450-92f7-15fbd957f2ae"),
                    "*",
                ),
            ],
            sources = [],
            platform = Platform("x86_64", "linux"; libgfortran_version = "5.0.0", libc = "musl"),
            name = "default",
            treehash = "fddad481425e9e42f168a86122c198106abef08b",
            download_sources = [
                JLLArtifactSource(
                    "https://github.com/JuliaBinaryWrappers/OpenBLAS_jll.jl/releases/download/OpenBLAS-v0.3.23+2/OpenBLAS.v0.3.23.x86_64-linux-musl-libgfortran5.tar.gz",
                    "1eb9ac5a0d7a008dd39de958a315c4f2d3b581def00c9c17594c73d039791d84",
                ),
            ],
            products = [
                JLLLibraryProduct(
                    :libopenblas,
                    "lib/libopenblas64_.so",
                    [JLLLibraryDep(:CompilerSupportLibraries_jll, :libgfortran)],
                    [:RTLD_LAZY, :RTLD_DEEPBIND],
                ),
            ],
            init_def = openblas_init_block,
        ),

        JLLArtifactInfo(;
            src_version = v"0.3.23+2",
            deps = [
                JLLPackageDependency(
                    "CompilerSupportLibraries_jll",
                    Base.UUID("e66e0078-7015-5450-92f7-15fbd957f2ae"),
                    "*",
                ),
            ],
            sources = [],
            platform = Platform("x86_64", "freebsd"; libgfortran_version = "3.0.0"),
            name = "default",
            treehash = "dd8d2eccb47e51a659264b4198d613371c392c67",
            download_sources = [
                JLLArtifactSource(
                    "https://github.com/JuliaBinaryWrappers/OpenBLAS_jll.jl/releases/download/OpenBLAS-v0.3.23+2/OpenBLAS.v0.3.23.x86_64-unknown-freebsd-libgfortran3.tar.gz",
                    "86a88358a5c7ea47ca5b9e5886d2ba242f8deed6c0efdc4f3e959be2af1d086b",
                ),
            ],
            products = [
                JLLLibraryProduct(
                    :libopenblas,
                    "lib/libopenblas64_.so",
                    [JLLLibraryDep(:CompilerSupportLibraries_jll, :libgfortran)],
                    [:RTLD_LAZY, :RTLD_DEEPBIND],
                ),
            ],
            init_def = openblas_init_block,
        ),

        JLLArtifactInfo(;
            src_version = v"0.3.23+2",
            deps = [
                JLLPackageDependency(
                    "CompilerSupportLibraries_jll",
                    Base.UUID("e66e0078-7015-5450-92f7-15fbd957f2ae"),
                    "*",
                ),
            ],
            sources = [],
            platform = Platform("x86_64", "freebsd"; libgfortran_version = "4.0.0"),
            name = "default",
            treehash = "1ef2b5fa2a1094df68e6410fa44e1dd8f8e701e0",
            download_sources = [
                JLLArtifactSource(
                    "https://github.com/JuliaBinaryWrappers/OpenBLAS_jll.jl/releases/download/OpenBLAS-v0.3.23+2/OpenBLAS.v0.3.23.x86_64-unknown-freebsd-libgfortran4.tar.gz",
                    "089ceb5cd7c4d518c6d1362ea321fa81b45c34b09531835f374a9cade04eb253",
                ),
            ],
            products = [
                JLLLibraryProduct(
                    :libopenblas,
                    "lib/libopenblas64_.so",
                    [JLLLibraryDep(:CompilerSupportLibraries_jll, :libgfortran)],
                    [:RTLD_LAZY, :RTLD_DEEPBIND],
                ),
            ],
            init_def = openblas_init_block,
        ),

        JLLArtifactInfo(;
            src_version = v"0.3.23+2",
            deps = [
                JLLPackageDependency(
                    "CompilerSupportLibraries_jll",
                    Base.UUID("e66e0078-7015-5450-92f7-15fbd957f2ae"),
                    "*",
                ),
            ],
            sources = [],
            platform = Platform("x86_64", "freebsd"; libgfortran_version = "5.0.0"),
            name = "default",
            treehash = "4011ada12d0e98a4ee64e12f3178e057e21cb0a0",
            download_sources = [
                JLLArtifactSource(
                    "https://github.com/JuliaBinaryWrappers/OpenBLAS_jll.jl/releases/download/OpenBLAS-v0.3.23+2/OpenBLAS.v0.3.23.x86_64-unknown-freebsd-libgfortran5.tar.gz",
                    "4578d827c83d62ef1f04efcc882d62304df88426253d787d08b07314c1092e5d",
                ),
            ],
            products = [
                JLLLibraryProduct(
                    :libopenblas,
                    "lib/libopenblas64_.so",
                    [JLLLibraryDep(:CompilerSupportLibraries_jll, :libgfortran)],
                    [:RTLD_LAZY, :RTLD_DEEPBIND],
                ),
            ],
            init_def = openblas_init_block,
        ),

        JLLArtifactInfo(;
            src_version = v"0.3.23+2",
            deps = [
                JLLPackageDependency(
                    "CompilerSupportLibraries_jll",
                    Base.UUID("e66e0078-7015-5450-92f7-15fbd957f2ae"),
                    "*",
                ),
            ],
            sources = [],
            platform = Platform("x86_64", "windows"; libgfortran_version = "3.0.0"),
            name = "default",
            treehash = "77a5659dc279d1c004e10c025051ee93d1ba94b1",
            download_sources = [
                JLLArtifactSource(
                    "https://github.com/JuliaBinaryWrappers/OpenBLAS_jll.jl/releases/download/OpenBLAS-v0.3.23+2/OpenBLAS.v0.3.23.x86_64-w64-mingw32-libgfortran3.tar.gz",
                    "5f813d7cc7fcf25ca388a7f78915cc5216e80365265b914bffcf541b32cd610b",
                ),
            ],
            products = [
                JLLLibraryProduct(
                    :libopenblas,
                    "bin\\libopenblas64_.dll",
                    [JLLLibraryDep(:CompilerSupportLibraries_jll, :libgfortran)],
                    [:RTLD_LAZY, :RTLD_DEEPBIND],
                ),
            ],
            init_def = openblas_init_block,
        ),

        JLLArtifactInfo(;
            src_version = v"0.3.23+2",
            deps = [
                JLLPackageDependency(
                    "CompilerSupportLibraries_jll",
                    Base.UUID("e66e0078-7015-5450-92f7-15fbd957f2ae"),
                    "*",
                ),
            ],
            sources = [],
            platform = Platform("x86_64", "windows"; libgfortran_version = "4.0.0"),
            name = "default",
            treehash = "9934244b3b85c86d0a9ad94372a08509b7cd69b3",
            download_sources = [
                JLLArtifactSource(
                    "https://github.com/JuliaBinaryWrappers/OpenBLAS_jll.jl/releases/download/OpenBLAS-v0.3.23+2/OpenBLAS.v0.3.23.x86_64-w64-mingw32-libgfortran4.tar.gz",
                    "d621985744485ecba18b58db177e7559f2889f88b23a31a63fcd3a0ec4663a51",
                ),
            ],
            products = [
                JLLLibraryProduct(
                    :libopenblas,
                    "bin\\libopenblas64_.dll",
                    [JLLLibraryDep(:CompilerSupportLibraries_jll, :libgfortran)],
                    [:RTLD_LAZY, :RTLD_DEEPBIND],
                ),
            ],
            init_def = openblas_init_block,
        ),

        JLLArtifactInfo(;
            src_version = v"0.3.23+2",
            deps = [
                JLLPackageDependency(
                    "CompilerSupportLibraries_jll",
                    Base.UUID("e66e0078-7015-5450-92f7-15fbd957f2ae"),
                    "*",
                ),
            ],
            sources = [],
            platform = Platform("x86_64", "windows"; libgfortran_version = "5.0.0"),
            name = "default",
            treehash = "9f38d0d35553b61f556fe1597555afc01cc555ce",
            download_sources = [
                JLLArtifactSource(
                    "https://github.com/JuliaBinaryWrappers/OpenBLAS_jll.jl/releases/download/OpenBLAS-v0.3.23+2/OpenBLAS.v0.3.23.x86_64-w64-mingw32-libgfortran5.tar.gz",
                    "3deab9f0b68d63ce8a5db9d36a4c0ae1930e32e0006433309e8c012bd4f4a155",
                ),
            ],
            products = [
                JLLLibraryProduct(
                    :libopenblas,
                    "bin\\libopenblas64_.dll",
                    [JLLLibraryDep(:CompilerSupportLibraries_jll, :libgfortran)],
                    [:RTLD_LAZY, :RTLD_DEEPBIND],
                ),
            ],
            init_def = openblas_init_block,
        ),

    ]
)

