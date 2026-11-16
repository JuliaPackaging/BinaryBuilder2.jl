using ObjectFile
using BinaryBuilderPlatformExtensions: macos_version
using BinaryBuilderToolchains: macos_target_kernel_version, oldest_glibc_version

"""
    verneed_libraries(oh::ELFHandle)

Return `(library, symbol_versions)` pairs for each library that `oh` needs symbol
versions from (its `.gnu.version_r` section), e.g. `("libc.so.6", ["GLIBC_2.2.5"])`.
"""
function verneed_libraries(oh::ELFHandle)
    verneeds = ELFVersionNeededData(oh)
    isempty(verneeds) && return Tuple{String,Vector{String}}[]
    strtab = StrTab(findfirst(Sections(oh), ".dynstr"))
    return [(strtab_lookup(strtab, vn.ver_need.vn_file), vn.names) for vn in verneeds]
end

# Parse the version out of a symbol version such as `GLIBC_2.17`, given its `prefix`
function symbol_version(name::AbstractString, prefix::AbstractString)
    startswith(name, prefix) || return nothing
    return tryparse(VersionNumber, name[length(prefix)+1:end])
end

function libgfortran_major(lib::AbstractString)
    m = match(r"^libgfortran(?:\.so\.|\.|-)(\d+)(?:\.dylib|\.dll)?$"i, basename(lib))
    return m === nothing ? nothing : parse(Int, m[1])
end

"""
    record_runtime_requirements!(result::AuditResult)

Record in `result.runtime_requirements` what the binary objects of the prefix need
from the runtime they get loaded into (see `RuntimeRequirements`): the libstdc++
release, glibc and FreeBSD libc symbol versions, linked `libgfortran` major versions
and the minimum macOS version.  Requirements on `libstdc++.so.6` are recorded even
if the prefix ships its own copy, since Julia's copy is loaded first.
"""
function record_runtime_requirements!(result::AuditResult)
    scan, reqs = result.scan, result.runtime_requirements
    gfortran = Dict{Int,RuntimeRequirement{Int}}()
    for rel_path in sort(collect(keys(scan.binary_objects)))
        oh = scan.binary_objects[rel_path]

        if isa(oh, MachOHandle)
            minos = min_os_version(oh)
            if minos !== nothing && build_platform(oh) == ObjectFile.MachO.PLATFORM_MACOS
                cmd = typeof(ObjectFile.MachO.version_cmd(oh)) <: MachOBuildVersionCmd ? "LC_BUILD_VERSION" : "LC_VERSION_MIN_MACOSX"
                reqs.macos = raise(reqs.macos, minos, rel_path, cmd)
            end
        end

        # Object files and static executables load no libraries
        isdynamic(oh) || continue
        for dl in DynamicLinks(oh)
            major = libgfortran_major(path(dl))
            if major !== nothing && !haskey(gfortran, major)
                gfortran[major] = RuntimeRequirement{Int}(major, rel_path, path(dl))
            end
        end

        isa(oh, ELFHandle) || continue
        for (lib, names) in verneed_libraries(oh), name in names
            if lib == "libstdc++.so.6"
                for (prefix, field) in (("GLIBCXX_", :glibcxx), ("CXXABI_", :cxxabi))
                    v = symbol_version(name, prefix)
                    if v !== nothing
                        setfield!(reqs, field, raise(getfield(reqs, field), v, rel_path, name))
                    end
                end
                libv = libstdcxx_version_for_symbol(name)
                if libv !== nothing
                    reqs.libstdcxx = raise(reqs.libstdcxx, libv, rel_path, name)
                elseif !any(r -> r.value == name, reqs.unknown_libstdcxx)
                    push!(reqs.unknown_libstdcxx, RuntimeRequirement{String}(name, rel_path, lib))
                end
            end

            v = symbol_version(name, "GLIBC_")
            if v !== nothing
                reqs.glibc = raise(reqs.glibc, v, rel_path, name)
            end
            v = symbol_version(name, "FBSD_")
            if v !== nothing
                reqs.freebsd = raise(reqs.freebsd, v, rel_path, name)
            end
        end
    end
    reqs.libgfortran = [gfortran[k] for k in sort(collect(keys(gfortran)))]
    return reqs
end

