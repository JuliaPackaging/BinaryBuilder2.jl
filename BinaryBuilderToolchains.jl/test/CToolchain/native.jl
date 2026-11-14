# Included by `runtests.jl` into a module that has already loaded `common.jl`.
# `use_ccache` is defined by `runtests.jl`.

@testset "CToolchain native (use_ccache=$(use_ccache))" begin
    # Use native compilers so that we can run the output.
    platform = CrossPlatform(BBHostPlatform() => HostPlatform())

    mktempdir() do ccache_dir
        compiler_configurations = [
            Dict(:vendor => :auto, :compiler_runtime => :auto, :cxx_runtime => :auto, ),
            Dict(:vendor => :gcc, :compiler_runtime => :libgcc, :cxx_runtime => :libstdcxx),
            Dict(:vendor => :clang, :compiler_runtime => :libgcc, :cxx_runtime => :libstdcxx),
            Dict(:vendor => :clang, :compiler_runtime => :libgcc, :cxx_runtime => :libcxx),
            Dict(:vendor => :clang, :compiler_runtime => :compiler_rt, :cxx_runtime => :libcxx),
        ]
        for config in compiler_configurations
            toolchain = CToolchain(platform; use_ccache, config...)
            @test get_vendor(toolchain) ∈ (:gcc, :clang)
            if get_vendor(toolchain) == :gcc
                @test !isempty(filter(jll -> jll.package.name == "GCC_jll", toolchain.deps))
            elseif get_vendor(toolchain) == :clang
                @test !isempty(filter(jll -> jll.package.name == "Clang_jll", toolchain.deps))
            end

            # Download the toolchain, make sure it runs
            println()
            @info("CToolchain tests", use_ccache, config...)
            with_toolchains([toolchain, htt_toolchain]) do prefix, env
                env["CCACHE_DIR"] = ccache_dir
                toolchain_tests(prefix, env, platform, "CToolchain";
                                do_cxxabi_tests=config[:cxx_runtime] == :libstdcxx)
            end
        end
    end
end
