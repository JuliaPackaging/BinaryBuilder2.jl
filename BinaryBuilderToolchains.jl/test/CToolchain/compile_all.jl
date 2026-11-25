# Included by `runtests.jl` into a module that has already loaded `common.jl`.
# `target` is defined by `runtests.jl`.

# Ensure that `make compile-all` works for every toolchain vendor targeting `target`
@testset "CToolchain compile-all" begin
    target_platform = CrossPlatform(BBHostPlatform() => target)
    for vendor in vendors_to_test()
        toolchain = CToolchain(target_platform; vendor, use_ccache=false)
        with_toolchains([toolchain, htt_toolchain]) do prefix, env
            @testset "$(triplet(target)) - $(vendor)" begin
                # First, run `$CC --version` for everything
                for tool_name in ("CC", "LD", "AS")
                    @testset "$(tool_name)" begin
                        p, output = capture_output(setenv(`bash -c "\$$(tool_name) --version || \$$(tool_name) -v"`, env))
                        if !success(p)
                            println(output)
                        end
                        @test success(p)
                    end
                end

                # Next, run `make compile-all`
                @testset "make compile-all" begin
                    cd(joinpath(testsuite_dir, "CToolchain")) do
                        EXCLUDED_DIRS = String[]
                        # Windows and macOS don't do debug sections, so there's no compressing them.
                        if Sys.isapple(target) || Sys.iswindows(target)
                            push!(EXCLUDED_DIRS, "07_compressed_debug_sections")
                        end
                        # the bootstrap GCC binutils doesn't have our deterministic strip patch
                        if Sys.iswindows(target) && vendor == :gcc_bootstrap
                            push!(EXCLUDED_DIRS, "08_strip_determinism")
                        end
                        p, output = capture_output(setenv(Cmd(["/bin/bash", "-c", "make clean-all && make compile-all EXCLUDED_DIRS='$(join(EXCLUDED_DIRS, " "))'"]), env))
                        if !success(p)
                            println(output)

                            # Tar up build products for later inspection
                            tarball_path = joinpath(test_dir, "$(triplet(target))-$(vendor)-files.tar.gz")
                            run(`tar -C $(ENV["TESTSUITE_OUTPUT_DIR"]) -czf $(tarball_path) .`)
                            @info("Build products saved", tarball_path)
                        end
                        @test success(p)
                    end
                end
            end
        end
    end
end
