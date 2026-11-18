# The library's SONAME, as recorded by JLLGenerator.  JLL.toml files that predate
# that record get the name of the library file instead.
function soname(product)
    haskey(product, "soname") && return product["soname"]
    if Sys.isapple()
        return "@rpath/$(basename(product["path"]))"
    else
        return basename(product["path"])
    end
end


function library_product_definition(jb::JLLBlocks, artifact, product)
    # Call `gen_lazy_artifact_path` first to generate our lazy artifact paths
    # and the `path` value itself.  We directly use the `lazy_path_var_name`
    # object itself though, as it can be used even during compilation.
    var_name, path_var_name, lazy_path_var_name = gen_lazy_artifact_path(jb, artifact, product)

    function mod_dot_name(name)
        split_name = split(name, ".")
        if length(split_name) == 1
            # dependency from within this JLL
            return Symbol(name)
        else
            # Dependency from another JLL
            mod, lib = split_name
            return Expr(:., Symbol(mod), QuoteNode(Symbol(lib)))
        end
    end

    if use_lazy_libraries()
        # On Julia v1.11+ we can use `LazyLibrary`, which runs the on-load callback
        # (defined at top level from `callback_defs`) on the library's first `dlopen()`.
        on_load_callback = haskey(product, "on_load_callback") ? Symbol(product["on_load_callback"]) : nothing
        push!(jb.top_level_blocks, emit_typed_global(
            var_name, LazyLibrary, quote
                LazyLibrary(
                    $(lazy_path_var_name),
                    dependencies = LazyJLLWrappers.filter_non_lazy_libraries([$(mod_dot_name.(product["deps"])...)]),
                    flags = $(Expr(:call, :|, [Expr(:., :Libdl, QuoteNode(f)) for f in Symbol.(product["flags"])]...)),
                    on_load_callback = $(on_load_callback),
                )
            end; isconst=true,
        ))
    else
        # Without `LazyLibrary` support, we export a `String`.  On Julia v1.6+ we
        # will overwrite this
        push!(jb.top_level_blocks, emit_typed_global(
            var_name, String, soname(product); isconst = VERSION < v"1.6.0",
        ))

        # Eagerly dlopen the library (now that the path has been resolved at `__init__()` time),
        # unless the JLL asks for it never to be loaded into this process.
        if !get(product, "dont_dlopen", false)
            push!(jb.init_blocks, :(dlopen($(path_var_name))))
        end

        # Also, invoke the callback function in `__init__()` here.
        if haskey(product, "on_load_callback")
            push!(jb.init_blocks, :($(Symbol(product["on_load_callback"]))()))
        end

        if VERSION >= v"1.6.0"
            # Update our exported path with the absolute path, on older Julia versions it
            # just stays as the SONAME because we did not have support for non-const library
            # values in `ccall()` invocations.
            push!(jb.init_blocks, :(global $(var_name) = $(path_var_name)))
        end
    end
    push!(jb.exports, var_name)

    # Aliases are the same library object, so it is loaded, and its callback run, once
    alias_definitions(jb, product, path_var_name) do alias
        if use_lazy_libraries()
            push!(jb.top_level_blocks, emit_typed_global(alias, LazyLibrary, var_name; isconst=true))
        else
            push!(jb.top_level_blocks, emit_typed_global(
                alias, String, soname(product); isconst = VERSION < v"1.6.0",
            ))
            if VERSION >= v"1.6.0"
                push!(jb.init_blocks, :(global $(alias) = $(var_name)))
            end
        end
    end
end
