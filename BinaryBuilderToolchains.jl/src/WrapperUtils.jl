
"""
    FlagString

Represents a flag that we are going to test against when running the compiler
wrapper bash script.  Use with the `@flag_str` macro, like so:

```
f_asm = flag"-x assembler"
```

Can use regular expression matching if the `r` flag macro flag is included:

```
f_march = flag"-march=.*"r
```
"""
struct FlagString
    s::String
    positive::Bool
    isregex::Bool
end

macro flag_str(s, flags...)
    isregex = "r" ∈ flags
    return quote
        FlagString($(esc(s)), true, $(isregex))
    end
end
Base.:(!)(fs::FlagString) = FlagString(fs.s, !fs.positive, fs.isregex)

function indent(x::String, amount::Int = 4)
    return join([string(" "^amount, l) for l in split(strip(x), '\n')], "\n")
end

function bash_if_statement(f::Function, io::IO, conditions::Vector{String})
    # First, run the given callback; if nothing is generated, don't emit anything.
    # This dodges the issue that `bash` doesn't like empty `if` statements. :(
    sub_io = IOBuffer()
    f(sub_io)
    sub_str = String(take!(sub_io))
    if isempty(sub_str)
        return
    end

    print(io, "if ")
    first = true
    for condition in conditions
        if !first
            print(io, " && \\\n    ")
        end
        print(io, "[[ ", condition, " ]]")
        first = false
    end
    println(io, "; then")
    println(io, indent(sub_str))
    println(io, "fi")
end
bash_if_statement(f::Function, io::IO, condition::String) = bash_if_statement(f, io, [condition])



"""
    flagmatch(f::Function, flags::Vector{FlagString})

Used to construct strings of bash snippets for use in creation of compiler
wrappers; an invocation such as:

    io = IOBuffer()
    flagmatch(io, [flag"-march=.*"r]) do fio
        println(fio, "die 'Cannot force an architecture via -march'")
    end
    println(String(take!(io)))

Will result in a string that looks like:

    if [[ " \${ARGS[@]} " == *' -march= '* ]]; then
        die 'Cannot force an architecture via -march'
    fi

Multiple flags passed into `flagmatch()` result in multiple conditionals,
combined via the `&&` bash operator.
"""
function flagmatch(f::Function, io::IO, flags::Vector{FlagString}; match_target::String = "\${ARGS[@]}")
    function make_condition(flag::FlagString, match_target::String)
        negation = flag.positive ? "" : "! "
        comparison = flag.isregex ? "=~" : "=="
        needle = flag.isregex ? "[[:space:]]$(flag.s)[[:space:]]" : "*' $(flag.s) '*"
        return string(
            negation,
            "\" ",
            match_target,
            " \" ",
            comparison,
            " ",
            needle
        )
    end
    conditions = make_condition.(flags, (match_target,))
    return bash_if_statement(f, io, conditions)
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
    compiler_wrapper(pre_func::Function, [post_func::Function,] io::IO, prog::String)

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
function compiler_wrapper(pre_func::Function, post_func::Function, io::IO, prog::String;
                          jobserver::Bool = false)
    # Start with standard header for all of our compiler wrappers
    println(io, """
    #!/bin/bash
    # This compiler wrapper script brought into existence by `compiler_wrapper()` in $(basename(@__FILE__))

    WRAPPER_DIR="\$( cd -- "\$( dirname -- "\$( realpath "\${BASH_SOURCE[0]}" )" )" &> /dev/null && pwd )"

    BB_WRAPPERS_VERBOSE_FD="\${BB_WRAPPERS_VERBOSE_FD:-2}"
    if [ "x\${SUPER_VERBOSE}" != "x" ]; then
        echo -e "\\e[93mWARN: SUPER_VERBOSE is deprecated, use BB_WRAPPERS_VERBOSE instead!\\e[0m" >&2
        BB_WRAPPERS_VERBOSE="\${SUPER_VERBOSE}\"
    fi

    # `vrun`` is a standard utility for verbosely printing command line arguments to our tools
    # if the special environment variable `BB_WRAPPERS_VERBOSE` is set, or if the special
    # environment variable `BB_WRAPPERS_DEBUG` is set.
    if [ "x\${BB_WRAPPERS_VERBOSE}" != "x" ] || [ "x\${BB_WRAPPERS_DEBUG}" != "x" ]; then
        vrun() {
            eval "printf \\"\\\\e[96m\\" >&\${BB_WRAPPERS_VERBOSE_FD}";
            eval "printf \\"'%s' \\" \\"\\\$@\\" >&\${BB_WRAPPERS_VERBOSE_FD}";
            eval "printf \\"\\\\e[0m\\n\\" >&\${BB_WRAPPERS_VERBOSE_FD}";
            "\$@";
        }
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
    PROG=( $(prog) )
    
    # Some tools like to have a hash of the args (e.g. for random seeds)
    ARGS_HASH="\$(echo -n "\${ARGS[@]}" | sha1sum | cut -c1-8)"
    """)

    # Invoke the callback to generate more pieces (flag munging/alteration, mostly)
    pre_func(io)

    if jobserver
        println(io)
        print(io, jobserver_snippet())
    end

    println(io, """

    # Finally, run the actual command itself
    vrun "\${PROG[@]}" "\${PRE_FLAGS[@]}" "\${ARGS[@]}" "\${POST_FLAGS[@]}"
    """)

    post_func(io)
