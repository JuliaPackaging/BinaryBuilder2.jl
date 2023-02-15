@kwdef struct CToolchain <: AbstractToolchain
    # When installing the C toolchain, we are going to generate compiler
    # wrapper scripts, and they will point to one vendor (e.g. GCC or clang)
    # as the default compiler; set `vendor` to force a choice one way
    # or the other, or leave it to default to a smart per-platform choice.
    vendor::Symbol

    # We can influence dependency versions here.  Most users will only want
    # to modify `gcc_version`.
    gcc_version::VersionSpec = VersionSpec("*")
    llvm_version::VersionSpec = VersionSpec("*")
    binutils_version::VersionSpec = VersionSpec("*")

    # TODO: Should this be embedded within the triplet somehow?
    glibc_version::VersionSpec = VersionSpec("*")

    function CToolchain(vendor, gcc_version, llvm_version, binutils_version, glibc_version)
        if vendor ∉ (:auto, :gcc, :clang)
            throw(ArgumentError("Unknown C toolchain vendor '$(vendor)'"))
        end
        return new(
            Symbol(vendor),
            VersionSpec(gcc_version),
            VersionSpec(llvm_version),
            VersionSpec(binutils_version),
            VersionSpec(glibc_version),
        )
    end
end

function toolchain_deps(toolchain::CToolchain, platform::CrossPlatform)
    deps = AbstractDependency[]

    gcc_triplet = triplet(gcc_platform(platform.target))
    if os(platform.target) == "linux"
        # Linux builds require the kernel headers for the target platform
        push!(deps, JLLDependency(
            "LinuxKernelHeaders_jll";
            platform.target,
        ))
    end

    if libc(platform.target) == "glibc"
        push!(deps, JLLDependency(
            "Glibc_jll";
            # TODO: Should we encode this in the platform object somehow?
            #version=toolchain.glibc_version,
            # This glibc is the one that gets embedded within GCC and it's for the target
            subprefix=gcc_triplet,
            platform.target,
        ))
    end

    # Include GCC, and it's own bundled versions of Zlib, as well as Binutils
    # These are compilers, so they take in the full cross platform.
    # TODO: Get `GCC_jll.jl` and `Binutils_jll.jl` packaged so that I don't
    #       have to pull down a special commit like this!
    # TODO: Do actual version selection!
    append!(deps, [
        JLLDependency(
            "GCC_jll";
            repo=Pkg.Types.GitRepo(
                rev="6e04e57d78fe742bcc357e7e7349dbe6e8ae4e2f",
                source="https://github.com/staticfloat/GCC_jll.jl"
            ),
            #version=toolchain.gcc_version,
            platform,
        ),
        JLLDependency(
            "Binutils_jll";
            repo=Pkg.Types.GitRepo(
                rev="ae1dd5078aaf195dd6efe876d2fb0fdde68a6d6e",
                source="https://github.com/JuliaBinaryWrappers/Binutils_jll.jl"
            ),
            #version=toolchain.binutils_version,
            platform,
        ),
        JLLDependency(
            "Zlib_jll";
            version=zlib_version,
            # zlib gets installed into `<prefix>/<triplet>/usr`
            subprefix=joinpath(gcc_triplet, "usr"),
            platform.target,
        ),
    ])
    return deps
end

