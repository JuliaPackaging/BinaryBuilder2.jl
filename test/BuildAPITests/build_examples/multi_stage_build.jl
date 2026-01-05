using BinaryBuilder2
using BinaryBuilder2: get_default_target_spec

if !isdefined(@__MODULE__, :TestingUtils)
    include(joinpath(pkgdir(BinaryBuilder2), "test", "TestingUtils.jl"))
end

# Build libstring
native_arch = arch(HostPlatform())
native_linux = Platform(native_arch, "linux")

cxx_string_abi_source =  DirectorySource(joinpath(
    pkgdir(BinaryBuilderToolchains),
    "test",
    "testsuite",
    "CToolchain"
))

build_tarballs(;
    src_name = "libstring",
    src_version = v"1.0.0",
    sources = [cxx_string_abi_source],
    target_dependencies = [],
    script = raw"""
    cd 02_cxx_string_abi
    make clean
    make libstring
    mkdir -p ${shlibdir}
    cp build/*.so ${shlibdir}/
    mkdir -p ${includedir}
    cp libstring.h ${includedir}/

    mkdir -p ${prefix}/share/licenses/libstring
    echo "public domain" > ${prefix}/share/licenses/libstring/LICENSE.md
    """,
    platforms = filter(p -> Sys.islinux(p), supported_platforms()),
    host_toolchains = [CToolchain(;use_ccache=false), HostToolsToolchain()],
    target_toolchains = [CToolchain(;use_ccache=false)],

    extract_spec_generator = (build, platform) -> begin
        return Dict(
            "libstring" => ExtractSpec(
                raw"""
                extract ${prefix}/lib
                """,
                [LibraryProduct("libstring", :libstring)],
                get_default_target_spec(build);
            ),
            "libstring_headers" => ExtractSpec(
                raw"""
                extract ${prefix}/include
                """,
                [FileProduct("include/libstring.h", :libstring_h)],
                get_default_target_spec(build);
                platform = AnyPlatform(),
            ),
        )
    end,
    # Must set this to use AnyPlatform extractions
    duplicate_extraction_handling = :ignore_identical,
    jll_extraction_map = Dict(
        "libstring" => ["libstring"],
        "libstring_headers" => ["libstring_headers"],
    ),
    disable_cache=true,
)

# Next, use those products as inputs for cxx_string_abi
build_tarballs(;
    src_name = "cxx_string_abi",
    src_version = v"1.0.0",
    sources = [cxx_string_abi_source],
    target_dependencies = [JLLSource("libstring_jll")],
    script = raw"""
    cd 02_cxx_string_abi

    # Explicitly use the `libstring` we built previously,
    # ensure this file does not get rebuilt by checking timestamps
    rm -rf build; mkdir build
    cp -v ${shlibdir}/libstring* build/
    orig_mtime=$(stat -c %Y libstring*)

    make cxx_string_abi
    [[ "${orig_mtime}" == "$(stat -c %Y libstring*)" ]]
    mkdir -p ${bindir}
    cp build/cxx_string_abi* ${bindir}/
    touch build/
    mkdir -p ${prefix}/share/licenses/cxx_string_abi
    echo "public domain" > ${prefix}/share/licenses/cxx_string_abi/LICENSE.md
    """,
    platforms = filter(p -> Sys.islinux(p), supported_platforms()),
    host_toolchains = [CToolchain(;use_ccache=false), HostToolsToolchain()],
    target_toolchains = [CToolchain(;use_ccache=false)],
    disable_cache=true,
)
