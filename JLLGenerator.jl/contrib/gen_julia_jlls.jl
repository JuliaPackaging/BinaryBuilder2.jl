using JLLGenerator, Base.BinaryPlatforms, Test

# Quick and dirty Julia JLLs generation
out_dir = joinpath(@__DIR__, "stdlib")
rm(out_dir; force=true, recursive=true)

for file in readdir(joinpath(@__DIR__, "stdlib_jllinfos"); join=true)
    m = Module()
    Core.eval(m, :(using JLLGenerator))
    Core.include(m, file)
    jll_out_dir = joinpath(out_dir, basename(file)[1:end-3])
    generate_jll(jll_out_dir, m.jll)

    # Test that reading the JLL.toml back in is the same as `m.jll`:
    @test m.jll == parse_toml_dict(TOML.parsefile(joinpath(jll_out_dir, "JLL.toml")))
end
