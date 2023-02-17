using Test, BB2, SHA

if !isdefined(Main, :TestingUtils)
    include("TestingUtils.jl")
end

@testset "Toolchains" begin
    platform = CrossPlatform(
        # Host
        Platform("x86_64", "linux"),
        # Target
        Platform("aarch64", "macos"; libgfortran_version=v"5"),
    )

    deps_trees = BB2.toolchain_map(platform)

    # Ensure we have an entry for our target and host compilers:
    opt_host = "/opt/x86_64-linux-gnu"
    opt_target = "/opt/aarch64-apple-darwin"
    @test haskey(deps_trees, opt_host)
    @test haskey(deps_trees, opt_target)

    # Host tools and extra target dependencies:
    @test haskey(deps_trees, "/usr/local")
    @test haskey(deps_trees, "/workspace/destdir")
    
    # Ensure that GCC_jll and Binitils_jll are both going to be installed in both of the `/opt` locations:
    for prefix in (opt_host, opt_target)
        @test any(jll.package.name == "GCC_jll" for jll in deps_trees[prefix])
        @test any(jll.package.name == "Binutils_jll" for jll in deps_trees[prefix])
    end
end
