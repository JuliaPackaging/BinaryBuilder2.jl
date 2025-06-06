using BinaryBuilder2, Pkg
using BinaryBuilder2: BuildTargetSpec, get_target_spec_by_name, get_default_target_spec, ExtractSpec, get_package_result

# The build host
host = Platform(arch(HostPlatform()), "linux")

# Check to see if the user has asked for a "bootstrap" build, which
# builds clang only for a few targets, using GCC instead of clang.
function llvm_platforms(;is_bootstrap::Bool = false)
    platforms = CrossPlatform[]
    # If this is a bootstrap build, only build for these hosts
    if is_bootstrap
        for host in [Platform("x86_64", "linux"), Platform("aarch64", "linux")]
            push!(platforms, CrossPlatform(host => AnyPlatform()))
        end
    else
        for host in supported_platforms()
            push!(platforms, CrossPlatform(host => AnyPlatform()))
        end
    end
    return platforms
end

# BuildSpec generator for Clang/libLLVM
function clang_build_spec_generator(;is_bootstrap::Bool = false)
    vendor = is_bootstrap ? :gcc_bootstrap : :clang_bootstrap

    return (host, platform) -> begin
        # This is a canadian cross, our `platform.target` is always `any`
        compiler_runtime = :libgcc
        if os(host_if_crossplatform(platform)) ∈ ("macos", "freebsd")
            compiler_runtime = :compiler_rt
        end
        specs = [
            BuildTargetSpec(
                "build",
                CrossPlatform(host => host),
                [CToolchain(;vendor, compiler_runtime), CMakeToolchain(), HostToolsToolchain()],
                [
                    JLLSource("Python_jll"),
                    JLLSource(
                        "LLVMTblgen_jll",
                        uuid=Base.UUID("47b65027-ac0b-59bd-a35b-966a6339d635"),
                        repo=Pkg.Types.GitRepo(
                            rev="main",
                            source="https://github.com/staticfloat/LLVMTblgen_jll.jl",
                        ),
                    ),
                ],
                Set([:host]),
            ),
            BuildTargetSpec(
                "host",
                CrossPlatform(host => platform.host),
                [CToolchain(;vendor, compiler_runtime), CMakeToolchain()],
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
                            rev="main",
                            source="https://github.com/staticfloat/Zlib_jll.jl"
                        ),
                    ),
                ],
                Set([:default]),
            ),
            BuildTargetSpec(
                "target",
                platform,
                [],
                [],
                Set{Symbol}(),
            ),
        ]
        return specs
    end
end

function llvm_name_prefix(name::String; is_bootstrap::Bool=false)
    if is_bootstrap
        return "LLVMBootstrap_$(name)"
    else
        return name
    end
end

function clang_buildscript(src_version::VersionNumber)
    return string(
        """
        LLVM_MAJ_VER="$(src_version.major)"
        LLVM_MIN_VER="$(src_version.minor)"

        """,
        llvm_script_prefix,
        raw"""
        CMAKE_CPP_FLAGS=()
        CMAKE_CXX_FLAGS=()
        CMAKE_C_FLAGS=()
        CMAKE_FLAGS+=('-DLLVM_TARGETS_TO_BUILD:STRING=X86;ARM;AArch64;PowerPC;RISCV;WebAssembly')

        # Only build clang and lld
        CMAKE_FLAGS+=(-DLLVM_ENABLE_PROJECTS='clang;lld')

        # We want a shared library
        CMAKE_FLAGS+=(-DLLVM_BUILD_LLVM_DYLIB:BOOL=ON)
        CMAKE_FLAGS+=(-DLLVM_LINK_LLVM_DYLIB:BOOL=ON)
        # set a SONAME suffix for FreeBSD https://github.com/JuliaLang/julia/issues/32462
        CMAKE_FLAGS+=(-DLLVM_VERSION_SUFFIX:STRING="jl")

        # Aggressively symbol version (added in LLVM 13.0.1)
        CMAKE_FLAGS+=(-DLLVM_SHLIB_SYMBOL_VERSION:STRING="JL_LLVM_${LLVM_MAJ_VER}.${LLVM_MIN_VER}")

        if [[ "${host}" == *mingw* ]]; then
            CMAKE_CPP_FLAGS+=(-remap -D__USING_SJLJ_EXCEPTIONS__ -D__CRT__NO_INLINE -pthread -DMLIR_CAPI_ENABLE_WINDOWS_DLL_DECLSPEC -Dmlir_arm_sme_abi_stubs_EXPORTS -femulated-tls)
            CMAKE_C_FLAGS+=(-pthread -DMLIR_CAPI_ENABLE_WINDOWS_DLL_DECLSPEC -femulated-tls)
            CMAKE_FLAGS+=(-DCOMPILER_RT_BUILD_SANITIZERS=OFF)
        fi

        # Build!
        $HOST_CMAKE ${LLVM_SRCDIR} ${CMAKE_FLAGS[@]}  -DCMAKE_CXX_FLAGS=\"${CMAKE_CPP_FLAGS[*]} ${CMAKE_CXX_FLAGS[*]}\" -DCMAKE_C_FLAGS=\"${CMAKE_C_FLAGS[*]}\"
        ninja

        # Install!
        ninja install
        """,
    )
