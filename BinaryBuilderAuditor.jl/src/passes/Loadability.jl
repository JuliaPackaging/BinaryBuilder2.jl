# Check that every library product can be loaded by `dlopen()` in the prefix the build ran against.
# If auditing for a platform other than the current host, nothing is checked.
function libraries_loadable(result::AuditResult, info::AuditInfo)
    scan, pass_results = result.scan, result.pass_results
    if !platforms_match(scan.platform, HostPlatform())
        return result
    end
    rel_paths = sort(collect(keys(scan.library_products)))
    if isempty(rel_paths)
        return result
    end

    dep_trees = String[]
    for deps in (info.transitive_deps, info.deps), name in sort(collect(keys(deps)))
        if deps[name].artifact_dir !== nothing
            push!(dep_trees, deps[name].artifact_dir)
        end
    end

    # Put the prefix in the depot of the dependencies, so they can be hardlinked
    prefix = try
        mktempdir(isempty(dep_trees) ? tempdir() : dirname(dirname(first(dep_trees))))
    catch
        mktempdir()
    end
    try
        for tree in dep_trees
            deploy_tree(tree, prefix; link = true)
        end
        deploy_tree(scan.prefix, prefix; link = false)

        outcomes = asyncmap(rel_path -> try_dlopen(joinpath(prefix, rel_path)), rel_paths;
                            ntasks = Sys.CPU_THREADS)
        for (rel_path, (proc, output)) in zip(rel_paths, outcomes)
            if success(proc)
                push_result!(pass_results, "libraries_loadable", :success, rel_path, "Loaded with dlopen()")
            else
                reason = strip(first(split(output, "Stacktrace:")))
                push_result!(pass_results, "libraries_loadable", :fail, rel_path, "Unable to dlopen() '$(rel_path)': $(reason)")
            end
        end
    finally
        rm(prefix; recursive = true, force = true)
    end
    return result
end

# Copy the tree at `src` over `dest`, hardlinking files instead when `link` is set
function deploy_tree(src::String, dest::String; link::Bool)
    for name in readdir(src)
        src_path, dest_path = joinpath(src, name), joinpath(dest, name)
        if !islink(src_path) && isdir(src_path)
            if islink(dest_path) || (ispath(dest_path) && !isdir(dest_path))
                rm(dest_path; force = true)
            end
            mkpath(dest_path)
            deploy_tree(src_path, dest_path; link)
            continue
        end
        rm(dest_path; force = true, recursive = true)
        if islink(src_path)
            symlink(readlink(src_path), dest_path)
        elseif !(link && try_hardlink(src_path, dest_path))
            cp(src_path, dest_path)
        end
    end
end

# Hardlinking fails across filesystems
function try_hardlink(src::String, dest::String)
    try
        hardlink(src, dest)
        return true
    catch
        return false
    end
end

# `dlopen()` a library in a fresh Julia process, with no help from the loader's search path
function try_dlopen(path::String)
    env = filter(((k, _),) -> k ∉ ("LD_LIBRARY_PATH", "DYLD_LIBRARY_PATH", "DYLD_FALLBACK_LIBRARY_PATH"), ENV)
    cmd = `$(Base.julia_cmd()) --startup-file=no --history-file=no -e "using Libdl; dlopen(ARGS[1])" $(path)`
    return capture_output(setenv(cmd, env))
end
