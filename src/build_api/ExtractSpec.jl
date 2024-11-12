export ExtractSpec

struct ExtractSpec
    script::String
    products::Vector{AbstractProduct}

    # Allows overriding the default choice for target platform
    target_spec::BuildTargetSpec
    platform::AbstractPlatform

    # If this extraction depends on others, list them here.
    inter_deps::Vector{String}

    function ExtractSpec(script, products, target_spec; platform = target_spec.platform.target, inter_deps = String[])
        return new(
            string(script),
            Vector{AbstractProduct}(products),
            target_spec,
            platform,
            inter_deps,
        )
    end
end

function default_extract_spec_generator(src_name::String, extract_script::String, products::Vector)
    products = Vector{AbstractProduct}(products)
    return (build_config, platform) -> begin
        return Dict{String,ExtractSpec}(
            src_name => ExtractSpec(
                extract_script,
                products,
                get_default_target_spec(build_config);
                platform,
                inter_deps = String[],
            ),
        )
    end
end

function extract!(extract_specs::Dict{String,ExtractSpec},
                  build_result::BuildResult;
                  kwargs...)
    # Toposort our extract_specs
    sorted_extract_names = toposort(extract_specs, e -> e.inter_deps)

    # Results for this build's extractions
    extract_results = Dict{String,ExtractResult}()

    # Sort extraction specs based on their dependencies 
    for extract_name in sorted_extract_names
        extract_spec = extract_specs[extract_name]
        extract_config = @auto_extract_kwargs ExtractConfig(
            build_result,
            extract_spec.script,
            extract_spec.products;
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
