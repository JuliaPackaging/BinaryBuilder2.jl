using BinaryBuilderProducts, JLLGenerator

function resolve_dynamic_links!(result::AuditResult, info::AuditInfo)
    scan, pass_results = result.scan, result.pass_results

    # Iterate over our own library products, get list of dependencies,
    # resolve each dep to the library providing it, in a dependency or in this JLL
    for (rel_path, lib) in scan.library_products
        local lib_soname, lib_deps

        # Helper to get the SONAME and dependencies from a binary object
        function get_soname_and_deps(oh::ObjectHandle)
            lib_soname = get_soname(oh)
            if lib_soname === nothing && Sys.iswindows(scan.platform)
                lib_soname = basename(rel_path)
            end
            lib_deps = [path(dl) for dl in DynamicLinks(oh)]
            return lib_soname, lib_deps
        end

        if rel_path ∈ keys(scan.binary_objects)
            lib_soname, lib_deps = get_soname_and_deps(scan.binary_objects[rel_path])
        else
            # Try to parse this as an implicit LD script, skipping it if we can't.
            ld_script = parse_implicit_ld_script(scan, rel_path)
            if ld_script === nothing
                @debug("Skipping unparseable library", lib_path=rel_path)
                continue
            end
            lib_deps = ld_script.dep_sonames
            # If there is only one backing library, we consider ourselves a
            # "forwarding" linker script, and just use the backing library directly
            if length(lib_deps) == 1
                oh = scan.binary_objects[scan.soname_locator[lib_deps[1]]]
                lib_soname, lib_deps = get_soname_and_deps(oh)
            else
                lib_soname = basename(rel_path)
            end
        end

        # Resolve each dependency to one of the `LibraryLink` objects
        # we created above, use that to construct a `JLLLibraryDep`
        jll_deps = JLLLibraryDep[]
        system_deps = String[]
        for lib_dep_soname in lib_deps
            lib_dep_soname = basename(lib_dep_soname)

            # First, is this a library from a dependency?
            local jll_name, lib_varname
            if haskey(info.sonames, lib_dep_soname)
                dep_lib = info.sonames[lib_dep_soname]
                jll_name = dep_lib.jll_name
                lib_varname = dep_lib.varname

            # If not, does it come from our current JLL?
            else
                # If this is not the real name (e.g. the user build `libfoo.so.1` without an
                # embedded SONAME, provided a symlink `libfoo.so -> libfoo.so.1`, and then
                # compiled `libbar.so` to link against `libfoo.so`) then we need to update
                # its linkage:
                if haskey(scan.soname_forwards, lib_dep_soname)
                    update_linkage!(result, rel_path, lib_dep_soname => scan.soname_forwards[lib_dep_soname])
                    lib_dep_soname = scan.soname_forwards[lib_dep_soname]
                end

                if !haskey(scan.soname_locator, lib_dep_soname)
                    # System libraries are checked as the last fallback so that we do not e.g.
                    # treat libgcc provided by the CSL JLL as system-provided
                    if is_system_library(lib_dep_soname, scan.platform)
                        name = system_library_linker_name(lib_dep_soname, scan.platform)
                        if name !== nothing
                            push!(system_deps, name)
                        end
                        continue
                    end
                    push_result!(pass_results, "resolve_dynamic_links!", :fail, rel_path, "Unable to map dependency '$(lib_dep_soname)'")
                    continue
                end
                dep_lib_relpath = scan.soname_locator[lib_dep_soname]

                if !haskey(scan.library_products, dep_lib_relpath)
                    push_result!(pass_results, "resolve_dynamic_links!", :fail, rel_path, "Dependency on '$(dep_lib_relpath)' is not listed as a LibraryProduct")
                    continue
                end

                jll_name = nothing
                lib_varname = scan.library_products[dep_lib_relpath].varname
            end
            push!(jll_deps, JLLLibraryDep(jll_name, lib_varname))
        end

        push!(result.jll_lib_products, JLLLibraryProduct(
            lib.varname,
            rel_path,
            jll_deps,
            sort(unique(system_deps));
            flags = lib.dlopen_flags,
            soname = lib_soname,
            on_load_callback = lib.on_load_callback,
        ))
    end

    # These products have all of their dependencies resolved as JLLLibraryDep
    # objects, either pointing at other libraries within this JLL, or to
    # libraries from other JLLs.
    sort!(result.jll_lib_products; by=jll->jll.varname)

    return result
end

function update_linkage!(result::AuditResult, rel_path::AbstractString,
                         (old_soname, new_soname)::Pair{<:AbstractString,<:AbstractString})
    scan, pass_results = result.scan, result.pass_results
    if Sys.iswindows(scan.platform)
        return
    end

    abs_path = abspath(scan, rel_path)
    if Sys.isapple(scan.platform)
        # `install_name_tool -change` only matches the full install name (e.g.
        # `@rpath/libfoo.dylib`), and silently does nothing otherwise, so find
        # the full name and keep its directory when swapping in the new name.
        oh = scan.binary_objects[rel_path]
        old_soname = only(path(dl) for dl in DynamicLinks(oh) if basename(path(dl)) == old_soname)
        if dirname(old_soname) != ""
            new_soname = string(dirname(old_soname), "/", new_soname)
        end
    end

    # The fact that these two commandlines serendipitously aligned their arguments made my day.
    if Sys.isapple(scan.platform)
        cmd = install_name_tool(scan, `-change $(old_soname) $(new_soname) $(abs_path)`)
    else
        cmd = patchelf(scan, `--replace-needed $(old_soname) $(new_soname) $(abs_path)`)
    end

    proc, output = with_writable(abs_path) do
        capture_output(cmd)
    end
    if !success(proc)
        push_result!(pass_results, "update_linkage!", :fail, rel_path, "Failed to update linkage '$(old_soname)' -> '$(new_soname)': $(output)")
    else
        push_result!(pass_results, "update_linkage!", :success, rel_path, "Updating linkage '$(old_soname)' -> '$(new_soname)'")
    end

    # Ensure that our object handle gets refreshed
    refresh!(scan, rel_path)
