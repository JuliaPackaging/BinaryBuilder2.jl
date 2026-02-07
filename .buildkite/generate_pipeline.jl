#!/usr/bin/env julia

"""
Helper functions to generate Buildkite pipeline YAML files.

This module provides utilities to construct Buildkite pipeline configurations
programmatically with flexible grouping options by Julia version, architecture,
or subproject name.
"""

# Ensure YAML is available
using YAML

# ============================================================================
# Core Data Structures
# ============================================================================

"""
    BuildkiteStep

Represents a single Buildkite step with all its configuration.
"""
Base.@kwdef struct BuildkiteStep
    label::String
    command::Union{String, Vector{String}, Nothing} = nothing
    plugins::Union{Dict, Nothing} = nothing
    agents::Union{Dict, Nothing} = nothing
    soft_fail::Union{Bool, String, Nothing} = nothing
    timeout_in_minutes::Union{Int, Nothing} = nothing
    artifact_paths::Union{Vector{String}, Nothing} = nothing
    env::Union{Dict{String, String}, Nothing} = nothing
    key::Union{String, Nothing} = nothing
    depends_on::Union{String, Vector{String}, Nothing} = nothing
end

"""
    BuildkiteGroup

Represents a group of Buildkite steps.
"""
Base.@kwdef struct BuildkiteGroup
    label::String
    key::Union{String, Nothing} = nothing
    steps::Vector{BuildkiteStep} = BuildkiteStep[]
end

# ============================================================================
# Configuration
# ============================================================================

"""
    TestConfig

Configuration for a single test job.
"""
Base.@kwdef struct TestConfig
    subproject::String
    subproject_name::String
    julia_version::String
    arch::String
    soft_fail::Bool = false
end

# ============================================================================
# Step Builders
# ============================================================================

"""
    create_test_step(config::TestConfig) -> BuildkiteStep

Create a Buildkite step for running tests with the given configuration.
"""
function create_test_step(config::TestConfig)
    BuildkiteStep(
        label = ":julia: :linux: $(config.arch) Julia $(config.julia_version) - $(config.subproject_name)",
        plugins = Dict(
            "staticfloat/metahook" => Dict(
                "post-checkout" => """
                    git config --global user.email "buildkite@julialang.org"
                    git config --global user.name "Buildkite"
                    """
            ),
            "JuliaCI/julia#v1" => Dict(
                "version" => config.julia_version,
                "arch" => config.arch
            ),
            "JuliaCI/julia-test#v1" => Dict(
                "project" => config.subproject
            )
        ),
        agents = Dict(
            "queue" => "juliaecosystem",
            "os" => "linux",
            "sandbox_capable" => "true",
            "arch" => config.arch
        ),
        soft_fail = config.soft_fail,
        timeout_in_minutes = 120,
        artifact_paths = ["BinaryBuilderToolchains.jl/test/*-files.tar.gz"]
    )
end

# ============================================================================
# Grouping Strategies
# ============================================================================

"""
    GroupBy

Enumeration of grouping strategies.
"""
@enum GroupBy begin
    ByJuliaVersion
    ByArchitecture
    BySubproject
    NoGrouping
end

"""
    group_label(group_by::GroupBy, key::String) -> String

Generate a human-readable label for a group based on the grouping strategy.
"""
function group_label(group_by::GroupBy, key::String)
    if group_by == ByJuliaVersion
        return "Julia $key"
    elseif group_by == ByArchitecture
        return "Architecture: $key"
    elseif group_by == BySubproject
        return "Subproject: $key"
    else
        return key
    end
end

"""
    group_steps(steps::Vector{BuildkiteStep}, configs::Vector{TestConfig}, group_by::GroupBy) -> Vector

Group steps according to the specified strategy.
"""
function group_steps(steps::Vector{BuildkiteStep}, configs::Vector{TestConfig}, group_by::GroupBy)
    if group_by == NoGrouping
        return steps
    end
    
    # Create mapping from steps to configs
    @assert length(steps) == length(configs) "Steps and configs must have same length"
    
    # Group by the appropriate key
    groups = Dict{String, Vector{Tuple{BuildkiteStep, TestConfig}}}()
    for (step, config) in zip(steps, configs)
        key = if group_by == ByJuliaVersion
            config.julia_version
        elseif group_by == ByArchitecture
            config.arch
        elseif group_by == BySubproject
            config.subproject_name
        else
            error("Unknown grouping strategy: $group_by")
        end
        
        if !haskey(groups, key)
            groups[key] = Tuple{BuildkiteStep, TestConfig}[]
        end
        push!(groups[key], (step, config))
    end
    
    # Sort groups by key for consistent output
    sorted_keys = sort(collect(keys(groups)))
    
    # Convert to Buildkite group format
    result = []
    for key in sorted_keys
        group_dict = Dict(
            "group" => group_label(group_by, key),
            "key" => replace(lowercase("group-$key"), " " => "-", "." => "-"),
            "steps" => [step_to_dict(step) for (step, _) in groups[key]]
        )
        push!(result, group_dict)
    end
    
    return result
end

# ============================================================================
# Serialization
# ============================================================================

"""
    step_to_dict(step::BuildkiteStep) -> Dict

Convert a BuildkiteStep to a dictionary suitable for YAML serialization.
"""
function step_to_dict(step::BuildkiteStep)
    d = Dict{String, Any}()
    d["label"] = step.label
    
    if !isnothing(step.command)
        d["command"] = step.command
    end
    
    if !isnothing(step.plugins)
        d["plugins"] = step.plugins
    end
    
    if !isnothing(step.agents)
        d["agents"] = step.agents
    end
    
    if !isnothing(step.soft_fail)
        d["soft_fail"] = step.soft_fail
    end
    
    if !isnothing(step.timeout_in_minutes)
        d["timeout_in_minutes"] = step.timeout_in_minutes
    end
    
    if !isnothing(step.artifact_paths)
        d["artifact_paths"] = step.artifact_paths
    end
    
    if !isnothing(step.env)
        d["env"] = step.env
    end
    
    if !isnothing(step.key)
        d["key"] = step.key
    end
    
    if !isnothing(step.depends_on)
        d["depends_on"] = step.depends_on
    end
    
    return d
