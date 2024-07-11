using BinaryBuilderToolchains, Base.BinaryPlatforms
platform = CrossPlatform(BBHostPlatform() => BBHostPlatform())
toolchains = [CToolchain(platform), HostToolsToolchain(platform)]

# Automated
with_toolchains(toolchains) do prefix, env
    mktempdir() do src_dir
        open(joinpath(src_dir, "main.c"); write=true) do io
            println(io, """
            #include <stdio.h>

            int main() {
                printf("Hello, JuliaCon!\\n");
                return 0;
            }
            """)
        end
        run(setenv(`/bin/bash -c "\$CC -o $(src_dir)/main -g -O2 $(src_dir)/main.c"`, env))
        run(`$(src_dir)/main`)
    end
end


