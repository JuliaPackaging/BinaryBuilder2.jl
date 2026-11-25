using Test, BinaryBuilderAuditor, Base.BinaryPlatforms, ObjectFile, BinaryBuilderToolchains, BinaryBuilderProducts, JLLGenerator
using BinaryBuilderAuditor: disabled_passes

@testset "AuditConfig" begin
    @test isempty(disabled_passes(AuditConfig()))
    @test disabled_passes(AuditConfig(; rpaths_consistent = false, licenses_present = false)) == [:rpaths_consistent, :licenses_present]
    @test AuditConfig(; rpaths_consistent = false) == AuditConfig(; rpaths_consistent = false)
    @test AuditConfig(; rpaths_consistent = false) != AuditConfig()
    @test repr(AuditConfig(; rpaths_consistent = false)) == "AuditConfig(rpaths_consistent = false)"
    # Passes the rest of the build relies upon have no switch
    @test_throws MethodError AuditConfig(; resolve_dynamic_links = false)
    @test_throws MethodError AuditConfig(; ensure_codesigned = false)
    @test disabled_passes(AuditConfig(; extra_system_libraries = ["libcuda.so.1"])) == Symbol[]
    @test AuditConfig(; extra_system_libraries = ["libcuda.so.1"]) == AuditConfig(; extra_system_libraries = ["libcuda.so.1"])
    @test hash(AuditConfig(; extra_system_libraries = ["libcuda.so.1"])) == hash(AuditConfig(; extra_system_libraries = ["libcuda.so.1"]))
    @test AuditConfig(; extra_system_libraries = ["libcuda.so.1"]) != AuditConfig()
    @test repr(AuditConfig(; rpaths_consistent = false, extra_system_libraries = ["libcuda.so.1"])) ==
          "AuditConfig(rpaths_consistent = false, extra_system_libraries = [\"libcuda.so.1\"])"

    target_platform = Platform("x86_64", "linux")
    platform = CrossPlatform(BBHostPlatform() => target_platform)
    toolchain = CToolchain(platform; use_ccache=false)
    libplus_c_path = joinpath(@__DIR__, "source", "libplus.c")
    libmult_c_path = joinpath(@__DIR__, "source", "libmult.c")

    mktempdir() do prefix
        # `libmult` links against `lib/plus/libplus.so` with no RPATH, and there is no license
        mkpath(joinpath(prefix, "lib", "plus"))
        libplus_path = joinpath(prefix, "lib", "plus", "libplus.so.1")
        libmult_path = joinpath(prefix, "lib", "libmult.so.2")
        with_toolchains([toolchain]) do _, env
            run(setenv(`$(env["CC"]) -o $(libplus_path) -shared -Wl,-soname,libplus.so.1 $(libplus_c_path)`, env))
            symlink("libplus.so.1", joinpath(prefix, "lib", "plus", "libplus.so"))
            run(setenv(`$(env["CC"]) -o $(libmult_path) -shared -Wl,-soname,libmult.so.2 $(libmult_c_path) -L $(prefix)/lib/plus -lplus`, env))
        end
        products = [LibraryProduct("lib/plus/libplus", :libplus), LibraryProduct("libmult", :libmult)]
        libmult_rpaths() = readmeta(ohs -> rpaths(RPath(only(ohs))), libmult_path)

        # By default the missing license fails the audit
        result = audit!(prefix, products, AuditInfo(); platform=target_platform, readonly=true)
        @test !success(result)
        @test any(r.status == :fail for r in result.pass_results["licenses_present"])

        # Disabled passes record a single `:skipped` entry, which does not fail the audit
        config = AuditConfig(; licenses_present = false, rpaths_consistent = false)
        result = audit!(prefix, products, AuditInfo(); platform=target_platform, config)
        @test success(result)
        for pass_name in ("licenses_present", "rpaths_consistent!")
            @test only(result.pass_results[pass_name]).status == :skipped
        end
        @test isempty(libmult_rpaths())
        # The library products are still described
        @test sort([p.varname for p in result.jll_lib_products]) == [:libmult, :libplus]
        # The skipped passes show in the audit output
        output = sprint(show, result)
        @test occursin("[skipped]", output)
        @test occursin("disabled by AuditConfig", output)

        # Re-enabling `rpaths_consistent!` gives `libmult` its RPATH
        result = audit!(prefix, products, AuditInfo(); platform=target_platform, config=AuditConfig(; licenses_present = false))
        @test success(result)
        @test !haskey(result.pass_results, "rpaths_consistent!") || all(r.status != :skipped for r in result.pass_results["rpaths_consistent!"])
        @test libmult_rpaths() == ["\$ORIGIN/plus"]
    end

    # A library provided by the system the binaries run on, rather than by this package
    # or a dependency, is accepted once it is listed in `extra_system_libraries`
    mktempdir() do external
        mktempdir() do prefix
            libext_path = joinpath(external, "libext.so.3")
            libuser_path = joinpath(prefix, "lib", "libuser.so.1")
            mkpath(dirname(libuser_path))
            mkpath(joinpath(prefix, "share", "licenses", "libuser"))
            touch(joinpath(prefix, "share", "licenses", "libuser", "LICENSE"))
            with_toolchains([toolchain]) do _, env
                run(setenv(`$(env["CC"]) -o $(libext_path) -shared -Wl,-soname,libext.so.3 $(libplus_c_path)`, env))
                symlink("libext.so.3", joinpath(external, "libext.so"))
                run(setenv(`$(env["CC"]) -o $(libuser_path) -shared -Wl,-soname,libuser.so.1 $(libmult_c_path) -L $(external) -lext`, env))
            end
            products = [LibraryProduct("libuser", :libuser)]

            result = audit!(prefix, products, AuditInfo(); platform=target_platform, readonly=true)
            @test !success(result)
            @test any(r.status == :fail for r in result.pass_results["resolve_dynamic_links!"])

            for extra in (["libext.so.3"], ["LIBEXT.SO.3"])
                result = audit!(prefix, products, AuditInfo(); platform=target_platform,
                                config=AuditConfig(; extra_system_libraries = extra))
                @test success(result)
                libuser = only(result.jll_lib_products)
                @test isempty(libuser.deps)
                @test "ext" ∉ libuser.system_deps
            end
        end
    end
end
