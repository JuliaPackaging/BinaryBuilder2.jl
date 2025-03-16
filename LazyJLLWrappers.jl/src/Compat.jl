# Julia 1.5 and lower have terrible `BinaryPlatforms` support
if !isdefined(BinaryPlatforms, :AbstractPlatform)
    const AbstractPlatform = Platform
end
if !isdefined(BinaryPlatforms, :HostPlatform)
    HostPlatform() = BinaryPlatforms.default_platkey
    Base.parse(::Type{<:AbstractPlatform}, str::AbstractString) = BinaryPlatforms.platform_key_abi(str)
end

if !isdefined(Base, :pkgdir)
    function pkgdir(m::Module, paths::String...)
        rootmodule = Base.moduleroot(m)
        path = Base.pathof(rootmodule)
        path === nothing && return nothing
        return joinpath(dirname(dirname(path)), paths...)
    end
end
