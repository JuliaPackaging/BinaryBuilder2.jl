using Test, BinaryBuilderAuditor, Base.BinaryPlatforms, ObjectFile, BinaryBuilderToolchains, BinaryBuilderProducts, TreeArchival
using BinaryBuilderAuditor: ensure_sonames!, ensure_codesigned!, relink_absolute_dependencies!, rpaths_consistent!, resolve_dynamic_links!

include(joinpath(dirname(@__DIR__), "CodeSignatureUtils.jl"))

@testset "ensure_codesigned!" begin
    libplus_c_path = joinpath(dirname(@__DIR__), "source", "libplus.c")
    libmult_c_path = joinpath(dirname(@__DIR__), "source", "libmult.c")

    for target in (Platform("aarch64", "macos"; os_version=v"20"), Platform("x86_64", "macos"; os_version=v"18"))
        toolchain = CToolchain(CrossPlatform(BBHostPlatform() => target); use_ccache=false)
        mktempdir() do prefix
            prefix = realpath(prefix)
            mkpath(joinpath(prefix, "lib"))
            mkpath(joinpath(prefix, "bin"))
            libplus_path = joinpath(prefix, "lib", "libplus.1.dylib")
            libmult_path = joinpath(prefix, "lib", "libmult.2.dylib")
            tool_path = joinpath(prefix, "bin", "tool")
            tool_link_path = joinpath(prefix, "bin", "tool-hardlink")
            obj_path = joinpath(prefix, "lib", "plus.o")
            main_c_path = joinpath(prefix, "main.c")
            write(main_c_path, "int plus(int, int);\nint mult(int, int);\nint main() { return mult(1, 0) + plus(1, -1); }\n")

            # Libraries with absolute install names and an executable that links them
            # by those names, so the auditor has to edit all three files.
            with_toolchains([toolchain]) do _, env
                run(setenv(`$(env["CC"]) -o $(libplus_path) -shared $(libplus_c_path)`, env))
                run(setenv(`$(env["CC"]) -o $(libmult_path) -shared $(libmult_c_path) $(libplus_path)`, env))
                run(setenv(`$(env["CC"]) -o $(tool_path) $(main_c_path) $(libmult_path) $(libplus_path)`, env))
                run(setenv(`$(env["CC"]) -c -o $(obj_path) $(libplus_c_path)`, env))
            end
            rm(main_c_path)
            hardlink(tool_path, tool_link_path)
            obj_contents = read(obj_path)

            products = [LibraryProduct("libplus", :libplus), LibraryProduct("libmult", :libmult)]
            scan = scan_files(prefix, target, products)
            result = AuditResult(scan)
            ensure_sonames!(result)
            relink_absolute_dependencies!(result)
            resolve_dynamic_links!(result, AuditInfo())
            rpaths_consistent!(result, AuditInfo())
            @test success(result.pass_results)

            # The edits leave the linker's signatures behind (or none at all)
            for p in (libplus_path, libmult_path, tool_path)
                @test codesignature_status(p) != :adhoc
            end

            ensure_codesigned!(result)
            @test success(result.pass_results)
            for p in (libplus_path, libmult_path, tool_path, tool_link_path)
                @test codesignature_status(p) == :adhoc
            end
            # The hard-linked copy is signed once and stays a hard link; object files are not signed at all
            @test stat(tool_path).inode == stat(tool_link_path).inode
            @test scan.files["bin/tool"].inode == scan.files["bin/tool-hardlink"].inode
            signed = [r.identifier for r in result.pass_results["ensure_codesigned!"]]
            @test sort(signed) == ["bin/tool", "lib/libmult.2.dylib", "lib/libplus.1.dylib"]
            @test read(obj_path) == obj_contents

            # Signing again is a no-op
            pre_treehash = treehash(prefix)
            ensure_codesigned!(result)
            @test treehash(prefix) == pre_treehash

            # A file `ldid` cannot sign is reported
            write(libplus_path, "I am not a Mach-O file anymore")
            result = AuditResult(scan)
            ensure_codesigned!(result)
            @test !success(result.pass_results)
            @test any(r.identifier == "lib/libplus.1.dylib" && r.status == :fail for r in result.pass_results["ensure_codesigned!"])
        end
    end

    # Nothing to do on other platforms
    target = Platform("x86_64", "linux")
    toolchain = CToolchain(CrossPlatform(BBHostPlatform() => target); use_ccache=false)
    mktempdir() do prefix
        mkpath(joinpath(prefix, "lib"))
        with_toolchains([toolchain]) do _, env
            run(setenv(`$(env["CC"]) -o $(joinpath(prefix, "lib", "libplus.so")) -shared $(libplus_c_path)`, env))
        end
        result = AuditResult(scan_files(prefix, target))
        pre_treehash = treehash(prefix)
        ensure_codesigned!(result)
        @test treehash(prefix) == pre_treehash
        @test !haskey(result.pass_results, "ensure_codesigned!")
    end
end

@testset "audit! signs macOS binaries" begin
    target = Platform("aarch64", "macos"; os_version=v"20")
    toolchain = CToolchain(CrossPlatform(BBHostPlatform() => target); use_ccache=false)
    mktempdir() do prefix
        prefix = realpath(prefix)
        mkpath(joinpath(prefix, "lib"))
        libplus_path = joinpath(prefix, "lib", "libplus.1.dylib")
        with_toolchains([toolchain]) do _, env
            run(setenv(`$(env["CC"]) -o $(libplus_path) -shared $(joinpath(dirname(@__DIR__), "source", "libplus.c"))`, env))
        end
        mkpath(joinpath(prefix, "share", "licenses", "libplus"))
        touch(joinpath(prefix, "share", "licenses", "libplus", "LICENSE.md"))

        products = [LibraryProduct("libplus", :libplus)]
        result = audit!(prefix, products, AuditInfo(); platform=target)
        @test success(result)
        @test codesignature_status(libplus_path) == :adhoc

        # A read-only audit leaves the files alone
        pre_treehash = treehash(prefix)
        result = audit!(prefix, products, AuditInfo(); platform=target, readonly=true)
        @test success(result)
        @test treehash(prefix) == pre_treehash
        @test !haskey(result.pass_results, "ensure_codesigned!")
    end
end
