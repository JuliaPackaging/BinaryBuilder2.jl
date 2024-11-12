struct ImplicitLDScript
    # Deps that this ld script links in, represented as relpaths
    dep_sonames::Vector{String}
end

"""
    parse_implicit_ld_script(path::String)

An EXTREMELY simple ld script parser, this probably fails for
all kinds of valid ld scripts, this is written basically just to
pass for things like `libgcc_s.so` that gets built by `GCC_jll`.

This is made only to work with "implicit" LD scripts, which are
defined by [0] to contain only INPUT and GROUP commands.

Feel free to expand this as needed in the future.

[0] https://ftp.gnu.org/old-gnu/Manuals/ld-2.9.1/html_chapter/ld_3.html
"""
function parse_implicit_ld_script(scan::ScanResult, rel_path::String)
    text = String(read(joinpath(scan.prefix, rel_path)))

    # Invalid text?  Probably a binary file of some kind.
    if !isvalid(text)
        return nothing
    end

    # First, eliminate any comments:
    text = replace(text, r"/\*.*\*/"s => "")

    # Next, parse out commands, ensure that they are all what we expect:
    lines = filter(!isempty, strip.(split(text, "\n")))

    deps = String[]
    for line in lines
        # Parse the `GROUP( libA libB )`... line
        m = match(r"^GROUP\s+\(([^)]+)\)", line)
        if m !== nothing
            # We just blindly find things that have SONAMEs that we've
            # seen before, and include those.  If we don't find it in our
            # SONAME 
            for lib in Base.shell_split(m.captures[1])
                lib_relpath = relpath(scan, joinpath(dirname(rel_path), lib))

                # If this matches a binary file in that same directory,
                # store its SONAME in our deps
                if haskey(scan.binary_objects, lib_relpath)
                    oh = scan.binary_objects[lib_relpath]
                    lib_soname = get_soname(oh)
                    if lib_soname === nothing
                        lib_soname = basename(lib_relpath)
                    end
                    push!(deps, lib_soname)
                else
                    # Otherwise, just skip it.
                    @debug("Skipping ld script library", ld_script=rel_path, lib)
                end
            end
        else
            if match(r"^VERSION\s+", line) === nothing &&
               match(r"^INPUT\s+", line) === nothing
                # We don't support such handsome and complex linker scripts,
                # error out because we can't properly trace the dependencies here.
                return nothing
            end
        end
    end

    return ImplicitLDScript(deps)
end
