using Base.BinaryPlatforms
using OrderedCollections

export Platform, AnyPlatform, CrossPlatform

"""
    AnyPlatform()

A special platform to be used to build platform-independent tarballs, like those
containing only header files.  [`FileProduct`](@ref) is the only product type
allowed with this platform.
"""
struct AnyPlatform <: AbstractPlatform end
Base.BinaryPlatforms.tags(::AnyPlatform) = Dict{String,String}()
Base.BinaryPlatforms.triplet(::AnyPlatform) = "any"
Base.BinaryPlatforms.arch(::AnyPlatform) = "any"
Base.BinaryPlatforms.os(::AnyPlatform) = "any"
Base.show(io::IO, ::AnyPlatform) = print(io, "AnyPlatform")

# Helper parsing function: it extends `parse(Platform, p)` by supporting
# `AnyPlatform` as well.
function Base.parse(::Type{AbstractPlatform}, p::AbstractString)
    if p == "any"
        return AnyPlatform()
    else
        parse(Platform, p; validate_strict=true)
    end
end

const AnyPlat = Union{AnyPlatform,Platform}

"""
    CrossPlatform(host::Platform, target::Platform)

A special platform to be used when building cross-compiling toolchains; it contains a
`host` platform and a `target` platform.  Both platforms are preserved through encoding
one of the platforms into tags (e.g. by adding a prefix to the set of tags, a la
`target_arch=x86_64`, `target_os=windows`, etc...).

We also support setting the `host` or `target` as an `AnyPlatform`, allowing the creation
of any-host but target-specific binaries (such as `LinuxKernelHeaders_jll`) or host-
specific but any-target binaries (such as certain builds of `Clang_jll`).  In order to
properly lower this `Platform` to a serialized representation (both in text as well as
an `Artifacts.toml` file) we must determine ways to properly encode the `host` and
`target` platforms while maintaining the overall serialization as one that is parseable
as the basic `Platform` type.  To this end, we generally choose the `host` as the "base"
platform, then encode the `target` within the tags, except when the `host` is an
`AnyPlatform`, in which case we flip and use the `target` as the "base" platform.  To
disambiguate these two cases, we set the sentinel tag `target=any` for when the `target`
is an `AnyPlatform`, and `host=any` for when the `host` is an `AnyPlatform`.  Because
of these two tags, all valid `CrossPlatform` objects are identifiable by the presence
of these tags (or the equally-identifiying `target_arch`/`host_os` etc... tags).

In the event that you try to turn a "normal" `Platform` object into a `CrossPlatform`,
it will return a `CrossPlatform` object that has `host` and `target` equal to eacother.
"""
struct CrossPlatform <: AbstractPlatform
    # We don't allow storing anything other than bog-standard `Platform`s or `AnyPlatform`s
    host::AnyPlat
    target::AnyPlat

    # As an optimization, store the encoded platform for future use
    encoded::Platform
    function CrossPlatform(host::AnyPlat, target::AnyPlat)
        return new(host, target, encode_cross_platform(host, target))
    end
end
CrossPlatform(::AnyPlatform, ::AnyPlatform) = AnyPlatform()
CrossPlatform(pair::Pair{<:AnyPlat,<:AnyPlat}) = CrossPlatform(pair[1], pair[2])

"""
    CrossPlatform(encoded_platform::Platform)

Given a platform that has its target encoded in tags, split them out into a proper
`CrossPlatform` object.
"""
function CrossPlatform(encoded_platform::Platform)
    # Check whether this is a `target-any` cross platform:
    if get(tags(encoded_platform), "target", "") == "any"
        delete!(tags(encoded_platform), "target")
        return CrossPlatform(encoded_platform, AnyPlatform())
    end

    # Check whether this is a `host-any` cross platform:
    if get(tags(encoded_platform), "host", "") == "any"
        delete!(tags(encoded_platform), "host")
        return CrossPlatform(AnyPlatform(), encoded_platform)
    end

    # If neither are `AnyPlatforms`, we expect that the base platform is the `host`,
    # and the `target` is encoded within tags:
    if haskey(encoded_platform, "target_os") && haskey(encoded_platform, "target_arch")
        target_tags = Dict(k[8:end] => v for (k, v) in tags(encoded_platform) if startswith(k, "target_"))
        arch = pop!(target_tags, "arch")
        os = pop!(target_tags, "os")
        target = Platform(arch, os; Dict(Symbol(k) => v for (k, v) in target_tags)...)

        # Remove all target tags from the encoded platform, call that the host
        for k in keys(tags(encoded_platform))
            if startswith(k, "target_")
                delete!(tags(encoded_platform), k)
            end
        end

        return CrossPlatform(
            encoded_platform,
            target,
        )
    end

    # If we were just given a simple `Platform` object with no tags at all, target yourself:
    return CrossPlatform(
        encoded_platform,
        encoded_platform,
    )
end

function encode_cross_platform(host, target)
    local encoded_platform
    if isa(host, AnyPlatform)
        # If `host` is an `AnyPlatform`, our "base platform" will be the target.
        encoded_platform = deepcopy(target)
        encoded_platform["host"] = "any"
    elseif isa(target, AnyPlatform)
        # If `target` is an `AnyPlatform`, our "base platform" will be the host
        encoded_platform = deepcopy(host)
        encoded_platform["target"] = "any"
    else
        # Otherwise, use the `host` as the "base platform", and then encode the
        # target into the tags.
        encoded_platform = deepcopy(host)
        for (tag, value) in tags(target)
            encoded_platform["target_"*tag] = value
        end
    end
    return encoded_platform
