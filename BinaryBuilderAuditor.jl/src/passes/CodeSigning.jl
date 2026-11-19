using ObjectFile
using ObjectFile.MachO: MH_EXECUTE, MH_DYLIB, MH_BUNDLE

"""
    needs_codesignature(oh::ObjectHandle)

Returns `true` for the Mach-O files that macOS checks the code signature of when
loading them: executables, dylibs and bundles.  Object files (`.o`) are not signed.
"""
needs_codesignature(oh::MachOHandle) = header(oh).filetype ∈ (MH_EXECUTE, MH_DYLIB, MH_BUNDLE)
needs_codesignature(oh::ObjectHandle) = false

"""
    ensure_codesigned!(result::AuditResult)

Gives every Mach-O executable, dylib and bundle in the prefix an ad-hoc code
signature with `ldid -S`.  Apple Silicon refuses to load binaries without a valid
signature, and any edit to a binary (such as the `install_name_tool` calls made by
the other passes) invalidates the signature the linker gave it, so this must run
after every pass that modifies binaries.  Every such file is signed, not only the
ones the auditor modified, so that files linked without a signature (or whose
signature a build step broke) load as well.  Does nothing on non-Apple platforms.
"""
function ensure_codesigned!(result::AuditResult)
    scan, pass_results = result.scan, result.pass_results
    if !Sys.isapple(scan.platform)
        return
    end

    signed = Set{String}()
    for rel_path in sort(collect(keys(scan.binary_objects)))
        if rel_path ∈ signed || !needs_codesignature(scan.binary_objects[rel_path])
            continue
        end

        # Sign each file once, even when it is installed under several (hard-linked) names
        names = hardlinks(scan, rel_path)
        union!(signed, names)

        abs_path = abspath(scan, rel_path)
        proc, output = with_writable(abs_path) do
            capture_output(ldid(scan, `-S $(abs_path)`))
        end
        if !success(proc)
            push_result!(pass_results, "ensure_codesigned!", :fail, rel_path, "Failed to sign: $(output)")
            continue
        end
        push_result!(pass_results, "ensure_codesigned!", :success, rel_path, "Signed (ad-hoc)")

        # `ldid` writes the signed file to a new inode and renames it into place, so
        # point the file's other names at the signed file again.
        old_st = scan.files[rel_path]
        scan.files[rel_path] = lstat(abs_path)
        for name in names
            if name != rel_path && scan.files[rel_path].inode != old_st.inode
                rm(abspath(scan, name))
                hardlink(abs_path, abspath(scan, name))
                scan.files[name] = lstat(abspath(scan, name))
            end
        end

        # Signing rewrites the `__LINKEDIT` segment and the `LC_CODE_SIGNATURE` load command
        refresh!(scan, rel_path)
    end
end
