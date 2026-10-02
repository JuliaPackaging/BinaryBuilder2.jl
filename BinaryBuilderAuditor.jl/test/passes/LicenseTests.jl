using Test, BinaryBuilderAuditor, Base.BinaryPlatforms
using BinaryBuilderAuditor: licenses_present

@testset "licenses_present" begin
    mktempdir() do src_dir
        scan = scan_files(src_dir, HostPlatform())
        result = AuditResult(scan)
    
        licenses_present(result)
        @test !success(result.pass_results)

        mkpath(joinpath(src_dir, "share", "licenses", "Foo"))
        open(joinpath(src_dir, "share", "licenses", "Foo", "LICENSE.md"); write=true) do io
            println(io, "This is totally a license")
        end

        scan = scan_files(src_dir, HostPlatform())
        result = AuditResult(scan)
        licenses_present(result)
        @test success(result.pass_results)
    end
end
