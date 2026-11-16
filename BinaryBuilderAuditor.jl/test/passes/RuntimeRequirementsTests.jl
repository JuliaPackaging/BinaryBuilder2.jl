using Test, BinaryBuilderAuditor, Base.BinaryPlatforms, BinaryBuilderToolchains
using BinaryBuilderAuditor: record_runtime_requirements!, check_runtime_requirements, freebsd_release

function runtime_requirements_audit(prefix, platform; os_version = Base.BinaryPlatforms.os_version(platform))
    result = AuditResult(scan_files(prefix, platform))
    record_runtime_requirements!(result)
    check_runtime_requirements(result; os_version)
    return result
end

function runtime_requirement_statuses(result)
    return [r.status for r in get(result.pass_results, "runtime_requirements", PassResult[])]
end

# Build a shared library `soname` in `dir` that defines `fn` under the symbol version
# `version_node`, plus the unversioned `.so` link that `-l` finds.
function stub_versioned_lib(env, dir, soname, version_node, fn)
    c_path = joinpath(dir, "$(fn).c")
    map_path = joinpath(dir, "$(fn).map")
    write(c_path, "int $(fn)(void) { return 0; }\n")
    write(map_path, "$(version_node) { global: $(fn); local: *; };\n")
    run(setenv(`$(env["CC"]) -shared -fPIC -o $(joinpath(dir, soname)) -Wl,-soname,$(soname) -Wl,--version-script=$(map_path) $(c_path)`, env))
    linkname = joinpath(dir, string(first(split(soname, ".so")), ".so"))
    if linkname != joinpath(dir, soname)
        symlink(soname, linkname)
    end
end

# Build `exe_path` from C source `src` that calls each function in `fns`, linking
# against `libs` from `libdir`.
function build_caller(env, exe_path, fns, libdir, libs; cflags = String[])
    c_path = string(exe_path, ".c")
    write(c_path, join(["int $(fn)(void);" for fn in fns], "\n") *
          "\nint main(void) { return " * join(["$(fn)()" for fn in fns], " + ") * "; }\n")
    run(setenv(`$(env["CC"]) $(cflags) -o $(exe_path) $(c_path) -L$(libdir) $(["-l$(l)" for l in libs]) -Wl,--no-as-needed`, env))
    rm(c_path)
end

