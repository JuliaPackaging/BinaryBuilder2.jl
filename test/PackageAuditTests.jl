using Test, BinaryBuilder2
using BinaryBuilder2: PackageAuditError, DEFAULT_JULIA_COMPAT
using BinaryBuilderAuditor: PassResult

@testset "PackageAuditError" begin
    err = PackageAuditError("HelloWorldCxx", "1.6", Dict(
        "julia_libstdcxx" => [
            PassResult(:fail, "[x86_64-linux-gnu-cxx11] bin/hello_world", "needs GLIBCXX_3.4.32 (libstdc++ 6.0.32), but ...; set julia_compat=\"1.10.1\""),
            PassResult(:success, "[aarch64-linux-gnu-cxx11] bin/hello_world", "fine"),
        ],
    ))
    msg = sprint(showerror, err)
    @test startswith(msg, "Package audit of HelloWorldCxx_jll (julia_compat \"1.6\") failed:")
    @test occursin("[julia_libstdcxx] [x86_64-linux-gnu-cxx11] bin/hello_world: needs GLIBCXX_3.4.32", msg)
    @test occursin("set julia_compat=\"1.10.1\"", msg)
    @test !occursin("aarch64", msg)
    @test DEFAULT_JULIA_COMPAT == "1.6"
end
