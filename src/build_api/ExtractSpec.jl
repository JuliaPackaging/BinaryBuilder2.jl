export ExtractSpec

struct ExtractSpec
    script::String
    products::Vector{AbstractProduct}

    # Name of the JLL package this extraction is destined for
    jll_name::String

    # The name used by `inter_deps` to refer to this `ExtractSpec`, as well as
    # by the `artifact_name` preference overload. Defaults to `jll_name`.
    name::String

    # Allows overriding the default choice for target platform
    target_spec::BuildTargetSpec
    platform::AbstractPlatform

    # If this extraction depends on others, list them here.
    inter_deps::Vector{String}

    function ExtractSpec(script, products, target_spec;
                         jll_name,
                         name = jll_name,
                         platform = target_spec.platform.target,
                         inter_deps = String[])
        return new(
            string(script),
            Vector{AbstractProduct}(products),
            String(jll_name),
            String(name),
            target_spec,
            platform,
            inter_deps,
        )
    end
end

"""
    check_unique_names(extract_specs::Vector{ExtractSpec})

Ensure that no two extractions share a name. Required so that extractions can
be meaningfully ID'd by `spec.inter_deps`.
"""
function check_unique_names(extract_specs::Vector{ExtractSpec})
    seen = Set{String}()
    for es in extract_specs
        if es.name ∈ seen
            throw(ArgumentError("Duplicate extraction name '$(es.name)'; each extraction must be named uniquely!"))
        end
        push!(seen, es.name)
    end
end

function default_extract_spec_generator(src_name::String, extract_script::String, products::Vector)
    products = Vector{AbstractProduct}(products)
    return (build_config, platform) -> begin
        return ExtractSpec[
            ExtractSpec(
                extract_script,
                products,
                get_default_target_spec(build_config);
                jll_name = src_name,
                platform,
                inter_deps = String[],
            ),
        ]
    end
end

function extract!(extract_specs::Vector{ExtractSpec},
                  build_result::BuildResult;
                  kwargs...)
    check_unique_names(extract_specs)
    specs_by_name = Dict(es.name => es for es in extract_specs)

    # Toposort our extract_specs
    sorted_extract_names = toposort(specs_by_name, e -> e.inter_deps)

    # Results for this build's extractions
    extract_results = Dict{String,ExtractResult}()

    # Sort extraction specs based on their dependencies
    for extract_name in sorted_extract_names
        extract_spec = specs_by_name[extract_name]
        extract_config = @auto_extract_kwargs ExtractConfig(
            build_result,
            extract_spec.script,
            extract_spec.products;
            jll_name = extract_spec.jll_name,
            target_spec = extract_spec.target_spec,
            platform = extract_spec.platform,
            inter_deps = Dict(name => extract_results[name] for name in extract_spec.inter_deps),
            kwargs...,
        )
        extract_result = @auto_extract_kwargs extract!(
            extract_config;
            kwargs...,
        )

        extract_results[extract_name] = extract_result
        # If something went wrong, break out immediately, the caller
        # will handle the error.
        if extract_result.status ∉ acceptable_statuses
            break
        end
    end
    return extract_results
end
