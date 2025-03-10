using Base.BinaryPlatforms

export Platform, AnyPlatform, AnyPlat

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
Base.repr(::AnyPlatform) = "AnyPlatform()"

# Helper parsing function: it extends `parse(Platform, p)` by supporting
# `AnyPlatform` as well.
function Base.parse(::Type{AbstractPlatform}, p::AbstractString)
    if p == "any"
        return AnyPlatform()
    else
        parse(Platform, p; validate_strict=false)
    end
end

const AnyPlat = Union{AnyPlatform,Platform}
