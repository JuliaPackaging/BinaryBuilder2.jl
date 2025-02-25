include("llvm_common.jl")

build_tarballs(;
    src_name = "Clang",
    src_version = llvm_version,
    sources = llvm_sources,
    script = clang_buildscript(llvm_version),
    platforms = llvm_platforms(;is_bootstrap=false),
    host,
    build_spec_generator = clang_build_spec_generator(;is_bootstrap=false),
    extract_spec_generator = (build, plat) -> clang_extract_spec_generator(build, plat; is_bootstrap=false),
    jll_extraction_map = clang_extraction_map(;is_bootstrap=false)
)
