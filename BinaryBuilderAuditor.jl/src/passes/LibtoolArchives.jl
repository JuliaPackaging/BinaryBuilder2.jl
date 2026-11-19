"""
    remove_libtool_archives!(result::AuditResult)

Deletes the libtool archives (`.la` files) found by `scan_files()`, and symlinks
to them.  They record the absolute paths of the build prefix and of each
dependency, which don't exist once the prefix is installed elsewhere, and
libtool would then fail to link against the library.  Without them, libtool
links against the shared or static library directly.
"""
function remove_libtool_archives!(result::AuditResult)
    scan, pass_results = result.scan, result.pass_results
    for rel_path in sort!(collect(scan.libtool_archives))
        rm(joinpath(scan.prefix, rel_path))
        delete!(scan.files, rel_path)
        delete!(scan.symlinks, rel_path)
        push_result!(pass_results, "remove_libtool_archives!", :success, rel_path, "removed")
    end
    empty!(scan.libtool_archives)
end
