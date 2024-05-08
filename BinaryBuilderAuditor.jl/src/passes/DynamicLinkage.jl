using BinaryBuilderProducts, JLLGenerator

function resolve_dynamic_links!(scan::ScanResult,
                                library_products::Vector{LibraryProduct},
                                dep_libs::Dict{Symbol,Vector{JLLLibraryProduct}},
                                env::Dict{String,String} = Dict{String,String}(
                                    "prefix" => scan.prefix,
                                    "bb_full_target" => triplet(scan.platform),
                                ),
                                verbose::Bool = false)
    # Invert `dep_libs` to be mapping SONAME -> (jll_name, lib_varname)
    soname_map = Dict{String,Tuple{Union{Symbol,Nothing},Symbol}}()
    for (jll_name, libs) in dep_libs
        for lib in libs
            if lib.soname ∈ keys(soname_map)
                @error("Duplicate SONAMEs detected", lib.soname)
                error("Duplicate SONAMEs detected")
            end
            soname_map[lib.soname] = (jll_name, lib.varname)
        end
    end

    # Add in the libraries in the current JLL, but with `jll_name` set to `nothing`
    # Also, avoid needing to call `locate()` multiple times
    for lib in library_products
        lib_located_path = locate(lib, scan.prefix; env, scan.platform)
        if lib_located_path === nothing
            @error("Unable to locate library", lib, scan.prefix)
            error("Unable to locate library")
        end
        scan.library_products[lib] = relpath(scan, lib_located_path)
        soname = get_soname(scan, lib)
        soname_map[soname] = (nothing, lib.varname)
    end

    # Ensure that symlinks of `libfoo.so` -> `libfoo.so.1` also work,
    # since that's common to see within a single JLL, as the linking
    # would be done _before_ our `ensure_sonames!()` has a chance to run.
    # We'll fix this up at the end of this function
    soname_forwards = Dict{String,String}()
    for (rel_path, link_target) in scan.symlinks
        for (lib, lib_rel_path) in scan.library_products
            if link_target == lib_rel_path
                soname = basename(rel_path)
                soname_map[soname] = (nothing, lib.varname)
                soname_forwards[soname] = get_soname(scan, lib)
            end
        end
    end

    # Iterate over our own library products, get list of dependencies,
    # resolve each dep to its matching value in `soname_map`
    stale_linkages = []
    jll_lib_products = JLLLibraryProduct[]
    for lib in library_products
        rel_path = scan.library_products[lib]
        oh = scan.binary_objects[rel_path]
        lib_soname = get_soname(oh)

        # Resolve each dependency to one of the `LibraryLink` objects
        # we created above, use that to construct a `JLLLibraryDep`
        jll_deps = JLLLibraryDep[]

        for soname in [path(dl) for dl in DynamicLinks(oh)]
            # Skip system libraries that we don't want to track, because
            # we don't redistribute them.
            if is_system_library(soname, scan.platform)
                @debug("Skipping system library", dep_soname=soname, lib_path=rel_path)
                continue
            end

            if !haskey(soname_map, soname)
                @error("Unable to map dependency", dep_soname=soname, lib_path=rel_path)
                error("Unable to map dependency")
            end

            # If this is not the real name (e.g. the user build `libfoo.so.1` without an
            # embedded SONAME, provided a symlink `libfoo.so -> libfoo.so.1`, and then
            # compiled `libbar.so` to link against `libfoo.so`) then we need to update
            # its linkage:
            if soname ∈ keys(soname_forwards)
                update_linkage!(scan, rel_path, soname, soname_forwards[soname]; verbose)
                soname = soname_forwards[soname]
            end
            jll_name, lib_varname = soname_map[soname]
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
                         old_soname::AbstractString, new_soname::AbstractString;
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
        @error("Unable to update linkage library", rel_path, old_soname, new_soname)
        error("Unable to update linkage on library")
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

    # Build mapping from SONAME to relative path
    soname_map = Dict{String,String}()
    for (_, rel_path) in scan.library_products
        soname = get_soname(scan.binary_objects[rel_path])
        soname_map[soname] = rel_path
    end
    for (_, libs) in dep_libs
        for lib in libs
            soname_map[lib.soname] = lib.path
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
            push!(dep_relpaths, relpath(dirname(soname_map[soname]), dirname(rel_path)))
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
            error("Unable to set RPATH on library")
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
