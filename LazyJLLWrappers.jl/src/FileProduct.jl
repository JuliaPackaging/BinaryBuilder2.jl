function file_product_definition(jb, artifact, product)
    var_name, path_var_name, lazy_path_var_name = gen_lazy_artifact_path(jb, artifact, product)
    push!(jb.top_level_blocks, emit_typed_global(
        var_name, String, ""; isconst=false,
    ))
    push!(jb.init_blocks, :(global $(var_name) = $(path_var_name)))
    push!(jb.exports, var_name)

    alias_definitions(jb, product, path_var_name) do alias
        push!(jb.top_level_blocks, emit_typed_global(alias, String, ""; isconst=false))
        push!(jb.init_blocks, :(global $(alias) = $(var_name)))
    end
end