end

function clang_extract_spec_generator(build::BuildConfig, platform::AbstractPlatform; is_bootstrap::Bool=false)
    return Dict(
        llvm_name_prefix("Clang"; is_bootstrap) => ExtractSpec(
            raw"""
            extract ${prefix}/**
            rm -f ${extract_dir}/lib/libLLVM*
            rm -f ${extract_dir}/lib/libLTO*
            """,
            [
                ExecutableProduct("clang", :clang),
                ExecutableProduct("clang++", :clangxx),
                LibraryProduct("libclang", :libclang),
                LibraryProduct("libclang-cpp", :libclang_cpp),
            ],
            get_target_spec_by_name(build, "host");
            platform,
            inter_deps = [llvm_name_prefix("libLLVM"; is_bootstrap)],
        ),
        llvm_name_prefix("libLLVM"; is_bootstrap) => ExtractSpec(
            raw"""
            extract ${shlibdir}/libLLVM*
            extract ${shlibdir}/libLTO*
            """,
            [
                LibraryProduct(["libLLVM", "libLLVM-$(VersionNumber(build.src_version).major)jl"], :libLLVM),
            ],
            get_target_spec_by_name(build, "host");
            platform = platform.host,
        ),
    )
end

function clang_extraction_map(;is_bootstrap::Bool = false)
    clang_name = llvm_name_prefix("Clang"; is_bootstrap)
    libllvm_name = llvm_name_prefix("libLLVM"; is_bootstrap)
    return Dict(
        clang_name => [clang_name],
        libllvm_name => [libllvm_name],
    )
end

llvm_version = v"17.0.6"
llvm_sources = [
    GitSource("https://github.com/llvm/llvm-project.git",
              "6009708b4367171ccdbf4b5905cb6a803753fe18";
              target="llvm-project"),
    DirectorySource(joinpath(@__DIR__, "bundled"), target="bundled"),
    DirectorySource(joinpath(@__DIR__, "patches", string("v", llvm_version)), target="patches"),
]

