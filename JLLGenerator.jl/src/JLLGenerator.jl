module JLLGenerator

using Pkg, MultiHashParsing, StructEquality, TOML, SHA, Reexport, LicenseCheck
import Base: UUID
@reexport using BinaryBuilderPlatformExtensions

export JLLInfo, JLLBuildInfo, JLLSourceRecord, JLLArtifactSource, JLLLibraryDep,
       AbstractJLLProduct, JLLExecutableProduct, JLLFileProduct, JLLLibraryProduct,
       JLLPackageDependency, JLLArtifactBinding, AbstractProducts, JLLBuildLicense,
       generate_jll, generate_toml_dict, parse_toml_dict

include("RTLD_flags.jl")
include("PkgCompatHacks.jl")
include("LicenseTexts.jl")

# Helper function for creating empty typed arrays
empty_convert(T, x) = isempty(x) ? T[] : x

"""
    AbstractJLLProduct

JLLProducts are similar to those found in the `BinaryBuilderProducts` package, but
optimized to only hold the bare information necessary to generate a JLL package.
"""
abstract type AbstractJLLProduct; end

struct JLLExecutableProduct <: AbstractJLLProduct
    varname::Symbol
    path::String
end

function generate_toml_dict(ep::JLLExecutableProduct)
    return Dict(
        "type" => "executable",
        "name" => string(ep.varname),
        "path" => ep.path,
    )
end
function parse_toml_dict(::Type{JLLExecutableProduct}, d)
    return JLLExecutableProduct(
        Symbol(d["name"]),
        d["path"],
    )
end

struct JLLFileProduct <: AbstractJLLProduct
    varname::Symbol
    path::String
end

function generate_toml_dict(fp::JLLFileProduct)
    return Dict(
        "type" => "file",
        "name" => string(fp.varname),
        "path" => fp.path,
    )
end
function parse_toml_dict(::Type{JLLFileProduct}, d)
    return JLLFileProduct(
        Symbol(d["name"]),
        d["path"],
    )
end

"""
    JLLLibraryDep

An idealization of a dependency edge from one library to another, denoting the
module name and library varname of the dependee.  If the module name is `nothing`
it is assumed to be the current module.
"""
struct JLLLibraryDep
    mod::Union{Nothing,Symbol}
    varname::Symbol

    function JLLLibraryDep(mod, varname)
        if mod !== nothing
            mod = Symbol(mod)
        end
        return new(mod, Symbol(varname))
    end
end

# Technically not generating/parsing a dict but a string
function generate_toml_dict(dp::JLLLibraryDep)
    if dp.mod === nothing
        return string(dp.varname)
    else
        return string(dp.mod, ".", dp.varname)
    end
end
function parse_toml_dict(::Type{JLLLibraryDep}, s)
    pieces = split(s, ".")
    if length(pieces) == 1
        return JLLLibraryDep(nothing, pieces[1])
    elseif length(pieces) == 2
        return JLLLibraryDep(pieces[1], pieces[2])
    else
        throw(ArgumentError("Invalid dependency name '$(s)', should be of the form 'module.libname'!"))
    end
end

@struct_hash_equal struct JLLLibraryProduct <: AbstractJLLProduct
    varname::Symbol
    path::String
    deps::Vector{JLLLibraryDep}
    soname::String
    flags::Vector{Symbol}
    on_load_callback::Union{Nothing,Symbol}

    function JLLLibraryProduct(varname, path, deps;
                               flags = rtld_symbols(default_rtld_flags),
                               soname = basename(path),
                               on_load_callback = nothing)
        if isa(flags, UInt32)
            flags = rtld_symbols(flags)
        end
        return new(varname, path, deps, soname, flags, on_load_callback)
    end
end

function generate_toml_dict(lp::JLLLibraryProduct)
    d = Dict(
        "type" => "library",
        "name" => string(lp.varname),
        "path" => lp.path,
        "deps" => generate_toml_dict.(lp.deps),
        "soname" => lp.soname,
        "flags" => string.(lp.flags),
    )
    if lp.on_load_callback !== nothing
        d["on_load_callback"] = string(lp.on_load_callback)
    end
    return d
