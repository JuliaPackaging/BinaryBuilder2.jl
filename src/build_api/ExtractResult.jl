
struct ExtractResult
    # Link back to the originating ExtractResult
    config::ExtractConfig

    # The overall status of the extraction.  One of :successful, :failed, :skipped.
    status::Symbol

    # Treehash that represents the packaged output for the given config
    # On a failed/skipped build, this may be the special all-zero artifact hash.
    artifact::Base.SHA1

    # Logs generated during this extraction (audit logs, mostly)
    logs::Dict{String,String}

    function ExtractResult(config::ExtractConfig, status::Symbol,
                              artifact::Base.SHA1, logs::Dict{AbstractString,AbstractString})
        return new(
            config,
            status,
            artifact,
            Dict(String(k) => String(v) for (k,v) in logs),
        )
    end
end


function ExtractResult_skipped(config::ExtractConfig)
    return ExtractResult(
        config,
        :skipped,
        Base.SHA1("0"^40),
        Dict{String,String}(),
    )
end
