using BinaryBuilder2

include("gcc_common.jl")

for version in (v"9.1.0",) #keys(gcc_version_sources)
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
        spec_generator = gcc_spec_generator,
        meta,
    )
end
