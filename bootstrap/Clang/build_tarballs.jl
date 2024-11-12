using BinaryBuilder2, Pkg
using BinaryBuilder2: BuildTargetSpec

host = Platform(arch(HostPlatform()), "linux")

platforms = []

for host in [Platform("x86_64", "linux"), Platform("aarch64", "linux")]
    append!(platforms, [
        CrossPlatform(host => AnyPlatform()),
    ])
end

products = [
    ExecutableProduct("\${bindir}/clang", :clang),
    ExecutableProduct("\${bindir}/clang++", :clangxx),
]

function clang_build_spec_generator(host, platform)
    specs = [
        BuildTargetSpec(
            "build",
            CrossPlatform(host => host),
            [CToolchain(), CMakeToolchain(), HostToolsToolchain()],
            [JLLSource("Python_jll")],
            Set([:host]),
        ),
        BuildTargetSpec(
            "host",
            CrossPlatform(host => platform.host),
            [],
            [
                # Disable this for now
                #=
                JLLSource(
                    "XML2_jll";
                    repo=Pkg.Types.GitRepo(
                        rev="bb2/ClangBootstrap",
                        source="https://github.com/staticfloat/XML2_jll.jl"
                    ),
                ),
                =#
                JLLSource(
                    "Zlib_jll";
                    repo=Pkg.Types.GitRepo(
                        rev="bb2/GCC",
                        source="https://github.com/staticfloat/Zlib_jll.jl"
                    ),
                ),
            ],
            Set([:default]),
        ),
    ]

    # We're going to add a new build spec for each target, so that our runtimes can
    # can compile against them:
    targets = [
        Platform("x86_64", "linux"),
        Platform("aarch64", "linux"),
        #Platform("aarch64", "macos"),
        #Platform("x86_64", "windows"),
    ]
    for target in targets
        push!(specs, BuildTargetSpec(
            "target",
            CrossPlatform(host => target),
            [CToolchain()],
            [],
            Set{Symbol}(),
        ))
    end
    return specs
end

