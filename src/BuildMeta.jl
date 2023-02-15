# Re-export some useful definitions from Base
export AbstractPlatform

# And then our exports
export BuildMeta, BuildConfig, BuildResult, ExtractConfig, ExtractResult, PackageConfig, PackageResult

const BUILD_HELP = (
    """
    Usage: build_tarballs.jl [target1,target2,...] [--help] [--verbose] [--debug=mode]
                             [--deploy=<repo>] [--register=<depot>] [--build-path=<dir>]
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

        --debug=<mode>      This causes a failed build to drop into an interactive shell
                            for debugging purposes.  `<mode>` can be one of:
                              - `error` drops you into the interactive shell only when
                                there is an error during the build, this is the default
                                when no mode is specified.
                              - `begin` stops the build at the beginning before any
                                command in the script is run.
                              - `end` stops the build at the end of the build script,
                                useful to inspect a successful build for which the
                                auditor or some other packaging step would fail.

        --deploy=<repo>     Deploy binaries and JLL wrapper code to a github release of
                            an autogenerated repository.  `repo` should be of the form
                            `"JuliaBinaryWrappers/Foo_jll.jl"`.  The default behavior
                            of deploying to the local `~/.julia/dev` directory only can
                            be explicitly requested by setting `<repo>` to `"local"`.
                            Note there is no way to _not_ deploy; a JLL package will
                            always be generated.  For testing, local deployment is
                            sufficient as the artifacts the generated JLL will reference
                            are already existent on the build machine, as they were just
                            built by BinaryBuilder.

        --register=<depot>  Register into the given depot.  By default, registers into
                            the first entry of `JULIA_DEPOT_PATH`, which is typically 
                            `~/.julia`.  Registration requires deployment to a non-
                            local target, as it must embed the URL that the deployed
                            JLL package is available at within the registry.

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

        --build-dir=<path>  Directory that holds in-progress builds.  Generally gets
                            cleaned up after a build completes.  Defaults to the value
                            `"\$(pwd())/build"`.

        --output-dir=<dir>  Directory that holds packaged tarball outputs.  Defaults to
                            the value `"\$(pwd())/products"`.

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
    parse_build_tarballs_args(ARGS::Vector{String})

Parse the arguments passed in to a `build_tarballs.jl` into a dictionary that can be
splatted into `BuildMeta()`.
"""
function parse_build_tarballs_args(ARGS::Vector{String})
    parsed_kwargs = Dict{Symbol,Any}()

    if check_flag!(ARGS, "--help")
        println(BUILD_HELP)
        exit(0)
    end

    # --verbose; simple boolean
    parsed_kwargs[:verbose] = check_flag!(ARGS, "--verbose")

    # This sets whether we drop into a debug shell on failure or not
    debug, debug_mode = extract_flag!(ARGS, "--debug", "error")
    if debug
        if debug_mode ∉ ("error", "begin", "end")
            throw(ArgumentError("Invalid choice for `debug_mode`: \"$(debug_mode)\""))
        end
        parsed_kwargs[:debug] = debug_mode
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

    # There is no option to not deploy, so ignore the first return value
    _, deploy_target = extract_flag!(ARGS, "--deploy", "local")
    parsed_kwargs[:deploy_target] = deploy_target

    # The depot we will register into
    register, register_path = extract_flag!(ARGS, "--register", Pkg.depots1())
    if register
        parsed_kwargs[:register_depot] = register_path
    end

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

    # Build/output directory locations
    build_dir, build_dir_path = extract_flag!(ARGS, "--build-dir")
    if build_dir
        parsed_kwargs[:build_dir] = build_dir_path
    end
    output_dir, output_dir_path = extract_flag!(ARGS, "--output-dir")
    if output_dir
        parsed_kwargs[:output_dir] = output_dir_path
    end

    # Slurp up the last argument as platforms
    if length(ARGS) == 1
        parse_platform(p::AbstractString) = p == "any" ? AnyPlatform() : parse(Platform, p; validate_strict=true)
        parsed_kwargs[:target_list] = parse_platform.(split(ARGS[1], ","))
    elseif length(ARGS) > 1
        throw(ArgumentError("Extraneous arguments to `build_tarballs.jl`: $(join([string("\"", x, "\"") for x in ARGS[2:end]], " "))"))
    end

    return parsed_kwargs
end

# Helper to convert SubStrings to Strings, but only if they're not `nothing`
string_or_nothing(x::AbstractString) = String(x)
string_or_nothing(::Nothing) = nothing