@testset "RuntimeRequirements" begin
    @test freebsd_release(v"1.0") == v"7.0"
    @test freebsd_release(v"1.7") == v"14.0"
    @test_throws ArgumentError freebsd_release(v"2.0")

    @testset "Linux glibc" begin
        target = Platform("x86_64", "linux")
        toolchain = CToolchain(CrossPlatform(BBHostPlatform() => target); use_ccache=false)
        mktempdir() do prefix
            mkpath(joinpath(prefix, "bin"))
            mkpath(joinpath(prefix, "lib"))
            with_toolchains([toolchain]) do _, env
                cxx_path = joinpath(prefix, "hello.cpp")
                write(cxx_path, """
                #include <iostream>
                int main() { std::cout << "hello" << std::endl; return 0; }
                """)
                run(setenv(`$(env["CXX"]) -o $(joinpath(prefix, "bin", "hello_cxx")) $(cxx_path)`, env))
                rm(cxx_path)
            end

            # A C++ binary built with GCC 14 records libstdc++ and glibc needs, within the floor
            result = runtime_requirements_audit(prefix, target)
            reqs = result.runtime_requirements
            @test reqs.libstdcxx !== nothing
            @test reqs.libstdcxx.value >= v"6.0.32"
            @test reqs.libstdcxx.file == "bin/hello_cxx"
            @test reqs.glibcxx.value >= v"3.4.32"
            @test startswith(reqs.glibcxx.source, "GLIBCXX_")
            @test reqs.cxxabi === nothing || startswith(reqs.cxxabi.source, "CXXABI_")
            @test isempty(reqs.unknown_libstdcxx)
            @test v"2.2.5" <= reqs.glibc.value <= v"2.17"
            @test isempty(reqs.libgfortran)
            @test reqs.macos === nothing && reqs.freebsd === nothing
            @test runtime_requirement_statuses(result) == [:success]
            @test success(result)
            @test occursin("libstdcxx:", sprint(show, reqs))

            # The prefix ships a libstdc++ defining a symbol version no known libstdc++ has;
            # needing it is recorded, and doesn't count towards `libstdcxx`.
            with_toolchains([toolchain]) do _, env
                stub_versioned_lib(env, joinpath(prefix, "lib"), "libstdc++.so.6", "GLIBCXX_3.4.999", "future_cxx_fn")
                build_caller(env, joinpath(prefix, "bin", "future_cxx"), ["future_cxx_fn"], joinpath(prefix, "lib"), ["stdc++"])
            end
            result = runtime_requirements_audit(prefix, target)
            reqs = result.runtime_requirements
            @test reqs.libstdcxx.file == "bin/hello_cxx"
            @test length(reqs.unknown_libstdcxx) == 1
            @test only(reqs.unknown_libstdcxx).value == "GLIBCXX_3.4.999"
            @test only(reqs.unknown_libstdcxx).file == "bin/future_cxx"
            @test reqs.glibcxx.value == v"3.4.999"
            @test success(result)

            # Symbol versions named `GLIBCXX_*` from other libraries are not libstdc++'s
            with_toolchains([toolchain]) do _, env
                stub_versioned_lib(env, joinpath(prefix, "lib"), "libnotcxx.so.1", "GLIBCXX_3.4.998", "notcxx_fn")
                build_caller(env, joinpath(prefix, "bin", "notcxx"), ["notcxx_fn"], joinpath(prefix, "lib"), ["notcxx"])
            end
            result = runtime_requirements_audit(prefix, target)
            @test result.runtime_requirements.glibcxx.value == v"3.4.999"
            @test length(result.runtime_requirements.unknown_libstdcxx) == 1
            for f in ("future_cxx", "notcxx")
                rm(joinpath(prefix, "bin", f))
            end

            # Object files and static executables load no libraries, and add no requirements
            before = runtime_requirements_audit(prefix, target).runtime_requirements
            with_toolchains([toolchain]) do _, env
                c_path = joinpath(prefix, "obj.c")
                write(c_path, "int main(void) { return 0; }\n")
                run(setenv(`$(env["CC"]) -c -o $(joinpath(prefix, "lib", "obj.o")) $(c_path)`, env))
                run(setenv(`$(env["CC"]) -static -o $(joinpath(prefix, "bin", "static_exe")) $(c_path)`, env))
                rm(c_path)
            end
            scan = scan_files(prefix, target)
            @test haskey(scan.binary_objects, "lib/obj.o") && haskey(scan.binary_objects, "bin/static_exe")
            @test runtime_requirements_audit(prefix, target).runtime_requirements == before
            rm(joinpath(prefix, "lib", "obj.o"))
            rm(joinpath(prefix, "bin", "static_exe"))

            # Needing a glibc newer than the architecture's oldest supported glibc fails
            with_toolchains([toolchain]) do _, env
                stub_versioned_lib(env, joinpath(prefix, "lib"), "libnewc.so.1", "GLIBC_2.39", "newc_fn")
                build_caller(env, joinpath(prefix, "bin", "newc"), ["newc_fn"], joinpath(prefix, "lib"), ["newc"])
            end
            result = runtime_requirements_audit(prefix, target)
            @test result.runtime_requirements.glibc.value == v"2.39"
            @test result.runtime_requirements.glibc.file == "bin/newc"
            @test occursin("glibc: 2.39 (bin/newc: GLIBC_2.39)", sprint(show, result.runtime_requirements))
            @test runtime_requirement_statuses(result) == [:fail]
            @test occursin("needs GLIBC_2.39, but x86_64 Linux targets must run on glibc 2.17",
                           only(result.pass_results["runtime_requirements"]).message)
            @test !success(result)

            # ... but not on musl, which has no such floor
            musl = Platform("x86_64", "linux"; libc="musl")
            @test isempty(runtime_requirement_statuses(runtime_requirements_audit(prefix, musl)))
            rm(joinpath(prefix, "bin", "newc"))
        end
    end

    @testset "macOS" begin
        target = Platform("aarch64", "macos"; os_version="20")
        toolchain = CToolchain(CrossPlatform(BBHostPlatform() => target); use_ccache=false)
        mktempdir() do prefix
            mkpath(joinpath(prefix, "bin"))
            build_dir = mktempdir()
            c_path = joinpath(build_dir, "hello.c")
            write(c_path, "int main(void) { return 0; }\n")
            with_toolchains([toolchain]) do _, env
                run(setenv(`$(env["CC"]) -o $(joinpath(prefix, "bin", "hello")) $(c_path)`, env))
                run(setenv(`$(env["CC"]) -mmacosx-version-min=12.0 -o $(joinpath(build_dir, "hello_12")) $(c_path)`, env))
            end

            # The default deployment target for aarch64 is macOS 11.0 (darwin20)
            result = runtime_requirements_audit(prefix, target)
            reqs = result.runtime_requirements
            @test reqs.macos.value == v"11.0"
            @test reqs.macos.file == "bin/hello"
            @test reqs.macos.source == "LC_BUILD_VERSION"
            @test reqs.glibc === nothing && reqs.libstdcxx === nothing
            @test runtime_requirement_statuses(result) == [:success]

            # Without an `os_version`, the toolchain's default deployment target applies
            result = runtime_requirements_audit(prefix, Platform("aarch64", "macos"))
            @test runtime_requirement_statuses(result) == [:success]

            # A binary needing macOS 12 doesn't run on the darwin20 (macOS 11) the platform names
            mv(joinpath(build_dir, "hello_12"), joinpath(prefix, "bin", "hello_12"))
            result = runtime_requirements_audit(prefix, target)
            @test result.runtime_requirements.macos.value == v"12.0"
            @test result.runtime_requirements.macos.file == "bin/hello_12"
            @test runtime_requirement_statuses(result) == [:fail]
            @test occursin("requires macOS 12.0, newer than the deployment target macOS 11.0 (darwin20)",
                           only(result.pass_results["runtime_requirements"]).message)
            @test runtime_requirement_statuses(runtime_requirements_audit(prefix, target; os_version=v"21")) == [:success]
        end
    end

    @testset "FreeBSD" begin
        target = Platform("x86_64", "freebsd"; os_version="14.1")
        toolchain = CToolchain(CrossPlatform(BBHostPlatform() => target); use_ccache=false)
        mktempdir() do prefix
            mkpath(joinpath(prefix, "bin"))
            # FreeBSD 14 changed `qsort_r()` to the POSIX argument order, as `qsort_r@FBSD_1.7`
            c_path = joinpath(prefix, "qsort.c")
            write(c_path, """
            #include <stdlib.h>
            static int cmp(const void *a, const void *b, void *arg) { return *(const int *)a - *(const int *)b; }
            int main(void) { int xs[] = {2, 1}; qsort_r(xs, 2, sizeof(int), cmp, NULL); return xs[0]; }
            """)
            with_toolchains([toolchain]) do _, env
                run(setenv(`$(env["CC"]) -o $(joinpath(prefix, "bin", "qsort")) $(c_path)`, env))
            end
            rm(c_path)

            result = runtime_requirements_audit(prefix, target)
            reqs = result.runtime_requirements
            @test reqs.freebsd.value == v"1.7"
            @test reqs.freebsd.source == "FBSD_1.7"
            @test reqs.freebsd.file == "bin/qsort"
            @test reqs.glibc === nothing
            @test runtime_requirement_statuses(result) == [:success]

            result = runtime_requirements_audit(prefix, target; os_version=v"13.2")
            @test runtime_requirement_statuses(result) == [:fail]
            @test occursin("needs FBSD_1.7, which first shipped with FreeBSD 14.0, newer than the target FreeBSD 13.2",
                           only(result.pass_results["runtime_requirements"]).message)

            # Without an `os_version` there is nothing to check against
            result = runtime_requirements_audit(prefix, Platform("x86_64", "freebsd"))
            @test runtime_requirement_statuses(result) == [:success]
        end
    end