llvm_script_prefix = raw"""
LLVM_SRCDIR=${WORKSPACE}/srcdir/llvm-project/llvm
mkcd ${WORKSPACE}/srcdir/llvm_build
install_license ${WORKSPACE}/srcdir/llvm-project/LICENSE.TXT

# Disable uname wrapper, because it makes LLVM build confused
rm -f $(which uname)

# Create fake `PlistBuddy` wrapper to make detection of aarch64 support work
mkdir -p /usr/libexec /usr/local/bin
cp ${WORKSPACE}/srcdir/bundled/PlistBuddy /usr/libexec/PlistBuddy
chmod +x /usr/libexec/PlistBuddy

# Apply patches to source
pushd "${WORKSPACE}/srcdir/llvm-project"
for patch in ${WORKSPACE}/srcdir/patches/*.patch; do
    if [[ -d "${patch}" ]]; then
        continue
    fi
    atomic_patch -p1 "${patch}"
done

if [[ "${host}" == *musl* ]]; then
    for patch in ${WORKSPACE}/srcdir/patches/musl_only/*.patch; do
        atomic_patch -p1 "${patch}"
    done
fi
popd

CMAKE_FLAGS=( -GNinja )

# Install to `prefix`, and make a release build
CMAKE_FLAGS+=("-DCMAKE_INSTALL_PREFIX=${prefix}")
CMAKE_FLAGS+=(-DCMAKE_BUILD_TYPE=Release)

# If we have a tblgen build, point it out.
if [[ -n "${build_prefix:-}" ]]; then
    CMAKE_FLAGS+=(-DLLVM_TABLEGEN=${build_prefix}/bin/llvm-tblgen)
    CMAKE_FLAGS+=(-DCLANG_TABLEGEN=${build_prefix}/bin/clang-tblgen)
    CMAKE_FLAGS+=(-DLLVM_CONFIG_PATH=${build_prefix}/bin/llvm-config)
    CMAKE_FLAGS+=(-DMLIR_TABLEGEN=${build_prefix}/bin/mlir-tblgen)
    CMAKE_FLAGS+=(-DMLIR_LINALG_ODS_GEN=${build_prefix}/bin/mlir-linalg-ods-gen)
    CMAKE_FLAGS+=(-DMLIR_LINALG_ODS_YAML_GEN=${build_prefix}/bin/mlir-linalg-ods-yaml-gen)
    CMAKE_FLAGS+=(-DCLANG_TIDY_CONFUSABLE_CHARS_GEN=${build_prefix}/bin/clang-tidy-confusable-chars-gen)
    CMAKE_FLAGS+=(-DCLANG_PSEUDO_GEN=${build_prefix}/bin/clang-pseudo-gen)
    CMAKE_FLAGS+=(-DMLIR_PDLL_TABLEGEN=${build_prefix}/bin/mlir-pdll)
    CMAKE_FLAGS+=(-DLLVM_NATIVE_TOOL_DIR=${build_prefix}/bin)
fi

# This disabled for now because it extends build time significantly
#CMAKE_FLAGS+=(-DLLVM_ENABLE_LTO=Full)

# Turn off bindings, docs, examples, benchmarks, etc...
CMAKE_FLAGS+=(
    -DLLVM_BINDINGS_LIST=
    -DLLVM_INCLUDE_DOCS=OFF
    -DLLVM_INCLUDE_EXAMPLES=OFF
    -DLLVM_INCLUDE_BENCHMARKS=OFF
    -DLIBCXX_INCLUDE_BENCHMARKS=OFF
    -DLLVM_ENABLE_LIBEDIT=OFF
    -DLLVM_ENABLE_TERMINFO=OFF
    -DLLVM_HAVE_LIBXAR=OFF
)

# Turn off XML2
CMAKE_FLAGS+=(-DLLVM_ENABLE_LIBXML2=OFF)

# Manually point to `zlib`, because it doesn't find it automatically properly.
export LDFLAGS="-L ${host_shlibdir}"

# We use this script fragment both in a cross-compile context (where `${host}` is the
# system the compilers are compiling for) and in a normal context (where `${target}` is
# the system the compilers are compiling for).
if [[ -n "${build_prefix:-}" ]]; then
    if [[ "${host}" != *mingw* ]] && [[ "${host}" != *darwin* ]]; then
        export LDFLAGS="${LDFLAGS} -Wl,-rpath,${host_shlibdir} -Wl,-rpath-link,${host_shlibdir}"
    fi
else
    if [[ "${target}" != *mingw* ]] && [[ "${target}" != *darwin* ]]; then
        export LDFLAGS="${LDFLAGS} -Wl,-rpath,${target_shlibdir} -Wl,-rpath-link,${target_shlibdir}"
    fi
fi


CMAKE_FLAGS+=(
    -DZLIB_ROOT="${host_prefix}"
    -DZLIB_LIBRARY="${host_shlibdir}/libz.${host_dlext}"
)
"""

