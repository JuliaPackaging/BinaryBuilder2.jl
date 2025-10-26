include("llvm_common.jl")

build_tarballs(;
    src_name = "LLVMTblgen",
    src_version = llvm_version,
    sources = llvm_sources,
    script = llvm_script_prefix * raw"""
    CMAKE_FLAGS+=(-DLLVM_TARGETS_TO_BUILD:STRING=host)
    
    # Install to `prefix`, and make a release build
    CMAKE_FLAGS+=(-DLLVM_ENABLE_PROJECTS='llvm;clang;clang-tools-extra;mlir')
    CMAKE_FLAGS+=(-DMLIR_BUILD_MLIR_C_DYLIB:BOOL=ON)

    mkcd ${WORKSPACE}/build

    TBLGEN_TARGETS=(
        llvm-tblgen
        clang-tblgen
        mlir-tblgen
        llvm-config
        mlir-linalg-ods-yaml-gen
        clang-tidy-confusable-chars-gen
        clang-pseudo-gen
        mlir-pdll
    )

    # Build!
    ${CMAKE} "${LLVM_SRCDIR}" "${CMAKE_FLAGS[@]}"
    ninja "${TBLGEN_TARGETS[@]}"

    # Install!
    mv ./bin "${bindir}"
    """,
    platforms = [BBHostPlatform()],
    products = [
        ExecutableProduct(["llvm-tblgen"], :llvm_tblgen),
        ExecutableProduct(["clang-tblgen"], :clang_tblgen),
        ExecutableProduct(["mlir-tblgen"], :mlir_tblgen),
        ExecutableProduct(["llvm-config"], :llvm_config),
    ],
    host_dependencies = [JLLSource("Python_jll")],
    target_dependencies = [
        JLLSource(
            "Zlib_jll";
            repo=Pkg.Types.GitRepo(
                rev="bb2/GCCBootstrap-x86_64-linux-gnu",
                source="https://github.com/staticfloat/Zlib_jll.jl",
            ),
        ),
    ],
    host_toolchains = [CToolchain(;vendor=:gcc_bootstrap), CMakeToolchain(), HostToolsToolchain()],
    target_toolchains = [CToolchain(;vendor=:gcc_bootstrap), CMakeToolchain()],
)
