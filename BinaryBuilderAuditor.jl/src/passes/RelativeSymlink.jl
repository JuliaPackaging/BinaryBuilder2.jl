"""
    absolute_to_relative_symlinks!(scan::ScanResult, prefix_alias::String)

Finds symlinks within the given `ScanResult`, converting any absolute links
to relative links, as long as the link target lies within the given `prefix`.
Because we are generally operating on files outside of the sandbox environment,
we allow passing in `prefix_alias` to serve as the in-sandbox path prefix, as
that is the prefix that symlinks would have been pointing to.
"""
function absolute_to_relative_symlinks!(scan::ScanResult, prefix_alias::String; verbose::Bool = false)
    if !isabspath(prefix_alias)
        throw(ArgumentError("prefix_alias must be an absolute path!"))
    end

    for (rel_path, link_target) in scan.symlinks
        # We explicitly do NOT use `abspath(scan, rel_path)` here, because
        # we need to not dereference the link!
        abs_path = joinpath(scan.prefix, rel_path)

        # If this symlink points to an absolute path within
        # our prefix, translate it to a relative path
        if startswith(readlink(abs_path), prefix_alias)
            new_link_target = relpath(
                joinpath(prefix_alias, link_target),
                joinpath(prefix_alias, dirname(rel_path)),
            )
            if verbose
                @info("Converting relative symlink", rel_path, new_link_target)
            end
            rm(abs_path; force=true)
            symlink(new_link_target, abs_path)
        end
    end
end
