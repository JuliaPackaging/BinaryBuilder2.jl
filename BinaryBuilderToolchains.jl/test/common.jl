using Test, Logging, BinaryBuilderToolchains, BinaryBuilderSources, BinaryBuilderPlatformExtensions, Base.BinaryPlatforms, Scratch
using BinaryBuilderToolchains: path_appending_merge, get_vendor
using ObjectFile

const test_dir = @__DIR__
const testsuite_dir = joinpath(test_dir, "testsuite")

# Enable this for lots of JLLPrefixes output
const verbose = false

const htt_toolchain = HostToolsToolchain(BBHostPlatform())

# Minimum OS version recorded in the (single-arch) Mach-O file at `path`
macho_minos(path::String) = readmeta(ohs -> min_os_version(only(ohs)), path)

function capture_output(cmd)
    output = Pipe()
    p = run(pipeline(cmd; stdout=output, stderr=output); wait=false)
    close(output.in)
    output = String(read(output))
    return p, output
end

# General has the bootstrap toolchain JLLs (`GCCBootstrap_jll`, `GCCBootstrapManual_jll`)
# for x86_64 hosts only, so the `*_bootstrap` vendors are only tested there.
bootstrap_vendors_available(curr_arch = arch(BBHostPlatform())) = curr_arch == "x86_64"

function vendors_to_test(curr_arch = arch(BBHostPlatform()))
    if bootstrap_vendors_available(curr_arch)
        return (:auto, :gcc, :clang, :gcc_bootstrap, :clang_bootstrap)
    else
        return (:auto, :gcc, :clang)
    end
end

function toolchain_tests(prefix, env, platform, testsuite; do_cxxabi_tests::Bool = false)
    testsuite_path = joinpath(testsuite_dir, testsuite)
    @testset "$(triplet(platform)) $(do_cxxabi_tests ? "cxxabi" : "")" begin
        cd(testsuite_path) do
            # Run our entire test suite first
            p = run(ignorestatus(setenv(`make -s cleancheck-all`, env)))
            # If this fails, run it again, but with `make` not set to silent
            if !success(p)
                run(setenv(`make cleancheck-all`, env))
            end
            @test success(p)

            # Run the `cxx_string_abi` with `BB_WRAPPERS_VERBOSE` and ensure that we get the right
            # `cxxstring_abi` defines showing in the build log:
            if do_cxxabi_tests
                @test haskey(platform.target, "cxxstring_abi")
                cxxstring_abi_define = string(
                    "-D_GLIBCXX_USE_CXX11_ABI=",
                    platform.target["cxxstring_abi"] == "cxx11" ? "1" : "0",
                )

                # Turn on verbose wrappers
                debug_env = copy(env)
                debug_env["BB_WRAPPERS_VERBOSE"] = "true"
                p, debug_out = capture_output(setenv(`make cleancheck-02_cxx_string_abi`, debug_env))
                @test success(p)
                @test occursin(cxxstring_abi_define, debug_out)
            end
        end

        # Ensure that every wrapper we generate actually runs (e.g. no dangling tool references)
        for wrapper in readdir(joinpath(prefix, "wrappers"); join=true)
            # Skip these, they're special
            if endswith(basename(wrapper), "-clang-as")
                continue
            end

            if Sys.isexecutable(wrapper)
                @testset "$(basename(wrapper))" begin
                    @test success(setenv(`$(wrapper) --version`, env))
                end
            end
        end
    end
end
