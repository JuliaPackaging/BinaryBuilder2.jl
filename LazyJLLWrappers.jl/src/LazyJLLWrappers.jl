module LazyJLLWrappers

@warn("TODO: Remove JLLGenerator from the deps, it should be a test-only dependency")

export LazyArtifactPath, @generate_jll_from_toml

using Libdl
if VERSION >= v"1.6.0"
    using TOML, Artifacts, Preferences, Base.BinaryPlatforms
else
    using Pkg, Pkg.TOML, Pkg.Artifacts, Pkg.BinaryPlatforms
end

"""
    LazyArtifactPath

Helper type that stores an artifact hash and a subpath, then lazily resolves it
on-demand for e.g. `ccall()` and friends.  Caches its result so that lookup only
happens once.
"""
struct LazyArtifactPath
    artifact_hash::Base.SHA1
    subpath::String
    result::Ref{String}

    function LazyArtifactPath(artifact_hash, subpath)
        return new(artifact_hash, subpath, Ref{String}())
    end
end
function Base.string(lap::LazyArtifactPath)
    if !isassigned(lap.result)
        lap.result[] = joinpath(
            artifact_path(lap.artifact_hash),
            lap.subpath,
        )
    end
    return lap.result[]
end

"""
    JLLBlocks

A structured datatype that holds all the Expr blocks that we will generate for a JLL.
Call `synthesize()` to get the JLL's source code.
"""
struct JLLBlocks
    mod::Module
    top_level_blocks::Vector{Expr}
    init_blocks::Vector{Expr}

    function JLLBlocks(mod)
        return new(mod, Expr[], Expr[])
    end
end

# We need to glue expressions together a lot, but we also need them
# to all be top-level expressions.
function excat(ex_type::Symbol, exs::Union{Expr,Nothing}...)
    ex = Expr(ex_type)
    for exn in exs
        exn === nothing && continue
        if Meta.isexpr(exn, :block) || Meta.isexpr(exn, :toplevel)
            append!(ex.args, exn.args)
        else
            push!(ex.args, exn)
        end
    end
    return esc(ex)
end

function synthesize(jb::JLLBlocks)
    ret = excat(:block,
        jb.top_level_blocks...,
        quote
            function __init__()
                $(jb.init_blocks...)
            end
        end
    )
    Base.remove_linenums!(ret)
    # For debugging.  Note that this does not include the source listing for the `platform_augmentation_module`
    # because it needs to be evaluated during compilation and I have not yet figured out a good way to do that
    # and also have it appear here.
    #println(stderr, ret)
    return ret
end

include("Compat.jl")
include("GeneratorUtils.jl")
include("ExecutableProduct.jl")
include("FileProduct.jl")
include("LibraryProduct.jl")
include("Runtime.jl")

macro generate_jll_from_toml()
    # Lookup TOML location from this module
    toml_path = joinpath(pkgdir(__module__), "JLL.toml")
    if !isfile(toml_path)
        throw(ArgumentError("Unable to load '$(toml_path)'!"))
    end

    # Read in the JLL metadata (allowing for preference overriding)
    if VERSION >= v"1.6.0"
        toml_path = load_preference(__module__, "toml_path", toml_path)
    end
    jll = TOML.parsefile(toml_path)

    # The `JLLBlocks` object is where we store up each of the pieces of code
    # that will constitute this JLL, including top-level statements, `__init__()`
    # fragments, etc...  At the end of this macro, we call `synthesize()` on
    # this object to generate the end result.
    jb = JLLBlocks(__module__)

    # Select a single artifact to use; we make this choice at precompile time,
    # and assert that if the host platform is to change (e.g. the CUDA version
    # gets upgraded, the MPI engine changes) we require recompilation.  As of
    # this writing, that is enforced by erroring during `__init__()` where we
    # check that the "live" `HostPlatform()` matches the one that we were
    # compiled with.  In the future, we may have a mechanism to allow a
    # precompilation cache to invalidate itself, but we don't have it yet, so
    # just choose a triplet and store it for validation in `__init__()` later.
    # Note that while most JLLs only have a single artifact built for multiple
    # platforms, some JLLs can provide alternate artifact names (e.g. `default`
    # vs. `debug`), you can switch between which one you want to download
    # by setting the `artifact_name` preference:
    artifact_name = "default"
    if VERSION >= v"1.6.0"
        artifact_name = load_preference(__module__, "artifact_name", artifact_name)
    end

    # If we have platform augmentation snippets, we need to evaluate them now,
    # and also insert the code into the end result JLL to be run again at
    # __init__() time, so that we can check that the platform augmentation
    # hasn't changed its mind since the last time we precompiled this JLL.
    platform = get_augmented_platform(jb, jll)
    artifact = select_artifact(jll["artifacts"], artifact_name, platform)

    # Add top-level statements like exports, imports of other libraries,
    # declarations of globals, etc...
    top_level_statements(jb, artifact, platform)

    # Sort our library products so that they are in dependency-order:
    lib_products = [p for p in artifact["products"] if p["type"] == "library"]
    function calc_depths(lib_products)
        depths = Dict()
        while length(depths) != length(lib_products)
            for p in lib_products
                if !haskey(depths, p["name"])
                    if all(haskey(depths, d) for d in p["deps"])
                        if isempty(p["deps"])
                            depths[p["name"]] = 1
                        else
                            depths[p["name"]] = maximum(depths[d] for d in p["deps"]) + 1
                        end
                    end
                end
            end
        end
        return depths
    end
    lib_depths = calc_depths(lib_products)
    function product_isless(p1, p2)
        if lib_depths[p1["name"]] != lib_depths[p2["name"]]
            return isless(lib_depths[p1["name"]], lib_depths[p2["name"]])
        end
        return isless(p1["name"], p2["name"])
    end
    lib_products = sort(lib_products, lt=product_isless)

    # Do all the library products first, since we have to sort them specifically.
    for product in lib_products
        library_product_definition(jb, artifact, product)
    end

    # Also, create our `eager_mode()` function body which will open all of our
    # libraries and tell all of our dependencies to open their libraries too.
    # This allows these packages to co-exist with the old `JLLWrappers`
    build_eager_mode(jb, lib_products)
    
    # Next all the other products
    for product in artifact["products"]
        if product["type"] == "library"
            continue
        elseif product["type"] == "executable"
            executable_product_definition(jb, artifact, product)
        elseif product["type"] == "file"
            file_product_definition(jb, artifact, product)
        else
            throw(ArgumentError("Unknown product type '$(product["type"])'"))
        end
    end

    # If we have an `init_def`, insert that into our `init_blocks`
    init_def = get(artifact, "init_def", nothing)
    if init_def !== nothing
        push!(jb.init_blocks, Meta.parse(init_def))
    end

    init_footer(jb, artifact)
    return synthesize(jb)
end

end # module LazyJLLWrappers