end

function rpaths_consistent!(result::AuditResult, info::AuditInfo)
    scan, pass_results = result.scan, result.pass_results
    # Windows doesn't do RPATHs, *sob*
    if Sys.iswindows(scan.platform)
        return
    end

    # Augment `scan.soname_locator` with the dependencies' libraries
    soname_locator = copy(scan.soname_locator)
    for (soname, dep_lib) in info.sonames
        soname_locator[soname] = dep_lib.path
    end

    # For each binary object, we need to build a list of the relative paths
    # from it to its dependencies, then ensure that all of those paths are
    # present in the RPATHs of that binary object
    for (rel_path, oh) in scan.binary_objects
        dep_relpaths = Set{String}()
        if !isdynamic(oh)
            continue
        end
        for soname in [basename(path(dl)) for dl in DynamicLinks(oh)]
            # Don't try to insert RPATHs for system libraries
            if is_system_library(soname, scan.platform)
                continue
            end

            # Map through symlink forwards
            soname = get(scan.soname_forwards, soname, soname)

            if soname ∉ keys(soname_locator)
                push_result!(pass_results, "rpaths_consistent!", :fail, rel_path, "Unable to resolve dependency '$(soname)'")
                continue
            end
            push!(dep_relpaths, relpath(dirname(soname_locator[soname]), dirname(rel_path)))
        end

        # Read RPATHs of this binary object
        obj_rpaths = rpaths(RPath(oh))

        # Normalize the RPATHs, forcing them to be unique, and relative
        # to the originating object, (append all of our auto-detected RPATHs
        # onto the end of the RPATHs that already exist in the object)
        all_rpaths = String[String(x) for x in vcat(obj_rpaths, collect(dep_relpaths))]
        all_rpaths = normalize_rpaths(all_rpaths, scan.platform, scan.prefix, rel_path)

        function run_and_log(cmd::Cmd, fatal::Bool, operation::String)
            proc, output = capture_output(cmd)
            if success(proc)
                push_result!(pass_results, "rpaths_consistent!", :success, rel_path, operation)
            else
                push_result!(pass_results, "rpaths_consistent!", fatal ? :fail : :warn, rel_path, "Failed to $(operation): $(output)")
            end
        end

        # Now, add them into the actual object
        abs_path = abspath(scan, rel_path)
        rpath_str = join(all_rpaths, ':')
        with_writable(abs_path) do
            if Sys.isapple(scan.platform)
                # Remove all rpaths from the object:
                for rpath in obj_rpaths
                    run_and_log(
                        install_name_tool(scan, `-delete_rpath $(rpath) $(abs_path)`),
                        false,
                        "Delete RPATH '$(rpath)'",
                    )
                end

                # Build up our new rpath:
                for rpath in all_rpaths
                    run_and_log(
                        install_name_tool(scan, `-add_rpath $(rpath) $(abs_path)`),
                        true,
                        "Add RPATH '$(rpath)'",
                    )
                end
            else
                run_and_log(
                    patchelf(scan, `--set-rpath $(rpath_str) $(abs_path)`),
                    true,
                    "Set RPATH '$(rpath_str)'",
                )
            end
        end
    end
end


function normalize_rpaths(rpaths::Vector{String}, platform::AbstractPlatform, prefix::String, obj_path::String)
    origin = "\$ORIGIN"
    if Sys.isapple(platform)
        origin = "@loader_path"
    end

    # Drop empty entries
    rpaths = filter(!isempty, rpaths)

    rpaths = map(rpaths) do rpath
        # If we have an absolute rpath, if it starts with `prefix`, rewrite it to be relative.
        if isabspath(rpath)
            if startswith(rpath, prefix)
                target = relpath(rpath, dirname(joinpath(prefix, obj_path)))
                rpath = joinpath(origin, target)
            else
                # Do nothing in this case, just leave it be, could be a weird system library or something
                @debug("External Absolute RPATH entry", rpath, obj_path)
            end
        else
            # If it's not an absolute rpath, then let's make sure it starts with `$(origin)`
            if !startswith(rpath, origin)
                # `relpath(rpath, ".")` is a convenient way of normalizing out paths that
                # start with `./`, reducing `a/../b/c` -> `b/c`, etc..., but it only works
                # if we already know that `rpath` is a relative path!
                rpath = joinpath(origin, relpath(rpath, "."))
            end
        end
        return rpath
    end

    # I don't like strings ending in '/.', like '$ORIGIN/.'.  I don't think
    # it semantically makes a difference, but why not be correct AND beautiful?
    rpaths = map(rpaths) do rpath
        if endswith(rpath, "/.")
            return rpath[1:end-2]
        end
        return rpath
    end

    return unique(rpaths)
end
