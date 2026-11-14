using BinaryBuilderToolchains, ParallelTestRunner
using Base.BinaryPlatforms: triplet

# Each entry runs in a worker process of its own, so that tests that `cd()`, mutate `ENV`
# or deploy toolchains do not interfere with each other.  The per-target entries split up
# the platform loops, which are by far the most expensive part of the suite.
include_test(file) = :(include($(joinpath(@__DIR__, file))))
function target_test(file, toolchain_type, target)
    return quote
        global target = only(filter(p -> triplet(p) == $(triplet(target)), supported_platforms($(nameof(toolchain_type)))))
        $(include_test(file))
    end
end

testsuite = Dict{String,Expr}(
    "PkgUtils" => include_test("PkgUtilsTests.jl"),
    "JLLPins" => include_test("JLLPinsTests.jl"),
    "WrapperUtils" => include_test("WrapperUtilsTests.jl"),
    "MacOSVersion" => include_test("MacOSVersionTests.jl"),
    "HostToolsToolchain" => include_test("HostToolsToolchainTests.jl"),
    "CToolchain/native/use_ccache=false" => :(global use_ccache = false; $(include_test("CToolchain/native.jl"))),
    "CToolchain/native/use_ccache=true" => :(global use_ccache = true; $(include_test("CToolchain/native.jl"))),
    "CToolchain/native/bootstrap" => include_test("CToolchain/bootstrap.jl"),
    "CToolchain/host_isolation" => include_test("CToolchain/host_isolation.jl"),
    "CToolchain/extra_libdirs" => include_test("CToolchain/extra_libdirs.jl"),
    "CToolchain/pkg_config" => include_test("CToolchain/pkg_config.jl"),
    "CToolchain/strict_tags" => include_test("CToolchain/strict_tags.jl"),
    "CToolchain/ld_wrappers" => include_test("CToolchain/ld_wrappers.jl"),
    "CToolchain/linker_selection" => include_test("CToolchain/linker_selection.jl"),
    "CToolchain/lto" => include_test("CToolchain/lto.jl"),
    "CToolchain/unwind_tables" => include_test("CToolchain/unwind_tables.jl"),
    "CToolchain/macos_strip" => include_test("CToolchain/macos_strip.jl"),
    "CToolchain/macos_as" => include_test("CToolchain/macos_as.jl"),
    "CMakeToolchain/basic" => include_test("CMakeToolchain/basic.jl"),
)
for target in supported_platforms(CToolchain)
    testsuite["CToolchain/compile_all/$(triplet(target))"] = target_test("CToolchain/compile_all.jl", CToolchain, target)
end
for target in supported_platforms(CMakeToolchain)
    testsuite["CMakeToolchain/compile_all/$(triplet(target))"] = target_test("CMakeToolchain/compile_all.jl", CMakeToolchain, target)
end

# Run once in every worker, before its first test
init_worker_code = quote
    # Clear out environment variables that can cause problems
    for flagvar in ("C", "CPP", "CXX", "LD")
        delete!(ENV, "$(flagvar)FLAGS")
    end
    for libvar in ("LD", "DYLD")
        delete!(ENV, "$(libvar)_LIBRARY_PATH")
        delete!(ENV, "$(libvar)_FALLBACK_LIBRARY_PATH")
    end

    # Give each worker its own source caches.  The JLL resolution cache records artifact
    # paths within the source download cache's depot, so it must not be shared either.
    # JLLPrefixes updates its cached git clones with a `git fetch` followed by a reset to
    # `FETCH_HEAD`, which fails when another process fetches into the same clone in
    # between, so workers get their own clones too.
    import BinaryBuilderSources, JLLPrefixes
    let dir = mktempdir()
        BinaryBuilderSources._source_download_cache[] = name -> joinpath(dir, "source_download", name)
        BinaryBuilderSources._generated_source_cache[] = name -> joinpath(dir, "generated_sources", name)
        BinaryBuilderSources._jll_resolve_cache[] = name -> joinpath(dir, "jll_resolve_cache", name)
        JLLPrefixes.set_git_clones_dir!(joinpath(dir, "git_clones"))
    end
end

# Run in the fresh module of every test
init_code = quote
    include($(joinpath(@__DIR__, "common.jl")))

    # Build products of the testsuite Makefiles go here
    ENV["TESTSUITE_OUTPUT_DIR"] = mktempdir()
end

@warn "TODO: test macos version min?"
@warn "TODO: test clang against libcxx and compiler_rt!"
@warn "TODO: test dlltool determinism"

runtests(BinaryBuilderToolchains, ARGS; testsuite, init_worker_code, init_code)
