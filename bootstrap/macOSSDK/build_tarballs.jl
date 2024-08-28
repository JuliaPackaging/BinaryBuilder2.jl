using BinaryBuilder2

meta = BinaryBuilder2.get_default_meta()
platforms = [
    Platform("x86_64", "macos"),
    Platform("aarch64", "macos"),
]

# Build the tarballs, and possibly a `build.jl` as well.
build_tarballs(;
    src_name = "macOSSDK",
    src_version = v"11.1",
    sources = [
        ArchiveSource("https://github.com/joseluisq/macosx-sdks/releases/download/11.1/MacOSX11.1.sdk.tar.xz",
                      "97a916b0b68aae9dcd32b7d12422ede3e5f34db8e169fa63bfb18ec410b8f5d9"),
        DirectorySource(joinpath(@__DIR__, "bundled"), target="bundled"),
    ],
    script = raw"""
    mv MacOSX*.sdk/usr ${prefix}/usr
    mv MacOSX*.sdk/System ${prefix}/
    install_license bundled/LICENSE.md

    # Delete `man` pages
    rm -rf ${prefix}/usr/share/man
    """,
    platforms,
    products = [
        FileProduct("usr/include/Availability.h", :Availability_h),
    ],
    host_toolchains = [HostToolsToolchain()],
    target_toolchains = [],
    meta,
)
