using Test, BinaryBuilderToolchains, BinaryBuilderSources, Pkg, Logging
using BinaryBuilderToolchains: check_jll_pins, jll_pins, pinned_rev
using BinaryBuilderSources: tracks_branch

@testset "JLL pins" begin
    @test pinned_rev("GCC_jll", "bb2/GCCBootstrap-x86_64-linux-gnu") == jll_pins[("GCC_jll", "bb2/GCCBootstrap-x86_64-linux-gnu")]
    @test pinned_rev("GCC_jll", "bb2/nonexistent") == "bb2/nonexistent"

    # Every JLL that our toolchains take from a git repository is pinned to a commit
    host = Platform(arch(BBHostPlatform()), "linux")
    for target in (host, Platform("x86_64", "windows"), Platform("aarch64", "macos"; os_version=v"20"), Platform("x86_64", "freebsd"))
        for vendor in (:auto, :bootstrap)
            logs, toolchain = Test.collect_test_logs(; min_level=Logging.Warn) do
                CToolchain(CrossPlatform(host => target); vendor)
            end
            @test !any(log -> occursin("tracks a branch", log.message), logs)
            repo_deps = filter(dep -> dep.package.repo.source !== nothing,
                               vcat(toolchain.deps, toolchain.binutils_toolchain.deps))
            @test !isempty(repo_deps)
            @test !any(dep -> tracks_branch(dep.package), repo_deps)
        end
    end

    # A JLL that does track a branch gets warned about, once per session
    unpinned(rev) = JLLSource("GCC_jll", host; repo=Pkg.Types.GitRepo(; source="https://github.com/staticfloat/GCC_jll.jl", rev))
    @test_logs (:warn, r"tracks a branch") check_jll_pins([unpinned("bb2/GCC")])
    io = IOBuffer()
    with_logger(ConsoleLogger(io)) do
        check_jll_pins([unpinned("bb2/GXXTEST")])
        check_jll_pins([unpinned("bb2/GXXTEST")])
        check_jll_pins([unpinned("bb2/armv7l_testing")])
    end
    @test count("tracks a branch", String(take!(io))) == 2
end
