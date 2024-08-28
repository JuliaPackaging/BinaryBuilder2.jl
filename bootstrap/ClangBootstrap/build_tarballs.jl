using BinaryBuilder2, Pkg
using BinaryBuilder2: BuildTargetSpec

host = Platform(arch(HostPlatform()), "linux")

platforms = []

for host in [Platform("x86_64", "linux"), Platform("aarch64", "linux")]
    append!(platforms, [
        CrossPlatform(host => Platform("x86_64", "macos")),
        CrossPlatform(host => Platform("aarch64", "macos")),
    ])
end

products = [
    ExecutableProduct("\${bindir}/clang", :clang),
    ExecutableProduct("\${bindir}/clang++", :clangxx),
]

function clang_spec_generator(host, platform)
    target_str = triplet(gcc_platform(platform.target))
    target_sources = []
    if os(platform.target) == "macos"
        # Eventually, get a version of this from General
        push!(target_sources, JLLSource(
            "macOSSDK_jll",
            platform.target;
            repo=Pkg.Types.GitRepo(
                source="https://github.com/staticfloat/macOSSDK_jll.jl",
                rev="main",
            ),
            target=target_str,
            uuid=Base.UUID("52f8e75f-aed1-5264-b4c9-b8da5a6d5365"),
        ))
    end
    return [
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
                JLLSource(
                    "XML2_jll",
                ),
                JLLSource(
                    "Zlib_jll",
                ),
                # Even though these have the target platform baked into them,
                # we put them as part of the `"host"` target spec, so that they
                # appear in the right prefix.
                target_sources...,
            ],
            Set([:default]),
        ),
        BuildTargetSpec(
            "target",
            CrossPlatform(host => platform.target),
            [],
            [],
            Set{Symbol}(),
        ),
    ]
end

build_tarballs(;
    src_name = "ClangBootstrap",
    src_version = v"17.0.6",
    sources = [
        GitSource("https://github.com/llvm/llvm-project.git",
                  "6009708b4367171ccdbf4b5905cb6a803753fe18";
                  target="llvm-project"),

        DirectorySource(joinpath(@__DIR__, "patches"), target="patches"),
    ],
    script = raw"""
    LLVM_SRCDIR=${WORKSPACE}/srcdir/llvm-project/llvm
    mkdir ${WORKSPACE}/srcdir/llvm_build && cd ${WORKSPACE}/srcdir/llvm_build
    install_license ${WORKSPACE}/srcdir/llvm-project/LICENSE.TXT

    # Disable uname wrapper, because it makes LLVM build confused
    rm -f $(which uname)

    # Determine SDK version
    mac_ver="$(grep "__MAC_[[:digit:]]" "${prefix}/${target}/usr/include/AvailabilityVersions.h" | tail -1 | cut -f2 -d' ')"
    mac_ver="$(echo ${mac_ver##__MAC_} | tr '_' '.')"

    # Create fake `xcrun` wrapper
    cat > /usr/local/bin/xcrun << EOF
#!/bin/bash
if [[ "\${@}" == *"--show-sdk-path"* ]]; then
   echo ${prefix}/${target}
elif [[ "\${@}" == *"--show-sdk-version"* ]]; then
   echo ${mac_ver}
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
    CMAKE_FLAGS+=('-DLLVM_TARGETS_TO_BUILD:STRING=X86;AArch64')

    # Install to `prefix`, and release build
    CMAKE_FLAGS+=("-DCMAKE_INSTALL_PREFIX=${prefix}")
    CMAKE_FLAGS+=(-DCMAKE_BUILD_TYPE=Release)

    # Only build clang, and the compiler-rt/libcxx runtimes
    CMAKE_FLAGS+=(-DLLVM_ENABLE_PROJECTS='clang;lld')
    #CMAKE_FLAGS+=(-DLLVM_ENABLE_RUNTIMES='compiler-rt;libcxx;libcxxabi')
    
    # Tell compiler-rt to generate builtins for all the supported arches
    CMAKE_FLAGS+=(-DCOMPILER_RT_DEFAULT_TARGET_ONLY=OFF)
    CMAKE_FLAGS+=(-DCOMPILER_RT_INCLUDE_TESTS=OFF)
    CMAKE_FLAGS+=(-DCOMPILER_RT_HAS_CRT=FALSE)
    CMAKE_FLAGS+=(-DCLANG_DEFAULT_CXX_STDLIB=libc++ -DCLANG_DEFAULT_LINKER=lld -DCLANG_DEFAULT_RTLIB=compiler-rt)
    CMAKE_FLAGS+=(-DLIBCXX_USE_COMPILER_RT=ON)

    # No bindings, we just want clang so we can build things
    CMAKE_FLAGS+=(-DLLVM_BINDINGS_LIST=)

    CMAKE_FLAGS+=("-DLLVM_DEFAULT_TARGET_TRIPLE=${target}")
    CMAKE_FLAGS+=("-DLLVM_BUILTIN_TARGETS=${target}")
    CMAKE_FLAGS+=("-DRUNTIMES_BUILD_ALLOW_DARWIN=TRUE")

    # Turn off docs
    CMAKE_FLAGS+=(-DLLVM_INCLUDE_DOCS=OFF -DLLVM_INCLUDE_EXAMPLES=OFF)

    # Hint to find Zlib
    export LDFLAGS="-L${prefix}/lib -Wl,-rpath-link,${prefix}/lib"
    CMAKE_FLAGS+=(-DZLIB_ROOT="${prefix}")

    # Hints for building targets
    CMAKE_FLAGS+=(-DBUILTINS_${target}_CMAKE_SYSROOT="${prefix}/${target}")
    CMAKE_FLAGS+=(-DBUILTINS_${target}_CMAKE_SYSTEM_NAME="Darwin")
    CMAKE_FLAGS+=(-DRUNTIMES_${target}_CMAKE_SYSROOT="${prefix}/${target}")
    CMAKE_FLAGS+=(-DRUNTIMES_${target}_CMAKE_SYSTEM_NAME="Darwin")

    # Build!    
    $BUILD_CMAKE ${LLVM_SRCDIR} ${CMAKE_FLAGS[@]}
    $BUILD_CMAKE -LA || true
    make -j${nproc}

    # Install!
    make install -j${nproc} #VERBOSE=1
    """,
    platforms,
    products,
    host,
    # No target toolchains, only the host one.
    target_toolchains = [],
    spec_generator = clang_spec_generator,
)