end

function compiler_wrapper(pre_func::Function, post_func::Function, wrapper_path::String, prog::String;
                          jobserver::Bool = false)
    open(wrapper_path; write=true) do io
        compiler_wrapper(pre_func, post_func, io, prog; jobserver)
    end
    chmod(wrapper_path, 0o755)
end

# Default for `post_func`
function compiler_wrapper(pre_func::Function, wrapper_path::String, prog::String; jobserver::Bool = false)
    return compiler_wrapper(pre_func, identity, wrapper_path, prog; jobserver)
end

function compiler_wrapper(wrapper_path::String, prog::String; jobserver::Bool = false)
    return compiler_wrapper(identity, wrapper_path, prog; jobserver)
end

"""
    jobserver_jll(platform::AbstractPlatform; target::String = "")

A `JLLSource` for `BBJobserver_jll`, which provides `bin/bb_jobserver`: the jobserver
daemon (`bb_jobserver serve`), the `bb_jobserver session` that a build environment keeps
open while a build runs, and `bb_jobserver run`, which the wrappers generated with
`compiler_wrapper(...; jobserver=true)` run their tool through (see
`jobserver_snippet()`).
"""
function jobserver_jll(platform::AbstractPlatform; target::String = "")
    # Not registered, so Pkg needs the UUID along with the repository
    return JLLSource("BBJobserver_jll", platform; target,
                     uuid = Base.UUID("6f5e319e-98ef-58dc-a873-406c0089afd5"),
                     repo = Pkg.Types.GitRepo(
                         rev = pinned_rev("BBJobserver_jll", "bb2/BBJobserver"),
                         source = "https://github.com/staticfloat/BBJobserver_jll.jl",
                     ))
end

"""
    jobserver_snippet()

The bash code that `compiler_wrapper(...; jobserver=true)` runs just before launching
the wrapped tool.  When the build environment exports `BB_JOBSERVER_SOCKET` (the
jobserver daemon's socket) and `BB_JOBSERVER_BIN` (`bb_jobserver`), the tool runs
through `bb_jobserver run`, which waits for a job slot from the daemon, then execs the
tool and holds the slot until the tool exits.  The daemon shares slots fairly between
the groups named by `BB_JOBSERVER_GROUP` (one per build).  The tool gets
`BB_JOBSERVER_HELD`, so wrappers it runs (e.g. `gcc` running `as` and `ld`) don't ask
for a second slot.  If the daemon can't be reached, the tool runs without a slot.
`bb_jobserver.c` (in Yggdrasil's `B/BBJobserver` recipe) has the details, including how
pipelines like `cpp x.S | as` avoid deadlocking.
"""
function jobserver_snippet()
    return raw"""
    # Run the tool once the jobserver grants it a job slot (see `jobserver_snippet()`)
    if [[ -n "${BB_JOBSERVER_SOCKET:-}" ]] && [[ -z "${BB_JOBSERVER_HELD:-}" ]] && [[ -x "${BB_JOBSERVER_BIN:-}" ]]; then
        PROG=( "${BB_JOBSERVER_BIN}" run -- "${PROG[@]}" )
    fi
    """
end
