include("llvm_common.jl")

build_tarballs(;
    src_name = "LLVMCompilerRT",
    src_version = llvm_version,
    sources = llvm_sources,
    script = llvm_script_prefix * raw"""
    # Specify exactly which pieces of compiler-rt we want
    CMAKE_FLAGS+=("-DCOMPILER_RT_BUILD_BUILTINS=ON")
    CMAKE_FLAGS+=("-DCOMPILER_RT_BUILD_CRT=ON")
    CMAKE_FLAGS+=("-DCOMPILER_RT_BUILD_LIBFUZZER=OFF")
    CMAKE_FLAGS+=("-DCOMPILER_RT_BUILD_MEMPROF=OFF")
    CMAKE_FLAGS+=("-DCOMPILER_RT_BUILD_PROFILE=OFF")
    CMAKE_FLAGS+=("-DCOMPILER_RT_BUILD_SANITIZERS=OFF")
    CMAKE_FLAGS+=("-DCOMPILER_RT_BUILD_XRAY=OFF")
    CMAKE_FLAGS+=("-DCOMPILER_RT_DEFAULT_TARGET_TRIPLE=${target}")

    # configure, build, install!
    ${CMAKE} ${WORKSPACE}/srcdir/llvm-project/compiler-rt ${CMAKE_FLAGS[@]}
    ninja
    ninja install
    """,
    platforms=supported_platforms(),
    host,
    # We need python, and we need to build with clang
    host_dependencies = [JLLSource("Python_jll")],
    target_dependencies = [
        JLLSource(
            "Zlib_jll";
            repo=Pkg.Types.GitRepo(
                rev="main",
                source="https://github.com/staticfloat/Zlib_jll.jl"
            ),
        ),
    ],
    host_toolchains = [CToolchain(;vendor=:clang_bootstrap), CMakeToolchain(), HostToolsToolchain()],
    target_toolchains = [CToolchain(;vendor=:clang_bootstrap, lock_microarchitecture=false), CMakeToolchain()],
)
