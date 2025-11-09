using JLLGenerator, StyledStrings
export PassResult, AuditResult, success

struct PassResult
    # One of `:success`, `:warn` or `:fail`
    status::Symbol

    # An identifier, usually the file being audited
    identifier::String

    # Extra message describing the result, if any.
    message::Union{Nothing,String}
end

struct AuditResult
    scan::ScanResult

    # These contain the results of our passes over the prefix
    pass_results::Dict{String,Vector{PassResult}}

    # These contain the learned interdependency structure of the libraries
    jll_lib_products::Vector{JLLLibraryProduct}
end

Base.success(ar::AuditResult) = success(ar.pass_results)
function Base.success(pass_results::Dict{String,Vector{PassResult}})
    for (name, results) in pass_results
        for result in results
            if result.status != :success
                return false
            end
        end
    end
    return true
end

function status_style(status::Symbol)
    return Dict{Symbol,Symbol}(
        :success => :green,
        :fail => :red,
        :warn => :yellow,
    )[status]
end

Base.show(io::IO, ar::AuditResult) = show(io, ar.pass_results)
function Base.show(io::IO, pass_results::Dict{String,Vector{PassResult}})
    println(io, "Audit results:")
    for (name, results) in pass_results
        println(io, "  -> $(name) ($(length(results)) entries)")
        for result in results
            color = status_style(result.status)
            print(io, styled"      -> [{$(color):$(result.status)}] $(result.identifier)")
            if result.message !== nothing
                println(io, ": ", result.message)
            else
                println(io)
            end
        end
    end
end

function push_result!(pass_results::Dict{String,Vector{PassResult}}, pass_name::String, status::Symbol, identifier::String, message::Union{Nothing,String} = nothing)
    if status ∉ (:success, :warn, :fail)
        throw(ArgumentError("Invalid status '$(status)' for audit result '$(identifier)'"))
    end

    if !haskey(pass_results, pass_name)
        pass_results[pass_name] = PassResult[]
    end
    push!(pass_results[pass_name], PassResult(status, identifier, message))
    return nothing
end
