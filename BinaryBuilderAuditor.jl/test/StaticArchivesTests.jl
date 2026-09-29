using Test, BinaryBuilderAuditor, BinaryBuilderToolchains, Base.BinaryPlatforms
using BinaryBuilderAuditor: is_static_archive, read_archive_members, scan_static_archive, symbol_base_name

@testset "symbol_base_name" begin
    # A reference to a specific version, and the definition of the default version
    @test symbol_base_name("malloc@GLIBC_2.2.5") == "malloc"
    @test symbol_base_name("malloc@@GLIBC_2.2.5") == "malloc"
    # Unversioned names pass through untouched
    @test symbol_base_name("malloc") == "malloc"
    @test symbol_base_name("_Z3foov") == "_Z3foov"
end

@testset "static archive parsing" begin
    target_platform = Platform("x86_64", "linux")
    platform = CrossPlatform(BBHostPlatform() => target_platform)
    toolchain = CToolchain(platform; use_ccache=false)
    source_dir = joinpath(@__DIR__, "source")

    mktempdir() do dir
        with_toolchains([toolchain]) do _, env
            compile(name) = begin
                obj = joinpath(dir, "$(name).o")
                run(setenv(`$(env["CC"]) -c -o $(obj) -fPIC $(joinpath(source_dir, "$(name).c"))`, env))
                return obj
            end
            plus_o, mult_o, alloc_o, extra_o = compile.(("libplus", "libmult", "liballoc", "libextra"))
            ar = get(env, "AR", "ar")
            run(setenv(`$(ar) rcs $(joinpath(dir, "libplus.a")) $(plus_o) $(alloc_o)`, env))
            run(setenv(`$(ar) rcs $(joinpath(dir, "libmult.a")) $(mult_o) $(extra_o)`, env))
            run(setenv(`$(env["CC"]) -o $(joinpath(dir, "libplus.so")) -shared $(plus_o)`, env))
        end

        @test is_static_archive(joinpath(dir, "libplus.a"))
        @test !is_static_archive(joinpath(dir, "libplus.so"))
        # Non-archives are simply not archives, rather than an error
        @test scan_static_archive(joinpath(dir, "libplus.so")) === nothing
        @test read_archive_members(joinpath(dir, "libplus.so")) === nothing

        members = read_archive_members(joinpath(dir, "libplus.a"))
        @test Set(basename.([m.name for m in members])) == Set(["libplus.o", "liballoc.o"])

        # `libplus.a` defines its own functions and needs libc's
        plus = scan_static_archive(joinpath(dir, "libplus.a"))
        @test plus.num_members == 2 && plus.num_objects == 2
        @test "plus" ∈ plus.defined && "dup_bytes" ∈ plus.defined
        @test "malloc" ∈ plus.undefined && "memcpy" ∈ plus.undefined
        @test "plus" ∉ plus.undefined

        # `libmult.a` references `plus`, which it does not define itself, and a
        # symbol that nothing provides
        mult = scan_static_archive(joinpath(dir, "libmult.a"))
        @test "mult" ∈ mult.defined && "extra" ∈ mult.defined
        @test "plus" ∈ mult.undefined && "undefined_extra_symbol" ∈ mult.undefined
    end
end
