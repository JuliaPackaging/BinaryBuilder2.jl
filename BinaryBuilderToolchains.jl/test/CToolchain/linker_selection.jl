# Included by `runtests.jl` into a module that has already loaded `common.jl`.

@testset "CToolchain" begin
    # The `linker` option: `:auto` picks `lld` for clang and `ld` for GCC, and GCC can't use `lld`
    @testset "linker selection" begin
        platform = CrossPlatform(BBHostPlatform() => Platform("x86_64", "linux"))
        riscv64 = CrossPlatform(BBHostPlatform() => Platform("riscv64", "linux"))
        get_linker = BinaryBuilderToolchains.get_linker
        @test get_linker(:auto, :clang, platform) == :lld
        @test get_linker(:auto, :clang_bootstrap, platform) == :lld
        @test get_linker(:auto, :gcc, platform) == :ld
        @test get_linker(:auto, :gcc_bootstrap, platform) == :ld
        @test get_linker(:ld, :clang, platform) == :ld
        @test get_linker(:auto, :clang, riscv64) == :ld
        @test get_linker(:lld, :clang, riscv64) == :lld
        @test_throws ArgumentError CToolchain(platform; vendor=:gcc, linker=:lld)
        @test_throws ArgumentError CToolchain(platform; vendor=:clang, linker=:gold)
        @test BinaryBuilderToolchains.cache_key(CToolchain(platform; vendor=:clang, linker=:ld)) !=
              BinaryBuilderToolchains.cache_key(CToolchain(platform; vendor=:clang, linker=:lld))
    end
end
