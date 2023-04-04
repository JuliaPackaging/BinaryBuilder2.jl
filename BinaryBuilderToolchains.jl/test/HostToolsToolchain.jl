using Test, BinaryBuilderToolchains, BinaryBuilderSources, Base.BinaryPlatforms, Scratch

@testset "HostToolsToolchain" begin
    platform = CrossPlatform(HostPlatform() => HostPlatform())
    toolchain = HostToolsToolchain(platform)

    # Download the toolchain, make sure it runs
    srcs = toolchain_sources(toolchain)
    @test !isempty(filter(src -> isa(src, JLLSource) && src.package.name == "GNUMake_jll", srcs))
    prepare(srcs; verbose=true)
    mktempdir(@get_scratch!("tempdirs")) do prefix
        deploy(srcs, prefix)
        env = toolchain_env(toolchain, prefix)
        @test success(addenv(`make --version`, env))
        @test success(addenv(`patchelf --version`, env))
        @test success(addenv(`ccache --version`, env))
    end
end
