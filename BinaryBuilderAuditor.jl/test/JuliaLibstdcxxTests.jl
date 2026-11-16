using Test, BinaryBuilderAuditor, ObjectFile
using BinaryBuilderAuditor: JULIA_LIBSTDCXX_VERSIONS, LIBSTDCXX_SYMBOL_VERSIONS, julia_libstdcxx_entry

# The `GLIBCXX_*`/`CXXABI_*` version names defined by the ELF library at `path`
function libstdcxx_defined_versions(path)
    return readmeta(path) do ohs
        names = String[]
        for entry in ObjectFile.ELFVersionData(only(ohs))
            isempty(entry.names) && continue
            name = first(entry.names)
            (startswith(name, "GLIBCXX_") || startswith(name, "CXXABI_")) && push!(names, name)
        end
        return names
    end
end

function max_symver(names, prefix)
    vs = [VersionNumber(name[length(prefix)+2:end]) for name in names
          if occursin(Regex("^$(prefix)_\\d+(\\.\\d+)*\$"), name)]
    return maximum(vs)
end

@testset "Julia libstdc++ table" begin
    @testset "self-consistency" begin
        versions = first.(JULIA_LIBSTDCXX_VERSIONS)
        @test issorted(versions)
        @test allunique(versions)
        @test first(versions) == v"1.0.0"
        @test all(v -> isempty(v.prerelease) && isempty(v.build), versions)

        # Each line's first release is recorded
        @test all(v -> VersionNumber(v.major, v.minor, 0) in versions, versions)
        # Within a line, a release is only recorded if its libstdc++ changed
        for i in 2:length(JULIA_LIBSTDCXX_VERSIONS)
            (prev, pe), (curr, ce) = JULIA_LIBSTDCXX_VERSIONS[i-1], JULIA_LIBSTDCXX_VERSIONS[i]
            if (prev.major, prev.minor) == (curr.major, curr.minor)
                @test pe != ce
            end
        end

        for (v, e) in JULIA_LIBSTDCXX_VERSIONS
            @test e.libstdcxx.major == 6 && e.libstdcxx.minor == 0
            # libstdc++.so.6.0.N defines GLIBCXX_3.4.N as its newest GLIBCXX version
            @test e.glibcxx == VersionNumber(3, 4, e.libstdcxx.patch)
            for symver in ("GLIBCXX_$(e.glibcxx)", "CXXABI_$(e.cxxabi)")
                lib = libstdcxx_version_for_symbol(symver)
                @test lib !== nothing && lib <= e.libstdcxx
            end
            # The next GLIBCXX version is only defined by newer libraries, if any
            next = libstdcxx_version_for_symbol("GLIBCXX_3.4.$(e.glibcxx.patch + 1)")
            @test next === nothing || next > e.libstdcxx
            @test julia_libstdcxx_version(v) == e.libstdcxx
        end

        # Every mapped library version is one some Julia release bundles
        bundled = Set(e.libstdcxx for (_, e) in JULIA_LIBSTDCXX_VERSIONS)
        @test all(in(bundled), values(LIBSTDCXX_SYMBOL_VERSIONS))
        # Each bundled libstdc++.so.6.0.N is the oldest library defining GLIBCXX_3.4.N
        for lib in bundled
            @test libstdcxx_version_for_symbol("GLIBCXX_3.4.$(lib.patch)") == lib
        end
        # Symbol versions are cumulative: a newer GLIBCXX/CXXABI version never maps to an
        # older library than an older version of the same family
        for prefix in ("GLIBCXX", "CXXABI")
            fam = sort([(VersionNumber(k[length(prefix)+2:end]), v) for (k, v) in LIBSTDCXX_SYMBOL_VERSIONS
                        if occursin(Regex("^$(prefix)_\\d+(\\.\\d+)*\$"), k)])
            @test issorted(last.(fam))
        end
    end

    @testset "accessors" begin
        @test julia_libstdcxx_version(v"1.0.0") == v"6.0.24"
        @test julia_libstdcxx_version(v"1.6") == julia_libstdcxx_version(v"1.6.0")
        @test julia_libstdcxx_version(v"1.12.0+build") == julia_libstdcxx_version(v"1.12.0")
        # Releases not recorded take the libstdc++ of the nearest recorded release before them
        @test julia_libstdcxx_version(v"1.6.2") == v"6.0.26"
        @test julia_libstdcxx_version(v"1.6.3") == v"6.0.29"
        @test julia_libstdcxx_version(v"1.6.7") == v"6.0.29"
        @test julia_libstdcxx_version(v"1.7.0") == v"6.0.29"
        @test julia_libstdcxx_version(v"1.11.5") == v"6.0.32"
        @test julia_libstdcxx_version(v"1.99.0") == last(last(JULIA_LIBSTDCXX_VERSIONS)).libstdcxx
        # Releases before 1.0 and prereleases are not covered
        @test julia_libstdcxx_version(v"0.7.0") === nothing
        @test julia_libstdcxx_version(v"1.7.0-beta1") === nothing
        @test julia_libstdcxx_version(v"1.13.0-rc1") === nothing
        @test libstdcxx_version_for_symbol("GLIBCXX_3.4.32") == v"6.0.32"
        @test libstdcxx_version_for_symbol(SubString("CXXABI_1.3.15")) == v"6.0.33"
        @test libstdcxx_version_for_symbol("GLIBCXX_3.4.999") === nothing
        @test libstdcxx_version_for_symbol("GLIBC_2.17") === nothing
    end

    # Known GLIBCXX/CXXABI maxima of each Julia release line, gathered by hand
    @testset "known releases" begin
        known = [
            v"1.0.0"  => (v"3.4.24", v"1.3.11"),
            v"1.5.0"  => (v"3.4.24", v"1.3.11"),
            v"1.6.0"  => (v"3.4.26", v"1.3.12"),
            v"1.6.7"  => (v"3.4.29", v"1.3.13"),
            v"1.7.0"  => (v"3.4.29", v"1.3.13"),
            v"1.8.0"  => (v"3.4.29", v"1.3.13"),
            v"1.8.5"  => (v"3.4.30", v"1.3.13"),
            v"1.9.0"  => (v"3.4.30", v"1.3.13"),
            v"1.10.0" => (v"3.4.30", v"1.3.13"),
            v"1.10.13" => (v"3.4.32", v"1.3.14"),
            v"1.11.0" => (v"3.4.32", v"1.3.14"),
            v"1.12.0" => (v"3.4.33", v"1.3.15"),
            v"1.13.0" => (v"3.4.34", v"1.3.15"),
        ]
        for (v, (glibcxx, cxxabi)) in known
            e = julia_libstdcxx_entry(v)
            @test e.glibcxx == glibcxx
            @test e.cxxabi == cxxabi
            @test e.libstdcxx == VersionNumber(6, 0, glibcxx.patch)
        end
    end

    @testset "running Julia" begin
        libdir = joinpath(Sys.BINDIR, Base.PRIVATE_LIBDIR)
        libs = filter(f -> occursin(r"^libstdc\+\+\.so\.6\.0\.\d+$", f) && !islink(joinpath(libdir, f)), readdir(libdir))
        v = VersionNumber(VERSION.major, VERSION.minor, VERSION.patch, VERSION.prerelease)
        if !Sys.islinux() || isempty(libs)
            @info("Skipping running-Julia check: no versioned libstdc++ in $(libdir)")
        elseif julia_libstdcxx_version(v) === nothing
            @info("Skipping running-Julia check: Julia $(v) is not in the table")
        else
            lib = only(libs)
            @test julia_libstdcxx_version(v) == VersionNumber(lib[length("libstdc++.so.")+1:end])
            names = libstdcxx_defined_versions(joinpath(libdir, lib))
            entry = julia_libstdcxx_entry(v)
            @test max_symver(names, "GLIBCXX") == entry.glibcxx
            @test max_symver(names, "CXXABI") == entry.cxxabi
            @test all(n -> libstdcxx_version_for_symbol(n) !== nothing && libstdcxx_version_for_symbol(n) <= entry.libstdcxx, names)
        end
    end
end
