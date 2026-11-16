using JLLGenerator: JLLGenerator, generate_toml_dict, parse_toml_dict
export RuntimeRequirement, RuntimeRequirements

"""
    RuntimeRequirement{T}

One runtime requirement of a prefix: `value` is what `file` (relative to the
prefix) needs from the runtime it gets loaded into, and `source` names what
records that need within `file`, e.g. the symbol version `"GLIBC_2.17"`, the
`DT_NEEDED` entry `"libgfortran.so.5"` or the load command `"LC_BUILD_VERSION"`.
"""
struct RuntimeRequirement{T}
    value::T
    file::String
    source::String
end

# `v"2.17.0"` -> `"2.17"`
short_version(v::VersionNumber) = v.patch == 0 ? "$(v.major).$(v.minor)" : string(v)

function Base.show(io::IO, r::RuntimeRequirement)
    print(io, isa(r.value, VersionNumber) ? short_version(r.value) : r.value, " (", r.file, ": ", r.source, ")")
end

"""
    RuntimeRequirements

The runtime requirements of all binary objects in a prefix, as recorded by
`record_runtime_requirements!()`.  Each field holds the largest requirement over
the whole prefix, or `nothing` if no binary object has one:

- `libstdcxx`: the oldest `libstdc++.so.6` release (as its shared library version,
  e.g. `v"6.0.32"`) that defines every `GLIBCXX_*` and `CXXABI_*` symbol version
  needed from `libstdc++.so.6`.
- `glibcxx`, `cxxabi`: the largest `GLIBCXX_*` and `CXXABI_*` symbol versions needed
  from `libstdc++.so.6`, e.g. `v"3.4.32"` for `GLIBCXX_3.4.32`.
- `unknown_libstdcxx`: every symbol version needed from `libstdc++.so.6` that no known
  libstdc++ release defines, as `RuntimeRequirement{String}`s whose `value` is the
  symbol version.  These do not contribute to `libstdcxx`.
- `glibc`: the largest `GLIBC_*` symbol version needed from any library, e.g. `v"2.17"`.
- `libgfortran`: every `libgfortran` major version linked against (via `DT_NEEDED` or
  `LC_LOAD_DYLIB`), one entry per distinct major version, sorted.
- `macos`: the largest minimum macOS version (from `LC_BUILD_VERSION` or
  `LC_VERSION_MIN_MACOSX`) of any Mach-O file, e.g. `v"10.10"`.
- `freebsd`: the largest `FBSD_*` symbol version needed from any library, e.g.
  `v"1.7"` for `FBSD_1.7`.
"""
mutable struct RuntimeRequirements
    libstdcxx::Union{Nothing,RuntimeRequirement{VersionNumber}}
    glibcxx::Union{Nothing,RuntimeRequirement{VersionNumber}}
    cxxabi::Union{Nothing,RuntimeRequirement{VersionNumber}}
    unknown_libstdcxx::Vector{RuntimeRequirement{String}}
    glibc::Union{Nothing,RuntimeRequirement{VersionNumber}}
    libgfortran::Vector{RuntimeRequirement{Int}}
    macos::Union{Nothing,RuntimeRequirement{VersionNumber}}
    freebsd::Union{Nothing,RuntimeRequirement{VersionNumber}}
end

RuntimeRequirements() = RuntimeRequirements(
    nothing, nothing, nothing, RuntimeRequirement{String}[],
    nothing, RuntimeRequirement{Int}[], nothing, nothing,
)

const RUNTIME_REQUIREMENT_FIELDS = fieldnames(RuntimeRequirements)

function Base.:(==)(a::RuntimeRequirements, b::RuntimeRequirements)
    return all(getfield(a, f) == getfield(b, f) for f in RUNTIME_REQUIREMENT_FIELDS)
end
function Base.hash(reqs::RuntimeRequirements, h::UInt)
    for f in RUNTIME_REQUIREMENT_FIELDS
        h = hash(getfield(reqs, f), h)
    end
    return hash(RuntimeRequirements, h)
end

function Base.show(io::IO, reqs::RuntimeRequirements)
    println(io, "Runtime requirements:")
    for f in RUNTIME_REQUIREMENT_FIELDS
        v = getfield(reqs, f)
        if v === nothing || (isa(v, Vector) && isempty(v))
            continue
        end
        if isa(v, Vector)
            println(io, "  -> $(f): ", join(string.(v), ", "))
        else
            println(io, "  -> $(f): ", v)
        end
    end
end

# `raise(current, value, file, source)`: whichever of `current` and the new requirement is larger
function raise(current::Union{Nothing,RuntimeRequirement{T}}, value::T, file::String, source::String) where {T}
    if current === nothing || value > current.value
        return RuntimeRequirement{T}(value, file, source)
    end
    return current
end

toml_value(v::VersionNumber) = string(v)
toml_value(v::Union{Int,String}) = v
parse_toml_value(::Type{VersionNumber}, v) = VersionNumber(v)
parse_toml_value(::Type{T}, v) where {T <: Union{Int,String}} = T(v)

function JLLGenerator.generate_toml_dict(r::RuntimeRequirement)
    return Dict{String,Any}("value" => toml_value(r.value), "file" => r.file, "source" => r.source)
end
function JLLGenerator.parse_toml_dict(::Type{RuntimeRequirement{T}}, d) where {T}
    return RuntimeRequirement{T}(parse_toml_value(T, d["value"]), d["file"], d["source"])
end

function JLLGenerator.generate_toml_dict(reqs::RuntimeRequirements)
    d = Dict{String,Any}()
    for f in RUNTIME_REQUIREMENT_FIELDS
        v = getfield(reqs, f)
        if isa(v, Vector)
            if !isempty(v)
                d[string(f)] = generate_toml_dict.(v)
            end
        elseif v !== nothing
            d[string(f)] = generate_toml_dict(v)
        end
    end
    return d
end

function JLLGenerator.parse_toml_dict(::Type{RuntimeRequirements}, d)
    reqs = RuntimeRequirements()
    for (f, FT) in zip(RUNTIME_REQUIREMENT_FIELDS, fieldtypes(RuntimeRequirements))
        haskey(d, string(f)) || continue
        if FT <: Vector
            setfield!(reqs, f, [parse_toml_dict(eltype(FT), x) for x in d[string(f)]])
        else
            setfield!(reqs, f, parse_toml_dict(Base.nonnothingtype(FT), d[string(f)]))
        end
    end
    return reqs
end
