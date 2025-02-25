include("llvm_common.jl")

build_tarballs(;
    src_name = "ClangBootstrap",
    src_version = llvm_version,
    sources = llvm_sources,
    script = clang_buildscript(llvm_version),
    platforms = llvm_platforms(;is_bootstrap=true),
    host,
    build_spec_generator = clang_build_spec_generator(;is_bootstrap=true),
    extract_spec_generator = (build, plat) -> clang_extract_spec_generator(build, plat; is_bootstrap=true),
    jll_extraction_map = clang_extraction_map(;is_bootstrap=true)
)
