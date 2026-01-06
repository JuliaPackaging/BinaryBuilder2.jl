using Base.BinaryPlatforms
using BinaryBuilderPlatformExtensions

export expand_cxxstring_abis, expand_microarchitectures

"""
    expand_cxxstring_abis(p::AbstractPlatform; skip=Sys.isbsd, old_abis::Bool=false)

Given a `Platform`, returns an array of `Platforms` with a spread of identical
entries with the exception of the `cxxstring_abi` tag within the `Platform`
object.  This is used to take, for example, a list of supported platforms and
expand them to include multiple GCC versions for the purposes of ABI matching.

If the given `Platform` already specifies a `cxxstring_abi` (as opposed to
`nothing`) only that `Platform` is returned.  If `skip` is a function for which
`skip(platform)` evaluates to `true`, the given platform is not expanded.  By
default FreeBSD and macOS platforms are skipped, due to their lack of a
dependence on `libstdc++` and not needing this compatibility shim.

If `old_abis` is `true`, old ABIs are included in the expanded list, otherwise
only the new ones are included.

"""
function expand_cxxstring_abis(platform::AbstractPlatform; skip=Sys.isbsd, old_abis::Bool=false)
    # If this platform cannot/should not be expanded, then exit out fast here.
    if cxxstring_abi(platform) !== nothing || skip(platform)
        return [platform]
    end

    if sanitize(platform) == "memory"
        p = deepcopy(platform)
        p["cxxstring_abi"] = "cxx11" # Clang only seems to generate cxx11 abi
        return [p]
    end

    # Otherwise, generate new versions! At the moment we only support the C++11 string ABI.
    abis = old_abis ? ["cxx03", "cxx11"] : ["cxx11"]
    map(abis) do abi
        p = deepcopy(platform)
        p["cxxstring_abi"] = abi
        return p
    end
end
function expand_cxxstring_abis(ps::Vector{T}; kwargs...) where {T<:AbstractPlatform}
    return collect(T,Iterators.flatten(expand_cxxstring_abis.(ps; kwargs...)))
end

"""
    expand_microarchitectures(p::AbstractPlatform, [microarchitectures::Vector{String}])

Given a `Platform`, returns a vector of `Platforms` with differing `march` attributes
as specified by the `ARCHITECTURE_FLAGS` mapping.  If the given `Platform` alread has a
`march` tag specified, only that platform is returned.  If the `microarchitectures`
argument is given, limit the expansion to the given microarchitectures.

```jldoctest
julia> expand_microarchitectures(Platform("x86_64", "freebsd"))
4-element Vector{Platform}:
 FreeBSD x86_64 {march=x86_64}
 FreeBSD x86_64 {march=avx}
 FreeBSD x86_64 {march=avx2}
 FreeBSD x86_64 {march=avx512}

julia> expand_microarchitectures(Platform("armv7l", "linux"))
2-element Vector{Platform}:
 Linux armv7l {call_abi=eabihf, libc=glibc, march=armv7l}
 Linux armv7l {call_abi=eabihf, libc=glibc, march=neonvfpv4}

julia> expand_microarchitectures(Platform("aarch64", "linux"), ["armv8_0", "a64fx"])
2-element Vector{Platform}:
 Linux aarch64 {libc=glibc, march=armv8_0}
 Linux aarch64 {libc=glibc, march=a64fx}

julia> expand_microarchitectures(Platform("i686", "windows"))
2-element Vector{Platform}:
 Windows i686 {march=pentium4}
 Windows i686 {march=prescott}
```
"""
function expand_microarchitectures(platform::AbstractPlatform,
                                   microarchitectures::Vector{String}=get_all_march_names(arch(platform)))
    all_marchs = get_all_march_names(arch(platform))

    # If this already has a `march`, or it's an `AnyPlatform`, or the microarchitectures we
    # want to expand aren't relative to this platform, just return it.
    if isa(platform, AnyPlatform) || march(platform) !== nothing ||
        !any(in(all_marchs), microarchitectures)
        return [platform]
    end

    # First, filter out some meaningless combinations of microarchitectures.
    marchs = filter(all_marchs) do march
        if (!Sys.isapple(platform) && march == "apple_m1") ||
            (Sys.isapple(platform) && arch(platform) == "aarch64" && march ∉ ("armv8_0", "apple_m1"))
            # `apple_m1` makes sense only on macOS, and the only aarch64 microarchitectures
            # that make sense on macOS are M1 and the generic one.
            return false
        elseif march == "a64fx" && !(Sys.islinux(platform) && libc(platform) == "glibc")
            # Let's be honest: it's unlikely we'll see Alpine Linux on A64FX.
            return false
        end
        return true
    end

    # But if none of the remaining microarchitectures are among those we want to expand,
    # return the given platform as is.
    if !any(in(microarchitectures), marchs)
        return [platform]
    end

    # Otherwise, return a bunch of Platform objects with appropriately-set `march` tags
    return [(p = deepcopy(platform); p["march"] = march; p) for march in marchs if march in microarchitectures]
