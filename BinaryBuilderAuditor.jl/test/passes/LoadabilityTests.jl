using Test, BinaryBuilderAuditor, BinaryBuilderProducts, BinaryBuilderToolchains, JLLGenerator, Base.BinaryPlatforms
using BinaryBuilderAuditor: libraries_loadable

# Libraries are loaded for real, so this needs libraries built for the machine we run on
if Sys.islinux()
@testset "libraries_loadable" begin
    platform = CrossPlatform(BBHostPlatform() => HostPlatform())
    toolchain = CToolchain(platform; use_ccache=false)
    source_dir = joinpath(dirname(@__DIR__), "source")
    libplus_soname = versioned_shlib("libplus", 1, platform)
    libmult_soname = versioned_shlib("libmult", 2, platform)

    mktempdir() do dir
        # `libplus` is in a dependency's artifact; `libmult` is ours, built with and without an RPATH
        dep_tree, good, bad = joinpath(dir, "dep"), joinpath(dir, "good"), joinpath(dir, "bad")
        foreach(d -> mkpath(joinpath(d, "lib")), (dep_tree, good, bad))
        with_toolchains([toolchain]) do _, env
            run(setenv(`$(env["CC"]) -o $(joinpath(dep_tree, "lib", libplus_soname)) -shared $(joinpath(source_dir, "libplus.c")) $(soname_flag(platform, libplus_soname))`, env))
            for (prefix, rpath) in ((good, [`-Wl,-rpath,\$ORIGIN`]), (bad, Cmd[]))
                run(setenv(`$(env["CC"]) -o $(joinpath(prefix, "lib", libmult_soname)) -shared $(joinpath(source_dir, "libmult.c")) -L $(joinpath(dep_tree, "lib")) -l:$(libplus_soname) $(soname_flag(platform, libmult_soname)) $(rpath...)`, env))
            end
        end
        plus = Dict(:Plus_jll => AuditDependencyInfo(
            AbstractJLLProduct[JLLLibraryProduct(:libplus, joinpath("lib", libplus_soname), [], [])];
            artifact_dir = dep_tree,
        ))
        scan(prefix) = scan_files(prefix, HostPlatform(), [LibraryProduct("libmult", :libmult)])
        audit(prefix, info) = libraries_loadable(AuditResult(scan(prefix)), info)
        outcome(result) = only(result.pass_results["libraries_loadable"])

        # With its dependency installed, `libmult` finds `libplus` through its RPATH
        result = audit(good, AuditInfo(plus))
        @test success(result)
        @test outcome(result).identifier == "lib/$(libmult_soname)"
        @test readdir(joinpath(good, "lib")) == [libmult_soname]
        @test readdir(joinpath(dep_tree, "lib")) == [libplus_soname]

        # A transitive dependency is installed just the same
        @test success(audit(good, AuditInfo(Dict{Symbol,AuditDependencyInfo}(); transitive_deps = plus)))

        # Without the dependency, the load fails and says what is missing
        result = audit(good, AuditInfo())
        @test outcome(result).status == :fail && contains(outcome(result).message, libplus_soname)

        # Without an RPATH it fails too, and the loader's search path is no help
        result = withenv("LD_LIBRARY_PATH" => joinpath(dep_tree, "lib")) do
            audit(bad, AuditInfo(plus))
        end
        @test outcome(result).status == :fail && contains(outcome(result).message, libplus_soname)

        # A platform we cannot load libraries for is not checked
        other = Platform(arch(HostPlatform()) == "x86_64" ? "aarch64" : "x86_64", "linux")
        result = AuditResult(scan_files(good, other, LibraryProduct[]))
        libraries_loadable(result, AuditInfo())
        @test !haskey(result.pass_results, "libraries_loadable")
    end
end
end