end
function parse_toml_dict(::Type{JLLLibraryProduct}, d)
    on_load_callback = nothing
    if haskey(d, "on_load_callback")
        on_load_callback = Symbol(d["on_load_callback"])
    end
    return JLLLibraryProduct(
        Symbol(d["name"]),
        d["path"],
        [parse_toml_dict(JLLLibraryDep, d) for d in d["deps"]];
        soname = d["soname"],
        flags = Symbol.(d["flags"]),
        on_load_callback,
    )
end


function parse_toml_dict(::Type{AbstractJLLProduct}, d)
    if d["type"] == "executable"
        return parse_toml_dict(JLLExecutableProduct, d)
    elseif d["type"] == "file"
        return parse_toml_dict(JLLFileProduct, d)
    elseif d["type"] == "library"
        return parse_toml_dict(JLLLibraryProduct, d)
    else
        throw(ArgumentError("Unknown JLL product type '$(d["type"])'"))
    end
end

"""
    JLLSourceRecord

A simplified record of where a particular source came from, tracking the URL and
content hash.
"""
struct JLLSourceRecord
    url::String
    treehash::MultiHash

    function JLLSourceRecord(url, treehash)
        return new(string(url), MultiHash(treehash))
    end
end

function generate_toml_dict(js::JLLSourceRecord)
    return Dict(
        "url" => js.url,
        "treehash" => string(js.treehash),
    )
end

function parse_toml_dict(::Type{JLLSourceRecord}, d)
    return JLLSourceRecord(
        d["url"],
        d["treehash"],
    )
end

"""
    JLLArtifactSource

A simplified record of where a particular artifact can be downloaded from,
tracking the URL and tarball hash.
"""
struct JLLArtifactSource
    url::String
    tarball_hash::SHA256Hash

    function JLLArtifactSource(url, tarball_hash)
        return new(string(url), MultiHash(tarball_hash))
    end
end

function generate_toml_dict(jas::JLLArtifactSource)
    return Dict(
        "url" => jas.url,
        "tarball_hash" => string(jas.tarball_hash),
    )
end

function parse_toml_dict(::Type{JLLArtifactSource}, d)
    return JLLArtifactSource(
        d["url"],
        d["tarball_hash"],
    )
end

"""
    JLLPackageDependency

A representation of a package that is required for this JLL to operate,
if `compat` is not given, defaults to `"*"`.
"""
struct JLLPackageDependency
    name::Symbol
    uuid::UUID
    compat::String

    function JLLPackageDependency(name, uuid = nothing, compat = "*")
        if uuid === nothing
            # Immediately try to get a UUID, or fall back to the default autogenerated JLL UUID
            uuids = unique(Pkg.Types.registered_uuids(
                Pkg.Types.Context().registries,
                string(name),
            ))
            if isempty(uuids)
                uuid = jll_specific_uuid5(uuid_package, "$(name)_jll")
            elseif length(uuids) > 1
                throw(ArgumentError("More than one '$(name)_jll' package registered?!"))
            else
                uuid = only(uuids)
            end
        end

        return new(
            Symbol(name),
            UUID(uuid),
            string(compat),
        )
    end
end

function generate_toml_dict(jpd::JLLPackageDependency)
    return Dict(
        "name" => string(jpd.name),
        "uuid" => string(jpd.uuid),
        "compat" => jpd.compat,
    )
end

function parse_toml_dict(::Type{JLLPackageDependency}, d)
    return JLLPackageDependency(
        d["name"],
        d["uuid"],
        d["compat"],
    )
end


@struct_hash_equal struct JLLArtifactBinding
    treehash::SHA1Hash
    download_sources::Vector{JLLArtifactSource}

    function JLLArtifactBinding(treehash, download_sources)
        return new(SHA1Hash(treehash), empty_convert(JLLArtifactSource, download_sources))
    end
end

function JLLArtifactBinding(;treehash, download_sources=[])
    return JLLArtifactBinding(treehash, download_sources)
end

function generate_toml_dict(info::JLLArtifactBinding)
    d = Dict(
        "treehash" => string(info.treehash),
        "download_sources" => generate_toml_dict.(info.download_sources),
    )
    return d
end

