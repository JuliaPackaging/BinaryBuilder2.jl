using KeywordArgumentExtraction
export build_tarballs, BuildError, run_build_tarballs, extract_build_tarballs

struct BuildError <: Exception
    message::String
    result::Union{BuildResult,ExtractResult,PackageResult}
end

function Base.showerror(io::IO, be::BuildError)
    stage_name(::BuildResult) = "build"
    stage_name(::ExtractResult) = "extract"
    stage_name(::PackageResult) = "package"

    println("BuildError ($(stage_name(be.result))): $(be.message)")
end


"""
    get_default_meta()

Return the 'default' `BuildMeta` object.  Typically, this is done by
parsing `ARGS`, however `with_default_meta()` can override the meta
object that is returned here.  This is used by `run_build_tarballs()`
to force the usage of a particular `meta` object.
"""
function get_default_meta()
    if _default_meta[] === nothing
        _default_meta[] = BuildMeta(;parse_build_tarballs_args(ARGS)...)
    end
    return _default_meta[]
end
const _default_meta = Ref{Union{Nothing,AbstractBuildMeta}}(nothing)
function with_default_meta(f::Function, meta::AbstractBuildMeta)
    old_default_meta = _default_meta[]
    try
        _default_meta[] = meta
        f()
    finally
        _default_meta[] = old_default_meta
    end
end

function make_BuildError(message, result)
    # If we're being run in an interactive context, and there's no `meta` in `Main`,
    # save the `meta` of this result out to `Main` as well, as sometimes getting the
    # `result` from the exception can be tricky.
    if isinteractive() && !isdefined(Main, :meta)
        @warn("build_tarballs() errored out; `meta` exported for use in the REPL")
        Core.eval(Main, :(global meta))
        Main.meta = AbstractBuildMeta(result)
    end
    return BuildError(message, result)
end

function toposort(data::Dict{K}, get_dep_keys::Function) where {K}
    keys_by_length = sort(collect(keys(data)), by=key -> length(get_dep_keys(data[key])))
    sorted = K[]

    num_elements = length(data)
    for _ in 1:num_elements
        # Early-exit
        if length(sorted) == num_elements
            break
        end

        to_delete = Int[]
        for (idx, key) in enumerate(keys_by_length)
            if all(dep ∈ sorted for dep in get_dep_keys(data[key]))
                push!(sorted, key)
                push!(to_delete, idx)
            end
        end
        deleteat!(keys_by_length, to_delete)
    end
    if length(sorted) != num_elements
        unsatisfied = setdiff(keys(data), sorted)
        for jll in unsatisfied
            missing_deps = setdiff(get_dep_keys(data[jll]), sorted)
            @error("Unsatisfied!", jll, missing_deps)
        end
        throw(ArgumentError("Unable to topologically sort, '$(collect(unsatisfied))' contain unsatisfiable dependencies!"))
    end
    return sorted
end

# These are the `Result` statuses that do not cause a `BuildError`
const acceptable_statuses = (:success, :skipped, :cached)

