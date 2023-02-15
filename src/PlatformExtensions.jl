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
Base.BinaryPlatforms.tags(p::AnyPlatform) = Dict{String,String}()
Base.BinaryPlatforms.triplet(::AnyPlatform) = "any"
Base.BinaryPlatforms.arch(::AnyPlatform) = "any"
Base.BinaryPlatforms.os(::AnyPlatform) = "any"
nbits(::AnyPlatform) = nbits(default_host_platform)
proc_family(::AnyPlatform) = "any"
Base.show(io::IO, ::AnyPlatform) = print(io, "AnyPlatform")


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
nbits(cp::CrossPlatform) = nbits(cp.encoded)
proc_family(cp::CrossPlatform) = proc_family(cp.encoded)
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
gcc_platform(p::AnyPlatform) = p


"""
    platform_exeext(p::AbstractPlatform)

Get the executable extension for the given Platform.  Includes the leading `.`.
"""
platform_exeext(p::AbstractPlatform) = Sys.iswindows(p) ? ".exe" : ""


# Helper parsing function: it extends `parse(Platform, p)` by supporting
# `AnyPlatform` as well.
parse_platform(p::AbstractString) = p == "any" ? AnyPlatform() : parse(Platform, p; validate_strict=true)


# Recursively test for key presence in nested dicts
function haskeys(d, keys...)
    for key in keys
        if !haskey(d, key)
            return false
        end
        d = d[key]
    end
    return true
end
function get_march_flags(arch::String, march::String, compiler::String)
    # First, check if it's in the `"common"`
    if haskeys(ARCHITECTURE_FLAGS, "common", arch, march)
        return ARCHITECTURE_FLAGS["common"][arch][march]
    end
    if haskeys(ARCHITECTURE_FLAGS, compiler, arch, march)
        return ARCHITECTURE_FLAGS[compiler][arch][march]
    end
    # If this march cannot be found, return no flags
    return String[]
end
# If `march` is `nothing`, that means get the "generic" flags
function get_march_flags(arch::String, march::Nothing, compiler::String)
    return get_march_flags(arch, first(get_all_march_names(arch)), compiler)
end
function get_all_arch_names()
    # We don't use Base.BinaryPlatforms.arch_march_isa_mapping here so that
    # we can experiment with adding new architectures in BB before they land in Julia Base.
    return unique(vcat(
        collect(keys(ARCHITECTURE_FLAGS["common"])),
        collect(keys(ARCHITECTURE_FLAGS["gcc"])),
        collect(keys(ARCHITECTURE_FLAGS["clang"])),
    ))
end
function get_all_march_names(arch::String)
    return unique(vcat(
        collect(keys(get(ARCHITECTURE_FLAGS["common"], arch, Dict{String,String}()))),
        collect(keys(get(ARCHITECTURE_FLAGS["gcc"], arch, Dict{String,String}()))),
        collect(keys(get(ARCHITECTURE_FLAGS["clang"], arch, Dict{String,String}()))),
    ))
end

# NOTE: This needs to be kept in sync with `ISAs_by_family` in `Base.BinaryPlatforms.CPUID`
# This will allow us to detect these names at runtime and select artifacts accordingly.
const ARCHITECTURE_FLAGS = Dict(
    # Many compiler flags are the same across clang and gcc, store those in "common"
    "common" => Dict(
        "i686" => OrderedDict(
            "pentium4" => ["-march=pentium4", "-mtune=generic"],
            "prescott" => ["-march=prescott", "-mtune=prescott"],
        ),
        "x86_64" => OrderedDict(
            # Better be always explicit about `-march` & `-mtune`:
            # https://lemire.me/blog/2018/07/25/it-is-more-complicated-than-i-thought-mtune-march-in-gcc/
            "x86_64" => ["-march=x86-64", "-mtune=generic"],
            "avx"    => ["-march=sandybridge", "-mtune=sandybridge"],
            "avx2"   => ["-march=haswell", "-mtune=haswell"],
            "avx512" => ["-march=skylake-avx512", "-mtune=skylake-avx512"],
        ),
        "armv6l" => OrderedDict(
            # This is the only known armv6l chip that runs Julia, so it's the only one we care about.
            "arm1176jzfs" => ["-mcpu=arm1176jzf-s", "-mfpu=vfp", "-mfloat-abi=hard"],
        ),
        "armv7l" => OrderedDict(
            # Base armv7l architecture, with the most basic of FPU's
            "armv7l"   => ["-march=armv7-a", "-mtune=generic-armv7-a", "-mfpu=vfpv3", "-mfloat-abi=hard"],
            # armv7l plus NEON and vfpv4, (Raspberry Pi 2B+, RK3328, most boards Elliot has access to)
            "neonvfpv4" => ["-mcpu=cortex-a53", "-mfpu=neon-vfpv4", "-mfloat-abi=hard"],
        ),
        "aarch64" => OrderedDict(
            # For GCC, see: <https://gcc.gnu.org/onlinedocs/gcc/AArch64-Options.html>.  For
            # LLVM, for the list of features see
            # <https://github.com/llvm/llvm-project/blob/1bcc28b884ff4fbe2ecc011b8ea2b84e7987167b/llvm/include/llvm/Support/AArch64TargetParser.def>
            # and
            # <https://github.com/llvm/llvm-project/blob/85e9b2687a13d1908aa86d1b89c5ce398a06cd39/llvm/lib/Target/AArch64/AArch64.td>.
            # Run `clang --print-supported-cpus` for the list of values of `-mtune`.
            "armv8_0"        => ["-march=armv8-a", "-mcpu=cortex-a57"],
            "armv8_1"        => ["-march=armv8.1-a", "-mcpu=thunderx2t99"],
            "armv8_2_crypto" => ["-march=armv8.2-a+aes+sha2", "-mcpu=cortex-a76"],
            "a64fx"          => ["-mcpu=a64fx"],
        ),
        "powerpc64le" => OrderedDict(
            "power8"  => ["-mcpu=power8", "-mtune=power8"],
            # Note that power9 requires GCC 6+, and we need CPUID for this
            #"power9"  => ["-mcpu=power9", "-mtune=power9"],
            # Eventually, we'll support power10, once we have compilers that support it.
            #"power10" => ["-mcpu=power10", "-mtune=power10"],
        )
    ),
    "gcc" => Dict(
        "aarch64" => OrderedDict(
            "apple_m1"       => ["-march=armv8.5-a+aes+sha2+sha3+fp16fml+fp16+rcpc+dotprod", "-mcpu=cortex-a76"],
        ),
    ),
    "clang" => Dict(
        "aarch64" => OrderedDict(
            "apple_m1"       => ["-mcpu=apple-m1"],
        ),
    ),
)
march(p::AbstractPlatform; default=nothing) = get(tags(p), "march", default)
@warn("TODO: integrate march tests!")
