using TimerOutputs, Pkg

# And then our exports
export BuildMeta

const BUILD_HELP = (
    """
    Usage: build_tarballs.jl [target1,target2,...] [--help] [--verbose] [--debug=mode]
                             [--universe=<name>] [--deploy=<org>] [--register]
                             [--output-dir=<dir>] [--dry-run=<tags>] [--meta-json]

    Options:
        targets             By default `build_tarballs.jl` will build a tarball for every
                            target within the `platforms` variable.  To override this,
                            pass in a list of comma-separated target triplets for each
                            target to be built.  Note that this can be used to build for
                            platforms that are not listed in the default list of
                            platforms in the `build_tarballs.jl` script.

        --verbose           This streams compiler and setup code output to `stdout`
                            during the build, which can help track down issues in your
                            build script.

        --debug=<mode>      This causes a build to drop into an interactive shell for
                            debugging purposes.  `<mode>` is a comma-separated list of
                            one or more of the following triggers:
                              - `build-start`   -- just before the build script.
                              - `build-error`   -- just after a failed build script.
                              - `build-stop`    -- just after a build script.
                              - `extract-start` -- just before the extraction script.
                              - `extract-error` -- just after a failed extraction script.
                              - `extract-stop`  -- just after an extraction script.

                            Additionally, the following shorthands are available:
                              - `start` -- equivalent to `build-start,extract-start`
                              - `error` -- equivalent to `build-error,extract-error`
                              - `stop`  -- equivalent to `build-stop,extract-stop`

                            In all cases, exiting the shell will continue the build, but
                            in the case of an error, the build will then immediately end.
                            If `*-stop` is already specified, specifying `*-debug` has no
                            effect, as the debug shell will already be launched.
                            The default `<mode>` value is `error`.

        --universe=<name>   Register JLL wrapper code in the named universe.  Defaults
                            to creating a new arbitrarily-named universe.  Naming a
                            universe is most useful when stacking multiple build
                            invocations from disparate `build_tarballs.jl` scripts.

        --deploy=<org>      Deploy binaries and JLL wrapper code to a github release of
                            an autogenerated repository.  `org` should be a user or
                            organization name, such as `"JuliaBinaryWrappers"`.
                            The default behavior of deploying only to the `dev`
                            directory of the current universe can be explicitly
                            requested via `--deploy=local`.

        --register=<url>    Open a pull request against the given registry URL,
                            typically that of `General`.  Registration requires
                            deployment to a target, as it must embed the URL that the
                            deployed JLL package is available at within the registry.

        --dry-run=<tags>    Allows skipping various parts of the build pipeline.  Must be
                            a list of comma-separated tags, one of `build`, `extract`,
                            `package`, or `all`.  If no `tags` are specified, defaults to
                            `all`, which is equivalent to specifying all categories.
                            Note that specifying `build` implies `extract`, which in turn
                            implies `package`.

        --meta-json=<path>  Output a JSON representation of the given build.  Often used
                            in conjunction with `--dry-run` to get a description of what
                            would be built, without any products actually being listed.
                            Note that in the case of complicated `build_tarballs.jl` with
                            multiple builds, it may output multiple JSON objects.  If no
                            path is given, defaults to writing to standard output.

        --output-dir=<dir>  Directory that holds packaged tarball outputs.  Defaults to
                            the value `"\$(pwd())/products"`.

        --disable-cache     Disable usage of the build cache, forcing all builds to be
                            run no matter if they were previously run and cached.

        --help              Print out this message.

    Examples:
        julia --color=yes build_tarballs.jl --verbose
            This builds all tarballs, with colorized output.

        julia build_tarballs.jl x86_64-linux-gnu,i686-linux-gnu
            This builds two tarballs for the two platforms given, with a
            minimum of output messages.
    """
)

"""
    extract_flag!(args::Vector{String}, flag::String, val = nothing)

Search for flags of the form `--flag` or `--flag=value`
Return `(found, value)`, where `found` is `true` if the given `flag` is found
within `args`, `false` otherwise.  If the value is found, return the string
after the `=` sign, 
"""
function extract_flag!(args::Vector{String}, flag::String,
                       val::Union{String,Nothing} = nothing)
    for f in args
        if f == flag || startswith(f, string(flag, "="))
            # Check if it's just `--flag` or if it's `--flag=foo`
            if f != flag
                val = split(f, '=')[2]
            end

            # Drop this value from our args
            filter!(x -> x != f, args)
            return (true, val)
        end
    end
    return (false, val)
end

