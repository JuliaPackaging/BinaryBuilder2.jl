# Included by `runtests.jl` into a module that has already loaded `common.jl`.

@testset "CToolchain" begin
    # On ELF targets, each extra library directory is also an `-rpath-link` directory
    @testset "extra_libdirs" begin
        for (target, elf) in ((Platform("i686", "linux"), true),
                              (Platform("x86_64", "freebsd"), true),
                              (Platform("aarch64", "macos"), false),
                              (Platform("x86_64", "windows"), false))
            for vendor in (:gcc, :clang)
                toolchain = CToolchain(CrossPlatform(BBHostPlatform() => target); vendor,
                                       extra_libdirs=["/opt/prefix/lib"],
                                       extra_ldflags=["-L/opt/other/lib"],
                                       use_ccache=false)
                mktempdir() do dir
                    wrappers_fn = vendor == :gcc ? BinaryBuilderToolchains.gcc_wrappers : BinaryBuilderToolchains.clang_wrappers
                    wrappers_fn(toolchain, dir)
                    cc = read(joinpath(dir, only(filter(f -> endswith(f, "-$(vendor)"), readdir(dir)))), String)
                    @test occursin("\"-L/opt/prefix/lib\"", cc)
                    @test occursin("-Wl,-rpath-link,/opt/prefix/lib", cc) == elf
                    # Only `extra_libdirs` become `-rpath-link` directories, not `-L` flags
                    @test !occursin("-rpath-link,/opt/other/lib", cc)

                    # GCC's own library directory keeps precedence over the extra ones
                    if elf && vendor == :gcc
                        gcc_libdir = findfirst("-Wl,-rpath-link,\$(dirname \"\${WRAPPER_DIR}\")/gcc/", cc)
                        @test gcc_libdir !== nothing
                        @test first(gcc_libdir) < first(findfirst("-Wl,-rpath-link,/opt/prefix/lib", cc))
                    end
                end
            end
        end

        # Cross-link an executable against `libbar.so`, which needs `libbaz.so`; both live
        # only in the extra library directory, so the linker must find `libbaz.so` there.
        if arch(BBHostPlatform()) == "x86_64"
            mktempdir() do prefix
                libdir = joinpath(prefix, "lib")
                mkpath(libdir)
                write(joinpath(prefix, "baz.c"), "int baz(void) { return 42; }\n")
                write(joinpath(prefix, "bar.c"), "int baz(void);\nint bar(void) { return baz(); }\n")
                write(joinpath(prefix, "main.c"), "int bar(void);\nint main(void) { return bar() != 42; }\n")
                toolchain = CToolchain(CrossPlatform(BBHostPlatform() => Platform("i686", "linux"));
                                       extra_libdirs=[libdir], use_ccache=false)
                with_toolchains([toolchain, htt_toolchain]) do _, env
                    cd(prefix) do
                        @test success(setenv(`bash -c "\${CC} -shared -fPIC -o lib/libbaz.so baz.c"`, env))
                        @test success(setenv(`bash -c "\${CC} -shared -fPIC -o lib/libbar.so bar.c -lbaz"`, env))
                        p, output = capture_output(setenv(`bash -c "\${CC} -o main main.c -lbar"`, env))
                        @test success(p)
                        @test !occursin("libbaz.so", output)
                    end
                end
            end
        end
    end
end
