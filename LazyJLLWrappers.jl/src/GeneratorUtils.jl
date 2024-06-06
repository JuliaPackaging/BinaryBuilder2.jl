"""
    get_augmented_platform(jll_dict)

Check for a `platform_augmentation` key in `jll_dict`, and if it exists, evaluate it
in an anonymous module.  The code should define an `augment_platform!(p::Platform)`
method as described in the Pkg docs [0].

[0] https://pkgdocs.julialang.org/v1/artifacts/#Extending-Platform-Selection
"""
function get_augmented_platform(jb, jll)
    # If there is no `platform_augmentation_code` key, don't do anything,
    # we just always use `HostPlatform()`.
    platform_augmentation_code = get(jll, "platform_augmentation_code", "")
    if isempty(platform_augmentation_code)
        return HostPlatform()
    end

    # Otherwise, let's parse the platform augmentation code and evaluate it
    # within `jb.module`.  We place the platform augmentation code within
    # its own module so that it cannot conflict with our other code.
    # We evaluate it immediately (rather than add it to `jb.top_level_blocks`)
    # because we need to get the value of `platform` right now.  Initially,
    # I had intended to evaluate it now and also add it to `jb.top_level_blocks`
    # for greater consistency, but I can't figure out how to evaluate ephemeral
    # chunks of code during precompilation of a module, all evaluated code
    # appears to need to belong to the module under compilation, and I don't
    # want to store our platform augmentation code twice.
    platform_augmentation_module = Core.eval(jb.mod, :(
        module platform_augmentation_module
            using Base.BinaryPlatforms
            $(Meta.parse(platform_augmentation_code))
        end # module
    ))
    if !isdefined(platform_augmentation_module, :augment_platform!)
        throw(ArgumentError("`platform_augmentation` code does not contain definition for `augment_platform!()`:\n$(platform_augmentation_code)\n"))
    end
    platform = Base.invokelatest(platform_augmentation_module.augment_platform!, HostPlatform())

    # Verify that the result of running `platform_augmentation_module.augment_platform!()`
    # at runtime matches what we ran at compile-time.
    push!(jb.init_blocks, quote
        host_platform = platform_augmentation_module.augment_platform!(Base.BinaryPlatforms.HostPlatform())
        if $(platform) != host_platform
            # TODO: Ask Jameson for a `__verify__()` or similar, so that we can abort
            # loading of this module and compile a new one, rather than just erroring
            # out within `__init__()`.
            error(string("Cached host platform ", $(platform), " != live host platform ", host_platform))
        end
    end)

    return platform
end

"""
    select_artifact(artifacts::Vector, host::AbstractPlatform)

Select a single artifact from our set of artifacts by first determining the name
of the artifact that should be used (overrideable by a preference)
"""
function select_artifact(artifacts, name::String, host::AbstractPlatform)
    # The `artifacts` vector contains metadata about potentially multiple disparate names,
    # e.g. `XZ` vs. `XZ_logs`, vs `XZ-debug`, etc... We first select based on the given
    # `name`, and then select based on the `host` platform.
    artifacts = filter(a -> a["name"] == name, artifacts)
    if isempty(artifacts)
        throw(ArgumentError("No artifacts found matching name '$(name)', this JLL is malformed."))
    end

    if any(a["platform"] == "any" for a in artifacts)
        if length(artifacts) == 1
            return only(artifacts)
        end
        # Throw an error since `AnyPlatform` artifacts can't exist alongside any other artifact with the same name.
        throw(ArgumentError("AnyPlatform artifact $(name) must be a singleton, this JLL is malformed."))
    end

    # Otherwise, do platform selection:
    artifacts = Dict(parse(Platform, a["platform"]) => a for a in artifacts)
    return select_platform(artifacts, host)
end


function top_level_statements(jb::JLLBlocks, artifact, platform)
    if VERSION >= v"1.6.0"
        push!(jb.top_level_blocks, :(using Libdl, LazyJLLWrappers, Artifacts, Base.BinaryPlatforms))
    elseif VERSION >= v"1.3.0-rc4"
        # Use slower Pkg-based artifacts
        push!(jb.top_level_blocks, :(using Libdl, LazyJLLWrappers, Pkg.Artifacts, Base.BinaryPlatforms))
    else
        error("Unable to use $(src_name)_jll on Julia versions older than 1.3!")
    end

    # Add `using $dep` for every dep
    for dep in artifact["deps"]
        push!(jb.top_level_blocks, :(using $(Symbol(dep["name"]))))
    end

    # Add `is_available()` definition based on whether `artifact` is `nothing` or not:
    push!(jb.top_level_blocks, quote
    is_available() = $(artifact !== nothing)
    end)

    # Add `export $foo` for every product
    for product in artifact["products"]
        push!(jb.top_level_blocks, :(export $(Symbol(product["name"]))))
    end

    # Add callback function definitions.  Even if we're not using `LazyLibrary` objects
    # that are actually capable of calling callback functions, we call these in `__init__()`.
    append!(jb.top_level_blocks, Meta.parse.(values(artifact["callback_defs"])))

    # Also add `PATH` and `LIBPATH` initialization
    push!(jb.top_level_blocks, emit_typed_global(:PATH, Ref{String}, Ref{String}(""); isconst=true))
    push!(jb.top_level_blocks, emit_typed_global(:LIBPATH, Ref{String}, Ref{String}(""); isconst=true))
    push!(jb.top_level_blocks, emit_typed_global(:PATH_list, Vector{String}, String[]; isconst=true))
    push!(jb.top_level_blocks, emit_typed_global(:LIBPATH_list, Vector{String}, String[]; isconst=true))

    # Add our platform object, so that we can introspect the result of platform augmentation
    push!(jb.top_level_blocks, emit_typed_global(:platform, typeof(platform), Meta.parse(repr(platform)); isconst=true))
