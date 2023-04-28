using Test, BinaryBuilderToolchains, BinaryBuilderSources, Base.BinaryPlatforms, Scratch

@testset "HostToolsToolchain" begin
    platform = CrossPlatform(HostPlatform() => HostPlatform())
    toolchain = HostToolsToolchain(platform)
    @test !isempty(filter(jll -> jll.package.name == "GNUMake_jll", toolchain.deps))
    @test !isempty(filter(jll -> jll.package.name == "Patchelf_jll", toolchain.deps))
    @test !isempty(filter(jll -> jll.package.name == "Ccache_jll", toolchain.deps))

    # Download the toolchain, make sure it runs
    srcs = toolchain_sources(toolchain)
    prepare(srcs; verbose=true)
    mktempdir(@get_scratch!("tempdirs")) do prefix
        deploy(srcs, prefix)
        env = toolchain_env(toolchain, prefix)
        @test success(addenv(`make --version`, env))
        @test success(addenv(`patchelf --version`, env))
        @test success(addenv(`ccache --version`, env))
    end
end

@warn("TODO: Test automake/autoconf")
