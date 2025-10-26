using BinaryBuilder2

include("../GCC/gcc_common.jl")


function notarget_build_spec_generator(host, platform)
    target_str = triplet(gcc_platform(platform.target))
    lock_microarchitecture = false

    target_sources = []
    if os(platform.target) == "macos"
        push!(target_sources, JLLSource(
            "macOSSDK_jll",
            platform.target;
            uuid=Base.UUID("52f8e75f-aed1-5264-b4c9-b8da5a6d5365"),
            repo=Pkg.Types.GitRepo(
                rev="bb2/GCCBootstrap-x86_64-linux-gnu",
                source="https://github.com/staticfloat/macOSSDK_jll.jl"
            ),
            target=target_str,
        ))
    elseif os(platform.target) == "freebsd"
        push!(target_sources, JLLSource(
            "FreeBSDSysroot_jll",
            platform.target;
            uuid=Base.UUID("671a10c0-f9bf-59ae-b52a-dff4adda89ae"),
            repo=Pkg.Types.GitRepo(
                source="https://github.com/staticfloat/FreeBSDSysroot_jll.jl",
                rev="bb2/GCCBootstrap-x86_64-linux-gnu",
            ),
            target=target_str,
        ))
    else
        throw(ArgumentError("Don't know how to install libc sources for $(triplet(platform.target))"))
    end

    return [
        BuildTargetSpec(
            "build",
            CrossPlatform(host => host),
            [CToolchain(; vendor=:gcc_bootstrap, lock_microarchitecture), HostToolsToolchain()],
            [],
            Set([:host]),
        ),
        BuildTargetSpec(
            "host",
            CrossPlatform(host => platform.host),
            [CToolchain(; vendor=:gcc_bootstrap, lock_microarchitecture)],
            [],
            Set([:default]),
        ),
        BuildTargetSpec(
            "target",
            CrossPlatform(host => platform.target),
            [BinutilsToolchain(:gcc_bootstrap)],
            #[CToolchain(; vendor=:gcc_bootstrap, lock_microarchitecture)],
            target_sources,
            Set([]),
        ),
    ]
end


for version in (v"14.2.0",)
    build_tarballs(;
        src_name = "GCCBootstrapManual",
        src_version = version,
        sources = [
            gcc_version_sources[version]...,
            DirectorySource("./patches-v$(version)"; follow_symlinks=true, target="patches"),
        ],
        script,
        platforms = [
            CrossPlatform(Platform(arch(HostPlatform()), "linux") => Platform("aarch64", "macos")),
            CrossPlatform(Platform(arch(HostPlatform()), "linux") => Platform("x86_64", "macos")),
            CrossPlatform(Platform(arch(HostPlatform()), "linux") => Platform("x86_64", "freebsd")),
            CrossPlatform(Platform(arch(HostPlatform()), "linux") => Platform("aarch64", "freebsd"))
        ],
        products = [
            FileProduct("bin", :bindir),
            ExecutableProduct("\${target}-gcc", :gcc),
            ExecutableProduct("\${target}-g++", :gxx),
        ],
        build_spec_generator = notarget_build_spec_generator,
        meta,
        duplicate_extraction_handling = :ignore_all,
    )
end