end

"""
    build_eager_mode(jb, lib_products)

In order to be compatible with JLLWrappers (the old version) we need to
support a way to force all libraries to load eagerly so that downstream
JLLs are able to make use of our libraries.  This method will define an
`eager_mode()` function that ensures that all libraries in this JLL are
dlopen()'ed and ready for use.  Old JLLWrappers will then call
`eager_mode()` on all dependencies to ensure that they are available.
"""
function build_eager_mode(jb::JLLBlocks, lib_products)
    statements = Expr[]
    # For every library in `lib_products`, open it!
    for lib in lib_products
        _, path_var_name, _ = product_names(lib)
        push!(statements, :(dlopen($(path_var_name))))
    end

    push!(jb.top_level_blocks, quote
        function eager_mode()
            $(statements...)
        end
    end)
end


function emit_typed_global(name, type, val; isconst::Bool = false)
    # On Julia v1.9+ we can type-annotate global variables, which provides slightly
    # better performance when grabbing these values.
    local ret
    if VERSION >= v"1.9"
        ret = quote
            $(name)::$(type) = $(val)
        end
    else
        ret = quote
            $(name) = $(val)
        end
    end

    if isconst
        ret = Expr(:const, Base.remove_linenums!(ret).args...)
    end
    return ret
end

function product_names(product)
    var_name = Symbol(product["name"])
    path_var_name = Symbol(string(product["name"], "_path"))
    lazy_path_var_name = Symbol(string("_", product["name"], "_path"))
    return var_name, path_var_name, lazy_path_var_name
end

function gen_lazy_artifact_path(jb::JLLBlocks, build, product)
    # The hashes in this TOML are `MultiHashParsing` hashes,
    # but we only support `sha1` hashes:
    treehash = build["artifact"]["treehash"]
    if !startswith(treehash, "sha1:")
        throw(ArgumentError("Treehash must start with `sha1:`: '$(treehash)'"))
    end
    treehash = Base.SHA1(treehash[6:end])
    var_name, path_var_name, lazy_path_var_name = product_names(product)

    # Luckily, our `LazyArtifactPath` is generic enough that it can run on any Julia
    # version that understands Artifacts (v1.3+) otherwise this would be a _huge_ pain.
    lazy_artifact_path = quote
        LazyArtifactPath(
            $(treehash),
            $(product["path"]),
        )
    end

    # If we're on a new enough Julia, check for an overriding preference
    if VERSION >= v"1.6.0"
        # This is some crazy dynamism; if we have a preference set, we
        # return a String pointing to the object, otherwise we return an `Expr`
        # that defines the `LazyArtifactPath`, both of which can be interpolated
        # `jb.top_level_blocks` just fine.
        lazy_artifact_path = load_preference(
            jb.mod,
            string(path_var_name),
            lazy_artifact_path,
        )
    end
    push!(jb.top_level_blocks, :($(lazy_path_var_name) = $(lazy_artifact_path)))

    # This value is kept a `String` for backwards-compatibility purposes, it is filled out in `__init__()`.
    push!(jb.top_level_blocks, emit_typed_global(path_var_name, String, ""; isconst=false))

    # I wish we didn't have to do this, but there's likely a lot of code out there that depends on
    # `Foo_jll.libfoo_path` being a String.
    push!(jb.init_blocks, :(global $(path_var_name) = string($(lazy_path_var_name))))

    return var_name, path_var_name, lazy_path_var_name
end

function init_footer(jb::JLLBlocks, build)
    for product in build["products"]
        var_name, path_var_name, lazy_path_var_name = product_names(product)
        if product["type"] == "executable"
            push!(jb.init_blocks, :(push!(PATH_list, $(path_var_name))))
        end
        if product["type"] == "library"
            push!(jb.init_blocks, :(push!(LIBPATH_list, $(path_var_name))))
        end
    end

    # Append our dependencies' PATH and LIBPATH:
    for dep in build["deps"]
        push!(jb.init_blocks, quote
            append!(PATH_list, $(Symbol(dep["name"])).PATH_list)
            append!(LIBPATH_list, $(Symbol(dep["name"])).LIBPATH_list)
        end)
    end

    # Unique the lists, and assign them to our globals:
    push!(jb.init_blocks, quote
        unique!(PATH_list)
        unique!(LIBPATH_list)
        PATH[] = join(PATH_list, $(pathsep))
        LIBPATH[] = join(vcat(LIBPATH_list, Base.invokelatest(LazyJLLWrappers.get_julia_libpaths))::Vector{String}, $(pathsep))
    end)
end
