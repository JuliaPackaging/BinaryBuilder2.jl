using BinaryBuilder2
using BinaryBuilder2: get_default_target_spec

## This test case builds Zlib, generating two extractions, and shows how
## to package those either as two extractions within a single JLL (only
## one of which gets installed by default, thanks to LazyJLLWrappers
## choosing the one named after the JLL's toplevel name).  Or as two
## separate JLLs.

## NOTE: This build_tarballs example is a little tortured, but it showcases
## just how dynamic these build scripts can be.  I do not recommend having
## command line arguments that change the shape of the output of your build
## but if you need it, know that it's there.

function zlib_extract_generator(;zlib_full_deps = String[])
    return (build_config, platform) -> begin
        return Dict(
            # The default extraction (denoted by matching the JLL name) contains only the shared library
            "Zlib" => ExtractSpec(
                raw"extract ${shlibdir}/**",
                [
                    LibraryProduct("libz", :libz),
                ],
                get_default_target_spec(build_config),
            ),
            # The "full" extraction contains everything
            "ZlibFull" => ExtractSpec(
                raw"extract ${prefix}/**",
                [
                    FileProduct("include/zlib.h", :zlib_h),
                    LibraryProduct("libz", :libz),
                ],
                get_default_target_spec(build_config),
                inter_deps = zlib_full_deps,
            ),
        )
    end
end

build_tarballs_args = Dict(
    :src_name => "Zlib",
    :src_version => v"1.2.13",
    :sources => [
        ArchiveSource("https://github.com/madler/zlib/releases/download/v1.2.13/zlib-1.2.13.tar.xz",
                      "sha256:d14c38e313afc35a9a8760dadf26042f51ea0f5d154b0630a31da0540107fb98")
    ],
    :script => """
    cd zlib*
    ./configure --prefix=\$prefix
    make -j\$(nproc)
    make install
    """,
    :platforms => [Platform(arch(HostPlatform()), "linux")],
)

if "--multi-extractions" ∈ ARGS
    build_tarballs_args[:jll_extraction_map] = Dict(
        "Zlib" => ["Zlib", "ZlibFull"],
    )
    build_tarballs_args[:extract_spec_generator] = zlib_extract_generator()
elseif "--multi-jlls" ∈ ARGS
    build_tarballs_args[:jll_extraction_map] = Dict(
        "Zlib" => ["Zlib"],
        "ZlibFull" => ["ZlibFull", "Zlib"],
    )
    build_tarballs_args[:extract_spec_generator] = zlib_extract_generator(;zlib_full_deps=["Zlib"])
else
    error("You must specify either --multi-extractions or --multi-jlls!")
end

build_tarballs(;build_tarballs_args...)
