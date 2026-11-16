#!/usr/bin/env julia
#
# Regenerates `../src/julia_libstdcxx_versions.jl`: for the official Julia releases listed in
# versions.json (no alpha, beta or rc releases), the libstdc++ bundled in their `lib/julia`,
# and the newest `GLIBCXX_*` and `CXXABI_*` symbol versions that library defines.  Also
# derives, from the same libraries, the oldest libstdc++ that defines each symbol version.
#
# Usage: julia --project=BinaryBuilderAuditor.jl/contrib BinaryBuilderAuditor.jl/contrib/generate_julia_libstdcxx_versions.jl
#
# Like HistoricalStdlibVersions.jl, the table records only the first release of each
# `major.minor` line and the releases whose libstdc++ differs from the previous release of
# their line, and every run inspects every release.
#
# Only the x86_64-linux-gnu tarballs are inspected; the table assumes the other Linux
# platforms of a release bundle the same libstdc++ version.  Each tarball is downloaded to a
# temporary directory, checked against its sha256, and deleted once its libstdc++ is extracted.

using Downloads, JSON, ObjectFile, SHA

const VERSIONS_JSON_URL = "https://julialang-s3.julialang.org/bin/versions.json"
const PLATFORM_TRIPLET = "x86_64-linux-gnu"
const NUM_CONCURRENT = 8
const OUTPUT_FILE = joinpath(dirname(@__DIR__), "src", "julia_libstdcxx_versions.jl")

const SYMVER_REGEX = r"^(GLIBCXX|CXXABI)_(\d+(?:\.\d+)*)$"
const LIBSTDCXX_FILE_REGEX = r"^libstdc\+\+\.so\.(6(?:\.\d+)*)$"

"""
    extract_libstdcxx(url, sha256_hex, dir)

Download the tarball at `url` into `dir`, check its sha256, extract only
`lib/julia/libstdc++.so*` from it, and delete it.  Returns the path of the extracted regular
file (not symlink).
"""
function extract_libstdcxx(url::String, sha256_hex::String, dir::String)
    tarball = joinpath(dir, "julia.tar.gz")
    Downloads.download(url, tarball)
    calc = bytes2hex(open(SHA.sha256, tarball))
    calc == sha256_hex || error("sha256 mismatch for $(url): expected $(sha256_hex), got $(calc)")
    run(`tar -C $(dir) -xzf $(tarball) --wildcards --strip-components=1 '*/lib/julia/libstdc++.so*'`)
    rm(tarball)

    libdir = joinpath(dir, "lib", "julia")
    files = filter(readdir(libdir; join=true)) do f
        isfile(f) && !islink(f) && occursin(LIBSTDCXX_FILE_REGEX, basename(f))
    end
    length(files) == 1 || error("expected exactly one libstdc++ file in $(url), found $(basename.(files))")
    return only(files)
end

"""
    defined_symbol_versions(path)

All `GLIBCXX_*` and `CXXABI_*` version names the ELF shared library at `path` defines.
"""
function defined_symbol_versions(path::String)
    names = String[]
    readmeta(path) do ohs
        oh = only(ohs)
        for entry in ObjectFile.ELFVersionData(oh)
            isempty(entry.names) && continue
            name = first(entry.names)
            startswith(name, "GLIBCXX_") || startswith(name, "CXXABI_") || continue
            push!(names, name)
        end
    end
    return sort!(unique!(names))
end

function max_symbol_version(names, prefix::String)
    versions = VersionNumber[]
    for name in names
        m = match(SYMVER_REGEX, name)
        if m !== nothing && m[1] == prefix
            push!(versions, VersionNumber(m[2]))
        end
    end
    isempty(versions) && error("no $(prefix)_* version defined")
    return maximum(versions)
end

"""
    libstdcxx_library_version(path, glibcxx)

The libstdc++ shared-library version `6.0.N` of the library at `path`, taken from its file
name.  Old Julia releases ship the library only as `libstdc++.so.6`; for those, `N` is the
patch number of the newest `GLIBCXX_3.4.N` the library defines, which is how libstdc++
numbers its releases (checked against every versioned file this script sees).
"""
function libstdcxx_library_version(path::String, glibcxx::VersionNumber)
    from_symbols = VersionNumber(6, 0, glibcxx.patch)
    filever = VersionNumber(match(LIBSTDCXX_FILE_REGEX, basename(path))[1])
    if filever == v"6"
        glibcxx.major == 3 && glibcxx.minor == 4 || error("unexpected GLIBCXX version $(glibcxx) in $(path)")
        return from_symbols, false
    end
    filever == from_symbols || error("$(basename(path)) defines GLIBCXX_$(glibcxx), expected libstdc++.so.$(from_symbols)")
    return filever, true
end

