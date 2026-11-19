"""
    relocate_pkgconfig_files!(result::AuditResult, prefix_alias::String)

Makes pkg-config (`.pc`) files relocatable by replacing every mention of the
absolute build prefix `prefix_alias` with a path relative to `\${pcfiledir}`,
e.g. `prefix=/workspace/destdir/foo` in `lib/pkgconfig/foo.pc` becomes
`prefix=\${pcfiledir}/../..`.  Symlinks are skipped, as `\${pcfiledir}`
refers to the directory of the file they point to, which is relocated itself.
"""
function relocate_pkgconfig_files!(result::AuditResult, prefix_alias::String)
    scan, pass_results = result.scan, result.pass_results
    # Match `prefix_alias` only when it is followed by `/` or the end of the path
    alias_re = Regex(string("\\Q", rstrip(prefix_alias, '/'), "\\E", raw"(?![\w.+-])"))

    for rel_path in sort!([p for (p, st) in scan.files if endswith(p, ".pc") && !islink(st)])
        path = joinpath(scan.prefix, rel_path)
        content = read(path, String)
        occursin(alias_re, content) || continue

        # One `..` per directory between the prefix and the `.pc` file
        pc_prefix = join(["\${pcfiledir}"; fill("..", count('/', rel_path))], "/")
        write(path, replace(content, alias_re => pc_prefix))
        push_result!(pass_results, "relocate_pkgconfig_files!", :success, rel_path, "prefix -> $(pc_prefix)")
    end
end
