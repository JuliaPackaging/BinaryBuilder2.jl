using BinaryBuilder2

include("../GCC/gcc_common.jl")

for version in (v"14.2.0",)
    build_tarballs(;
        src_name = "GCCBootstrapMacOS",
        src_version = version,
        sources = [
            gcc_version_sources[version]...,
            DirectorySource("./patches-v$(version)"; follow_symlinks=true, target="patches"),
        ],
        script,
        platforms = [
            CrossPlatform(Platform(arch(HostPlatform()), "linux") => Platform("aarch64", "macos")),
            CrossPlatform(Platform(arch(HostPlatform()), "linux") => Platform("x86_64", "macos")),
        ],
        products = [
            FileProduct("bin", :bindir),
            ExecutableProduct("\${target}-gcc", :gcc),
            ExecutableProduct("\${target}-g++", :gxx),
        ],
        build_spec_generator = gcc_build_spec_generator,
        meta,
        duplicate_extraction_handling = :ignore_all,
    )
end
