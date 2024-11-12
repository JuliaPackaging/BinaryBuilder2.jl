include("llvm_common.jl")

build_tarballs(;
    src_name = "ClangBootstrap",
    src_version = llvm_version,
    sources = llvm_sources,
    script = llvm_script_prefix * raw"""
    CMAKE_FLAGS=()
    CMAKE_FLAGS+=('-DLLVM_TARGETS_TO_BUILD:STRING=X86;ARM;AArch64;PowerPC;RISCV;WebAssembly')

    # Install to `prefix`, and make a release build
    CMAKE_FLAGS+=("-DCMAKE_INSTALL_PREFIX=${prefix}")
    CMAKE_FLAGS+=(-DCMAKE_BUILD_TYPE=Release)

    # Only build clang (we rely on libgcc_s)
    CMAKE_FLAGS+=(-DLLVM_ENABLE_PROJECTS='clang;lld')

    # No bindings
    CMAKE_FLAGS+=(-DLLVM_BINDINGS_LIST=)
    CMAKE_FLAGS+=(-DBUILD_SHARED_LIBS:BOOL=ON -DLLVM_BUILD_LLVM_DYLIB:BOOL=ON)
    #CMAKE_FLAGS+=(-DLLVM_ENABLE_LTO=Full)

    # Turn off docs
    CMAKE_FLAGS+=(-DLLVM_INCLUDE_DOCS=OFF -DLLVM_INCLUDE_EXAMPLES=OFF -DLLVM_INCLUDE_BENCHMARKS=OFF)

    # Turn off XML2
    CMAKE_FLAGS+=(-DLLVM_ENABLE_LIBXML2=OFF)

    # Hint to find Zlib
    export LDFLAGS="-L${host_prefix}/lib -Wl,-rpath-link,${host_prefix}/lib"
    export LD_LIBRARY_PATH="${host_prefix}/lib"
    CMAKE_FLAGS+=(-DZLIB_ROOT="${host_prefix}")

    # Build!
    $BUILD_CMAKE ${LLVM_SRCDIR} ${CMAKE_FLAGS[@]}
    make -j${nproc}

    # Install!
    make install -j${nproc} #VERBOSE=1
    """,
    platforms,
    host,
    build_spec_generator = clang_build_spec_generator,
    extract_spec_generator = (build, plat) -> clang_extract_spec_generator(build, plat; is_bootstrap=true),
    jll_extraction_map = clang_extraction_map(;is_bootstrap=true)
)
