# Included by `runtests.jl` into a module that has already loaded `common.jl`.

@testset "CToolchain" begin
    # Ensure that objects assembled directly with `as` get the same minimum macOS
    # version as objects compiled through `cc`, independent of `MACOSX_DEPLOYMENT_TARGET`.
    @testset "macos as deployment target" begin
        tagged_targets = filter(Sys.isapple, supported_platforms(CToolchain))
        untagged_targets = [Platform(arch(p), "macos") for p in tagged_targets]
        for macos_target in vcat(tagged_targets, untagged_targets)
            macos_cp = CrossPlatform(BBHostPlatform() => macos_target)
            expected_minos = macos_version(BinaryBuilderToolchains.macos_target_kernel_version(macos_target))
            mktempdir() do dir
                BinaryBuilderToolchains.binutils_wrappers(BinutilsToolchain(macos_cp, :clang), dir)
                @test occursin("-mmacosx-version-min=$(expected_minos)", read(joinpath(dir, "as"), String))
            end
        end

        # Also cover a tag other than the darwin 20 that the toolchain JLLs are built for
        older_targets = [Platform("x86_64", "macos"; os_version="16")]
        for macos_target in vcat(tagged_targets, untagged_targets, older_targets)
            macos_cp = CrossPlatform(BBHostPlatform() => macos_target)
            expected_minos = macos_version(BinaryBuilderToolchains.macos_target_kernel_version(macos_target))

            with_toolchains([CToolchain(macos_cp), htt_toolchain]) do prefix, env
                mktempdir() do dir
                    write(joinpath(dir, "foo.s"), ".text\n.globl _foo\n_foo:\n    ret\n")
                    write(joinpath(dir, "foo.c"), "int foo(void) { return 0; }\n")
                    write(joinpath(dir, "main.c"), "int main(void) { return 0; }\n")
                    function minos(cmd, obj)
                        @test success(setenv(cmd, env))
                        return macho_minos(obj)
                    end

                    @test env["MACOSX_DEPLOYMENT_TARGET"] == expected_minos
                    @test minos(`cc -c -o $(dir)/foo_c.o $(dir)/foo.c`, "$(dir)/foo_c.o") == VersionNumber(expected_minos)
                    @test minos(`as -o $(dir)/foo_as.o $(dir)/foo.s`, "$(dir)/foo_as.o") == VersionNumber(expected_minos)
                    @test minos(`env -u MACOSX_DEPLOYMENT_TARGET as -o $(dir)/foo_noenv.o $(dir)/foo.s`, "$(dir)/foo_noenv.o") == VersionNumber(expected_minos)
                    @test minos(`env MACOSX_DEPLOYMENT_TARGET=12.0 as -o $(dir)/foo_env12.o $(dir)/foo.s`, "$(dir)/foo_env12.o") == VersionNumber(expected_minos)
                    @test minos(`as -mmacosx-version-min=13.0 -o $(dir)/foo_flag13.o $(dir)/foo.s`, "$(dir)/foo_flag13.o") == v"13.0"
                    @test minos(`cc -o $(dir)/main $(dir)/main.c`, "$(dir)/main") == VersionNumber(expected_minos)
                end
            end
        end
    end
end