"""
    check_flag!(args::Vector{String}, flag::String)

Return `true` if `flag `is in `args`. Also, remove that flag from `args`
"""
check_flag!(args, flag) = extract_flag!(args, flag, nothing)[1]

"""
    parse_build_tarballs_args(ARGS::Vector{String})

Parse the arguments passed in to a `build_tarballs.jl` into a dictionary that can be
splatted into `BuildMeta()`.
"""
function parse_build_tarballs_args(ARGS::Vector{String})
    # Don't mutate the original!
    ARGS = copy(ARGS)

    parsed_kwargs = Dict{Symbol,Any}()

    if check_flag!(ARGS, "--help")
        println(BUILD_HELP)
        exit(0)
    end

    # --verbose; simple boolean
    parsed_kwargs[:verbose] = check_flag!(ARGS, "--verbose")

    # This sets whether we drop into a debug shell at various points in the build
    debug, debug_mode = extract_flag!(ARGS, "--debug", "error")
    if debug
        debug_modes = Set(split(debug_mode, ","))
        # Map some shorthands to their expanded forms
        shorthands = Dict(
            "start" => ["build-start", "extract-start"],
            "error" => ["build-error", "extract-error"],
            "stop" => ["build-stop", "extract-stop"],
        )
        for (shorthand, equivalences) in shorthands
            if shorthand ∈ debug_modes
                delete!(debug_modes, shorthand)
                for equivalence in equivalences
                    push!(debug_modes, equivalence)
                end
            end
        end
        parsed_kwargs[:debug_modes] = debug_modes
    end

    # Are we skipping building and just outputting JSON?
    meta_json, meta_json_file = extract_flag!(ARGS, "--meta-json")
    if meta_json
        if meta_json_file === nothing
            parsed_kwargs[:json_output] = stdout
        else
            parsed_kwargs[:json_output] = meta_json_file
        end
    end

    # The organization we deploy to
    _, deploy_org = extract_flag!(ARGS, "--deploy", nothing)
    parsed_kwargs[:deploy_org] = deploy_org

    # Get the universe name
    _, universe_name = extract_flag!(ARGS, "--universe", nothing)
    parsed_kwargs[:universe_name] = universe_name

    # Whether we're pushing our registration up into a registry or not
    parsed_kwargs[:register] = check_flag!(ARGS, "--register")

    # Dry run settings
    dry_run, dry_run_csv = extract_flag!(ARGS, "--dry-run", "all")
    if dry_run
        # Parse the given set of categories
        dry_run_categories = Symbol.(split(dry_run_csv, ","))

        # Ensure that we only have valid values in these dry run categories
        valid_categories = [:build, :extract, :package, :all]
        for d in dry_run_categories
            if d ∉ valid_categories
                throw(ArgumentError("Invalid dry_run setting '$(d)'; value values are: $(valid_categories)"))
            end
        end

        # If `:all` was passed, just set the parsed values to all valid possibilities
        if :all ∈ dry_run_categories
            dry_run_categories = valid_categories
        else
            # If `:build` was passed, that implies `:extract` and `:package`,
            # just like `:extract` implies `:package`.
            if :build ∈ dry_run_categories
                push!(dry_run_categories, :extract)
            end

            if :extract in dry_run_categories
                push!(dry_run_categories, :package)
            end
        end
        parsed_kwargs[:dry_run] = sort(collect(Set(dry_run_categories)))
    end

    parsed_kwargs[:disable_cache] = check_flag!(ARGS, "--disable-cache")

    # Slurp up the last argument as platforms
    if length(ARGS) == 1
        parsed_kwargs[:target_list] = parse.(AbstractPlatform, split(ARGS[1], ","))
    elseif length(ARGS) > 1
        throw(ArgumentError("Extraneous arguments to `build_tarballs.jl`: $(join([string("\"", x, "\"") for x in ARGS[2:end]], " "))"))
    end

    return parsed_kwargs
end