"""
    BuildConfig

This structure holds all of the inputs that are needed to generate a build of a software
project in the build environment.  Things such as the project name, the list of sources,
the build script, the dependencies, etc... are all listed within this structure.  Once
the user calls `build!()`, each `BuildConfig` will get a `BuildResult` packed into the
overall `BuildMeta` object.
"""
struct BuildConfig
    # The name of the package being built.  This is exported as an environment variable during build
    # so that internal tooling such as "install_license" can install into intelligent paths.
    src_name::String

    # The source version; this may not be what the resultant JLL gets published under, but it will
    # be recorded as metadata in the JLL itself.
    src_version::VersionNumber

    # Sources that we will build from (Git repositories, tarballs, directories on-disk, etc...)
    sources::Vector{<:AbstractSource}

    # Dependencies that must be installed in the build environment.
    # Contains host dependencies, target dependencies, and cross-dependencies (e.g. compilers).
    # Organized by installation prefix (e.g. `/usr/local` for host dependencies, `/opt/$(triplet)`
    # for cross-compilers, etc...)
    dep_trees::Dict{String,Vector{JLLSource}}

    # Flags that influence the build environment and the generated compiler wrappers
    allow_unsafe_flags::Bool
    lock_microarchitecture::Bool

    # Bash script that will perform the actual build itself
    script::String

    # The platform this build will target, both the user-requested
    # (possibly not-fully-concretized) as well as the fully-concretized
    # due to compiler ABI constraints.
    target::AbstractPlatform
    #concrete_target::AbstractPlatform

    function BuildConfig(src_name::AbstractString,
                         src_version::VersionNumber,
                         sources::Vector{<:AbstractSource},
                         script::AbstractString,
                         target::AbstractPlatform;
                         target_deps::Vector{<:JLLSource} = JLLSource[],
                         host_deps::Vector{<:JLLSource} = JLLSource[],
                         allow_unsafe_flags::Bool = false,
                         lock_microarchitecture::Bool = true,
                         toolchains = default_toolchains(),
                         )

        compilers = Set(compilers)
        cross_platform = CrossPlatform(
            Platform("x86_64", "linux"),
            target,
        )
        append!(host_deps, host_build_tools(cross_platform))

        # Construct our various trees of dependencies:
        dep_trees = Dict{String,Vector{JLLSource}}(
            # We will place our compilers at `/opt/$(gcc_triplet())`
            # This allows us to have multiple different compilers!
            "/opt/$(triplet(gcc_target(target)))" => compiler_deps(compilers, cross_platform),

            # Host dependencies get installed into `/usr/local` so they can be run natively
            "/usr/local" => host_deps,
            
            # Target dependencies are assumed to be 
            "/workspace/destdir" => target_deps,
        )

        # Now that we know which compilers we're building with, let's figure out our actual
        # platform that we will use to construct the build environment (this will strictly be
        # a valid sub-platform of the `target` given here).
        #concrete_target = BinaryBuilderBase.get_concrete_platform(target, shards)
        return new(
            String(src_name),
            src_version,
            sources,
            dep_trees,
            compilers,
            shards,
            allow_unsafe_flags,
            lock_microarchitecture,
            String(script),
            target,
            #concrete_target,
        )
    end
end

# Helper function to better control when we download all our deps
function prepare(config::BuildConfig)
    prepare(config.sources)
    for (prefix, deps) in config.dep_trees
        prepare(deps)
    end
end


"""
    BuildResult

A `BuildResult` represents a constructed build prefix; it contains the paths to the
binaries (typically within an artifact directory) as well as some metadata about the
audit passes and whatnot that ran upon the files.
"""
struct BuildResult
    # The config that this result was built from
    config::BuildConfig

    # The overall status of the build.  One of [:successful, :failed, :skipped]
    status::Symbol

    # The location of the build prefix on-disk (typically an artifact directory)
    # For a failed or skipped build, this may be empty or only partially filled.
    prefix::String

    # Logs that are generated from build invocations and audit passes.
    # Key name is an identifier for the operation, value is the log content.
    # Example: ("audit-libfoo-relink_to_rpath").
    logs::Dict{String,String}

    # These are `@info`/`@warn`/`@error` messages that get emitted during the build/audit
    # we may eventually want to make this more structured, e.g. organize them by audit
    # pass and whatnot.  These messages are not written out to disk during packaging.
    #msgs::Vector{Test.LogRecord}

    ## TODO: merge `logs` and `msgs` with a better, more structured logging facility?

    function BuildResult(config::BuildConfig,
                         status::Symbol,
                         prefix::AbstractString,
                         logs::Dict{AbstractString,AbstractString})
                         #msgs::Vector{Test.LogRecord})
        return new(
            config,
            status,
            String(prefix),
            Dict(String(k) => String(v) for (k, v) in logs),
            #msgs,
        )
    end
