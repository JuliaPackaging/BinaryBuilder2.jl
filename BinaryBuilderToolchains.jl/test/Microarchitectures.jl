using Test
using BinaryBuilderToolchains: get_march_flags, get_all_arch_names, get_all_march_names

@testset "march flags" begin
    # test one that is common between gcc and clang
    @test get_march_flags("x86_64", "avx", "gcc") == ["-march=sandybridge", "-mtune=sandybridge"]

    # Test one that is different between gcc and clang
    @test get_march_flags("aarch64", "apple_m1", "gcc") == ["-march=armv8.5-a+aes+sha2+sha3+fp16fml+fp16+rcpc+dotprod", "-mcpu=cortex-a76"]
    @test get_march_flags("aarch64", "apple_m1", "clang") == ["-mcpu=apple-m1"]

    for compiler in ("gcc", "clang")
        # Make sure we get the right base microarchitecture for all compilers
        @test get_march_flags("aarch64", nothing, compiler) == get_march_flags("aarch64", "armv8_0",  compiler)
        @test get_march_flags("armv7l",  nothing, compiler) == get_march_flags("armv7l",  "armv7l",   compiler)
        @test get_march_flags("i686",    nothing, compiler) == get_march_flags("i686",    "pentium4", compiler)
        @test get_march_flags("x86_64",  nothing, compiler) == get_march_flags("x86_64",  "x86_64",   compiler)
    end

    # Get all architectures and all microarchitectures for the different architectures
    @test sort(get_all_arch_names()) == ["aarch64", "armv6l", "armv7l", "i686", "powerpc64le", "x86_64"]
    @test sort(get_all_march_names("x86_64")) == ["avx", "avx2", "avx512", "x86_64"]
    @test sort(get_all_march_names("armv7l")) == ["armv7l", "neonvfpv4"]
end