function build_tarballs(src_name::String,
                        src_version::Union{String,VersionNumber},
                        sources::Vector,
                        script::String;
                        products::Vector = [],
                        meta::AbstractBuildMeta = get_default_meta(),

                        # By default, we have a single extraction named `src_name`
                        # that uses `extract_script` and get packaged into a single JLL, also named `src_name`.
                        extract_script = raw"extract ${prefix}/*",
                        extract_spec_generator::Function = default_extract_spec_generator(
                            src_name,
                            extract_script,
                            products,
                        ),
                        jll_extraction_map::Dict{String,Vector{String}} = Dict(src_name => [src_name]),

                        # Platform control
                        host::AbstractPlatform = default_host(),
                        platforms::Vector = supported_platforms(),
                        ignore_meta_target_list::Bool = false,
                        package_jll::Bool = true,

                        # Toolchain arguments; note that these are ignored
                        # if `spec_generator` is specified.
                        target_dependencies::Vector = [],
                        host_dependencies::Vector = [],
                        target_toolchains::Vector = [CToolchain(), CMakeToolchain()],
                        host_toolchains::Vector = [CToolchain(), CMakeToolchain(), HostToolsToolchain()],
                        build_spec_generator::Function = default_build_spec_generator(;
                            target_dependencies,
                            target_toolchains,
                            host_dependencies,
                            host_toolchains,
                            cross_compiler = isa(first(platforms), CrossPlatform)
                        ),
                        
                        eager_cleanup::Bool = true,
                        kwargs...)
    @ensure_all_kwargs_consumed_header()
    # Ensure that our vectors can be properly typed
    sources = Vector{AbstractSource}(sources)
    target_dependencies = Vector{ConvenienceSource}(target_dependencies)
    host_dependencies = Vector{ConvenienceSource}(host_dependencies)
    platforms = Vector{AbstractPlatform}(platforms)

    # By default, we always take the `meta.target_list` as the most
    # important, as the user should be able to override the platform list
    # if one is specified on the command-line.
    if !ignore_meta_target_list
        if !isempty(meta.target_list)
            platforms = meta.target_list
        end
    end

    # If any of our platforms are a `CrossPlatform`, all of them must be.
    canadian_platies = isa.(platforms, (CrossPlatform,))
    if any(canadian_platies) && !all(canadian_platies)
        throw(ArgumentError("Either all `platforms` must be `CrossPlatform`s, or none may be."))
    end
    build_error = nothing

    # First, build for all platforms
    extract_results = Dict{String,Vector{ExtractResult}}()
    cleanup_tasks = Task[]
    for platform in platforms
        build_config = @auto_extract_kwargs BuildConfig(
            meta,
            src_name,
            src_version,
            sources,
            build_spec_generator(host, platform),
            script;
            host,
            kwargs...,
        )

        extract_specs = extract_spec_generator(build_config, platform)
        # Ensure that all JLL names match up
        for (jll_name, extraction_names) in jll_extraction_map
            for extraction_name in extraction_names
                if extraction_name ∉ keys(extract_specs)
                    throw(ArgumentError("JLL '$(jll_name)' uses extraction '$(extraction_name)' that does not exist in `extract_specs`!"))
                end
            end
        end

        # Ensure that there are no "unused" extractions:
        for extraction_name in keys(extract_specs)
            if !any(extraction_name ∈ extraction_names for extraction_names in values(jll_extraction_map))
                throw(ArgumentError("Extraction '$(extraction_name)' not used by any JLLs!"))
            end
        end

        build_result = @auto_extract_kwargs build!(
            build_config;
            extract_arg_hints = [(es.script, es.products) for es in values(extract_specs)],
            kwargs...,
        )
        if build_result.status ∉ acceptable_statuses
            if build_result.status == :failed
                build_error = make_BuildError("Build script failed", build_result)
            elseif build_result.status == :errored
                build_error = make_BuildError("Unknown build error", build_result)
            else
                build_error = make_BuildError("Unexpected BuildResult status :$(build_result.status)", build_result)
            end
            # break out of `for` loop
            break
        end

        build_extract_results = extract!(extract_specs, build_result; kwargs...)
        for (extract_name, extract_result) in build_extract_results
            if extract_result.status ∉ acceptable_statuses
                if extract_result.status == :failed
                    build_error = make_BuildError("Extract script failed", extract_result)
                elseif extract_result.status == :errored
                    build_error = make_BuildError("Unknown extraction error", extract_result)
                else
                    build_error = make_BuildError("Unexpected ExtractResult status :$(extract_result.status)", extract_result)
                end
                # break out of inner `for` loop, will break out of outer one a little farther down
                break
            end
            if !haskey(extract_results, extract_name)
                extract_results[extract_name] = ExtractResult[]
            end
            push!(extract_results[extract_name], extract_result)
        end

        # In the background, cleanup the previous build result
        if eager_cleanup
            push!(cleanup_tasks, Threads.@spawn cleanup(build_result))
        end
        # Break out of outer `for` loop if an extraction failed
        if build_error !== nothing
            break
        end
    end

    if build_error === nothing
        # Take those extractions, and group them together into packages
        package_results = []
        function get_jll_deps(extract_names)
            jll_dep_names = String[]
            for extract_name in extract_names
                # This `first()` just completely ignores the possibility
                # that different platforms might have different dependencies
                config = first(extract_results[extract_name]).config
                append!(jll_dep_names, filter(d -> d ∈ keys(jll_extraction_map), keys(config.inter_deps)))
            end
            return jll_dep_names
        end
        jll_packaging_order = toposort(jll_extraction_map, get_jll_deps)
        for jll_name in jll_packaging_order
            # Because we're packaging in topo-sorted order, we know that
            # all extra dependencies will be availalbe in `package_results`.
            extra_deps = PackageSpec[]
            for dep in get_jll_deps(jll_extraction_map[jll_name])
                push!(extra_deps, PackageSpec(
                    only(filter(pr -> pr.config.name == dep, package_results))
                ))
            end

            package_config = @auto_extract_kwargs PackageConfig(
                Dict(name => extract_results[name] for name in jll_extraction_map[jll_name]);
                jll_name,
                extra_deps,
                kwargs...,
            )
            if package_jll
                package_result = package!(package_config)
                if package_result.status ∉ acceptable_statuses
                    build_error = make_BuildError("Unknown packaging error", package_result)
                    # break out of `for` loop
                    break
                end
            else
                package_result = PackageResult_skipped(package_config)
            end
            push!(package_results, package_result)
        end
    end

    save_cache(meta.build_cache)
    wait.(cleanup_tasks)

    # Only do this check if we didn't run into some kind of error, because if we did,
    # we may not have traveled through to all the codepaths that would have consumed kwargs.
    if build_error === nothing
        @ensure_all_kwargs_consumed_check(kwargs)
    else
        throw(build_error)
    end
    return meta
