# Included by `runtests.jl` into a module that has already loaded `common.jl`.

@testset "CToolchain" begin
    # Ensure that the `ld.<triplet>` / `ld64.<triplet>` wrappers exist, work, and are
    # what `clang` links through.
    @testset "ld.<triplet> wrappers" begin
        ld_targets = [
            Platform("x86_64", "linux"),
            Platform("aarch64", "macos"; os_version="20"),
            Platform("x86_64", "windows"),
        ]
        for target in ld_targets
            target_cp = CrossPlatform(BBHostPlatform() => target)
            fuse_name = triplet(BinaryBuilderToolchains.gcc_platform(target))
            ld_name = string(Sys.isapple(target) ? "ld64." : "ld.", fuse_name)

            # Generating the binutils wrappers emits no warnings about `ld` wrappers
            mktempdir() do dir
                logger = Test.TestLogger(; min_level=Logging.Warn, respect_maxlog=false)
                Logging.with_logger(logger) do
                    BinaryBuilderToolchains.binutils_wrappers(BinutilsToolchain(target_cp, :clang), dir)
                end
                @test !any(log -> occursin(r"\bld\b|ld\.", string(log.message)), logger.logs)
                @test Sys.isexecutable(joinpath(dir, ld_name))
            end

            for vendor in (:gcc, :clang)
                toolchain = CToolchain(target_cp; vendor, linker=:ld, use_ccache=false)
                with_toolchains([toolchain, htt_toolchain]) do prefix, env
                    @testset "$(triplet(target)) - $(vendor)" begin
                        ld = joinpath(prefix, "wrappers", ld_name)
                        cc = joinpath(prefix, "wrappers", env["CC"])
                        @test Sys.isexecutable(ld)
                        mktempdir() do dir
                            write(joinpath(dir, "foo.c"), "int foo(void) { return 42; }\n")
                            @test success(setenv(`$(cc) -c foo.c -o foo.o`, env; dir))

                            # Perform a relocatable link through the wrapper
                            p, output = capture_output(setenv(`$(ld) -r foo.o -o foo_r.o`, env; dir))
                            if !success(p)
                                println(output)
                            end
                            @test success(p)
                            @test isfile(joinpath(dir, "foo_r.o"))

                            if vendor == :clang
                                # With `linker = :ld`, `clang` selects the wrapper when linking...
                                p, output = capture_output(setenv(`$(cc) -\#\#\# -shared foo.o -o libfoo`, env; dir))
                                @test success(p)
                                @test occursin(ld, output)

                                # ...unless the user picks their own linker
                                debug_env = copy(env)
                                debug_env["BB_WRAPPERS_VERBOSE"] = "true"
                                p, output = capture_output(setenv(`$(cc) -\#\#\# -shared -fuse-ld=lld foo.o -o libfoo`, debug_env; dir))
                                @test occursin("'-fuse-ld=lld'", output)
                                @test !occursin("'-fuse-ld=$(fuse_name)'", output)

                                # ...and actually links successfully through it.
                                @test success(setenv(`$(cc) -shared foo.o -o libfoo`, env; dir))
                            end
                        end
                    end
                end
            end
        end
    end
end