function parse_toml_dict(::Type{JLLArtifactBinding}, d::Dict)
    return JLLArtifactBinding(;
        treehash = MultiHash(d["treehash"]),
        download_sources = [parse_toml_dict(JLLArtifactSource, p) for p in d["download_sources"]],
    )
end


"""
    JLLBuildLicense

Describes the license a JLL build is released under.  Contains a `filename`, and the
full `license_text`, which gets written out to `\${jll_prefix}/licenses/\${filename}`.
The `license_type` is the SPDX identifier of the license, if any exists.  This can be
automatically determined by a convenience constructor, using `LicenseCheck`.
"""
@struct_hash_equal struct JLLBuildLicense
    filename::String
    license_text::String
    license_type::Union{Nothing,String}
end

"""
    JLLBuildLicense(filename::String, license_text::String)

Helper to construct a new JLLBuildLicense and use `LicenseCheck` to auto-guess
what type of license is contained within `license_text`.
"""
function JLLBuildLicense(filename::String, license_text::String)
    # Dodge annoying `go` limitation on aarch64-apple-darwin
    # X-ref: https://github.com/ericphanson/LicenseCheck.jl/issues/11
    if Sys.isapple()
        result = (;licenses_found=[])
    else
        result = licensecheck(license_text)
    end
    if length(result.licenses_found) != 1
        return JLLBuildLicense(filename, license_text, nothing)
    end
    return JLLBuildLicense(filename, license_text, only(result.licenses_found))
end

function generate_toml_dict(license::JLLBuildLicense)
    d = Dict(
        "filename" => license.filename,
        "license_text" => license.license_text,
    )
    if license.license_type !== nothing
        d["license_type"] = license.license_type
    end
    return d
end
function parse_toml_dict(::Type{JLLBuildLicense}, d::Dict)
    return JLLBuildLicense(
        d["filename"],
        d["license_text"],
        get(d, "license_type", nothing),
    )
end


"""
    JLLBuildInfo

A structure representing all platform-specific information in a JLL.  This structure is
essentially a distillation of the `BuildResult/ExtractResult` structures in `BinaryBuilder2`, but
is distinct in order to maintain separation between the two packages, and to make it
easier for non-BinaryBuilder2 users to make use of this package if needed.
"""
@struct_hash_equal struct JLLBuildInfo
    # Version of the upstream source that was built (doesn't have to even be a VersionNumber)
    # It's a little strange if this is different across platforms, but it's technically
    # allowable for projects such as p7zip where we install a completely different project's
    # binaries for Windows, and they're versioned completely separately.
    src_version::String

    # The platform this is built for
    platform::AbstractPlatform

    # The name and artifact bindings for this artifact
    name::String
    artifact::JLLArtifactBinding
    auxilliary_artifacts::Dict{String,JLLArtifactBinding}

    # List of products in cut-down JLL format
    products::Vector{<:AbstractJLLProduct}

    # A list of JLL dependencies that must be available to use this JLL
    # Each element can be just a symbol, or a symbol and a version spec string
    deps::Vector{JLLPackageDependency}

    # A list of sources as `(source_url, hash)` pairs
    sources::Vector{JLLSourceRecord}

    # The license this build is released under
    licenses::Vector{JLLBuildLicense}

    # Whether this artifact should be considered lazy
    lazy::Bool

    # on-callback function definitions in the form of `func_name => code_as_string`
    callback_defs::Dict{Symbol,String}

    # __init__ snippet definition as a string, or `nothing` if not needed.
    init_def::Union{Nothing,String}

    function JLLBuildInfo(src_version, platform, name, artifact, auxilliary_artifacts, products,
                          deps, sources, licenses, lazy, callback_defs, init_def)
        # Quick verification of dependency structure, to ensure we're not incoherent.
        for p in products
            if isa(p, JLLLibraryProduct)
                for d in p.deps
                    # A "nothing" module means it's an intra-package dependency
                    if d.mod === nothing
                        # Check to ensure we have another library product with that name:
                        if !any(op.varname == d.varname for op in products)
                            throw(ArgumentError("Product '$(p.varname)' depends on '$(d.varname)' in the same JLL, but no such library product exists for platform '$(triplet(platform))'!"))
                        end
                    else
                        # Check to ensure we've declared a dependency on `d.mod`
                        if d.mod ∉ [d.name for d in deps]
                            throw(ArgumentError("Product '$(p.varname)' depends on '$(d.mod).$(d.varname)', but '$(d.mod)' is not in the top-level list of dependencies!"))
                        end
                    end
                end

                if p.on_load_callback !== nothing
                    if p.on_load_callback ∉ keys(callback_defs)
                        throw(ArgumentError("Product '$(p.varname)' references on-load callback '$(p.on_load_callback)', but matching definition not found!"))
                    end
                end
            end
        end

        if isempty(licenses)
            throw(ArgumentError("Must provide at least one license for JLLBuild!"))
        end

        return new(
            string(src_version),
            platform,
            string(name),
            artifact,
            Dict{String,JLLArtifactBinding}(String(name) => art for (name, art) in auxilliary_artifacts),
            empty_convert(AbstractJLLProduct, products),
            empty_convert(JLLPackageDependency, deps),
            empty_convert(JLLSourceRecord, sources),
            licenses,
            lazy,
            Dict{Symbol,String}(Symbol(k) => string(v) for (k,v) in callback_defs),
            init_def,
        )
    end
