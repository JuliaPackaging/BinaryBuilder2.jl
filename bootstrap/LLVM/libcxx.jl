include("llvm_common.jl")
using BinaryBuilderPlatformExtensions: macos_kernel_version
using BinaryBuilder2: default_build_spec_generator

platforms = supported_platforms()
push!(platforms, Platform("x86_64", "linux"; sanitize="memory"))

host_toolchains = [CToolchain(;vendor=:clang, compiler_runtime=:compiler_rt), CMakeToolchain(), HostToolsToolchain()]
host_dependencies = [JLLSource("Python_jll")]

# The sanitized libc++ is built before any sanitized C++ runtime exists, so it links
# against the plain libstdc++ and libgcc.
function target_toolchains(platform)
    if sanitize(platform) == "memory"
        return [CToolchain(;vendor=:clang, compiler_runtime=:libgcc, cxx_runtime=:unsanitized_libstdcxx), CMakeToolchain()]
    end
    return [CToolchain(;vendor=:clang, compiler_runtime=:compiler_rt), CMakeToolchain()]
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

    # MemorySanitizer ignores libunwind's sources, so it neither reports nor tracks
    # uninitialized values there: the unwinder reads saved registers and return
    # addresses off the stack, whose shadow MemorySanitizer doesn't track.  The flag
    # propagates to everything linking libunwind, but only matches its sources.
    if [[ "${bb_full_target}" == *-sanitize+memory* ]]; then
        echo 'src:*/libunwind/src/*' > ${WORKSPACE}/srcdir/msan_ignorelist.txt
        CMAKE_FLAGS+=( "-DLIBUNWIND_ADDITIONAL_COMPILE_FLAGS=-fsanitize-ignorelist=${WORKSPACE}/srcdir/msan_ignorelist.txt" )
    fi

    # configure, build, install!
    mkcd "${WORKSPACE}/srcdir/build"
    ${CMAKE} ${WORKSPACE}/srcdir/llvm-project/runtimes "${CMAKE_FLAGS[@]}"
    ninja
    ninja install

    # An instrumented libc++ calls into the MemorySanitizer runtime
    if [[ "${bb_full_target}" == *-sanitize+memory* ]]; then
        if ! nm -D --undefined-only ${libdir}/libc++.so.1 | grep -q __msan_; then
            echo "libc++.so.1 is not instrumented with MemorySanitizer" >&2
            exit 1
        fi
    fi
    """,
    platforms,
    # We need python, and we need to build with clang
    build_spec_generator = (host, platform) -> default_build_spec_generator(;
        target_toolchains = target_toolchains(platform),
        host_toolchains,
        host_dependencies,
    )(host, platform),

    extract_spec_generator = (build_config, platform) -> begin
        return ExtractSpec[
            ExtractSpec(
                raw"""
                extract ${prefix}/include/*unwind*
                extract ${prefix}/include/mach-o
                extract ${shlibdir}/libunwind*
                """,
                [
                    LibraryProduct("libunwind", :libunwind),
                ],
                get_target_spec_by_name(build_config, "target");
                jll_name = "LLVMLibunwind",
            ),
            ExtractSpec(
                raw"""
                extract ${prefix}/include/c++/**
                extract ${shlibdir}/libc++\*
                """,
                [
                    LibraryProduct("libc++", :libcxx),
                ],
                get_default_target_spec(build_config);
                jll_name = "LLVMLibcxx",
                platform,
                inter_deps = ["LLVMLibunwind"],
            ),
        ]
    end,
)
