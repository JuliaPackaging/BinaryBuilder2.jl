using ObjectFile, Patchelf_jll


"""
    ensure_sonames!(scan::ScanResult)

We want all libraries to have consistent SONAMEs.  This makes it much easier to
ensure that dependencies are matched up properly when loading, since we rely
upon the dynamic linker's SONAME short-circuit when loading transitive library
dependencies. To enforce this, we ensure that every non-Windows target has a
reasonable SONAME in all of its libraries.

This function also has a side-effect of filling out `scan.soname_locator`, which
allows mapping from library SONAME to `rel_path`, which is very useful for
resolving dynamic linkage.
"""
function ensure_sonames!(scan::ScanResult, pass_results::Dict{String,Vector{PassResult}})
    # Windows doesn't do SONAMEs, it just always uses the basename of the DLL.
    if Sys.iswindows(scan.platform)
        return
    end

    # `scan_files()` already found the libraries with missing SONAMEs,
    # so here all we need to do is update the binaries
    for rel_path in scan.missing_sonames
        soname = basename(rel_path)
        abs_path = abspath(scan, rel_path)
        if Sys.isapple(scan.platform)
            cmd = `-id $(soname) $(abs_path)`
        elseif Sys.islinux(scan.platform) || Sys.isbsd(scan.platform)
            cmd = `$(patchelf()) $(patchelf_flags(scan.platform)) --set-soname $(soname) $(abs_path)`
        end

        proc, output = capture_output(cmd)
        if !success(proc)
            push_result!(pass_results, "ensure_sonames!", :fail, rel_path, "Failed to set SONAME: $(output)")
            continue
        end

        # Refresh our ObjectHandle, since the above manipulation
        # may have completely re-arranged things.
        refresh!(scan, rel_path)
    end
end

function get_soname(oh::ELFHandle)
    # Get the dynamic entries, see if it contains a DT_SONAME
    es = ELFDynEntries(oh)
    soname_idx = findfirst(e -> e.entry.d_tag == ELF.DT_SONAME, es)
    if soname_idx === nothing
        # If all else fails, just return the filename.
        return nothing
    end

    # Look up the SONAME from the string table
    return strtab_lookup(es[soname_idx])
end

function get_soname(oh::MachOHandle)
    # Get the dynamic entries, see if it contains an ID_DYLIB_CMD
    lcs = MachOLoadCmds(oh)
    id_idx = findfirst(lc -> typeof(lc) <: MachOIdDylibCmd, lcs)
    if id_idx === nothing
        return nothing
    end

    # Return the Dylib ID
    return dylib_name(lcs[id_idx])
end
get_soname(oh::COFFHandle) = nothing

function get_soname(scan::ScanResult, lib::LibraryProduct)
    lib_path = relpath(scan, scan.library_products[lib])
    return get_soname(scan.binary_objects[lib_path])
end
