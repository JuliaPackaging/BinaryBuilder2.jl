using Test, BinaryBuilder2, SHA, MultiHashParsing
using BinaryBuilder2: extract_spec_hash, resolve_audit_config

@testset "extraction spec hash" begin
    build_hash = SHA1Hash(sha1("build"))
    h(products...) = extract_spec_hash(build_hash, "install libfoo", AbstractProduct[products...])

    # Products without an archive hash as they always have, so that existing cache
    # entries stay valid
    legacy = SHA1Hash(sha1(join([
        "[extraction_metadata]",
        "  build_hash = $(build_hash)",
        "  script_hash = $(SHA1Hash(sha1("install libfoo")))",
        "[products]",
        "  libfoo = [\"libfoo\"]",
        "",
    ], "\n")))
    @test h(LibraryProduct("libfoo", :libfoo)) == legacy

    # A library's archive counts, and so does what it declares
    lib(; kwargs...) = LibraryProduct("libfoo", :libfoo; static = StaticLibraryProduct("libfoo"; kwargs...))
    @test h(lib()) != legacy
    @test h(lib()) != h(lib(; deps = LibraryDependency[]))
    @test h(lib(; deps = [LibraryDependency(:libbar)])) != h(lib(; deps = [LibraryDependency(:Bar_jll, :libbar)]))
    @test h(lib()) != h(lib(; system_deps = ["m"]))

    # ... and a standalone archive's declarations count just the same
    standalone(; deps = LibraryDependency[], system_deps = String[]) =
        StaticLibraryProduct("libfoo"; varname = :libfoo_a, deps, system_deps)
    @test h(standalone()) == h(standalone())
    @test h(standalone()) != h(standalone(; deps = [LibraryDependency(:libbar)]))
    @test h(standalone()) != h(standalone(; system_deps = ["m"]))

    # Only a non-default audit config counts
    @test extract_spec_hash(build_hash, "install libfoo", AbstractProduct[LibraryProduct("libfoo", :libfoo)], AuditConfig()) == legacy
    no_rpaths = AuditConfig(; rpaths_consistent = false)
    @test extract_spec_hash(build_hash, "install libfoo", AbstractProduct[LibraryProduct("libfoo", :libfoo)], no_rpaths) != legacy
    extra_libs = AuditConfig(; extra_system_libraries = ["libcuda.so.1"])
    @test extract_spec_hash(build_hash, "install libfoo", AbstractProduct[LibraryProduct("libfoo", :libfoo)], extra_libs) != legacy
end

@testset "resolve_audit_config" begin
    no_rpaths = AuditConfig(; rpaths_consistent = false)
    linux = Platform("x86_64", "linux")
    cross = CrossPlatform(linux => Platform("aarch64", "linux"))
    @test resolve_audit_config(no_rpaths, linux) === no_rpaths
    per_platform = p -> isa(p, CrossPlatform) ? no_rpaths : AuditConfig()
    @test resolve_audit_config(per_platform, cross) == no_rpaths
    @test resolve_audit_config(per_platform, linux) == AuditConfig()
    @test_throws ArgumentError resolve_audit_config(p -> nothing, linux)
end