end

function JLLBuildInfo(;src_version, platform, name, artifact, products, licenses,
                          deps = [], sources = [], lazy = false, callback_defs = Dict(),
                          init_def = nothing, auxilliary_artifacts = Dict())
    return JLLBuildInfo(src_version, platform, name, artifact, auxilliary_artifacts, products,
                           deps, sources, licenses, lazy, callback_defs, init_def)
end

function generate_toml_dict(info::JLLBuildInfo)
    d = Dict(
        "src_version" => info.src_version,
        "deps" => generate_toml_dict.(info.deps),
        "sources" => generate_toml_dict.(info.sources),
        "licenses" => generate_toml_dict.(info.licenses),
        "platform" => triplet(info.platform),
        "name" => string(info.name),
        "artifact" => generate_toml_dict(info.artifact),
        "auxilliary_artifacts" => Dict(string(name) => generate_toml_dict(art) for (name, art) in info.auxilliary_artifacts),
        "lazy" => string(info.lazy),
        "callback_defs" => Dict(string(k) => v for (k, v) in info.callback_defs),
        "products" => generate_toml_dict.(info.products),
    )
    if info.init_def !== nothing
        d["init_def"] = info.init_def
    end
    return d
end

function parse_toml_dict(::Type{JLLBuildInfo}, d::Dict)
    return JLLBuildInfo(;
        src_version = d["src_version"],
        deps = [parse_toml_dict(JLLPackageDependency, p) for p in d["deps"]],
        sources = [parse_toml_dict(JLLSourceRecord, p) for p in d["sources"]],
        licenses = parse_toml_dict.(JLLBuildLicense, d["licenses"]),
        platform = parse(AbstractPlatform, d["platform"]),
        name = d["name"],
        artifact = parse_toml_dict(JLLArtifactBinding, d["artifact"]),
        auxilliary_artifacts = Dict(name => parse_toml_dict(JLLArtifactBinding, art) for (name, art) in d["auxilliary_artifacts"]),
        lazy = parse(Bool, d["lazy"]),
        callback_defs = Dict{Symbol,String}(Symbol(k) => string(v) for (k,v) in d["callback_defs"]),
        init_def = get(d, "init_def", nothing),
        products = [parse_toml_dict(AbstractJLLProduct, p) for p in d["products"]],
    )
end

function guess_julia_compat(artifacts)
    julia_v16_platforms = [
        Platform("aarch64", "macos"),
        Platform("armv6l", "linux"; libc="glibc"),
        Platform("armv6l", "linux"; libc="musl"),
    ]
    for artifact in artifacts
        # If any of our artifacts contain one of these platforms, we have a hard
        # dependency on Julia v1.6+
        if any(platforms_match.(Ref(artifact.platform), julia_v16_platforms))
            return "1.6"
        end
    end

    # We require at least Julia 1.3+, for Pkg.builds support, but we claim
    # Julia 1.0+ by default so that empty JLLs can be installed on older versions.
    return "1.0"
end

