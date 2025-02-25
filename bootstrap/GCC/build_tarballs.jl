using BinaryBuilder2

include("gcc_common.jl")

for version in (v"9.4.0",) #keys(gcc_version_sources)
    build_tarballs(;
        src_name = "GCC",
        src_version = version,
        sources = [
            gcc_version_sources[version]...,
            DirectorySource("./patches-v$(version)"; follow_symlinks=true, target="patches"),
        ],
        script, 
        platforms,
        products = [
            FileProduct("bin", :bindir),
            ExecutableProduct("\${target}-gcc", :gcc),
            ExecutableProduct("\${target}-g++", :gxx),
        ],
        build_spec_generator = gcc_build_spec_generator,
        extract_spec_generator = gcc_extract_spec_generator,
        jll_extraction_map = gcc_extraction_map,
        meta,
        duplicate_extraction_handling = :ignore_all,
    )
end
