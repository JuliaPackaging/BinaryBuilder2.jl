# TODO: Drop this, once we no longer have to depend on a `Pkg.Types.GitRepo` down below!
using Pkg

@kwdef struct CToolchain <: AbstractToolchain
    platform::CrossPlatform

    # When installing the C toolchain, we are going to generate compiler
    # wrapper scripts, and they will point to one vendor (e.g. GCC or clang)
    # as the default compiler; set `vendor` to force a choice one way
    # or the other, or leave it to default to a smart per-platform choice.
    vendor::Symbol = :auto

    # We can influence dependency versions here.  Most users will only want
    # to modify `gcc_version`.
    gcc_version::VersionSpec = VersionSpec("*")
    llvm_version::VersionSpec = VersionSpec("*")
    binutils_version::VersionSpec = VersionSpec("*")

    # TODO: Should this be embedded within the triplet somehow?
    glibc_version::VersionSpec = VersionSpec("*")

    function CToolchain(platform, vendor, gcc_version, llvm_version, binutils_version, glibc_version)
        if vendor ∉ (:auto, :gcc, :clang)
            throw(ArgumentError("Unknown C toolchain vendor '$(vendor)'"))
        end
        return new(
            platform,
            Symbol(vendor),
            VersionSpec(gcc_version),
            VersionSpec(llvm_version),
            VersionSpec(binutils_version),
            VersionSpec(glibc_version),
        )
    end
end

function gcc_target_triplet(target::AbstractPlatform)
    tags = Dict{Symbol,String}()
    for tag in ("call_abi", "libc")
        if haskey(target, tag)
            tags[Symbol(tag)] = target[tag]
        end
    end
    return triplet(Platform(arch(target), os(target); tags...))
end
gcc_target_triplet(platform::CrossPlatform) = gcc_target_triplet(platform.target)

toolchain_prefix(toolchain::CToolchain) = "/opt/$(gcc_target_triplet(toolchain.platform))"
function toolchain_deps(toolchain::CToolchain)
    deps = JLLSource[]

    gcc_triplet = triplet(gcc_platform(toolchain.platform.target))
    if os(toolchain.platform.target) == "linux"
        # Linux builds require the kernel headers for the target platform
        push!(deps, JLLSource(
            "LinuxKernelHeaders_jll",
            toolchain.platform.target,
        ))
    end

    if libc(toolchain.platform.target) == "glibc"
        push!(deps, JLLSource(
            "Glibc_jll",
            toolchain.platform.target;
            # TODO: Should we encode this in the platform object somehow?
            version=toolchain.glibc_version,
            # This glibc is the one that gets embedded within GCC and it's for the target
            target=gcc_triplet,
        ))
    end

    # Include GCC, and it's own bundled versions of Zlib, as well as Binutils
    # These are compilers, so they take in the full cross platform.
    # TODO: Get `GCC_jll.jl` and `Binutils_jll.jl` packaged so that I don't
    #       have to pull down a special commit like this!
    # TODO: Do actual version selection!
    append!(deps, [
        JLLSource(
            "GCC_jll",
            toolchain.platform;
            repo=Pkg.Types.GitRepo(
                rev="6e04e57d78fe742bcc357e7e7349dbe6e8ae4e2f",
                source="https://github.com/staticfloat/GCC_jll.jl"
            ),
            version=toolchain.gcc_version,
        ),
        JLLSource(
            "Binutils_jll",
            toolchain.platform;
            repo=Pkg.Types.GitRepo(
                rev="ae1dd5078aaf195dd6efe876d2fb0fdde68a6d6e",
                source="https://github.com/JuliaBinaryWrappers/Binutils_jll.jl"
            ),
            version=toolchain.binutils_version,
        ),
        JLLSource(
            "Zlib_jll",
            toolchain.platform.target;
            #version=toolchain.zlib_version,
            # zlib gets installed into `<prefix>/<triplet>/usr`, and it's only for the target
            target=joinpath(gcc_triplet, "usr"),
        ),
    ])
    return deps
end

