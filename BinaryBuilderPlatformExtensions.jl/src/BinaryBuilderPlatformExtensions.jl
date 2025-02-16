module BinaryBuilderPlatformExtensions

using Reexport
@reexport using Base.BinaryPlatforms
using PrecompileTools: @setup_workload, @compile_workload
export BBHostPlatform

"""
    BBHostPlatform()

This provides a stripped-down form of `HostPlatform()` that does not include
constraints on the julia version, the libgfortran version, etc...
This is useful when you need the most generic form of what will work on the
host machine, but don't care about compatibility with all of Julia's deps.
This platform will include arch, os, libc type and cxxstring_abi.
"""
function BBHostPlatform()
    julia_host = HostPlatform()
    return Platform(arch(julia_host), os(julia_host); libc=libc(julia_host))
end

include("AnyPlatform.jl")
include("CrossPlatform.jl")
include("PlatformProperties.jl")
include("Microarchitectures.jl")
include("Utils.jl")

@setup_workload begin
    @compile_workload begin
        cross_hosts = [
            Platform("x86_64", "linux"),
            Platform("aarch64", "macos"),
            AnyPlatform(),
        ]
        for host in cross_hosts
            for target in [cross_hosts...,
                           Platform("i686", "windows"),
                           Platform("ppc64le", "linux"; libgfortran_version=v"3"),
                           AnyPlatform()]
                cp = CrossPlatform(host => target)

                # Early-exit if we're dealing with AnyPlatform's on both sides
                if isa(host, AnyPlatform) && isa(target, AnyPlatform)
                    continue
                end
                if !isa(cp.host, AnyPlatform) && !isa(cp.target, AnyPlatform)
                    cp["target_arch"]
                    target["arch"]
                end
                string(cp)
                for p = [cp, cp.target, cp.host]
                    nbits(p)
                    proc_family(p)
                    exeext(p)
                    dlext(p)
                end
                cp = parse(CrossPlatform, triplet(cp))

                glibc_libgfortran_to_m1 = CrossPlatform(
                    Platform("x86_64", "linux"; libc="glibc", libgfortran_version=v"5"),
                    Platform("aarch64", "macos")
                )
                glibc_libgfortran_to_m1_osver = CrossPlatform(
                    Platform("x86_64", "linux"; libc="glibc", libgfortran_version=v"5"),
                    Platform("aarch64", "macos"; os_version=v"20"),
                )

                # All these crosses should be compatible, as they are all
                # valid subsets of eachother
                compatible_cps = [
                    glibc_libgfortran_to_m1,
                    glibc_libgfortran_to_m1_osver,
                ]
                for a in compatible_cps, b in compatible_cps
                    platforms_match(a, b)
                end

                cp = CrossPlatform(Platform("x86_64", "linux") => Platform("aarch64", "macos"))
                artifacts = Dict(
                    cp => true,
                    CrossPlatform(Platform("x86_64", "linux") => Platform("aarch64", "linux")) => false,
                    CrossPlatform(Platform("aarch64", "macos") => Platform("x86_64", "linux")) => false,
                    CrossPlatform(Platform("x86_64", "linux")) => false,
                    CrossPlatform(Platform("aarch64", "macos")) => false,
                )
                select_platform(artifacts, cp)

                get_march_flags("x86_64", "avx", "gcc")
                get_march_flags("aarch64", nothing, "clang")
                get_all_march_names("x86_64")
                get_all_march_names("armv7l")
            end
        end
    end
end

end # module BinaryBuilderPlatformExtensions
