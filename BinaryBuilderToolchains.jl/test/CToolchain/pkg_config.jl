# Included by `runtests.jl` into a module that has already loaded `common.jl`.

@testset "CToolchain" begin
    # Use native compilers so that we can run the output.
    platform = CrossPlatform(BBHostPlatform() => HostPlatform())

    # Each `CToolchain` gets `pkg-config` wrappers that only see its own prefix's `.pc` files
    @testset "pkg-config wrappers" begin
        mktempdir() do dir
            # Relocatable `.pc` files, as written by `BinaryBuilderAuditor`
            function write_pc(prefix, name; subdir="lib/pkgconfig", requires="")
                mkpath(joinpath(prefix, subdir))
                write(joinpath(prefix, subdir, "$(name).pc"), """
                prefix=\${pcfiledir}/../..
                libdir=\${prefix}/lib
                includedir=\${prefix}/include

                Name: $(name)
                Description: $(name)
                Version: 1.0
                Requires: $(requires)
                Libs: -L\${libdir} -l$(name)
                Cflags: -I\${includedir}
                """)
            end
            host_prefix = joinpath(dir, "host")
            target_prefix = joinpath(dir, "target")
            write_pc(host_prefix, "hostonly")
            write_pc(target_prefix, "bar")
            write_pc(target_prefix, "foo"; subdir="share/pkgconfig", requires="bar")

            target = CrossPlatform(BBHostPlatform() => Platform("aarch64", "linux"))
            host_toolchain = CToolchain(platform; use_ccache=false,
                                        env_prefixes=["HOST_"], wrapper_prefixes=["host-"],
                                        extra_libdirs=["$(host_prefix)/lib"])
            target_toolchain = CToolchain(target; use_ccache=false,
                                          extra_libdirs=["$(target_prefix)/lib"])
            with_toolchains([host_toolchain, htt_toolchain]) do _, host_env
                with_toolchains([target_toolchain]) do _, target_env
                    env = path_appending_merge(host_env, target_env)
                    @test env["PKG_CONFIG"] == "aarch64-linux-gnu-pkg-config"
                    @test env["HOST_PKG_CONFIG"] == "host-pkg-config"
                    # `env` has the user's `PATH` between both toolchains, and that can contain the
                    # system's own `aarch64-linux-gnu-pkg-config`, so run the target's with `target_env`.
                    pc_env(pc) = pc == "HOST_PKG_CONFIG" ? env : target_env
                    pkg_config(pc, args) = readchomp(setenv(Cmd(["/bin/bash", "-c", "\${$(pc)} $(args)"]), pc_env(pc)))
                    pkg_config_success(pc, args) = success(setenv(Cmd(["/bin/bash", "-c", "\${$(pc)} $(args)"]), pc_env(pc)))

                    # `Requires:` is followed, and paths resolve into the prefix
                    foo_pc = "$(target_prefix)/share/pkgconfig/../.."
                    bar_pc = "$(target_prefix)/lib/pkgconfig/../.."
                    @test pkg_config("PKG_CONFIG", "--cflags foo") == "-I$(foo_pc)/include -I$(bar_pc)/include"
                    @test pkg_config("PKG_CONFIG", "--libs foo") == "-L$(foo_pc)/lib -lfoo -L$(bar_pc)/lib -lbar"
                    @test pkg_config("HOST_PKG_CONFIG", "--libs hostonly") == "-L$(host_prefix)/lib/pkgconfig/../../lib -lhostonly"

                    # Each wrapper only sees its own prefix
                    @test !pkg_config_success("PKG_CONFIG", "--exists hostonly")
                    @test !pkg_config_success("HOST_PKG_CONFIG", "--exists foo")
                    # `pkgconf`'s own `.pc` file is not visible either
                    @test !pkg_config_success("PKG_CONFIG", "--exists libpkgconf")

                    # The plain `pkg-config` and the `\${triplet}-` names are the target's.
                    @test success(setenv(`pkg-config --exists foo`, target_env))
                    @test success(setenv(`aarch64-linux-gnu-pkg-config --exists foo`, target_env))
                    @test success(setenv(`host-pkg-config --exists hostonly`, env))

                    # `PKG_CONFIG_PATH` is still honored
                    write_pc(joinpath(dir, "extra"), "extra")
                    extra_env = copy(target_env)
                    extra_env["PKG_CONFIG_PATH"] = joinpath(dir, "extra", "lib", "pkgconfig")
                    @test success(setenv(`pkg-config --exists extra`, extra_env))
                end
            end
        end
    end
end
