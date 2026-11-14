# Included by `runtests.jl` into a module that has already loaded `common.jl`.

@testset "CToolchain" begin
    # GCC wrappers request asynchronous unwind tables only on aarch64 Linux with GCC < 8
    # (newer GCC emits them there by default), and the user's own
    # `-fno-asynchronous-unwind-tables` overrides the tables either way.
    @testset "aarch64 Linux unwind tables" begin
        for (target, gcc_version, expected) in (("aarch64-linux-gnu", v"4.8.5", true),
                                                ("aarch64-linux-musl", v"7.1.0", true),
                                                ("aarch64-linux-gnu", v"8.1.0", false),
                                                ("aarch64-linux-gnu", v"14.2.0", false),
                                                ("x86_64-linux-gnu", v"4.8.5", false),
                                                ("aarch64-apple-darwin", v"4.8.5", false))
            toolchain = (; platform = CrossPlatform(BBHostPlatform() => parse(Platform, target)))
            io = IOBuffer()
            BinaryBuilderToolchains.add_unwind_table_flags(io, toolchain, gcc_version)
            @test occursin("-fasynchronous-unwind-tables", String(take!(io))) == expected
        end

        # The GCC we ship emits unwind tables on its own, so the wrappers do not add the flag
        for target in ("aarch64-linux-gnu", "aarch64-linux-musl")
            toolchain = CToolchain(CrossPlatform(BBHostPlatform() => parse(Platform, target)); vendor=:gcc, use_ccache=false)
            @test toolchain.binutils_toolchain.gcc_version >= v"8"
            mktempdir() do dir
                BinaryBuilderToolchains.gcc_wrappers(toolchain, dir)
                for tool in ("gcc", "g++")
                    wrapper = read(joinpath(dir, "$(triplet(gcc_platform(parse(Platform, target))))-$(tool)"), String)
                    @test !occursin("-fasynchronous-unwind-tables", wrapper)
                end
            end
        end

        no_unwind = ["-fno-asynchronous-unwind-tables", "-fno-unwind-tables"]
        for target in ("aarch64-linux-gnu", "aarch64-linux-musl")
            target_platform = CrossPlatform(BBHostPlatform() => parse(Platform, target))
            for extra_cflags in (String[], no_unwind)
                toolchain = CToolchain(target_platform; vendor=:gcc, use_ccache=false, extra_cflags)
                with_toolchains([toolchain, htt_toolchain]) do prefix, env
                    mktempdir() do dir
                        write(joinpath(dir, "unwind.c"), "int f(int x) { return x * 3; }\n")
                        function has_eh_frame(cflags)
                            cmd = "cd $(dir) && \${CC} -O2 $(join(cflags, " ")) -c unwind.c -o unwind.o"
                            @test success(setenv(Cmd(["/bin/bash", "-c", cmd]), env))
                            return open(joinpath(dir, "unwind.o")) do io
                                any(s -> section_name(s) == ".eh_frame", Sections(only(readmeta(io))))
                            end
                        end
                        @test has_eh_frame(String[]) == isempty(extra_cflags)
                        @test !has_eh_frame(no_unwind)
                    end
                end
            end
        end
    end
end
