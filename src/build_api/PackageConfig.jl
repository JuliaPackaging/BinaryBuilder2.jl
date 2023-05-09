export PackageConfig, package!

struct PackageConfig
    # The name of the generated JLL; if not specified, defaults to `$(src_name)_jll`.
    # Note that by default we add `_jll` at the end, but this is not enforced in code!
    name::String

    # The list of successful extractions that we're going to combine
    # together into a single package
    extractions::Vector{ExtractResult}

    function PackageConfig(extractions::Vector{ExtractResult}; name::Union{AbstractString,Nothing} = nothing)
        if !isempty(extractions) && any(e.config.builds[1].name != extractions[1].config.builds[1].name for e in extractions)
            throw(ArgumentError("Cannot package extractions from different builds!"))
        end
        # We allow overriding the name, but default to `$(src_name)_jll`
        if name === nothing
            name = string(extractions[1].config.builds[1].config.src_name, "_jll")
        end
        if !Base.isidentifier(name)
            throw(ArgumentError("Package name '$(name)' is not a valid identifier!"))
        end
        return new(name, extractions)
    end    
end
