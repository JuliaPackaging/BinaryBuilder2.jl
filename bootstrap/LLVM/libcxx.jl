include("llvm_common.jl")

build_tarballs(;
    src_name = "LLVMLibcxx",
    src_version = llvm_version,
    sources = llvm_sources,
    script = llvm_script_prefix * raw"""
    # Configure libcxx
    CMAKE_FLAGS+=("-DLIBCXX_INCLUDE_BENCHMARKS=OFF")
    CMAKE_FLAGS+=("-DLIBCXX_HAS_ATOMIC_LIB=NO")
    CMAKE_FLAGS+=("-DLLVM_ENABLE_RUNTIMES=libcxx;libcxxabi;libunwind")

    if [[ "${target}" == *musl* ]]; then
        CMAKE_FLAGS+=("-DLIBCXX_HAS_MUSL_LIBC=ON")
    fi

    # Configure libcxxabi
    CMAKE_FLAGS+=( "-DLIBCXX_USE_COMPILER_RT=ON" )
    CMAKE_FLAGS+=( "-DLIBCXX_ENABLE_SHARED=ON" )
    CMAKE_FLAGS+=( "-DLIBCXX_ENABLE_STATIC=ON" )
    CMAKE_FLAGS+=( "-DLIBCXX_ENABLE_STATIC_ABI_LIBRARY=ON" )
    CMAKE_FLAGS+=( "-DLIBCXX_INSTALL_MODULES=ON" )
    if [[ "${target}" == *mingw* ]]; then
        CMAKE_FLAGS+=( "-DLIBCXX_HAS_WIN32_THREAD_API=ON" )
        CMAKE_FLAGS+=( "-DLIBCXXABI_HAS_WIN32_THREAD_API=ON" )
    fi

    CMAKE_FLAGS+=( "-DLIBCXXABI_USE_COMPILER_RT=ON" )
    CMAKE_FLAGS+=( "-DLIBCXXABI_USE_LLVM_UNWINDER=ON" )
    CMAKE_FLAGS+=( "-DLIBCXXABI_ENABLE_STATIC_UNWINDER=ON" )
    CMAKE_FLAGS+=( "-DLIBUNWIND_USE_COMPILER_RT=ON" )
    
    CMAKE_FLAGS+=( "-DLIBCXXABI_ENABLE_SHARED=OFF" )
    CMAKE_FLAGS+=( "-DLIBCXXABI_ENABLE_STATIC=ON" )
    CMAKE_FLAGS+=( "-DLIBUNWIND_ENABLE_FRAME_APIS=ON" )
    CMAKE_FLAGS+=( "-DLIBUNWIND_ENABLE_SHARED=ON" )
    CMAKE_FLAGS+=( "-DLIBUNWIND_ENABLE_STATIC=ON" )

    # configure, build, install!
    mkcd build
    ${CMAKE} ${WORKSPACE}/srcdir/llvm-project/runtimes "${CMAKE_FLAGS[@]}"
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
                rev="bb2/GCC",
                source="https://github.com/staticfloat/Zlib_jll.jl",
            ),
        ),
    ],
    extract_spec_generator = (build_config, platform) -> begin
        return Dict(
            "LLVMLibunwind" => ExtractSpec(
                raw"""
                extract ${prefix}/include/*unwind*
                extract ${prefix}/include/mach-o
                extract ${shlibdir}/libunwind*
                """,
                [
                    LibraryProduct("libunwind", :libunwind),
                ],
                get_target_spec_by_name(build_config, "target"),
            ),
            "LLVMLibcxx" => ExtractSpec(
                raw"""
                extract ${prefix}/include/c++/**
                extract ${shlibdir}/libc++\*
                """,
                [
                    LibraryProduct("libc++", :libcxx),
                    #LibraryProduct("libc++abi", :libcxxabi),
                ],
                get_default_target_spec(build_config);
                platform,
                inter_deps = ["LLVMLibunwind"],
            ),
        )
    end,
    jll_extraction_map = Dict(
        "LLVMLibcxx" => ["LLVMLibcxx"],
        "LLVMLibunwind" => ["LLVMLibunwind"],
    ),
    host_toolchains = [CToolchain(;vendor=:clang, compiler_runtime=:compiler_rt), CMakeToolchain(), HostToolsToolchain()],
    target_toolchains = [CToolchain(;vendor=:clang, compiler_runtime=:compiler_rt), CMakeToolchain()],
)
