# Included by `runtests.jl` into a module that has already loaded `common.jl`.

@testset "CToolchain native bootstrap" begin
    # Use native compilers so that we can run the output.
    platform = CrossPlatform(BBHostPlatform() => HostPlatform())

    # `GCCBootstrap`
    toolchain = CToolchain(platform; vendor=:gcc_bootstrap, use_ccache=false)
    @info("CToolchain tests", vendor=:gcc_bootstrap, use_ccache=false)
    with_toolchains([toolchain, htt_toolchain]) do prefix, env
        toolchain_tests(prefix, env, platform, "CToolchain"; do_cxxabi_tests=true)
    end

    # `LLVMBootstrap_Clang`
    toolchain = CToolchain(platform; vendor=:clang_bootstrap, use_ccache=false)
    @info("CToolchain tests", vendor=:clang_bootstrap, use_ccache=false)
    with_toolchains([toolchain, htt_toolchain]) do prefix, env
        toolchain_tests(prefix, env, platform, "CToolchain"; do_cxxabi_tests=true)
    end
end