end

# For those that like to use keyword arguments to name everything
function build_tarballs(;src_name::String,
                         src_version::Union{String,VersionNumber},
                         sources::Vector,
                         script::String,
                         kwargs...)
    return build_tarballs(
        src_name,
        src_version,
        sources,
        script;
        kwargs...
    )
end

"""
    run_build_tarballs(meta::AbstractBuildMeta, build_tarballs_path::String; dry_run::Bool = false)

Helper function to evaluate a `build_tarballs.jl` script within a new anonymous module.
Uses `with_default_meta()` to set the default `meta` for use inside of the included
script, however if the included script explicitly creates its own `BuildMeta` object
without using the default constructor, you may not be able to get at the built objects,
so try to avoid doing that in any script you want to use this function with.

The `dry_run` keyword argument exists as a convenient way to override the `dry_run`
parameter inside of `meta`.
"""
function run_build_tarballs(meta::AbstractBuildMeta, build_tarballs_path::AbstractString, args::Vector{String} = String[]; dry_run::Bool = false)
    build_tarballs_path = abspath(build_tarballs_path)
    # If `dry_run` is set, we need to toggle `dry_run` in `meta`, but only
    # for the duration of this call:
    old_dry_run = copy(meta.dry_run)
    if dry_run
        empty!(meta.dry_run)
        push!.((meta.dry_run,), ("build", "extract", "package"))
    end
    old_ARGS = copy(ARGS)
    empty!(ARGS)
    append!(ARGS, args)
    try
        cd(dirname(build_tarballs_path)) do
            with_default_meta(meta) do
                m = Module()
                Core.eval(m, quote
                    eval(x) = Core.eval($m, x)
                    include(f) = Core.include($m, f)
                end)
                Core.include(m, build_tarballs_path)
            end
        end
    finally
        empty!(meta.dry_run)
        # Can't use `append!()` because this is a `Set`
        push!.((meta.dry_run,), old_dry_run)
        empty!(ARGS)
        append!(ARGS, old_ARGS)
    end
end

