
"""
    FlagString

Represents a flag that we are going to test against when running the compiler
wrapper bash script.  Use with the `@flag_str` macro, like so:

```
f_asm = flag"-x assembler"
```
"""
struct FlagString
    s::String
    match::Bool
end

macro flag_str(s)
    return quote
        FlagString($(esc(s)), true)
    end
end
Base.:(!)(fs::FlagString) = FlagString(fs.s, !fs.match)

function indent(x::String, amount::Int = 4)
    return join([string(" "^amount, l) for l in split(strip(x), '\n')], "\n")
end
indent(io::IOBuffer, args...) = indent(String(take!(io)), args...)


"""
    flagmatch(f::Function, flags::Vector{FlagString})

Used to construct strings of bash snippets for use in creation of compiler
wrappers; an invocation such as:

    io = IOBuffer()
    flagmatch(io, [flag"-march="]) do fio
        println(fio, "die 'Cannot force an architecture via -march'")
    end
    println(String(take!(io)))

Will result in a string that looks like:

    if [[ " \${ARGS} " == *' -march= '* ]]; then
        die 'Cannot force an architecture via -march'
    fi
"""
function flagmatch(f::Function, io::IO, flags::Vector{FlagString})
    print(io, "if ")
    first = true
    for flag in flags
        if !first
            print(io, " && \\\n   ")
        end
        comparison = flag.match ? "==" : "!="
        print(io, "[[ \" \${ARGS[@]} \" $(comparison) *' $(flag.s) '* ]]")
        first = false
    end
    println(io, "; then")
    indented_io = IOBuffer()
    f(indented_io)
    println(io, indent(indented_io))
    println(io, "fi")
end

"""
    append_flags(io::IO, flag_type::Symbol, flags::String)

We are often building up the `PRE_FLAGS` and `POST_FLAGS` arrays in our bash
compiler wrappers; this makes it easy to append a bunch of values to those
bash arrays without worrying about quoting, spelling the name of the array
right, etc...

Use it like so:

    clang_link_only_flags = String["-rtlib=libgcc", "-fuse-ld=x86_64-linux-gnu"]
    flagmatch([!flag"-c", !flag"-E", !flag"-M", !flag"-fsyntax-only"]) do io
        append_flags(io, :POST, clang_link_only_flags)
    end

To get a bash wrapper script that looks like:

    if [[ " \${ARGS[@]} " != *' -c '* ]] && [[ " \${ARGS[@]} " != *' -E '* ]] &&
       [[ " \${ARGS[@]} " != *' -M '* ]] && [[ " \${ARGS[@]} " != *' -fsyntax-only '* ]]; then
        POST+=( '-rtlib=libgcc' 'fuse-ld=x86_64-linux-gnu' )
    fi
"""
function append_flags(io::IO, flag_type::Symbol, flags::Vector{String})
    local bash_array
    if flag_type == :PRE
        bash_array = "PRE_FLAGS"
    elseif flag_type == :POST
        bash_array = "POST_FLAGS"
    else
        throw(ArgumentError("Invalid flag type '$(flag_type)'"))
    end

    print(io, "$(bash_array)+=( ")
    for flag in flags
        print(io, "\"$(flag)\" ")
    end
    print(io, ")\n")
end
append_flags(io::IO, flag_type::Symbol, flag::String) = append_flags(io, flag_type, [flag])


"""
    compiler_wrapper(f::Function, io::IO, prog::String)

This utility function allows the automated construction of `bash` wrapper
scripts for compiler executables.  It allows for easy composition of conditionals
to insert compiler flags using the helper methods `flagmatch` and `append_flags`.

An intermediate example of writing a wrapper for `clang` for `x86_64-linux-gnu`:

    compiler_wrapper("clang_wrapper.sh", "clang") do io
        append_flags(io, :PRE, [
            # Set the `target` for `clang` so it generates the right kind of code
            "--target=x86_64-linux-gnu",
            # Set the sysroot
            "--sysroot=/opt/x86_64-linux-gnu/x86_64-linux-gnu/sys-root",
            # Set the GCC toolchain location
            "--gcc-toolchain=/opt/x86_64-linux-gnu",
        ])

        # If linking is involved, ensure that we link against libgcc and use the right linker
        clang_link_only_flags = String["-rtlib=libgcc", "-fuse-ld=x86_64-linux-gnu"]
        flagmatch(io, [!flag"-c", !flag"-E", !flag"-M", !flag"-fsyntax-only"]) do io
            append_flags(io, :POST, clang_link_only_flags)
        end
    end
"""
function compiler_wrapper(f::Function, io::IO, prog::String)
    # Start with standard header for all of our compiler wrappers
    println(io, """
    #!/bin/bash
    # This compiler wrapper script brought into existence by `compiler_wrapper()` in $(basename(@__FILE__))

    WRAPPER_DIR="\$( cd -- "\$( dirname -- "\${BASH_SOURCE[0]}" )" &> /dev/null && pwd )"

    if [ "x\${SUPER_VERBOSE}" != "x" ]; then
        echo -e "\\e[93mWARN: SUPER_VERBOSE is deprecated, use BB_WRAPPERS_VERBOSE instead!\\e[0m" >&2
        BB_WRAPPERS_VERBOSE="\${SUPER_VERBOSE}\"
    fi

    # `vrun`` is a standard utility for verbosely printing command line arguments to our tools
    # if the special environment variable `BB_WRAPPERS_VERBOSE` is set, or if the special
    # environment variable `BB_WRAPPERS_DEBUG` is set.
    if [ "x\${BB_WRAPPERS_VERBOSE}" != "x" ] || [ "x\${BB_WRAPPERS_DEBUG}" != "x" ]; then
        vrun() { echo -e "\\e[96m\$@\\e[0m" >&2; "\$@"; }
    else
        vrun() { "\$@"; }
    fi

    # If `BB_WRAPPERS_DEBUG` is set, apply `set -x` to our wrapper scripts
    if [[ -n "\${BB_WRAPPERS_DEBUG}" ]]; then
        PS4=">"
        set -x
    fi

    # We like bash arrays, so let's use them to store our given arguments,
    # the set of flags we'll insert before the given arguments, and the
    # set of flags we'll append after the given arguments.
    ARGS=( "\$@" )
    PRE_FLAGS=()
    POST_FLAGS=()
    PROG=( "$(prog)" )
    
    # Some tools like to have a hash of the args (e.g. for random seeds)
    ARGS_HASH="\$(echo -n "\${ARGS[@]}" | sha1sum | cut -c1-8)"
    """)

    # Invoke the callback to generate more pieces (flag munging/alteration, mostly)
    f(io)

    println(io, """

    # Finally, run the actual command itself
    vrun "\${PROG[@]}" "\${PRE_FLAGS[@]}" "\${ARGS[@]}" "\${POST_FLAGS[@]}"
    """)
end

function compiler_wrapper(f::Function, wrapper_path::String, prog::String)
    open(wrapper_path; write=true) do io
        compiler_wrapper(f, io, prog)
    end
    chmod(wrapper_path, 0o755)
end
