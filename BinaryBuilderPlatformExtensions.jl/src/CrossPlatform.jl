using Base.BinaryPlatforms
export CrossPlatform

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
it will return a `CrossPlatform` object that has `host` and `target` equal to eachother.
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
Base.repr(cp::CrossPlatform) = "CrossPlatform($(repr(cp.encoded)))"

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
