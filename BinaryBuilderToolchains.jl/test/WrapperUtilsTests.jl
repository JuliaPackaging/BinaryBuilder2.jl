using Test, BinaryBuilderToolchains
using BinaryBuilderToolchains: compiler_wrapper, @flag_str, flagmatch, append_flags

@testset "WrapperUtils" begin
    mktempdir() do dir
        # Our wrapped "compiler tool" will just be this simple script:
        fooifier_path = joinpath(dir, "fooifier")
        open(fooifier_path, write=true) do io
            println(io, """
            #!/bin/bash

            echo "fooifier: \$@"
            """)
        end
        chmod(fooifier_path, 0o755)

        # Create an example wrapper around `fooifier`
        foo_wrapper_path = joinpath(dir, "foo-wrapper")
        compiler_wrapper(foo_wrapper_path, fooifier_path) do io
            # Test finding flags and excluding flags
            flagmatch(io, [flag"--foo"]) do io
                append_flags(io, :PRE, "--found-foo-pre")
                println(io, "echo 'found foo!'")
            end
            flagmatch(io, [!flag"--bar"]) do io
                println(io, "echo 'no bar!'")
                append_flags(io, :POST, "--no-bar-post")
            end

            # Test regex flags, and only on certain arguments
            flagmatch(io, [flag"--.*"r]; match_target="\${ARGS[0]}") do io
                println(io, "echo 'starting with double dash!'")
            end
            flagmatch(io, [!flag"b..h"r]) do io
                println(io, "echo 'no blah-like things!'")
            end

            # Test finding `--foo` and `--bar` at the same time
            flagmatch(io, [flag"--foo", flag"--bar"]) do io
                println(io, "echo 'found foo and bar!'")
            end
        end

        output = readchomp(`$(foo_wrapper_path) --foo --bar`)
        @test strip(output) == strip("""
        found foo!
        starting with double dash!
        no blah-like things!
        found foo and bar!
        fooifier: --found-foo-pre --foo --bar
        """)

        output = readchomp(`$(foo_wrapper_path) blah --zork`)
        @test strip(output) == strip("""
        no bar!
        fooifier: blah --zork --no-bar-post
        """)

        # A wrapper with a post-processing step still exits with the wrapped tool's
        # exit code, and the post step can see that exit code.
        exiter_path = joinpath(dir, "exiter")
        open(exiter_path, write=true) do io
            println(io, """
            #!/bin/bash
            exit "\$1"
            """)
        end
        chmod(exiter_path, 0o755)
        post_wrapper_path = joinpath(dir, "post-wrapper")
        post_func(io) = println(io, "echo \"post: \${WRAPPED_EXIT_CODE}\"")
        compiler_wrapper(identity, post_func, post_wrapper_path, exiter_path)
        for code in (0, 3)
            out = IOBuffer()
            p = run(pipeline(ignorestatus(`$(post_wrapper_path) $(code)`); stdout=out))
            @test p.exitcode == code
            @test strip(String(take!(out))) == "post: $(code)"
        end
    end
end