"""
    extract_build_tarballs(package_config::PackageConfig)
    extract_build_tarballs(package_result::PackageResult)

This analyzes the information embedded within the provided `PackageConfig`, determines if
it could have possibly come from a single `build_tarballs()` call, and if it could have,
returns a dict of the arguments to be passed to a `build_tarballs()` call to replicate
the build.

One exception to the faithful recreation is the `dry_run` property of the `BuildMeta` the
`build_tarballs()` call will create; because this function is often used in conjunction
with `run_build_tarballs(build_tarballs_path; ARGS=["--dry-run"])` to parse out the build
arguments of another `build_tarballs.jl` script without actually runnin the build.  Due
to this, the `dry_run` property is always disabled.
"""
function extract_build_tarballs(package_config::PackageConfig)
    # Explore tree of extractions/builds, ensure that all important settings are the same:
    extract_configs = ExtractConfig[]
    for (name, extractions) in package_config.named_extractions
        for extraction in extractions
            push!(extract_configs, extraction.config)
        end
    end

    # Try to have consistent failure messages
    fail_out(msg) = throw(ArgumentError("Cannot extract build_tarballs(): $(msg)"))

    for extract_config in extract_configs[2:end]
        # First, check to make sure the extract configs are all identical
        for prop in (:script, :products)
            if getproperty(extract_config, prop) != getproperty(extract_configs[1], prop)
                fail_out("ExtractionConfig objects do not agree on '$(prop)' property!")
            end
        end

        # Next, check to make sure the build configs are all identical
        build_config = extract_config.build.config
        build_config1 = extract_configs[1].build.config
        for prop in (:src_name, :src_version, :script)
            if getproperty(build_config, prop) != getproperty(build_config1, prop)
                fail_out("BuildConfig objects do not agree on '$(prop)' property!")
            end
        end

        # Special checks on dependencies
        source_prefixes = Dict(
            "source" => config -> config.source_trees[source_prefix()],
            "host" => config -> config.source_trees[host_prefix()],
        )
        for (name, getter) in source_prefixes
            if getter(build_config) != getter(build_config1)
                fail_out("BuildConfig objects do not match on $(name) dependencies!")
            end
        end
    end

    # Check that all extraction's platforms are the builds' platforms
    for extract_config in extract_configs
        build_platform = get_default_target_spec(extract_config.build.config).platform.target
        if target_if_crossplatform(extract_config.platform) != build_platform
            fail_out("Extract and Build configs do not match on platform!")
        end
    end

    # Once we're convinced that everything matches up, extract all the various pieces
    # necessary to fill out all `build_tarballs()` arguments:
    extract_config = first(extract_configs)
    build_config = extract_config.build.config
    build_spec_dict = Dict(extract_config.platform => extract_config.build.config.target_specs for extract_config in extract_configs)
    host_spec = get_host_target_spec(build_config)

    # Do not inherit `--dry-run` modes
    meta = AbstractBuildMeta(build_config)
    empty!(meta.dry_run)

    return Dict{Symbol,Any}(
        :src_name => build_config.src_name,
        :src_version => build_config.src_version,
        :sources => build_config.source_trees[source_prefix()],
        :script => build_config.script,
        :products => extract_config.products,
        :meta => meta,
        :platforms => getproperty.(extract_configs, :platform),
        :build_spec_generator => (host, platform) -> build_spec_dict[platform],
        :host => host_spec.platform.host,
        #:extract_specs => extract_config.script,
        #:jll_name => package_config.name,
        :version_series => VersionNumber(package_config.version.major, package_config.version.minor),
        :julia_compat => package_config.julia_compat,
    )
end
extract_build_tarballs(result::PackageResult) = extract_build_tarballs(result.config)

"""
    extract_build_tarballs(packagings::Dict{PackageConfig,PackageResult})

Helper for running `extract_build_tarballs(run_build_tarballs(path; ARGS=["--dry-run"]))`
"""
function extract_build_tarballs(packagings::Dict{PackageConfig,<:Union{Nothing,PackageResult}})
    if length(packagings) == 0
        throw(ArgumentError("No packagings to extract a build_tarballs argument list from!"))
    end
    if length(packagings) != 1
        throw(ArgumentError("Cannot guess which packaging to analyze; manually select one!"))
    end
    return extract_build_tarballs(only(keys(packagings)))
end
AbstractBuildMeta(packagings::Dict{PackageConfig,<:Union{Nothing,PackageResult}}) = AbstractBuildMeta(first(keys(packagings)))

function runshell(platform::CrossPlatform;
                  target_specs::Vector = apply_spec_plan(make_target_spec_plan(), platform.host, platform.target),
                  meta = BuildMeta(),
                  kwargs...)
    config = BuildConfig(
        meta,
        "test",
        v"1.0.0",
        [],
        target_specs,
        "",
    )
    try
        runshell(config; kwargs...)
    finally
        # Eagerly cleanup our universe
        cleanup(meta.universe)
    end
end
runshell(platform::Platform; kwargs...) = runshell(CrossPlatform(BBHostPlatform() => platform); kwargs...)
runshell(triplet::String; kwargs...) = runshell(parse(Platform, triplet); kwargs...)