"""
    BuildMeta

This structure holds the metadata of a BinaryBuilder session including:

 - All build inputs as `BuildConfig` objects
 - All build trees as `BuildResult` objects
 - All extraction targets as `ExtractConfig` objects
 - All extracted artifacts as `ExtractResult` objects
 - All build outputs as `PackageConfig` objects
 - All generated JLLs as `PackageResult` objects

When constructed, global options (most commonly passed in on the command line through
`ARGS`) can be passed to the `BuildMeta` through a `BuildMeta(ARGS::Vector{String})`
parsing method, or directly through keyword arguments in the constructor.
"""
struct BuildMeta <: AbstractBuildMeta
    # Contains a list of builds; when you run build!() with arguments, it records
    # what the metadata for that build was in here.
    builds::Dict{BuildConfig,Union{Nothing,BuildResult}}

    # Contains a list of "extractions"; when you run `extract!()` with arguments, it
    # records the pieces that were generated here.
    extractions::Dict{ExtractConfig,Union{Nothing,ExtractResult}}

    # Contains a list of JLL packages; when you run `package!()` with arguments, it
    # records the pieces that were generated here.
    packagings::Dict{PackageConfig,Union{Nothing,PackageResult}}

    ## Options that get toggled by the user through `ARGS`; see `BUILD_HELP`
    # `target_list` provides a default set of platforms to build for,
    # it defaults to `supported_platforms()`.
    target_list::Vector{AbstractPlatform}
    verbose::Bool
    debug_modes::Set{String}

    # The universe we register into and deploy from
    universe::Universe

    # Our build cache, allowing us to skip builds (unless it is disabled)
    build_cache::BuildCache
    build_cache_disabled::Bool

    # Most steps have a JSON representation that they can output, to allow us to
    # "trace" through a build and see what steps were run.  On Yggdrasil, we combine
    # this with the "dry run" mode, to allow us to generate a series of jobs.
    dry_run::Set{Symbol}
    json_output::Union{Nothing,IO}
    register::Bool

    function BuildMeta(;target_list::Vector{<:AbstractPlatform} = AbstractPlatform[],
                        universe_name::Union{AbstractString,Nothing} = nothing,
                        deploy_org::Union{AbstractString,Nothing} = nothing,
                        verbose::Bool = false,
                        debug_modes = Set{String}(),
                        json_output::Union{Nothing,AbstractString,IO} = nothing,
                        disable_cache::Bool = false,
                        dry_run::Vector{Symbol} = Symbol[],
                        register::Bool = false,
                       )
        if !isa(debug_modes, Set)
            debug_modes = Set(debug_modes)
        end
        for mode in debug_modes
            if mode ∉ Set(["build-start",   "build-error",   "build-stop",
                           "extract-start", "extract-error", "extract-stop"])
                throw(ArgumentError("Invalid debug mode`: \"$(mode)\".  try `build-start`, `build-stop`, `extract-error`, etc..."))
            end
        end

        universe = Universe(
            something([universe_name], [])...;
            deploy_org,
            persistent=universe_name !== nothing,
        )

        if isa(json_output, AbstractString)
            json_output = open(json_output, write=true)
        end

        if register && deploy_org === nothing
            throw(ArgumentError("Cannot register with a local deployment!"))
        end

        return new(
            Dict{BuildConfig,BuildResult}(),
            Dict{ExtractConfig,ExtractResult}(),
            Dict{PackageConfig,PackageResult}(),
            Vector{AbstractPlatform}(target_list),
            verbose,
            debug_modes,
            universe,
            load_cache(),
            disable_cache,
            Set{Symbol}(dry_run),
            json_output,
            register,
        )
    end
end
AbstractBuildMeta(meta::BuildMeta) = meta

function build_cache_enabled(meta::BuildMeta)
    # If the user has specifically requested we not use the cache, return `false`
    if meta.build_cache_disabled
        return false
    end

    # If the user has requested any of these debugging modes, we can't use the
    # build cache, we have to run everything so that we can drop into the build environment.
    if any(("build-start", "extract-start", "build-end", "extract-end") ∈ meta.debug_modes)
        return false
    end

    return true
end

"""
    BuildMeta(ARGS::Vector{String})

Convenience constructor that calls `parse_build_tarballs_args()` on `ARGS`.
"""
BuildMeta(ARGS::Vector{String}) = BuildMeta(;parse_build_tarballs_args(ARGS)...)

function strip_jll_suffix(name)
    if endswith(name, "_jll")
        name = name[1:end-4]
    end
    return name
end
function get_package_result(meta::BuildMeta, name::String)
    criteria(config) = config.name == strip_jll_suffix(name)
    return meta.packagings[only(filter(criteria, keys(meta.packagings)))]
end

function get_extract_result(meta::BuildMeta, src_name::String, platform::AbstractPlatform = AnyPlatform())
    criteria(config) = config.build.config.src_name == src_name && platforms_match(config.platform, platform)
    return meta.extractions[only(filter(criteria, keys(meta.extractions)))]
end

function get_build_result(meta::BuildMeta, src_name::String)
    criteria(config) = config.src_name == src_name
    return meta.builds[only(filter(criteria, keys(meta.builds)))]
end

# TODO: Add serialization tools for all of these structures