build_tarballs(;
    src_name = "Clang",
    src_version = v"17.0.6",
    sources = [
        GitSource("https://github.com/llvm/llvm-project.git",
                  "6009708b4367171ccdbf4b5905cb6a803753fe18";
                  target="llvm-project"),
        #DirectorySource(joinpath(@__DIR__, "patches"), target="patches"),
    ],
    script = raw"""
    LLVM_SRCDIR=${WORKSPACE}/srcdir/llvm-project/llvm
    mkcd ${WORKSPACE}/srcdir/llvm_build
    install_license ${WORKSPACE}/srcdir/llvm-project/LICENSE.TXT

    # Disable uname wrapper, because it makes LLVM build confused
    rm -f $(which uname)

    # Create fake `xcrun` wrapper
    cat > /usr/local/bin/xcrun << EOF
#!/bin/bash
if [[ "\${@}" == *"--show-sdk-path"* ]]; then
   echo /opt/target-aarch64-apple-darwin/clang/aarch64-apple-darwin
elif [[ "\${@}" == *"--show-sdk-version"* ]]; then
   echo 11.1
else
   exec "\${@}"
fi
EOF
    chmod +x /usr/local/bin/xcrun

    # Fake `PlistBuddy` to make detection of aarch64 support work
    mkdir -p /usr/libexec
    cat > /usr/libexec/PlistBuddy << EOF
#!/bin/bash

if [[ "${target}" == aarch64-* ]]; then
    echo " arm64"
else
    echo " $(uname -m)"
fi
EOF
    chmod +x /usr/libexec/PlistBuddy

    CMAKE_FLAGS=()

    # Only target Aarch64 and x86_64, since we only use this to bootstrap
    # for macOS and FreeBSD
    CMAKE_FLAGS+=('-DLLVM_TARGETS_TO_BUILD:STRING=X86;ARM;AArch64;PowerPC;RISCV;WebAssembly')

    # Install to `prefix`, and release build
    CMAKE_FLAGS+=("-DCMAKE_INSTALL_PREFIX=${prefix}")
    CMAKE_FLAGS+=(-DCMAKE_BUILD_TYPE=Release)

    # Only build clang, and the compiler-rt/libcxx runtimes
    CMAKE_FLAGS+=(-DLLVM_ENABLE_PROJECTS='clang;lld')
    CMAKE_FLAGS+=(-DLLVM_ENABLE_RUNTIMES='compiler-rt;libcxx;libcxxabi')
    
    # Tell compiler-rt to generate builtins for all the supported arches
    CMAKE_FLAGS+=(-DCOMPILER_RT_DEFAULT_TARGET_ONLY=OFF)
    CMAKE_FLAGS+=(-DCOMPILER_RT_INCLUDE_TESTS=OFF)
    CMAKE_FLAGS+=(-DCOMPILER_RT_HAS_CRT=FALSE)
    CMAKE_FLAGS+=(-DCLANG_DEFAULT_CXX_STDLIB=libc++ -DCLANG_DEFAULT_LINKER=lld -DCLANG_DEFAULT_RTLIB=compiler-rt)
    CMAKE_FLAGS+=(-DLIBCXX_USE_COMPILER_RT=ON)
    CMAKE_FLAGS+=(-DLIBCXXABI_USE_COMPILER_RT=ON)

    # No bindings
    CMAKE_FLAGS+=(-DLLVM_BINDINGS_LIST=)
    CMAKE_FLAGS+=(-DBUILD_SHARED_LIBS:BOOL=ON)

    # Turn off docs
    CMAKE_FLAGS+=(-DLLVM_INCLUDE_DOCS=OFF -DLLVM_INCLUDE_EXAMPLES=OFF -DLLVM_INCLUDE_BENCHMARKS=OFF)

    # Turn off XML2
    CMAKE_FLAGS+=(-DLLVM_ENABLE_LIBXML2=OFF)

    # Hint to find Zlib
    #export LDFLAGS="-L${host_prefix}/lib -Wl,-rpath-link,${host_prefix}/lib"
    export LD_LIBRARY_PATH="${host_prefix}/lib"
    CMAKE_FLAGS+=(-DZLIB_ROOT="${host_prefix}")

    system_name() {
        if [[ "${1}" == *linux* ]]; then
            echo -n "Linux";
        elif [[ "${1}" == *darwin* ]]; then
            echo -n "Darwin";
        elif [[ "${1}" == *mingw* ]]; then
            echo -n "Windows";
        elif [[ "${1}" == *freebsd* ]]; then
            echo -n "FreeBSD";
        fi
    }

    # Hints for building targets
    TARGET_LIST=( $(compgen -G '/opt/target-*' | sed -e 's&/opt/target-&&g') )
    for target in ${TARGET_LIST[@]}; do
        for var_type in BUILTINS RUNTIMES; do
            _SYSROOT="$("/opt/target-${target}/wrappers/${target}-cc" -print-sysroot)"
            # for mingw, we need to not have the triplet, it gets added automatically
            if [[ ${target} == *mingw* ]]; then
                CMAKE_FLAGS+=("-D${var_type}_${target}_CMAKE_SYSROOT=$(dirname "${_SYSROOT}")")
            else
                CMAKE_FLAGS+=("-D${var_type}_${target}_CMAKE_SYSROOT=${_SYSROOT}")
            fi
            CMAKE_FLAGS+=("-D${var_type}_${target}_CMAKE_SYSTEM_NAME=$(system_name "${target}")")
        done

        # Windows can't build the crtbegin.o/crtend.o
        if [[ "${target}" == *mingw* ]]; then
            CMAKE_FLAGS+=("-DRUNTIMES_${target}_COMPILER_RT_BUILD_CRT=OFF")
        fi
    done

    join_by() {
        local d=${1-} f=${2-}
        if shift 2; then
            printf %s "$f" "${@/#/$d}"
        fi
    }
    CMAKE_FLAGS+=( "-DLLVM_RUNTIME_TARGETS=$(join_by ";" "${TARGET_LIST[@]}")" )
    CMAKE_FLAGS+=( "-DLLVM_BUILTIN_TARGETS=$(join_by ";" "${TARGET_LIST[@]}")" )

    # Build!    
    $BUILD_CMAKE ${LLVM_SRCDIR} ${CMAKE_FLAGS[@]}
    make -j${nproc}

    # Install!
    make install -j${nproc} #VERBOSE=1
    """,
    platforms,
    products,
    host,
    build_spec_generator = clang_build_spec_generator,
)
