"""
    insert_PATH!(env::Dict, pre_post::Symbol, new_paths::Vector{String})

Given a set of new elements to put onto `PATH`, append them either at
the end of the given path (`pre_post == :POST`) or at the beginning
(`pre_post == :PRE`).
"""
function insert_PATH!(env::Dict{String,String},
                      pre_post::Symbol,
                      new_paths::Vector{<:AbstractString};
                      varname::String = "PATH",
                      pathsep::String = ":")
    # Get old PATH
    PATH = split(get(env, varname, ""), pathsep)

    # Add our new elements
    if pre_post == :PRE
        prepend!(PATH, new_paths)
    elseif pre_post == :POST
        append!(PATH, new_paths)
    else
        throw(ArgumentError("Invalid `pre_post` value '$(pre_post)'"))
    end

    # Drop empty elements
    filter!(!isempty, PATH)

    # Update env
    env[varname] = join(PATH, pathsep)
    return env
end
insert_PATH!(env::Dict{String,String}, pre_post::Symbol, path_element::AbstractString; kwargs...) = insert_PATH!(env, pre_post, [path_element]; kwargs...)
