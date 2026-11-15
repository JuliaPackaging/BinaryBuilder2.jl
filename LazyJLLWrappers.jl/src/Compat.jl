# Julia 1.5 and lower have terrible `BinaryPlatforms` support
if !isdefined(BinaryPlatforms, :AbstractPlatform)
    const AbstractPlatform = Platform
end
if !isdefined(BinaryPlatforms, :HostPlatform)
    HostPlatform() = BinaryPlatforms.default_platkey
    Base.parse(::Type{<:AbstractPlatform}, str::AbstractString) = BinaryPlatforms.platform_key_abi(str)
    function Base.tryparse(::Type{<:AbstractPlatform}, str::AbstractString)
        # `platform_key_abi()` warns about every triplet it does not understand; those
        # are reported by returning `nothing` instead.
        p = Base.CoreLogging.with_logger(Base.CoreLogging.NullLogger()) do
            BinaryPlatforms.platform_key_abi(str)
        end
        return p isa BinaryPlatforms.UnknownPlatform ? nothing : p
    end
end

if !isdefined(Base, :pkgdir)
    function pkgdir(m::Module, paths::String...)
        rootmodule = Base.moduleroot(m)
        path = Base.pathof(rootmodule)
        path === nothing && return nothing
        return joinpath(dirname(dirname(path)), paths...)
    end
end
