using BinaryBuilder2

include(joinpath(@__DIR__, "..", "..", "test", "build_recipes", "Readline.jl"))
include(joinpath(@__DIR__, "..", "..", "test", "build_recipes", "Ncurses.jl"))
include(joinpath(@__DIR__, "..", "..", "test", "build_recipes", "Zlib.jl"))

function crosstool_ng_build_tarballs(meta, platforms; version = v"1.25.0")
    version_sources_map = Dict(
        v"1.25.0" => [
            ArchiveSource("http://crosstool-ng.org/download/crosstool-ng/crosstool-ng-1.25.0.tar.xz",
                          "68162f342243cd4189ed7c1f4e3bb1302caa3f2cbbf8331879bd01fe06c60cd3"),
        ]
    )
    patches = [
        DirectorySource(joinpath(@__DIR__, "./bundled")),
    ]
    return build_tarballs(
        "CrosstoolNG",
        version,
        AbstractSource[version_sources_map[version]..., patches...],
        [
            JLLSource("Ncurses_jll", host),
            JLLSource("Zlib_jll", host),
        ],
        AbstractSource[],
        raw"""
        cd ${WORKSPACE}/srcdir/crosstool-ng*/

        # Eventually, it'd be nice to provide these via JLLs.
        apt update
        apt install -y texinfo help2man

        # Copy in our extra patches for all packages
        for package in ${WORKSPACE}/srcdir/patches/*; do
            package="$(basename "${package}")"
            for version in ${WORKSPACE}/srcdir/patches/${package}/*; do
                version="$(basename "${version}")"
                if [ ! -d packages/${package}/${version} ]; then
                    continue
                fi
                cp -v ${WORKSPACE}/srcdir/patches/${package}/${version}/* packages/${package}/${version}/
            done
        done

        # Disable some checks that ct-ng performs
        export CT_ALLOW_BUILD_AS_ROOT_SURE=1

        # Build crosstool-ng
        # The extra CFLAGS here are because the `kconfig/` directory of `crosstool-ng` doesn't
        # pay attention to the actual location of `ncurses`, it just directly looks for `panel.h`
        CFLAGS="-I${prefix}/include/ncursesw" ./configure --prefix=${prefix}
        make -j${nproc} V=1
        make -j${nproc} install
        """,
        platforms,
        [
            ExecutableProduct("ct-ng", :ct_ng),
        ];
        meta,
        host,
    )
end

meta = BuildMeta(;
    universe_name="GCCBoostrap",
    debug_modes=["build-error", "extract-error"],
)
host = Platform(arch(HostPlatform()), "linux")

# First, build the dependencies for crosstool-ng.
# Right now, this is _required_, because we need the `JLL.toml` files to exist for these
# dependencies in order to properly build `crosstool-ng`.
zlib_build_tarballs(meta, [host])
readline_build_tarballs(meta, [host])
ncurses_build_tarballs(meta, [host])

# Next, crosstool-ng
crosstool_ng_build_tarballs(meta, [host])
