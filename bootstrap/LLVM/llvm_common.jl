using BinaryBuilder2, Pkg
using BinaryBuilder2: BuildTargetSpec, get_target_spec_by_name

host = Platform(arch(HostPlatform()), "linux")

platforms = []
for host in [Platform("x86_64", "linux"), Platform("aarch64", "linux")]
    append!(platforms, [
        CrossPlatform(host => AnyPlatform()),
    ])
end

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

function llvm_name_prefix(name::String; is_bootstrap::Bool=false)
    if is_bootstrap
        return "LLVMBootstrap_$(name)"
    else
        return name
    end
end

function clang_extract_spec_generator(build::BuildConfig, platform::AbstractPlatform; is_bootstrap::Bool=false)
    llvm_arches = [
        "X86",
        "ARM",
        "AArch64",
        "PowerPC",
        "RISCV",
        "WebAssembly",
    ]
    llvm_libs = [
        string.(llvm_arches, ("AsmParser",))...,
        string.(llvm_arches, ("CodeGen",))...,
        string.(llvm_arches, ("Disassembler",))...,
        string.(llvm_arches, ("Desc",))...,
        string.(llvm_arches, ("Info",))...,
        "X86TargetMCA",
        "RISCVTargetMCA",
        "AArch64Utils",
        "AggressiveInstCombine",
        "Analysis",
        "ARMUtils",
        "AsmParser",
        "AsmPrinter",
        "BinaryFormat",
        "BitReader",
        "BitstreamReader",
        "BitWriter",
        "CFGuard",
        "CFIVerify",
        "CodeGen",
        "CodeGenTypes",
        "Core",
        "Coroutines",
        "Coverage",
        "DebugInfoBTF",
        "DebugInfoCodeView",
        "Debuginfod",
        "DebugInfoDWARF",
        "DebugInfoGSYM",
        "DebugInfoLogicalView",
        "DebugInfoMSF",
        "DebugInfoPDB",
        "Demangle",
        "Diff",
        "DlltoolDriver",
        "DWARFLinker",
        "DWARFLinkerParallel",
        "DWP",
        "Extensions",
        "ExecutionEngine",
        "Exegesis",
        "ExegesisAArch64",
        "ExegesisPowerPC",
        "ExegesisX86",
        "FrontendOpenMP",
        "FrontendHLSL",
        "GlobalISel",
        "InstCombine",
        "Instrumentation",
        "InterfaceStub",
        "Interpreter",
        "ipo",
        "IRPrinter",
        "IRReader",
        "JITLink",
        "LineEditor",
        "Linker",
        "LibDriver",
        "LTO",
        "MC",
        "MCA",
        "MCJIT",
        "MCDisassembler",
        "MIRParser",
        "MCParser",
        "ObjCARCOpts",
        "ObjCopy",
        "Object",
        "ObjectYAML",
        "Option",
        "OrcJIT",
        "OrcShared",
        "OrcTargetProcess",
        "Passes",
        "ProfileData",
        "Remarks",
        "RuntimeDyld",
        "ScalarOpts",
        "SelectionDAG",
        "Support",
        "Symbolize",
        "TableGen",
        "TableGenGlobalISel",
        "Target",
        "TargetParser",
        "TextAPI",
        "TransformUtils",
        "Vectorize",
        "WebAssemblyUtils",
        "WindowsDriver",
        "WindowsManifest",
        "XRay",
    ]
    llvm_libs = string.(("libLLVM",), llvm_libs)

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
            [LibraryProduct.(lib, Symbol(lib)) for lib in llvm_libs],
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
]

llvm_script_prefix = raw"""
LLVM_SRCDIR=${WORKSPACE}/srcdir/llvm-project/llvm
mkcd ${WORKSPACE}/srcdir/llvm_build
install_license ${WORKSPACE}/srcdir/llvm-project/LICENSE.TXT

# Disable uname wrapper, because it makes LLVM build confused
rm -f $(which uname)

# Create fake `xcrun` wrapper and `PlistBuddy` wrappers, to make detection of aarch64 support work
mkdir -p /usr/libexec
cp ${WORKSPACE}/srcdir/bundled/xcrun /usr/local/bin/xcrun
cp ${WORKSPACE}/srcdir/bundled/PlistBuddy /usr/libexec/PlistBuddy
chmod +x /usr/local/bin/xcrun /usr/libexec/PlistBuddy
"""