end

function Base.:(==)(a::CrossPlatform, b::CrossPlatform)
    return a.host == b.host && a.target == b.target
end
Base.parse(::Type{CrossPlatform}, triplet::AbstractString) = CrossPlatform(parse(Platform, triplet))
Base.BinaryPlatforms.tags(cp::CrossPlatform) = Base.BinaryPlatforms.tags(cp.encoded)
Base.BinaryPlatforms.triplet(cp::CrossPlatform) = Base.BinaryPlatforms.triplet(cp.encoded)
Base.show(io::IO, cp::CrossPlatform) = print(io, "CrossPlatform(", cp.host, " -> ", cp.target, ")")

# Specifically override comparison between a `CrossPlatform` and a `Platform` to compare against the `target`,
# unless the other `Platform` is actually an encoded `CrossPlatform`, in which case we just use the `encoded`
# platform within the `CrossPlatform` to match.
function Base.BinaryPlatforms.platforms_match(cp::CrossPlatform, p::Platform)
    if get(tags(p), "target", "") == "host" || get(tags(p), "host", "") == "any" ||
        (haskey(p, "target_os") && haskey(p, "target_arch"))
        return platforms_match(cp.encoded, p)
    end
    platforms_match(cp.target, p)
end
Base.BinaryPlatforms.platforms_match(p::Platform, cp::CrossPlatform) = platforms_match(cp, p)



"""
    gcc_platform(p::AbstractPlatform)

Strip out any tags that are not the basic annotations like `libc` and `call_abi`.
"""
function gcc_platform(p::Platform)
    keeps = ("libc", "call_abi", "os_version")
    filtered_tags = Dict{Symbol,String}(Symbol(k) => v for (k, v) in tags(p) if k ∈ keeps)
    return Platform(arch(p)::String, os(p)::String; filtered_tags...)
end
gcc_platform(p::CrossPlatform) = CrossPlatform(gcc_platform(p.host), gcc_platform(p.target))
gcc_platform(p::AnyPlatform) = p

"""
    gcc_target_triplet(p::AbstractPlatform)

Return the kind of triplet that gcc would give for the given platform.  For a
`CrossPlatform`, applies to the `target`.
"""
gcc_target_triplet(target::AbstractPlatform) = triplet(gcc_platform(target))
gcc_target_triplet(platform::CrossPlatform) = gcc_target_triplet(platform.target)


function macos_version(kernel_version::Integer)
    # See https://en.wikipedia.org/wiki/Darwin_(operating_system)#Release_history
    kernel_to_macos = Dict(
        12 => "10.8",
        13 => "10.9",
        14 => "10.10",
        15 => "10.11",
        16 => "10.12",
        17 => "10.13",
        18 => "10.14",
        19 => "10.15",
        20 => "11.0",
        21 => "12.0",
    )
    return get(kernel_to_macos, kernel_version, nothing)
end

"""
    macos_version(p::AbstractPlatform)

If no `os_version` is specified in `p`, default to the oldest we support in the Julia world,
which is `macOS 10.8` (kernel version 14), but if it is actually specified, then return the
specified value (mapping from kernel version to macOS version).

```jldoctest
julia> macos_version(Platform("x86_64", "macos"; os_version="18"))
"10.14"
```
"""
function macos_version(p::AbstractPlatform)
    if os(p) != "macos"
        return nothing
    end
    version = something(os_version(p), v"14.0.0")
    return macos_version(version.major)
end


export nbits
"""
    nbits(p::AbstractPlatform)

Return the number of bits in the architecture of the given Platform.
Usually either 32 or 64.
"""
function nbits(p::AbstractPlatform)
    if arch(p) ∈ ("x86_64", "aarch64", "powerpc64le", "riscv64")
        return 64
    elseif arch(p) ∈ ("i686", "armv7l")
        return 32
    else
        error("Unknown number of bits for architecture of platform $(triplet(p))")
    end
end
# We have to give an answer (e.g. when the target of a build is `AnyPlatform`),
# so just default to a reasonable choice
nbits(::AnyPlatform) = 64
nbits(cp::CrossPlatform) = nbits(cp.target)

export proc_family
"""
    proc_family(p::AbstractPlatform)

Return the processor family of the architecture of the given Platform.
Usually one of "intel", "arm" or "power".
"""
function proc_family(p::AbstractPlatform)
    if arch(p) in ("x86_64", "i686")
        return "intel"
    elseif arch(p) in ("armv6l", "armv7l", "aarch64")
        return "arm"
    elseif arch(p) == "powerpc64le"
        return "power"
    else
        error("Unknown processor family for architecture of platform $(triplet(p))")
    end
end
proc_family(::AnyPlatform) = "any"
proc_family(cp::CrossPlatform) = proc_family(cp.target)


export exeext
"""
    exeext(p::AbstractPlatform)

Return the executable extension for the given platform.  Currently only Windows
platforms return ".exe", all other platforms return "".
"""
function exeext(p::AbstractPlatform)
    if Sys.iswindows(p)
        return ".exe"
    else
        return ""
    end
end
exeext(::AnyPlatform) = ""
exeext(cp::CrossPlatform) = exeext(cp.target)

export dlext
"""
    dlext(p::AbstractPlatform)

Return the dynamic library extension for the given platform.
"""
function dlext(p::AbstractPlatform)
    if Sys.iswindows(p)
        return ".dll"
    elseif Sys.isapple(p)
        return ".dylib"
    else
        return ".so"
    end
end
dlext(::AnyPlatform) = ""
dlext(cp::CrossPlatform) = dlext(cp.target)
