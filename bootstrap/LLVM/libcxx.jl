include("llvm_common.jl")
using BinaryBuilderPlatformExtensions: macos_kernel_version

platforms = supported_platforms()
platforms = map(platforms) do p
    # x86_64-apple-darwin needs to target at least 10.13
    if Sys.isapple(p) && arch(p) == "x86_64"
        p["os_version"] = string(macos_kernel_version("10.13"))
    end
    return p
end

build_tarballs(;
    src_name = "LLVMLibcxx",
    src_version = llvm_version,
    sources = llvm_sources,
    script = llvm_script_prefix * raw"""
    # Configure libcxx
    CMAKE_FLAGS+=("-DLLVM_ENABLE_RUNTIMES=libcxx;libcxxabi;libunwind")

    # Use lld to dodge annoying symbol resolution issues on mingw
    CMAKE_FLAGS+=("-DLLVM_USE_LINKER=lld")

    if [[ "${target}" == *musl* ]]; then
        CMAKE_FLAGS+=("-DLIBCXX_HAS_MUSL_LIBC=ON")
    fi

    # Tell HandleCompilerRT.cmake that we're compiling for macOS
    if [[ "${target}" == *darwin* ]]; then
        ln -s "$($CC -print-sysroot)" "/tmp/MacOSX.sdk"
        CMAKE_FLAGS+=( "-DCMAKE_OSX_SYSROOT=/tmp/MacOSX.sdk/" )

        # I don't know why this isn't working, some kind of bug?
        CMAKE_FLAGS+=( "-DCXX_SUPPORTS_FNO_EXCEPTIONS_FLAG=TRUE" )
    fi

    # Configure libcxxabi
    CMAKE_FLAGS+=( "-DLIBCXX_USE_COMPILER_RT=ON" )
    CMAKE_FLAGS+=( "-DLIBCXX_ENABLE_SHARED=ON" )
    CMAKE_FLAGS+=( "-DLIBCXX_ENABLE_STATIC=ON" )
    CMAKE_FLAGS+=( "-DLIBCXX_ENABLE_STATIC_ABI_LIBRARY=ON" )
    CMAKE_FLAGS+=( "-DLIBCXX_INSTALL_MODULES=ON" )
    #CMAKE_FLAGS+=("-DLIBCXX_HAS_ATOMIC_LIB=NO")
    CMAKE_FLAGS+=( "-DLIBCXX_CXX_ABI=libcxxabi" )
    #if [[ "${target}" == *mingw* ]]; then
        #CMAKE_FLAGS+=( "-DLIBCXX_HAS_WIN32_THREAD_API=ON" )
        #CMAKE_FLAGS+=( "-DLIBCXXABI_HAS_WIN32_THREAD_API=ON" )
        #CMAKE_FLAGS+=( "-DLIBCXX_ENABLE_NEW_DELETE_DEFINITIONS=ON" )
        #CMAKE_FLAGS+=( "-DLIBCXXABI_ENABLE_NEW_DELETE_DEFINITIONS=OFF" )
    #fi

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
    mkcd "${WORKSPACE}/srcdir/build"
    ${CMAKE} ${WORKSPACE}/srcdir/llvm-project/runtimes "${CMAKE_FLAGS[@]}"
    ninja
    ninja install
    """,
    platforms,
    host,
    # We need python, and we need to build with clang
    host_dependencies = [JLLSource("Python_jll")],
    target_dependencies = [
        JLLSource(
            "Zlib_jll";
            repo=Pkg.Types.GitRepo(
                rev="main",
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
