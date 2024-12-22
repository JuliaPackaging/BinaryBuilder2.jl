include("llvm_common.jl")

build_tarballs(;
    src_name = "LLVMCompilerRT",
    src_version = llvm_version,
    sources = llvm_sources,
    script = llvm_script_prefix * raw"""
    CMAKE_FLAGS=()
    CMAKE_FLAGS+=('-DLLVM_TARGETS_TO_BUILD:STRING=X86;ARM;AArch64;PowerPC;RISCV;WebAssembly')

    # Install to `prefix`, and make a release build
    CMAKE_FLAGS+=("-DCMAKE_INSTALL_PREFIX=${prefix}")
    CMAKE_FLAGS+=(-DCMAKE_BUILD_TYPE=Release)

    # Only build clang (we rely on libgcc_s)
    CMAKE_FLAGS+=("-DCOMPILER_RT_BUILD_BUILTINS=ON")
    CMAKE_FLAGS+=("-DCOMPILER_RT_BUILD_LIBFUZZER=OFF")
    CMAKE_FLAGS+=("-DCOMPILER_RT_BUILD_MEMPROF=OFF")
    CMAKE_FLAGS+=("-DCOMPILER_RT_BUILD_PROFILE=OFF")
    CMAKE_FLAGS+=("-DCOMPILER_RT_BUILD_SANITIZERS=OFF")
    CMAKE_FLAGS+=("-DCOMPILER_RT_BUILD_XRAY=OFF")
    CMAKE_FLAGS+=("-DCOMPILER_RT_DEFAULT_TARGET_TRIPLE=${target}")

    # Build!
    $CMAKE ${WORKSPACE}/srcdir/llvm-project/compiler-rt ${CMAKE_FLAGS[@]}
    make -j${nproc}

    # Install!
    make install -j${nproc} #VERBOSE=1
    """,
    platforms=supported_platforms(),
    host,
    # We need python, and we need to build with clang
    host_dependencies = [JLLSource("Python_jll")],
    target_dependencies = [
        JLLSource(
            "Zlib_jll";
            repo=Pkg.Types.GitRepo(
                rev="bb2/GCC",
                source="https://github.com/staticfloat/Zlib_jll.jl"
            ),
        ),
    ],
    host_toolchains = [CToolchain(;vendor=:clang_bootstrap), CMakeToolchain(), HostToolsToolchain()],
    target_toolchains = [CToolchain(;vendor=:clang_bootstrap, lock_microarchitecture=false), CMakeToolchain()],
)
