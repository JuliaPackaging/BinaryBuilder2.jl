using Test, BinaryBuilder2, SHA, MultiHashParsing
using BinaryBuilder2: extract_spec_hash

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
end
