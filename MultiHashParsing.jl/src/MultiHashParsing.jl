module MultiHashParsing

using SHA

export MultiHash

"""
    MultiHash

Allows dealing with hashes that self-identify their algorithm, e.g. `sha256:xxxxxxx`.
Some pieces of BinaryBuilder, such as an ArchiveSource, may support multiple different hash algorithms.
Others, such as a GitSource, currently only support a SHA1Hash, for instance.
"""
abstract type MultiHash; end

hash_prefix(::T) where {T <: MultiHash} = hash_prefix(T)
hash_length(::T) where {T <: MultiHash} = hash_length(T)
Base.string(hash::MultiHash) = string(hash_prefix(hash), ":", bytes2hex(hash.data))
Base.bytes2hex(hash::MultiHash) = bytes2hex(hash.data)

# Equality convenience methods
Base.:(==)(hash::MultiHash, data::Union{Vector{UInt8}, NTuple{N, UInt8}}) where {N} = all(hash.data .== data)
Base.:(==)(data::Union{Vector{UInt8}, NTuple{N, UInt8}}, hash::MultiHash) where {N} = hash == data

# For strings, we try to parse them and then do the comparison
function Base.:(==)(hash::MultiHash, str::String)
    try
        return hash == MultiHash(str)
    catch e
        if isa(e, ArgumentError)
            return false
        end
        rethrow(e)
    end
end
Base.:(==)(str::String, hash::MultiHash) = hash == str

Base.show(io::IO, hash::MultiHash) = print(io, string(hash))
# If we already have a `MultiHash`, just return that back
MultiHash(hash::T) where {T <: MultiHash} = hash

const MULTIHASH_TYPES = Type{<:MultiHash}[]

macro define_multi_hash(prefix, len, func)
    T = esc(Symbol(string(uppercase(prefix), "Hash")))
    quote
        export $T

        # Create a struct that just has an ntuple of the right size to hold the hash bytes
        struct $T <: MultiHash
            data::NTuple{$(esc(len)), UInt8}
        end

        # Helper functions
        $(esc(:hash_length))(::Type{$T}) = $(esc(len))
        $(esc(:hash_prefix))(::Type{$T}) = $(esc(prefix))

        # Create a constructor to convert from Vector{UInt8} -> NTuple
        function $T(data::Vector{UInt8})
            if length(data) != $(esc(len))
                # It's a little awkard to dodge string interpolation due to being in a `quote` block
                throw(ArgumentError(string(
                    "Invalid length for ",
                    hash_prefix($T),
                    " hash: expected ",
                    hash_length($T),
                    "bytes, got ",
                    length(data),
                    " instead")
                ))
            end
            return $T(tuple(data...))
        end
        $T(data::String) = $T(hex2bytes(data))

        # Create trivial identity constructors
        $T(hash::$T) = hash

        $(esc(:hash_like))(::$T, input) = $T($(esc(func))(input))
        $(esc(:verify))(hash::$T, input) = hash == hash_like(hash, input)
        push!(MULTIHASH_TYPES, $T)
    end
end

# Use that macro to define our MultiHash sub-types
@define_multi_hash("sha1", 20, SHA.sha1)
@define_multi_hash("sha256", 32, SHA.sha256)

function Base.parse(::Type{T}, hash::AbstractString) where {T <: MultiHash}
    if length(hash) != hash_length(T)*2
        throw(ArgumentError("Invalid length for $(hash_prefix(T)) hash: expected $(hash_length(T)*2), got $(length(hash))"))
    end
    if !all(isxdigit.(collect(hash)))
        throw(ArgumentError("Hash strings must be composed of hexadecimal digits only, got '$(hash)'"))
    end
    return T(hex2bytes(hash))
end

# Given a list of bytes, try to guess what kind of hash it is based on length alone
function MultiHash(hash::Union{NTuple{N, UInt8}, Vector{UInt8}}) where {N}
    for H in MULTIHASH_TYPES
        if length(hash) == hash_length(H)
            return H(hash)
        end
    end
    throw(ArgumentError("Unrecognizeable hash with length $(length(hash)): '$(bytes2hex(hash))'"))
end

# Given a string, see if it starts with one of our prefixes, and if so parse it
function MultiHash(hash::AbstractString)
    # First, check for explicit prefixes
    for H in MULTIHASH_TYPES
        prefix = hash_prefix(H)
        if startswith(hash, prefix)
            return parse(H, hash[length(prefix)+2:end])
        end
    end
    
    # If that didn't work, try to `hex2bytes()` it and try based on length:
    if !all(isxdigit.(collect(hash)))
        throw(ArgumentError("Hash strings must be composed of hexadecimal digits only, got '$(hash)'"))
    end
    return MultiHash(hex2bytes(hash))
end

end # module MultiHashParsing
