# A library that is shipped as a framework bundle on macOS and as an ordinary
# shared library elsewhere, described by `LibraryProduct`s listing both paths.
# `Mult` links against `Plus`.
using BinaryBuilder2

build_tarballs(;
    src_name = "FrameworkExample",
    src_version = v"1.0.0",
    sources = [DirectorySource(joinpath(@__DIR__, "..", "bundled", "framework"))],
    script = raw"""
    if [[ "${target}" == *-apple-* ]]; then
        for name in Plus Mult; do
            fw="${libdir}/${name}.framework"
            mkdir -p "${fw}/Versions/A/Resources"
            ln -s A "${fw}/Versions/Current"
            ln -s "Versions/Current/${name}" "${fw}/${name}"
            ln -s Versions/Current/Resources "${fw}/Resources"
        done
        cc -shared -o "${libdir}/Plus.framework/Versions/A/Plus" plus.c \
            -Wl,-install_name,@rpath/Plus.framework/Versions/A/Plus
        # No install name: the auditor gives it `@rpath/Mult.framework/Versions/A/Mult`
        cc -shared -o "${libdir}/Mult.framework/Versions/A/Mult" mult.c -F"${libdir}" -framework Plus
    else
        mkdir -p "${libdir}"
        cc -shared -fPIC -o "${libdir}/libPlus.${dlext}" plus.c
        cc -shared -fPIC -o "${libdir}/libMult.${dlext}" mult.c -L"${libdir}" -lPlus
    fi
    mkdir -p "${prefix}/share/licenses/FrameworkExample"
    echo "public domain" > "${prefix}/share/licenses/FrameworkExample/LICENSE.md"
    """,
    products = [
        LibraryProduct(["Plus.framework", "libPlus"], :libplus),
        LibraryProduct(["Mult.framework", "libMult"], :libmult),
    ],
    platforms = [
        filter(Sys.isapple, supported_platforms())...,
        Platform(arch(HostPlatform()), "linux"),
    ],
    host_toolchains = [CToolchain(; use_ccache=false), HostToolsToolchain()],
    target_toolchains = [CToolchain(; use_ccache=false)],
)
