using Test, BinaryBuilderAuditor
using BinaryBuilderAuditor: RuntimeRequirement, RuntimeRequirements, minimum_julia_for_libstdcxx,
                            julia_compat_string, oldest_admitted_libstdcxx, JULIA_LIBSTDCXX_VERSIONS

function libstdcxx_requirements(libstdcxx, source; file = "bin/hello_world", unknown = String[])
    reqs = RuntimeRequirements()
    if libstdcxx !== nothing
        reqs.libstdcxx = RuntimeRequirement{VersionNumber}(libstdcxx, file, source)
    end
    reqs.unknown_libstdcxx = [RuntimeRequirement{String}(u, file, "libstdc++.so.6") for u in unknown]
    return reqs
end

statuses(pass_results) = [r.status for r in get(pass_results, "julia_libstdcxx", PassResult[])]
messages(pass_results) = [something(r.message, "") for r in get(pass_results, "julia_libstdcxx", PassResult[])]

@testset "audit_package" begin
    @testset "minimum_julia_for_libstdcxx" begin
        @test julia_compat_string(v"1.11.0") == "1.11"
        @test julia_compat_string(v"1.10.13") == "1.10.13"
        # 1.10.1 was the first release to bundle libstdc++ 6.0.32 (GLIBCXX_3.4.32)
        @test minimum_julia_for_libstdcxx(v"6.0.32") == v"1.10.1"
        @test minimum_julia_for_libstdcxx(v"6.0.24") == v"1.0.0"
        @test minimum_julia_for_libstdcxx(v"6.0.99") === nothing
        # Every release from the answer on bundles a new enough libstdc++
        for libv in unique(e.libstdcxx for (_, e) in JULIA_LIBSTDCXX_VERSIONS)
            floor = minimum_julia_for_libstdcxx(libv)
            @test all(e.libstdcxx >= libv for (v, e) in JULIA_LIBSTDCXX_VERSIONS if v >= floor)
        end
    end

    @testset "oldest_admitted_libstdcxx" begin
        weakest(compat) = (w = oldest_admitted_libstdcxx(compat); (first(w), last(w).libstdcxx))
        @test weakest("1.6") == (v"1.6.0", v"6.0.26")
        @test weakest("1.6.5") == (v"1.6.5", v"6.0.29")
        @test weakest("1.10.13") == (v"1.10.13", v"6.0.32")
        @test weakest("1.11, 1.10") == (v"1.10.0", v"6.0.30")
        @test weakest("1.12") == (v"1.12.0", v"6.0.33")
        @test oldest_admitted_libstdcxx("0.7") === nothing
    end

    gcc14 = libstdcxx_requirements(v"6.0.32", "GLIBCXX_3.4.32")

    # No libstdc++ needed: passes with any julia_compat
    @test success(audit_package("1.0", ["x86_64-linux-gnu" => RuntimeRequirements()]))
    @test isempty(statuses(audit_package("1.0", ["x86_64-linux-gnu" => RuntimeRequirements()])))
    @test success(audit_package("1.6", []))

    # Too-low julia_compat fails, naming the file, the symbol version and the julia_compat that works
    res = audit_package("1.6", ["x86_64-linux-gnu-cxx11" => gcc14, "aarch64-linux-gnu-cxx11" => gcc14])
    @test !success(res)
    @test statuses(res) == [:fail, :fail]
    @test [r.identifier for r in res["julia_libstdcxx"]] == ["[x86_64-linux-gnu-cxx11] bin/hello_world", "[aarch64-linux-gnu-cxx11] bin/hello_world"]
    msg = first(messages(res))
    @test occursin("GLIBCXX_3.4.32", msg)
    @test occursin("julia_compat \"1.6\" admits Julia v1.6.0, which bundles libstdc++ 6.0.26", msg)
    @test occursin("set julia_compat=\"1.10.1\"", msg)

    # Sufficient julia_compat passes, including patch-level bounds
    for compat in ("1.10.1", "1.10.13", "1.11", "1.12", "1.11, 1.12")
        @test success(audit_package(compat, ["x86_64-linux-gnu" => gcc14]))
    end
    # ...but not when a lower bound or an older range is also admitted
    @test !success(audit_package("1.10", ["x86_64-linux-gnu" => gcc14]))
    @test !success(audit_package("1.9, 1.11", ["x86_64-linux-gnu" => gcc14]))
    @test !success(audit_package("~1.10.0", ["x86_64-linux-gnu" => gcc14]))

    # Only failing extractions fail
    res = audit_package("1.6", ["a" => libstdcxx_requirements(v"6.0.24", "GLIBCXX_3.4.24"), "b" => gcc14])
    @test statuses(res) == [:success, :fail]

    # A symbol version that no released Julia's libstdc++ defines always fails
    res = audit_package("1.12", ["x86_64-linux-gnu" => libstdcxx_requirements(nothing, ""; unknown = ["GLIBCXX_3.4.99"])])
    @test statuses(res) == [:fail]
    @test occursin("GLIBCXX_3.4.99", only(messages(res)))
    @test occursin("no released Julia bundles", only(messages(res)))

    # A julia_compat that admits no release from v1.0 on can't be checked
    res = audit_package("0.7", ["x86_64-linux-gnu" => gcc14])
    @test statuses(res) == [:warn]
end
