path_within(path::AbstractString, dir::AbstractString) = path == dir || startswith(path, rstrip(dir, '/') * "/")

"""
    dangling_symlinks(result::AuditResult, prefix_alias::String)

Checks every symlink in the prefix (including symlinks to directories) and
fails the audit for each one whose target does not exist, that forms a loop,
or that resolves to a path outside of the prefix.  Absolute targets under
`prefix_alias` are checked inside the prefix.  Links to absolute paths outside
of `prefix_alias` refer to the user's system rather than the artifact and are
not checked.
"""
function dangling_symlinks(result::AuditResult, prefix_alias::String)
    scan, pass_results = result.scan, result.pass_results
    pass_name = "dangling_symlinks"
    for (root, dirs, files) in walkdir(scan.prefix)
        for name in vcat(dirs, files)
            abs_path = joinpath(root, name)
            if !islink(abs_path)
                continue
            end
            rel_path = relpath(abs_path, scan.prefix)
            target = readlink(abs_path)
            check_path = abs_path
            if isabspath(target)
                if !path_within(target, prefix_alias)
                    continue
                end
                check_path = joinpath(scan.prefix, relpath(target, prefix_alias))
            end

            resolved = try
                realpath(check_path)
            catch e
                if !isa(e, Base.IOError)
                    rethrow()
                end
                msg = e.code == Base.UV_ELOOP ? "symlink loop" : "dangling symlink"
                push_result!(pass_results, pass_name, :fail, rel_path, "$(msg) -> $(target)")
                continue
            end
            if !path_within(resolved, scan.prefix)
                push_result!(pass_results, pass_name, :fail, rel_path, "symlink points outside of the prefix -> $(target)")
            end
        end
    end
end
