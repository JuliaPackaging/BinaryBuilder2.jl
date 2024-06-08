using BinaryBuilderProducts, JLLGenerator

function resolve_dynamic_links!(scan::ScanResult,
                                dep_libs::Dict{Symbol,Vector{JLLLibraryProduct}},
                                verbose::Bool = false)
    # We need to generate a graph showing which libraries are needed by the
    # `library_products` in our `scan`.
    dep_soname_map = Dict{String,Tuple{Symbol,Symbol}}()
    for (jll_name, libs) in dep_libs
        for lib in libs
            dep_soname_map[lib.soname] = (Symbol(string(jll_name, "_jll")), lib.varname)
        end
    end

    # Iterate over our own library products, get list of dependencies,
    # resolve each dep to its matching value in `soname_map`
    jll_lib_products = JLLLibraryProduct[]
    for (rel_path, lib) in scan.library_products
        oh = scan.binary_objects[rel_path]
        lib_soname = get_soname(oh)

        # Resolve each dependency to one of the `LibraryLink` objects
        # we created above, use that to construct a `JLLLibraryDep`
        jll_deps = JLLLibraryDep[]
        for lib_dep_soname in [path(dl) for dl in DynamicLinks(oh)]
            # Skip system libraries that we don't want to track, because
            # we don't redistribute them.
            if is_system_library(lib_dep_soname, scan.platform)
                @debug("Skipping system library", lib_dep_soname, lib_path=rel_path)
                continue
            end

            # First, is this a library from a dependency?
            local jll_name, lib_varname
            if haskey(dep_soname_map, lib_dep_soname)
                jll_name, lib_varname = dep_soname_map[lib_dep_soname]

            # If not, does it come from our current JLL?
            else
                # If this is not the real name (e.g. the user build `libfoo.so.1` without an
                # embedded SONAME, provided a symlink `libfoo.so -> libfoo.so.1`, and then
                # compiled `libbar.so` to link against `libfoo.so`) then we need to update
                # its linkage:
                if haskey(scan.soname_forwards, lib_dep_soname)
                    update_linkage!(scan, rel_path, lib_dep_soname => scan.soname_forwards[lib_dep_soname]; verbose)
                    lib_dep_soname = scan.soname_forwards[lib_dep_soname]
                end

                if !haskey(scan.soname_locator, lib_dep_soname)
                    @error("Unable to map dependency", lib_dep_soname, lib_path=rel_path)
                    error()
                end
                dep_lib_relpath = scan.soname_locator[lib_dep_soname]

                if !haskey(scan.library_products, dep_lib_relpath)
                    @show scan.library_products
                    @error("Dependency on library that is not listed as a LibraryProduct!", rel_path, lib_dep_soname)
                    error()
                end

                jll_name = nothing
                lib_varname = scan.library_products[dep_lib_relpath].varname
            end
            push!(jll_deps, JLLLibraryDep(jll_name, lib_varname))
        end

        push!(jll_lib_products, JLLLibraryProduct(
            lib.varname,
            rel_path,
            jll_deps;
            flags = lib.dlopen_flags,
            soname = lib_soname,
            on_load_callback = lib.on_load_callback,
        ))
    end

    # These returned products have all of their dependencies resolved as
    # JLLLibraryDep objects, either pointing at other libraries wtihin this
    # JLL, or to libraries from other JLLs.
    return jll_lib_products
end

function update_linkage!(scan::ScanResult, rel_path::AbstractString,
                         (old_soname, new_soname)::Pair{<:AbstractString,<:AbstractString};
                         verbose::Bool = false)
    if Sys.iswindows(scan.platform)
        return
    end

    abs_path = abspath(scan, rel_path)
    if Sys.isapple(scan.platform)
        @warn("TODO: Do something with `install_name_tool` here")
    else
        cmd = patchelf(scan, `--replace-needed $(old_soname) $(new_soname) $(abs_path)`)
    end

    if verbose
        @info("Updating linkage", rel_path, old_soname, new_soname)
    end

    proc, output = capture_output(cmd)
    if !success(proc)
        println(String(take!(output)))
        @error("Unable to update linkage", rel_path, old_soname, new_soname)
        error()
    end

    # Ensure that our object handle gets refreshed
    refresh!(scan, rel_path)
end

function rpaths_consistent!(scan::ScanResult,
                            dep_libs::Dict{Symbol,Vector{JLLLibraryProduct}};
                            verbose::Bool = false)
    # Windows doesn't do RPATHs, *sob*
    if Sys.iswindows(scan.platform)
        return
    end

    # Augment `scan.soname_locator` with information from `dep_libs`:
    soname_locator = copy(scan.soname_locator)
    for (_, libs) in dep_libs
        for lib in libs
            soname_locator[lib.soname] = lib.path
        end
    end

    # For each binary object, we need to build a list of the relative paths
    # from it to its dependencies, then ensure that all of those paths are
    # present in the RPATHs of that binary object
    for (rel_path, oh) in scan.binary_objects
        dep_relpaths = Set{String}()
        for soname in [path(dl) for dl in DynamicLinks(oh)]
            # Don't try to insert RPATHs for system libraries
            if is_system_library(soname, scan.platform)
                continue
            end
            # Map through symlink forwards
            soname = get(scan.soname_forwards, soname, soname)

            if soname ∉ keys(soname_locator)
                @error("Unable to resolve dependency", lib_path=rel_path, soname)
                error()
            end
            push!(dep_relpaths, relpath(dirname(soname_locator[soname]), dirname(rel_path)))
        end

        # Read RPATHs of this binary object
        obj_rpaths = rpaths(RPath(oh))

        # Normalize the RPATHs, forcing them to be unique, and relative
        # to the originating object, (append all of our auto-detected RPATHs
        # onto the end of the RPATHs that already exist in the object)
        all_rpaths = String[String(x) for x in vcat(obj_rpaths, collect(dep_relpaths))]
        obj_rpaths = normalize_rpaths(all_rpaths, scan.platform, scan.prefix, rel_path)

        # Now, add them into the actual object
        abs_path = abspath(scan, rel_path)
        rpath_str = join(obj_rpaths, ':')
        if Sys.isapple(scan.platform)
            error("TODO: Implement this with install_name_tool")
        elseif Sys.islinux(scan.platform) || Sys.isbsd(scan.platform)
            cmd = patchelf(scan, `--set-rpath $(rpath_str) $(abs_path)`)
        end

        if verbose
            @info("Setting RPATH", rel_path, rpath_str)
        end

        proc, output = capture_output(cmd)
        if !success(proc)
            println(String(take!(output)))
            @error("Unable to set RPATH on library", rel_path, rpath_str)
            error()
        end
    end
end


function normalize_rpaths(rpaths::Vector{String}, platform::AbstractPlatform, prefix::String, obj_path::String)
    origin = "\$ORIGIN"
    if Sys.isapple(platform)
        origin = "@loader_path"
    end

    rpaths = map(rpaths) do rpath
        # If we have an absolute rpath, if it starts with `prefix`, rewrite it to be relative.
        if isabspath(rpath)
            if startswith(rpath, prefix)
                target = relpath(replace(rpath, prefix => ""), obj_path)
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
