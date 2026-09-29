using BinaryBuilderProducts, JLLGenerator

const static_pass_name = "resolve_static_libraries!"

"""
    StaticDepResolution

What the auditor learned about a single declared dependency edge of an archive:
whether the library it names ships a static archive, and which symbols we could
actually observe it providing.  `symbols === nothing` means the library's files are
not reachable from here (it lives in a JLL whose artifact is not unpacked for this
build), so nothing can be verified against it.
"""
struct StaticDepResolution
    dep::JLLLibraryDep
    has_static::Bool
    symbols::Union{Nothing,Set{String}}
end

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
    # Once resolved, the edges are checked against what the libraries they name really
    # provide: every symbol an archive leaves undefined must be satisfied by them.

    function resolve(rel_path::String, dep::LibraryDependency)
        jll_dep = JLLLibraryDep(dep.pkg, dep.varname)
        if dep.pkg === nothing
            if dep.varname ∉ own_libraries
                push_result!(pass_results, static_pass_name, :fail, rel_path,
                             "Dependency '$(dep.varname)' does not name any library product of this build")
            end
        else
            dep_info = get(info.deps, dep.pkg, nothing)
            if dep_info === nothing
                push_result!(pass_results, static_pass_name, :fail, rel_path,
                             "Dependency '$(dep_string(jll_dep))' names '$(dep.pkg)', which is not a dependency of this build")
            elseif !any(lib -> lib.varname == dep.varname, dep_info.libs)
                available = join(sort(unique(string(lib.varname) for lib in dep_info.libs)), ", ")
                push_result!(pass_results, static_pass_name, :fail, rel_path,
                             "Dependency '$(dep_string(jll_dep))' does not name a library product of '$(dep.pkg)' (it provides: $(isempty(available) ? "nothing" : available))")
            end
        end
        return jll_dep
    end
    resolve(rel_path::String, deps::Vector{LibraryDependency}) = unique!(JLLLibraryDep[resolve(rel_path, dep) for dep in deps])

    # Archives are read at most once each; one that cannot be read fails the audit
    # for the archive the reading was on behalf of.
    contents_cache = Dict{String,Union{Nothing,ArchiveContents}}()
    function archive_contents(abs_path::String, on_behalf_of::String)
        get!(contents_cache, abs_path) do
            try
                contents = scan_static_archive(abs_path)
                if contents === nothing
                    push_result!(pass_results, static_pass_name, :fail, on_behalf_of,
                                 "'$(relpath(abs_path, scan.prefix))' is not a static archive")
                end
                contents
            catch e
                isa(e, ArgumentError) || rethrow()
                push_result!(pass_results, static_pass_name, :fail, on_behalf_of,
                             "Unable to read static archive '$(relpath(abs_path, scan.prefix))': $(e.msg)")
                nothing
            end
        end
    end

    # The libraries of this build, by name: where each one's archive and shared object are
    own_archives = Dict{Symbol,String}(slp.varname => rel_path for (rel_path, slp) in scan.static_library_products)
    own_objects = Dict{Symbol,String}(lib.varname => rel_path for (rel_path, lib) in scan.library_products)
    ctx = (; scan, pass_results, info, archive_contents, own_archives, own_objects)

    dynamic_libs = Dict{Symbol,JLLLibraryProduct}(p.varname => p for p in products if isa(p, JLLLibraryProduct))
    for (rel_path, slp) in scan.static_library_products
        shlib = get(dynamic_libs, slp.varname, nothing)
        if shlib === nothing
            # no corresponding dynamic library - require explicit deps
            if slp.deps === nothing || slp.system_deps === nothing
                push_result!(pass_results, static_pass_name, :fail, rel_path,
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

        # Check the declaration against what is really there
        resolutions = resolve_static_deps!(ctx, rel_path, deps)
        contents = archive_contents(abspath(scan, rel_path), rel_path)
        if contents !== nothing
            verify_static_closure!(ctx, rel_path, contents, resolutions, shlib)
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

# The spelling of an edge in messages: `libz` for a library of this JLL, `Zlib_jll.libz` otherwise
dep_string(d::JLLLibraryDep) = d.mod === nothing ? string(d.varname) : string(d.mod, ".", d.varname)

"""
    resolve_static_deps!(ctx, rel_path, deps)

Look up what each dependency edge of the archive at `rel_path` names: whether that
library ships an archive, and which symbols it can be seen to provide.  An edge
naming a library that does not exist has already failed the audit when it was
declared, and is left out here.
"""
function resolve_static_deps!(ctx, rel_path::String, deps::Vector{JLLLibraryDep})
    resolutions = StaticDepResolution[]
    for dep in deps
        resolution = dep.mod === nothing ? resolve_own_dep(ctx, rel_path, dep) : resolve_foreign_dep(ctx, rel_path, dep)
        resolution === nothing && continue
        if !resolution.has_static
            # Not an anomaly: linking an archive against a dependency that only ships a
            # shared library is the normal arrangement (libgfortran.a against libgcc_s,
            # say).  It is noted so that the consumer's provisioning is visible in the
            # audit log, but must not fail the build.
            push_result!(ctx.pass_results, static_pass_name, :success, rel_path,
                         "Dependency '$(dep_string(dep))' has no static library; a static link against this archive will provision it dynamically")
        end
        push!(resolutions, resolution)
    end
    return resolutions
end

# A library of this build: its archive, if it has one, and its shared object
function resolve_own_dep(ctx, rel_path::String, dep::JLLLibraryDep)
    archive_rel_path = get(ctx.own_archives, dep.varname, nothing)
    object_rel_path = get(ctx.own_objects, dep.varname, nothing)
    archive_rel_path === nothing && object_rel_path === nothing && return nothing
    symbols = Set{String}()
    if archive_rel_path !== nothing
        contents = ctx.archive_contents(abspath(ctx.scan, archive_rel_path), rel_path)
        contents === nothing || union!(symbols, contents.defined)
    end
    if object_rel_path !== nothing
        oh = get(ctx.scan.binary_objects, object_rel_path, nothing)
        if oh !== nothing
            defined, _, _ = object_symbols(oh)
            union!(symbols, defined)
        end
    end
    return StaticDepResolution(dep, archive_rel_path !== nothing, symbols)
end

# A library of a dependency: what its records say, and, when its artifact is
# unpacked for this build, what its files say
function resolve_foreign_dep(ctx, rel_path::String, dep::JLLLibraryDep)
    dep_info = get(ctx.info.deps, dep.mod, nothing)
    dep_info === nothing && return nothing
    libs = dep_info.libs
    dynamic = findfirst(l -> isa(l, JLLLibraryProduct) && l.varname == dep.varname, libs)
    static = findfirst(l -> isa(l, JLLStaticLibraryProduct) && l.varname == dep.varname, libs)
    dynamic === nothing && static === nothing && return nothing

    # Without the dependency's files, the edge can only be taken on trust
    artifact_dir = dep_info.artifact_dir
    if artifact_dir === nothing || !isdir(artifact_dir)
        return StaticDepResolution(dep, static !== nothing, nothing)
    end
    symbols = Set{String}()
    if static !== nothing
        archive_path = joinpath(artifact_dir, libs[static].path)
        if isfile(archive_path)
            contents = ctx.archive_contents(archive_path, rel_path)
            contents === nothing || union!(symbols, contents.defined)
        end
    end
    if dynamic !== nothing
        object_path = joinpath(artifact_dir, libs[dynamic].path)
        if isfile(object_path)
            oh = get_object_handle(object_path, ctx.scan.platform)
            if oh !== nothing
                defined, _, _ = object_symbols(oh)
                union!(symbols, defined)
            end
        end
    end
    return StaticDepResolution(dep, static !== nothing, isempty(symbols) ? nothing : symbols)
end

"""
    verify_static_closure!(ctx, rel_path, contents, resolutions, dynamic_variant)

Check that every symbol the archive leaves undefined is provided by something we
know about: a resolved dependency, or, for a library that also ships as a shared
object, whatever its dynamic variant resolved at link time.  That dynamic variant
is a reliable oracle: it was linked successfully against precisely the libraries the archive
declares, so the symbols it defines and imports are exactly what a static link of
the same objects will need, its declared system libraries and the C runtime
included.

An unresolved symbol fails the audit when every dependency could be read, and is a
warning when one could not, since then the symbol cannot be proven missing.
"""
function verify_static_closure!(ctx, rel_path::String, contents::ArchiveContents,
                                resolutions::Vector{StaticDepResolution},
                                dynamic_variant::Union{Nothing,JLLLibraryProduct})
    # Weak undefined symbols legitimately resolve to zero, and linker-synthesized
    # symbols are never provided by a library.
    unresolved = setdiff(contents.undefined, contents.weak_undefined, linker_synthesized_symbols)

    provided = Set{String}()
    unreadable = String[]
    for resolution in resolutions
        if resolution.symbols === nothing
            push!(unreadable, dep_string(resolution.dep))
        else
            union!(provided, resolution.symbols)
        end
    end
    if dynamic_variant !== nothing
        oh = get(ctx.scan.binary_objects, dynamic_variant.path, nothing)
        if oh !== nothing
            defined, undefined, _ = object_symbols(oh; only_external = false)
            union!(provided, defined, undefined)
        end
    end
    setdiff!(unresolved, provided)

    if isempty(unresolved)
        push_result!(ctx.pass_results, static_pass_name, :success, rel_path,
                     "Static closure verified ($(contents.num_objects) objects)")
        return nothing
    end
    missing_syms = sort(collect(unresolved))
    preview = join(first(missing_syms, 10), ", ")
    if length(missing_syms) > 10
        preview = string(preview, ", ... (", length(missing_syms) - 10, " more)")
    end
    if dynamic_variant === nothing && isempty(resolutions)
        push_result!(ctx.pass_results, static_pass_name, :warn, rel_path,
                     "$(length(missing_syms)) undefined symbols left unverified (no dynamic variant and no declared dependencies to check against; assumed to come from the declared system libraries or the C runtime): $(preview)")
    elseif !isempty(unreadable)
        push_result!(ctx.pass_results, static_pass_name, :warn, rel_path,
                     "$(length(missing_syms)) undefined symbols left unverified (could not inspect $(join(unreadable, ", "))): $(preview)")
    else
        push_result!(ctx.pass_results, static_pass_name, :fail, rel_path,
                     "$(length(missing_syms)) undefined symbols are not provided by the archive, its declared dependencies, or the C runtime: $(preview)")
    end
    return nothing
end
