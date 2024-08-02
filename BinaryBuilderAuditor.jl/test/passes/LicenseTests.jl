using Test, BinaryBuilderAuditor, Base.BinaryPlatforms
using BinaryBuilderAuditor: licenses_present

@testset "licenses_present" begin
    mktempdir() do src_dir
        scan = scan_files(src_dir, HostPlatform())
        pass_results = Dict{String,Vector{PassResult}}()
    
        licenses_present(scan, pass_results)
        @test !success(pass_results)

        mkpath(joinpath(src_dir, "share", "licenses", "Foo"))
        open(joinpath(src_dir, "share", "licenses", "Foo", "LICENSE.md"); write=true) do io
            println(io, "This is totally a license")
        end

        scan = scan_files(src_dir, HostPlatform())
        pass_results = Dict{String,Vector{PassResult}}()
        licenses_present(scan, pass_results)
        @test success(pass_results)
    end
end