"""
    freebsd_release(fbsd_version::VersionNumber)

The first FreeBSD release whose libraries define the `FBSD_*` symbol version
`fbsd_version`, e.g. `v"14.0"` for `FBSD_1.7`.  `FBSD_1.0` arrived with FreeBSD 7.0,
and each later major release added the next `FBSD_1.N` namespace.
"""
function freebsd_release(fbsd_version::VersionNumber)
    if fbsd_version.major != 1
        throw(ArgumentError("Unknown FreeBSD symbol version FBSD_$(fbsd_version)"))
    end
    return VersionNumber(fbsd_version.minor + 7, 0)
end

"""
    check_runtime_requirements(result::AuditResult; os_version)

Check the recorded `result.runtime_requirements` against everything the target
platform alone decides, adding to `result.pass_results` under
`"runtime_requirements"`:

- glibc: no `GLIBC_*` symbol version newer than the oldest glibc that
  `CToolchain` supports for the architecture (`oldest_glibc_version()`).
- libgfortran: binaries that link `libgfortran` need a `libgfortran_version`
  platform tag naming the same major version.
- macOS: no Mach-O file may need a macOS newer than the deployment target that
  `os_version` (a Darwin kernel version) names.
- FreeBSD: no `FBSD_*` symbol version newer than the FreeBSD release `os_version`.

`os_version` is the OS version the platform gets packaged with; when it is
`nothing`, macOS targets use the toolchain's default deployment target, and FreeBSD
targets go unchecked.
"""
function check_runtime_requirements(result::AuditResult;
                                    os_version::Union{Nothing,VersionNumber} = Base.BinaryPlatforms.os_version(result.scan.platform))
    platform, reqs, pass_results = result.scan.platform, result.runtime_requirements, result.pass_results
    pass_name = "runtime_requirements"
    fail(id, msg) = push_result!(pass_results, pass_name, :fail, id, msg)
    pass(id, msg) = push_result!(pass_results, pass_name, :success, id, msg)

    if Sys.islinux(platform) && libc(platform) == "glibc" && reqs.glibc !== nothing
        floor = oldest_glibc_version(platform)
        r = reqs.glibc
        if r.value > floor
            fail(r.file, "needs $(r.source), but $(arch(platform)) Linux targets must run on glibc $(short_version(floor))")
        else
            pass(r.file, "needs $(r.source), within glibc $(short_version(floor))")
        end
    end

    if !isempty(reqs.libgfortran)
        tag = get(tags(platform), "libgfortran_version", nothing)
        tag_major = tag === nothing ? nothing : VersionNumber(tag).major
        for r in reqs.libgfortran
            if tag_major === nothing
                fail(r.file, "links $(r.source), but the platform has no libgfortran_version tag; build one platform per libgfortran version, each tagged with its `libgfortran_version`")
            elseif r.value != tag_major
                fail(r.file, "links $(r.source), but the platform's libgfortran_version is $(tag)")
            else
                pass(r.file, "links $(r.source), matching libgfortran_version $(tag)")
            end
        end
    end

    if Sys.isapple(platform) && reqs.macos !== nothing
        kernel = something(os_version, macos_target_kernel_version(platform))
        target = VersionNumber(macos_version(kernel))
        r = reqs.macos
        if r.value > target
            fail(r.file, "$(r.source) requires macOS $(short_version(r.value)), newer than the deployment target macOS $(short_version(target)) (darwin$(kernel.major))")
        else
            pass(r.file, "$(r.source) requires macOS $(short_version(r.value)), within the deployment target macOS $(short_version(target))")
        end
    end

    if Sys.isfreebsd(platform) && reqs.freebsd !== nothing
        r = reqs.freebsd
        needed = freebsd_release(r.value)
        if os_version === nothing
            pass(r.file, "needs $(r.source) (FreeBSD $(short_version(needed))); the platform has no os_version to check it against")
        elseif needed > VersionNumber(os_version.major, os_version.minor)
            fail(r.file, "needs $(r.source), which first shipped with FreeBSD $(short_version(needed)), newer than the target FreeBSD $(short_version(os_version))")
        else
            pass(r.file, "needs $(r.source) (FreeBSD $(short_version(needed))), within the target FreeBSD $(short_version(os_version))")
        end
    end
    return nothing
end
