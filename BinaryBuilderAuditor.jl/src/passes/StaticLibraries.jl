using BinaryBuilderProducts, JLLGenerator

function resolve_static_libraries!(result::AuditResult, info::AuditInfo)
    scan, pass_results, products = result.scan, result.pass_results, result.jll_lib_products
    if isempty(scan.static_library_products)
        return result
    end
    own_libraries = Set{Symbol}(lib.varname for lib in values(scan.library_products))
    union!(own_libraries, (slp.varname for slp in values(scan.static_library_products)))

    # Unlike their dynamic counterparts, static libraries do not track dependency information
    # so the only resolution we can do here is to (1) translate the LibraryDependency's the
    # user provided explicitly, or (2) inherit the info from the dynamic audit.
    #
    # TODO: A proper audit would also verify that undefined symbols can be resolved as expected
    # by these dependencies.
    dep_string(d::JLLLibraryDep) = d.mod === nothing ? string(d.varname) : string(d.mod, ".", d.varname)

    function resolve(rel_path::String, dep::LibraryDependency)
        jll_dep = JLLLibraryDep(dep.pkg, dep.varname)
        if dep.pkg === nothing
            if dep.varname ∉ own_libraries
                push_result!(pass_results, "resolve_static_libraries!", :fail, rel_path,
                             "Dependency '$(dep.varname)' does not name any library product of this build")
            end
        else
            dep_info = get(info.deps, dep.pkg, nothing)
            if dep_info === nothing
                push_result!(pass_results, "resolve_static_libraries!", :fail, rel_path,
                             "Dependency '$(dep_string(jll_dep))' names '$(dep.pkg)', which is not a dependency of this build")
            elseif !any(lib -> lib.varname == dep.varname, dep_info.libs)
                available = join(sort(unique(string(lib.varname) for lib in dep_info.libs)), ", ")
                push_result!(pass_results, "resolve_static_libraries!", :fail, rel_path,
                             "Dependency '$(dep_string(jll_dep))' does not name a library product of '$(dep.pkg)' (it provides: $(isempty(available) ? "nothing" : available))")
            end
        end
        return jll_dep
    end
    resolve(rel_path::String, deps::Vector{LibraryDependency}) = unique!(JLLLibraryDep[resolve(rel_path, dep) for dep in deps])

    dynamic_libs = Dict{Symbol,JLLLibraryProduct}(p.varname => p for p in products if isa(p, JLLLibraryProduct))
    for (rel_path, slp) in scan.static_library_products
        shlib = get(dynamic_libs, slp.varname, nothing)
        if shlib === nothing
            # no corresponding dynamic library - require explicit deps
            if slp.deps === nothing || slp.system_deps === nothing
                push_result!(pass_results, "resolve_static_libraries!", :fail, rel_path,
                             "Standalone StaticLibraryProduct '$(slp.varname)' has no dynamic variant to inherit from; declare both `deps` and `system_deps` explicitly")
                continue
            end
            deps = resolve(rel_path, slp.deps)
            system_deps = unique(slp.system_deps)
        else
            if slp.deps === nothing
                deps = unique(shlib.deps) # inherit from dynamic library
            else
                deps = resolve(rel_path, slp.deps)
                # warn if the declared deps do not match the dynamic library
                note_omissions(rel_path, "dependencies", String[
                    d.mod === nothing ? string(d.varname) : "$(d.mod).$(d.varname)"
                    for d in setdiff(shlib.deps, deps)
                ])
            end
            if slp.system_deps === nothing
                system_deps = unique(shlib.system_deps) # inherit from dynamic library
            else
                system_deps = unique(slp.system_deps)
                # warn if the declared system_deps do not match the dynamic library
                note_omissions(rel_path, "system dependencies", setdiff(shlib.system_deps, system_deps))
            end
        end
        push!(products, JLLStaticLibraryProduct(slp.varname, rel_path; deps, system_deps))
    end

    sort!(products; by = p -> (p.varname, isa(p, JLLStaticLibraryProduct)))

    return result
end

function note_omissions(rel_path::String, what::String, omitted::Vector{String})
    isempty(omitted) && return nothing
    @warn("Declared $(what) of '$(rel_path)' omit $(length(omitted)) inherited from the dynamic variant: $(join(omitted, ", "))")
    return nothing
end
