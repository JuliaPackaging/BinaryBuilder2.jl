using Base.BinaryPlatforms
import Libdl

if isdefined(Base.Libc.Libdl, :default_rtld_flags)
    const default_rtld_flags::UInt32 = Base.Libc.Libdl.default_rtld_flags
else
    # This is hardcoded in older versions of Julia
    const default_rtld_flags::UInt32 = Libdl.RTLD_LAZY | Libdl.RTLD_DEEPBIND
end

const RTLD_flags = Dict(
    name => getproperty(Libdl, name)
    for name in filter(n -> startswith(string(n), "RTLD_"), propertynames(Libdl))
)

"""
    rtld_symbols(flags::UInt32)::Vector{Symbol}

Convert a packed bitflag form of RTLD flags into a vector of symbols.
Throws an error if bits are set that have no corresponding bit in `RTLD_flags`.
"""
function rtld_symbols(flags::UInt32)
    symbols = Symbol[]
    for (name, val) in RTLD_flags
        if flags & val != 0
            push!(symbols, name)
            flags &= ~val
        end
    end
    if flags != 0
        throw(ArgumentError("`flags` contains leftover bits that do not correspond to any known RTLD flag: $(string(flags, base=2))"))
    end
    return sort(symbols)
end


"""
    rtld_flags(symbols::Vector{Symbol})::UInt332

Convert a vector of RTLD flag symbols into the packed bitflags form.
Throws an error if a symbolic name is provided that does not appear in `RTLD_flags`.
"""
function rtld_flags(symbols::Vector{Symbol})::UInt32
    flags = UInt32(0)
    for sym in symbols
        if !haskey(RTLD_flags, sym)
            throw(ArgumentError("Invalid RTLD flag name '$(sym)'"))
        end
        flags |= RTLD_flags[sym]
    end
    return flags
end
