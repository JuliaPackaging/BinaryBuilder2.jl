
struct ExtractConfig
    # The build result we're packaging up
    build::BuildResult

    # The extraction script that we're using to copy build results out into our artifacts
    script::String

    # The products that this package will ensure are available
    products::Vector{<:AbstractProduct}

    # TODO: Add an `AuditConfig` field
    #audit::AuditConfig

    function ExtractConfig(build::BuildResult,
                           script::AbstractString,
                           products::Vector{<:AbstractProduct},
                           audit_config = nothing)
        return new(
            build,
            String(script),
            products,
            #audit_config,
        )
    end
end