end

@testset "RuntimeRequirements TOML round trip" begin
    using JLLGenerator: generate_toml_dict, parse_toml_dict
    empty = RuntimeRequirements()
    @test parse_toml_dict(RuntimeRequirements, generate_toml_dict(empty)) == empty
    @test isempty(generate_toml_dict(empty))

    reqs = RuntimeRequirements()
    reqs.libstdcxx = RuntimeRequirement(v"6.0.32", "bin/a", "GLIBCXX_3.4.32")
    reqs.glibcxx = RuntimeRequirement(v"3.4.32", "bin/a", "GLIBCXX_3.4.32")
    reqs.cxxabi = RuntimeRequirement(v"1.3.15", "lib/b.so", "CXXABI_1.3.15")
    reqs.unknown_libstdcxx = [RuntimeRequirement("GLIBCXX_3.4.99", "bin/c", "libstdc++.so.6")]
    reqs.glibc = RuntimeRequirement(v"2.17", "bin/a", "GLIBC_2.17")
    reqs.libgfortran = [RuntimeRequirement(4, "bin/d", "libgfortran.so.4"), RuntimeRequirement(5, "bin/e", "libgfortran.so.5")]
    reqs.macos = RuntimeRequirement(v"10.10", "bin/f", "LC_BUILD_VERSION")
    reqs.freebsd = RuntimeRequirement(v"1.7", "bin/g", "FBSD_1.7")
    d = generate_toml_dict(reqs)
    @test d["libstdcxx"] == Dict("value" => "6.0.32", "file" => "bin/a", "source" => "GLIBCXX_3.4.32")
    @test d["libgfortran"][2]["value"] == 5
    roundtrip = parse_toml_dict(RuntimeRequirements, d)
    @test roundtrip == reqs
    @test hash(roundtrip) == hash(reqs)
    @test roundtrip != empty
end
