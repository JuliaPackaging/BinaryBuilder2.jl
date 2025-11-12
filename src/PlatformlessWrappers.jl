using BinaryBuilderSources: PkgSpec
export PlatformlessWrapper, apply_platform

"""
    PlatformlessWrapper{T}

Many objects in BinaryBuilder2 want to be fully-concretized for a particular
platform, such as `JLLSource`s, or `CToolchain`s.  This struct provides a
convenient method of delaying full concretization while allowing carrythrough
of arguments past API layers.  Example usage is via the constructor of an
implemented type (such as `CToolchain`), but lacking the platform argument,
then later invoking `apply_platform()` on that type.

See the [`PlatformlessWrapper`](@ref) documentation page for examples.
"""
Base.@kwdef struct PlatformlessWrapper{T}
    args::Vector = []
    kwargs::Dict{Symbol,Any} = Dict{Symbol,Any}()
end
Base.copy(pw::PlatformlessWrapper{T}) where {T} = PlatformlessWrapper{T}(copy(pw.args), copy(pw.kwargs))

function Base.show(io::IO, pw::PlatformlessWrapper{T}) where {T}
    print(io, "$(T)(...) (platformless wrapper)")
end

# JLLSource support
function BinaryBuilderSources.JLLSource(pkg::PkgSpec; target="")
    return PlatformlessWrapper{JLLSource}(;args=[pkg], kwargs=Dict(:target => target))
end
function BinaryBuilderSources.JLLSource(name::String; target="", kwargs...)
    return PlatformlessWrapper{JLLSource}(;args=[PkgSpec(;name, kwargs...)], kwargs=Dict(:target => target))
end
function apply_platform(pw::PlatformlessWrapper{JLLSource}, platform::AbstractPlatform)
    return JLLSource(pw.args..., platform; pw.kwargs...)
end
# If someone tries to apply a platform to a non-platformless source, just ignore it.
# They've already specified the platform, we're not going to check.
# This allows installation of things like a `target` libc inside of `host_prefix` when building GCC
function apply_platform(jll::JLLSource, p::AbstractPlatform)
    #=
    if !platforms_match(jll.platform, p)
        throw(ArgumentError("Attempted to `apply_platform` a JLLSource with platform $(triplet(jll.platform)) but for $(triplet(p))"))
    end
    =#
    return jll
end

PlatformlessWrapper(jll::JLLSource) = JLLSource(jll.pkg; target=jll.target)


# CToolchain support
function BinaryBuilderToolchains.CToolchain(; kwargs...)
    return PlatformlessWrapper{CToolchain}(;kwargs=Dict(kwargs...))
end
function apply_platform(pw::PlatformlessWrapper{CToolchain}, platform::CrossPlatform)
    return CToolchain(platform; pw.kwargs...)
end
function apply_platform(ct::CToolchain, p::AbstractPlatform)
    if !platforms_match(ct.platform, p)
        throw(ArgumentError("Attempted to `apply_platform` a CToolchain with platform $(triplet(ct.platform)) but for $(triplet(p))"))
    end
    return ct
end
function PlatformlessWrapper(ct::CToolchain)
    return CToolchain(;vendor=BinaryBuilderToolchains.get_vendor(ct))
end

# BinutilsToolchain support
function BinaryBuilderToolchains.BinutilsToolchain(vendor; kwargs...)
    return PlatformlessWrapper{BinutilsToolchain}(; args=[vendor], kwargs=Dict(kwargs...))
end
function apply_platform(pw::PlatformlessWrapper{BinutilsToolchain}, platform::CrossPlatform)
    return BinutilsToolchain(platform, pw.args...; pw.kwargs...)
end
function apply_platform(bt::BinutilsToolchain, p::AbstractPlatform)
    if !platforms_match(bt.platform, p)
        throw(ArgumentError("Attempted to `apply_platform` a BinutilsToolchain with platform $(triplet(bt.platform)) but for $(triplet(p))"))
    end
    return bt
end
function PlatformlessWrapper(bt::BinutilsToolchain)
    return BinutilsToolchain(bt.vendor)
end

# CMakeToolchain support
function BinaryBuilderToolchains.CMakeToolchain(; kwargs...)
    return PlatformlessWrapper{CMakeToolchain}(;kwargs=Dict(kwargs...))
end
function apply_platform(pw::PlatformlessWrapper{CMakeToolchain}, platform::CrossPlatform)
    return CMakeToolchain(platform; pw.kwargs...)
end
function apply_platform(cmt::CMakeToolchain, p::AbstractPlatform)
    if !platforms_match(cmt.platform, p)
        throw(ArgumentError("Attempted to `apply_platform` a CMakeToolchain with platform $(triplet(cmt.platform)) but for $(triplet(p))"))
    end
    return cmt
end
function PlatformlessWrapper(cmt::CMakeToolchain)
    return CMakeToolchain(;vendor=BinaryBuilderToolchains.get_vendor(cmt))
end

# HostToolsToolchain support
function BinaryBuilderToolchains.HostToolsToolchain(;kwargs...)
    return PlatformlessWrapper{HostToolsToolchain}(;kwargs=kwargs)
end
function apply_platform(pw::PlatformlessWrapper{HostToolsToolchain}, platform::AbstractPlatform)
    return HostToolsToolchain(platform; pw.kwargs...)
end
apply_platform(htt::HostToolsToolchain, ::AbstractPlatform) = htt
PlatformlessWrapper(htt::HostToolsToolchain) = HostToolsToolchain()

# Automatic conversion of `Pair{Platform,Platform}` => `CrossPlatform`
apply_platform(x, cp::Pair{Platform,Platform}) = apply_platform(x, CrossPlatform(cp))

# Other sources don't even have platform arguments
apply_platform(src::AbstractSource, ::AbstractPlatform) = src

const ConvenienceSource = Union{AbstractSource,PlatformlessWrapper{<:AbstractSource}}
const ConvenienceToolchain = Union{AbstractToolchain,PlatformlessWrapper{<:AbstractToolchain}}