"""
    JLLInfo

A structure representing a JLL that is to be generated.  All relevant information on the
JLL is stored within, including sources 
"""
@struct_hash_equal struct JLLInfo
    # Name of the JLL, e.g. `libfoo_jll`
    name::String

    # Version of the JLL that is being published (strict SemVer adherence)
    version::VersionNumber

    # Each platform build can be completely different from the others, so all the other
    # information is stored in `builds`
    builds::Vector{JLLBuildInfo}

    # A snippet of Julia code that is used to add specific tags to the platform that will
    # be used to look up the correct artifact from `artifacts`.
    platform_augmentation_code::String

    # This JLL can declare a compatibility against Julia itself.
    # If `artifacts` contains builds for one of the platforms that requires
    # `v1.6` (such as `aarch64-apple-darwin` or `armv6l-linux-gnueabihf`) we
    # automatically default to `v1.6`, otherwise we default to `v1.3`.
    # Note that all the new LazyLibrary stuff only kicks in for Julia `v1.11+`,
    # but we still do our best to support older julia versions.
    julia_compat::String

    function JLLInfo(name, version, artifacts, platform_augmentation_code, julia_compat)
        return new(
            string(name),
            VersionNumber(version),
            artifacts,
            string(platform_augmentation_code),
            julia_compat,
        )
    end
end
function JLLInfo(;name, version, builds,
                  platform_augmentation_code = "",
                  julia_compat = guess_julia_compat(builds))
    return JLLInfo(name, version, builds, platform_augmentation_code, julia_compat)
end

function Base.BinaryPlatforms.select_platform(jll::JLLInfo, platform::AbstractPlatform = HostPlatform())
    builds = Dict(jart.platform => jart for jart in jll.builds)
    jart = Base.BinaryPlatforms.select_platform(builds, platform)
    if jart === nothing
        throw(ArgumentError("No matching platform for $(platform) found in $(jll.builds)"))
    end
    return jart
end

# For historical reasons, our UUIDs are generated with some rather strange constants
function jll_specific_uuid5(namespace::UUID, key::String)
    data = [reinterpret(UInt8, [namespace.value]); codeunits(key)]
    u = reinterpret(UInt128, SHA.sha1(data)[1:16])[1]
    u &= 0xffffffffffff0fff3fffffffffffffff
    u |= 0x00000000000050008000000000000000
    return UUID(u)
end
const uuid_package = UUID("cfb74b52-ec16-5bb7-a574-95d9e393895e")
# For even more interesting historical reasons, we append an extra
# "_jll" to the name of the new package before computing its UUID.
UUID(info::JLLInfo) = jll_specific_uuid5(uuid_package, "$(info.name)_jll_jll")


function generate_toml_dict(info::JLLInfo)
    return Dict(
        "name" => info.name,
        "version" => string(info.version),
        "builds" => generate_toml_dict.(info.builds),
        "julia_compat" => info.julia_compat,
        "platform_augmentation_code" => info.platform_augmentation_code,
    )
end

function parse_toml_dict(::Type{JLLInfo}, d::Dict)
    return JLLInfo(;
        name = d["name"],
        version = VersionNumber(d["version"]),
        builds = [parse_toml_dict(JLLBuildInfo, p) for p in d["builds"]],
        platform_augmentation_code = d["platform_augmentation_code"],
        julia_compat = d["julia_compat"],
    )
end
parse_toml_dict(d::Dict) = parse_toml_dict(JLLInfo, d)

function bind_jll_artifact!(artifacts_toml_path::String, name::String, platform::AbstractPlatform,
                            artifact::JLLArtifactBinding; lazy::Bool = false)
    kwargs = Dict(
        :download_info => [(s.url, bytes2hex(s.tarball_hash)) for s in artifact.download_sources],
        :lazy => lazy,
        :force => true,
    )

    if !isa(platform, AnyPlatform)
        kwargs[:platform] = platform
    end

    Pkg.Artifacts.bind_artifact!(
        artifacts_toml_path,
        name,
        Base.SHA1(artifact.treehash);
        kwargs...,
    )
end

function coalesce_licenses(info::JLLInfo)
    # Easy case; are all license vectors the same?
    if all(build.licenses == info.builds[1].licenses for build in info.builds)
        return Dict(l.filename => l for l in info.builds[1].licenses)
    end

    # Hard case; write out a triplet-suffixed license:
    ret = Dict{String,JLLBuildLicense}()
    for build in info.builds
        for lic in build.licenses
            ret["$(triplet(build.platform))-$(lic.filename)"] = lic
        end
    end
    return ret