end

"""
    expand_microarchitectures(ps::Vector{<:Platform}, [microarchitectures::Vector{String}];
                              filter=Returns(true))

Expand all platforms in the vector `ps` with the supported microarchitectures.

If the `microarchitectures` argument is given, limit the expansion to the given
platforms.  This is useful if you do not want to expand to all available
microarchitectures.

The expansion is applied only to the platforms matching the `filter` predicate, by
default all platforms.  This is useful if you want to limit the expansion to some
platforms, without having to explicitly list its microarchitectures in the second
argument.

```jldoctest
julia> using BinaryBuilderBase

julia> expand_microarchitectures(filter!(p -> Sys.islinux(p) && libc(p) == "glibc", supported_platforms()))
15-element Vector{Platform}:
 Linux i686 {libc=glibc, march=pentium4}
 Linux i686 {libc=glibc, march=prescott}
 Linux x86_64 {libc=glibc, march=x86_64}
 Linux x86_64 {libc=glibc, march=avx}
 Linux x86_64 {libc=glibc, march=avx2}
 Linux x86_64 {libc=glibc, march=avx512}
 Linux aarch64 {libc=glibc, march=armv8_0}
 Linux aarch64 {libc=glibc, march=armv8_1}
 Linux aarch64 {libc=glibc, march=armv8_2_crypto}
 Linux aarch64 {libc=glibc, march=a64fx}
 Linux armv6l {call_abi=eabihf, libc=glibc, march=arm1176jzfs}
 Linux armv7l {call_abi=eabihf, libc=glibc, march=armv7l}
 Linux armv7l {call_abi=eabihf, libc=glibc, march=neonvfpv4}
 Linux powerpc64le {libc=glibc, march=power8}
 Linux riscv64 {libc=glibc, march=riscv64}

julia> expand_microarchitectures(filter!(p -> Sys.islinux(p) && libc(p) == "glibc", supported_platforms()), ["x86_64", "avx2"])
8-element Vector{Platform}:
 Linux i686 {libc=glibc}
 Linux x86_64 {libc=glibc, march=x86_64}
 Linux x86_64 {libc=glibc, march=avx2}
 Linux aarch64 {libc=glibc}
 Linux armv6l {call_abi=eabihf, libc=glibc}
 Linux armv7l {call_abi=eabihf, libc=glibc}
 Linux powerpc64le {libc=glibc}
 Linux riscv64 {libc=glibc}

julia> expand_microarchitectures(filter!(p -> Sys.islinux(p) && libc(p) == "glibc", supported_platforms()); filter=p->arch(p)=="x86_64")
10-element Vector{Platform}:
 Linux i686 {libc=glibc}
 Linux x86_64 {libc=glibc, march=x86_64}
 Linux x86_64 {libc=glibc, march=avx}
 Linux x86_64 {libc=glibc, march=avx2}
 Linux x86_64 {libc=glibc, march=avx512}
 Linux aarch64 {libc=glibc}
 Linux armv6l {call_abi=eabihf, libc=glibc}
 Linux armv7l {call_abi=eabihf, libc=glibc}
 Linux powerpc64le {libc=glibc}
 Linux riscv64 {libc=glibc}
```
"""
function expand_microarchitectures(ps::Vector{<:AbstractPlatform},
                                   microarchitectures::Vector{String}=collect(Iterators.flatten(get_all_march_names.(unique!(arch.(ps)))));
                                   filter=Returns(true),
                                   )
    out = map(ps) do p
        return if filter(p)
            # If the platform satisfies the predicate, expand its microarchitectures
            expand_microarchitectures(p, microarchitectures)
        else
            # otherwise return it as-is.
            [p]
        end
    end
    return collect(Iterators.flatten(out))
end