function inspect_release(version::VersionNumber, url::String, sha256_hex::String)
    mktempdir() do dir
        @info("Inspecting Julia $(version)", url)
        path = extract_libstdcxx(url, sha256_hex, dir)
        names = defined_symbol_versions(path)
        glibcxx = max_symbol_version(names, "GLIBCXX")
        cxxabi = max_symbol_version(names, "CXXABI")
        libstdcxx, from_filename = libstdcxx_library_version(path, glibcxx)
        return (; libstdcxx, glibcxx, cxxabi, names, from_filename)
    end
end

minor_line(v::VersionNumber) = (v.major, v.minor)

"""
    drop_unchanged!(entries)

Drop each entry (sorted by version) whose libstdc++ is the same as that of the entry before
it in the same `major.minor` line.  The first release of each line is always kept.
"""
function drop_unchanged!(entries)
    keep = trues(length(entries))
    for i in 2:length(entries)
        (prev, pe), (curr, ce) = entries[i-1], entries[i]
        minor_line(prev) == minor_line(curr) || continue
        keep[i] = pe != ce
    end
    keepat!(entries, keep)
end

function symver_sort_key(name::String)
    m = match(SYMVER_REGEX, name)
    m === nothing && return (name, v"0")
    return (String(m[1]), VersionNumber(m[2]))
end

function write_table(path::String, entries, symbol_map)
    open(path, "w") do io
        print(io, """
        ## This file is autogenerated by BinaryBuilderAuditor.jl/contrib/generate_julia_libstdcxx_versions.jl.
        ## Do not edit it by hand; it is regenerated monthly by .github/workflows/UpdateJuliaLibstdcxx.yml.

        # The libstdc++ bundled in `lib/julia` of each official Julia release (from its
        # x86_64-linux-gnu tarball in https://julialang-s3.julialang.org/bin/versions.json): the
        # shared-library version (`libstdc++.so.6.0.N`), and the newest `GLIBCXX_*` and `CXXABI_*`
        # symbol versions that library defines.  Only the first release of each `major.minor` line,
        # and the releases that change the libstdc++ from the previous release of their line, are
        # recorded; every other release bundles the same libstdc++ as the nearest recorded release
        # before it.
        const JULIA_LIBSTDCXX_VERSIONS = [
        """)
        for (v, e) in entries
            println(io, "    ", repr(v), " => (libstdcxx = ", repr(e.libstdcxx),
                    ", glibcxx = ", repr(e.glibcxx), ", cxxabi = ", repr(e.cxxabi), "),")
        end
        print(io, """
        ]

        # Every `GLIBCXX_*`/`CXXABI_*` symbol version defined by a libstdc++ bundled with any Julia
        # release, mapped to the oldest of those libstdc++ versions that defines it.
        const LIBSTDCXX_SYMBOL_VERSIONS = Dict{String,VersionNumber}(
        """)
        for name in sort!(collect(keys(symbol_map)); by=symver_sort_key)
            println(io, "    ", repr(name), " => ", repr(symbol_map[name]), ",")
        end
        println(io, ")")
    end
end

function main()
    @info("Downloading versions.json")
    versions_json = JSON.parse(String(take!(Downloads.download(VERSIONS_JSON_URL, IOBuffer()))))

    todo = []
    for (vstr, d) in versions_json
        v = VersionNumber(vstr)
        (v < v"1.0.0" || !d["stable"] || !isempty(v.prerelease)) && continue
        files = filter(f -> f["triplet"] == PLATFORM_TRIPLET && f["kind"] == "archive", d["files"])
        isempty(files) && error("Julia $(v) has no $(PLATFORM_TRIPLET) tarball")
        f = only(files)
        push!(todo, (v, String(f["url"]), String(f["sha256"])))
    end
    sort!(todo; by=first)
    @info("$(length(todo)) releases to inspect")

    failed = String[]
    results = asyncmap(todo; ntasks=NUM_CONCURRENT) do (v, url, sha)
        try
            return v => retry(() -> inspect_release(v, url, sha); delays=ExponentialBackOff(n=3))()
        catch e
            e isa InterruptException && rethrow()
            @error("Failed to inspect Julia $(v)", exception=(e, catch_backtrace()))
            push!(failed, string(v))
            return nothing
        end
    end
    # A missing release would leave a hole in the table, so write nothing.
    isempty(failed) || error("Could not inspect $(length(failed)) releases: ", join(failed, ", "))

    entries = Pair{VersionNumber,Any}[]
    symbol_map = Dict{String,VersionNumber}()
    for (v, r) in results
        for name in r.names
            symbol_map[name] = min(get(symbol_map, name, r.libstdcxx), r.libstdcxx)
        end
        push!(entries, v => (; r.libstdcxx, r.glibcxx, r.cxxabi))
        r.from_filename || @info("Julia $(v) ships an unversioned libstdc++.so.6; inferred $(r.libstdcxx) from GLIBCXX_$(r.glibcxx)")
    end
    sort!(entries; by=first)
    drop_unchanged!(entries)

    @info("Writing $(OUTPUT_FILE)")
    write_table(OUTPUT_FILE, entries, symbol_map)
end

main()