end

function generate_jll(out_dir::String, info::JLLInfo; clear::Bool = true, build_metadata::Dict{String,String} = Dict{String,String}())
    if clear && isdir(out_dir)
        for child in readdir(out_dir)
            # Don't clear `.git` directories
            if child == ".git"
                continue
            end
            rm(joinpath(out_dir, child); force=true, recursive=true)
        end
    end
    mkpath(joinpath(out_dir, "src"))

    # Generate `jll.toml`, which contains _all_ information about this JLL
    toml_dict = generate_toml_dict(info)
    open(joinpath(out_dir, "JLL.toml"); write=true) do io
        TOML.print(io, toml_dict)
    end

    # Generate `Artifacts.toml`
    artifacts_toml_path = joinpath(out_dir, "Artifacts.toml")

    # Sort builds to make this more deterministic
    for build in sort(info.builds; by=b->triplet(b.platform))
        # Bind the main artifact
        bind_jll_artifact!(artifacts_toml_path, build.name, build.platform, build.artifact; lazy=build.lazy)

        # Also bind any auxilliary artifacts (which are automatically lazy)
        for (name, binding) in build.auxilliary_artifacts
            bind_jll_artifact!(
                artifacts_toml_path,
                string(build.name, "-", name),
                build.platform,
                binding;
                lazy=true,
            )
        end
    end

    # Generate `README.md`
    open(joinpath(out_dir, "README.md"); write=true) do io
        # Start with the name of the JLL
        println(io, """
        # $(info.name) v$(info.version)
        This is an autogenerated package constructed using [JLLGenerator.jl](https://github.com/JuliaPackaging/BinaryBuilder2.jl/tree/main/JLLGenerator.jl).
        """)

        # Print provenance information
        provenance_str = ""
        if haskey(build_metadata, "build_script_url")
            build_script_url = build_metadata["build_script_url"]
            println(io, "This package was built according to [the instructions in this build script]($(build_script_url)).")

            # Parse out org/repo and point users to the appropriate bug tracker
            m = match(r"https://github.com/(?<org>[^/]+)/(?<repo>[^/]+)/.*", build_script_url)
            if m !== nothing
                println(io, """
                # Bug Reports
                If you have any issues, please report them to the [$(m[:repo]) bug tracker](https://github.com/$(m[:org])/$(m[:repo])/issues).
                """)
            end
        end

        println(io, """
        # Documentation
        For more details about JLL packages and how to use them, see the `BinaryBuilder.jl` [documentation](https://docs.binarybuilder.org/stable/jll/).
        """)
    
        source_versions = unique([jart.src_version for jart in info.builds])
        source_versions_str = length(source_versions) == 1 ?
                          "version v$(only(source_versions))" :
                          "versions $(string(source_versions))"

        println(io, """
        # Sources
        The binaries for `$(info.name)` have been built from upstream sources $(source_versions_str):
        """)

        sources = unique(stack([jart.sources for jart in info.builds]))
        for source in sources
            println(io, " - [$(source.url)]($(source.url)) (treehash: $(source.treehash))")
        end

        println(io, """
        # Platforms

        `$(info.name)` is available for the following platforms:
        """)
        for jart in info.builds
            println(io, " - `$(jart.platform)`")
        end

        # In general, we'd need access to a registry lookup to turn our name/UUID pairs in `JLLInfo`
        # into a linkable URL, so we punt this off to the caller by only printing the name unless
        # the URL is listed in `dep_url_mapping` in the `build_metadata` dictionary.
        deps = unique(vcat([jart.deps for jart in info.builds]...))
        dep_url_mapping = get(build_metadata, "dep_url_mapping", Dict{String,String}())
        println(io, """
        # Dependencies
        The following JLL packages are required by `$(info.name)`:
        """)
        for dep in deps
            dep_url = get(dep_url_mapping, dep.name, nothing)
            if dep_url !== nothing
                println(io, " - [`$(dep.name)`]($(dep_url))")
            else
                println(io, " - `$(dep.name)`")
            end
        end

        println(io, """
        # Products
        
        The code bindings within this package are generated to wrap the following `Product`s:
        <TODO>
        """)        
    end

    # Generate top-level `LICENSE.md` (always MIT)
    open(joinpath(out_dir, "LICENSE.md"); write=true) do io
        println(io, get_license_text("MIT"))
    end

    # Generate per-build licenses
    mkpath(joinpath(out_dir, "licenses"))
    for (name, lic) in coalesce_licenses(info)
        open(joinpath(out_dir, "licenses", name); write=true) do io
            println(io, lic.license_text)
        end
    end

    # Generate `Project.toml`
    open(joinpath(out_dir, "Project.toml"); write=true) do io
        project_dict = Dict(
            "name" => "$(info.name)_jll",
            "uuid" => string(UUID(info)),
            "version" => string(info.version),
            # We'll add either `Pkg` or `Artifacts` to this list, depending on the `julia_compat`.
            "deps" => Dict{String,Any}(
                "LazyJLLWrappers" => "21706172-204c-4d4f-5420-656854206f44",
                "Libdl" => "8f399da3-3557-5675-b5ff-fb832c97cbdb",
            ),

            "compat" => Dict{String,Any}(
                "LazyJLLWrappers" => "1.0.0",
                "julia" => info.julia_compat,
            )
        )

        # If our julia_compat is too old, add `Pkg` as a dependency, otherwise use `Artifacts`:
        if v"1.5" ∈ Pkg.Types.semver_spec(info.julia_compat)
            project_dict["deps"]["Pkg"] = "44cfe95a-1eb2-52ea-b672-e2afdf69b78f"
        else
            project_dict["deps"]["Artifacts"] = "56f22d72-fd6d-98f1-02f0-08ddc0907c33"
        end

        alldeps = unique(vcat((a.deps for a in info.builds)...))
        
        # Check for dependencies specified multiple times with different versions,
        # collapsing them into a single version if possible:
        alldeps_by_uuid = Dict(d.uuid => JLLPackageDependency[] for d in alldeps)
        for dep in alldeps
            if !haskey(alldeps_by_uuid, dep.uuid)
                alldeps_by_uuid[dep.uuid] = JLLPackageDependency[]
            end
            push!(alldeps_by_uuid[dep.uuid], dep)
        end
        for (uuid, deps) in alldeps_by_uuid
            if length(deps) > 1
                # Ensure that they all use the same name:
                names = unique([d.name for d in deps])
                if length(names) != 1
                    throw(ArgumentError("Cannot refer to the same dependency '$(uuid)' by different names: $(repr(names))"))
                end
                name = only(names)

                version_specs = Pkg.Types.semver_spec.([d.compat for d in deps])
                final_compat = intersect(version_specs...)
                if isempty(final_compat)
                    throw(ArgumentError("Unable to satisfy multiple compat constraints on dependency '$(name) ($(uuid))'"))
                end

                # Replace all those deps by a single dep with the given restricted compat:
                alldeps_by_uuid[uuid] = [JLLPackageDependency(
                    name,
                    uuid,
                    workaround_string(final_compat),
                )]
            end
        end

        alldeps = only.(values(alldeps_by_uuid))
        for dep in alldeps
            name = string(dep.name)
            project_dict["deps"][name] = string(dep.uuid)
            if dep.compat != "*"
                # verify dep.compat is valid
                Pkg.Types.semver_spec(dep.compat)
                project_dict["compat"][name] = dep.compat
            end
        end
        TOML.print(io, project_dict)
    end

    # Generate JLLWrapper stub
    open(joinpath(out_dir, "src", "$(info.name)_jll.jl"); write=true) do io
        println(io, """
        module $(info.name)_jll
        using LazyJLLWrappers
        @generate_jll_from_toml()
        end # module $(info.name)_jll
        """)
    end
end

# BB-specific stuff (like version of BB used to do build, etc... will be in a separate `BB.toml`)
@warn("""
TODO: Add the following to our JLL.toml output:
- Upstream URL
- Description
""")

# This function will be overloaded by `BinaryBuilderProductsExt`
function AbstractProducts(infos, platform)
    error("Must load BinaryBuilderProducts to reconstruct products from JLLInfos!")
end

end # module JLLGenerator