end

"""
    generate_pipeline(configs::Vector{TestConfig}; group_by::GroupBy = NoGrouping) -> Dict

Generate a complete Buildkite pipeline from test configurations.
"""
function generate_pipeline(configs::Vector{TestConfig}; group_by::GroupBy = NoGrouping)
    # Create steps
    steps = [create_test_step(config) for config in configs]
    
    # Group steps if requested
    if group_by == NoGrouping
        pipeline_steps = [step_to_dict(step) for step in steps]
    else
        pipeline_steps = group_steps(steps, configs, group_by)
    end
    
    return Dict("steps" => pipeline_steps)
end

"""
    write_pipeline(filename::String, pipeline::Dict)

Write a pipeline dictionary to a YAML file.
"""
function write_pipeline(filename::String, pipeline::Dict)
    YAML.write_file(filename, pipeline)
end

"""
    write_pipeline(io::IO, pipeline::Dict)

Write a pipeline dictionary to an IO stream as YAML.
"""
function write_pipeline(io::IO, pipeline::Dict)
    YAML.write(io, pipeline)
end

# ============================================================================
# Discovery Utilities
# ============================================================================

"""
    discover_subprojects(root_dir::String = ".") -> Vector{String}

Discover subprojects by finding directories with Project.toml files.
Excludes the 'docs' directory.
"""
function discover_subprojects(root_dir::String = ".")
    subprojects = String[]
    
    # Find all Project.toml files at depth 1 and 2
    for entry in readdir(root_dir, join=true)
        if isdir(entry)
            project_file = joinpath(entry, "Project.toml")
            if isfile(project_file)
                basename_entry = basename(entry)
                if basename_entry ∉ ["docs", ".buildkite"]
                    push!(subprojects, basename_entry)
                end
            end
        end
    end
    
    # Check root directory
    if isfile(joinpath(root_dir, "Project.toml"))
        push!(subprojects, ".")
    end
    
    return sort(subprojects)
end

"""
    subproject_display_name(subproject::String) -> String

Get a human-readable display name for a subproject.
"""
function subproject_display_name(subproject::String)
    if subproject == "."
        return "BinaryBuilder2.jl"
    else
        return subproject
    end
end

# ============================================================================
# High-Level API
# ============================================================================

"""
    generate_test_matrix(;
        julia_versions::Vector{String} = ["1"],
        architectures::Vector{String} = ["x86_64", "aarch64"],
        subprojects::Union{Vector{String}, Nothing} = nothing,
        root_dir::String = ".",
        nightly_soft_fail::Bool = true
    ) -> Vector{TestConfig}

Generate a matrix of test configurations for all combinations of Julia versions,
architectures, and subprojects.

# Arguments
- `julia_versions`: Julia versions to test (default: ["1"])
- `architectures`: CPU architectures to test (default: ["x86_64", "aarch64"])
- `subprojects`: Subprojects to test (default: auto-discover)
- `root_dir`: Root directory for subproject discovery (default: "..")
- `nightly_soft_fail`: Whether to allow nightly builds to fail (default: true)
"""
function generate_test_matrix(;
    julia_versions::Vector{String} = ["1"],
    architectures::Vector{String} = ["x86_64", "aarch64"],
    subprojects::Union{Vector{String}, Nothing} = nothing,
    root_dir::String = dirname(@__DIR__),
    nightly_soft_fail::Bool = true
)
    # Discover subprojects if not provided
    if isnothing(subprojects)
        subprojects = discover_subprojects(root_dir)
    end
    
    # Generate all combinations
    configs = TestConfig[]
    for julia_version in julia_versions
        for arch in architectures
            for subproject in subprojects
                soft_fail = (julia_version == "nightly" && nightly_soft_fail)
                config = TestConfig(
                    subproject = subproject,
                    subproject_name = subproject_display_name(subproject),
                    julia_version = julia_version,
                    arch = arch,
                    soft_fail = soft_fail
                )
                push!(configs, config)
            end
        end
    end
    
    return configs
end

"""
    main()

Main entry point for generating the pipeline. Can be customized based on
environment variables or command-line arguments.
"""
function main()
    # Parse command-line arguments
    group_by = NoGrouping
    output_file = nothing
    
    for arg in ARGS
        if arg == "--group-by-julia"
            group_by = ByJuliaVersion
        elseif arg == "--group-by-arch"
            group_by = ByArchitecture
        elseif arg == "--group-by-subproject"
            group_by = BySubproject
        elseif startswith(arg, "--output=")
            output_file = arg[10:end]
        end
    end
    
    # Generate test matrix
    configs = generate_test_matrix(
        julia_versions = ["1"],  # Can add "nightly" when ready
        architectures = ["x86_64", "aarch64"]
    )
    
    # Generate pipeline
    pipeline = generate_pipeline(configs; group_by = group_by)
    
    # Write to file or stdout
    if isnothing(output_file)
        write_pipeline(stdout, pipeline)
    else
        write_pipeline(output_file, pipeline)
        println(stderr, "Pipeline written to $output_file")
    end
end

# ============================================================================
# Execute main if run as script
# ============================================================================

if abspath(PROGRAM_FILE) == @__FILE__
    main()
end
