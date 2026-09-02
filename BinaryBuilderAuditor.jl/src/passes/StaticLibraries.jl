using BinaryBuilderProducts, JLLGenerator
using BinaryBuilderProducts: resolve_deps

"""
    resolve_static_libraries!(scan, pass_results, jll_lib_products)

Describe every static archive the scan located as a library entry of its own.

An archive subordinate to a library product is written under that product's name:
the two are one library, described once per linkage.  Its dependency edges and
system dependencies default to those of the dynamic sibling, which
`resolve_dynamic_links!` has just derived from the shared library's own linkage
(the two are built from the same objects); the product's declaration may augment
or replace either list, see [`StaticLibraryProduct`](@ref).  A replacement that
drops entries the sibling has is pointed out in the log, since archives can
legitimately differ from their siblings but usually do not.  A standalone archive
declares everything itself.

Nothing is read from the archives here: the record says what the recipe declared,
and what the sibling was observed to link against.

Returns the products handed in, plus one entry per archive.
"""
function resolve_static_libraries!(scan::ScanResult,
                                   pass_results::Dict{String,Vector{PassResult}},
                                   jll_lib_products::Vector{AbstractJLLProduct})
    if isempty(scan.static_library_products)
        return jll_lib_products
    end

    products = AbstractJLLProduct[]
    for product in jll_lib_products
        # Every product we were handed stays; an archive is written as an additional
        # entry sharing its sibling's name, never in place of it
        push!(products, product)
        isa(product, JLLLibraryProduct) || continue
        static_rel_path = get(scan.static_archives, product.varname, nothing)
        static_rel_path === nothing && continue
        slp = scan.static_library_products[static_rel_path]

        inherited_deps = String[generate_toml_dict(d) for d in product.deps]
        deps, omitted_deps = resolve_deps(slp.deps, inherited_deps)
        system_deps, omitted_system_deps = resolve_deps(slp.system_deps, product.system_deps)
        note_omissions(static_rel_path, "dependencies", omitted_deps)
        note_omissions(static_rel_path, "system dependencies", omitted_system_deps)

        push!(products, JLLStaticLibraryProduct(
            product.varname,
            static_rel_path;
            deps = JLLLibraryDep[parse_toml_dict(JLLLibraryDep, d) for d in deps],
            system_deps,
        ))
    end

    # Standalone archives have no sibling to learn from and declare everything themselves
    for (rel_path, slp) in scan.static_library_products
        slp.varname === nothing && continue
        deps, _ = resolve_deps(slp.deps, String[])
        system_deps, _ = resolve_deps(slp.system_deps, String[])
        push!(products, JLLStaticLibraryProduct(
            slp.varname,
            rel_path;
            deps = JLLLibraryDep[parse_toml_dict(JLLLibraryDep, d) for d in deps],
            system_deps,
        ))
    end

    # One library, once per linkage: the loadable entry first
    sort!(products; by = p -> (p.varname, isa(p, JLLStaticLibraryProduct)))
    return products
end

# A replacing declaration that drops what the sibling links is worth a look, but it
# is the recipe author's call: this is a log message, not an audit result.
function note_omissions(rel_path::String, what::String, omitted::Vector{String})
    isempty(omitted) && return nothing
    @warn("Declared $(what) of '$(rel_path)' omit $(length(omitted)) inherited from the dynamic sibling: $(join(omitted, ", "))")
    return nothing
end