end

# Helper function for skipped builds
function BuildResult_skipped(config::BuildConfig)
    return BuildResult(
        config,
        :skipped,
        "/dev/null",
        Dict{String,String}(),
    )
end

# TODO: construct helper to reconstruct BuildResult objects from S3-saved tarballs

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

struct PackageResult
    # Link back to the originating Package Config
    config::PackageConfig

    # Overall status of the packaging.  One of :successful, :failed or :skipped
    status::Symbol

    # The version number this package result is getting published under
    # (may disagree with `src_version`).
    published_version::VersionNumber

    function PackageResult(config::PackageConfig,
                           status::Symbol,
                           published_version::VersionNumber)
        return new(
            config,
            status,
            published_version,
        )
    end
end

# Note that this helper still takes in the `published_version`, as that is
# potentially quite useful for static analysis to know.
function PackageResult_skipped(config::PackageConfig, published_version::VersionNumber)
    return PackageResult(
        config,
        :skipped,
        published_version,
    )
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
struct BuildMeta
    # Contains a list of builds; when you run build!() with arguments, it records
    # what the metadata for that build was in here.
    builds::Dict{BuildConfig,Union{Nothing,BuildResult}}

    # Contains a list of "extractions"; when you run `extract!()` with arguments, it
    # records the pieces that were generated here.
    extractions::Dict{ExtractConfig,Union{Nothing,ExtractResult}}

    # Contains a list of JLL packages; when you run `package!()` with arguments, it
    # records the pieces that were generated here.
    packages::Dict{PackageConfig,Union{Nothing,PackageResult}}

    ## Options that get toggled by the user through `ARGS`; see `BUILD_HELP`
    # `target_list` overrides a build recipe's built-in target specification.
    # An empty list does no overriding.
    target_list::Vector{Platform}
    verbose::Bool
    debug::Union{Nothing,String}

    # Most steps have a JSON representation that they can output, to allow us to
    # "trace" through a build and see what steps were run.  On Yggdrasil, we combine
    # this with the "dry run" mode, to allow us to generate a series of jobs.
    dry_run::Set{Symbol}
    json_output::Union{Nothing,IO}
    deploy_target::String
    register_depot::Union{Nothing,String}
    build_dir::String
    output_dir::String

    # Metadata about the version of BB used to build this thing
    bb_metadata::Dict

    function BuildMeta(;target_list::Vector{Platform} = Platform[],
                        verbose::Bool = false,
                        debug::Union{Nothing,AbstractString} = nothing,
                        json_output::Union{Nothing,AbstractString,IO} = nothing,
                        dry_run::Vector{Symbol} = Symbol[],
                        deploy_target::AbstractString = "local",
                        register_depot::Union{Nothing,AbstractString} = nothing,
                        build_dir::AbstractString = joinpath(pwd(), "build"),
                        output_dir::AbstractString = joinpath(pwd(), "products"),
                       )
        if debug !== nothing
            if debug ∉ ("begin", "end", "error")
                throw(ArgumentError("If `debug` is specified, it must be one of \"begin\", \"end\" or \"error\""))
            end
        end

        if deploy_target != "local" && (isempty(dirname(deploy_target)) || isempty(basename(deploy_target)))
            throw(ArgumentError("`deploy` must be of the form \"GithubUser/RepoName\", or \"local\""))
        end

        if isa(json_output, AbstractString)
            json_output = open(json_output, write=true)
        end

        if register_depot !== nothing
            if deploy_target == "local"
                throw(ArgumentError("Cannot register with a local deployment!"))
            end
        end

        return new(
            Dict{BuildConfig,BuildResult}(),
            Dict{ExtractConfig,ExtractResult}(),
            Dict{PackageConfig,PackageResult}(),
            target_list,
            verbose,
            string_or_nothing(debug),
            Set{Symbol}(dry_run),
            json_output,
            string_or_nothing(deploy_target),
            string_or_nothing(register_depot),
            build_dir,
            output_dir,
            Dict("bb_version" => get_bb_version())
        )
    end
end

"""
    BuildMeta(ARGS::Vector{String})

Convenience constructor that calls `parse_build_tarballs_args()` on `ARGS`.
"""
BuildMeta(ARGS::Vector{String}) = BuildMeta(;parse_build_tarballs_args(ARGS)...)

# TODO: Add serialization tools for all of these structures
