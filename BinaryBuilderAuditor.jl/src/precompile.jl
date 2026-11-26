using PrecompileTools: @setup_workload, @compile_workload
import Libdl

"""
    precompile_audit_prefix(prefix::String)

Populate `prefix` with a small build result for the host: a copy of Julia's `libz` with
its versioned symlinks, a header, a pkg-config file and a license.  Returns `nothing` if
there is no `libz` to copy.
"""
function precompile_audit_prefix(prefix::String)
    libz = try
        Libdl.dlpath("libz")
    catch
        return nothing
    end
    libdir = joinpath(prefix, Sys.iswindows() ? "bin" : "lib")
    mkpath(libdir)
    real_name = basename(realpath(libz))
    cp(realpath(libz), joinpath(libdir, real_name))
    chmod(joinpath(libdir, real_name), 0o755)
    if Sys.islinux() || Sys.isbsd()
        # `libz.so.1.3.1` -> `libz.so.1`, `libz.so`
        parts = split(real_name, ".so")
        if length(parts) == 2 && !isempty(parts[2])
            soversion = first(split(lstrip(parts[2], '.'), '.'))
            symlink(real_name, joinpath(libdir, "libz.so.$(soversion)"))
            symlink("libz.so.$(soversion)", joinpath(libdir, "libz.so"))
        elseif real_name != "libz.so"
            symlink(real_name, joinpath(libdir, "libz.so"))
        end
    end
    mkpath(joinpath(prefix, "include"))
    write(joinpath(prefix, "include", "zlib.h"), "/* precompile */\n")
    mkpath(joinpath(prefix, "lib", "pkgconfig"))
    write(joinpath(prefix, "lib", "pkgconfig", "zlib.pc"), """
        prefix=$(prefix)
        libdir=\${prefix}/lib
        Name: zlib
        Version: 1.3.1
        Libs: -L\${libdir} -lz
        """)
    mkpath(joinpath(prefix, "share", "licenses", "Zlib"))
    write(joinpath(prefix, "share", "licenses", "Zlib", "LICENSE"), "precompile\n")
    return prefix
end

"""
    precompile_audit(prefix::String)

Audit `prefix`, populated by `precompile_audit_prefix()`, the way BinaryBuilder2 does after
an extraction.
"""
function precompile_audit(prefix::String)
    platform = Platform(arch(HostPlatform()), os(HostPlatform()); libc=libc(HostPlatform()))
    env = Dict{String,String}("prefix" => prefix, "bb_full_target" => triplet(platform))
    deps = Dict{Symbol,AuditDependencyInfo}()
    # Recipes pass both concretely-typed and mixed product vectors
    for products in (LibraryProduct[LibraryProduct("libz", :libz)],
                     AbstractProduct[LibraryProduct("libz", :libz)])
        result = audit!(
            prefix,
            products,
            AuditInfo(deps);
            prefix_alias = prefix,
            env,
            platform,
            os_version = Base.BinaryPlatforms.os_version(platform),
            config = AuditConfig(),
        )
        success(result)
        sprint(show, result)
    end
    return nothing
end

@setup_workload begin
    prefix = mktempdir()
    try
        if precompile_audit_prefix(prefix) !== nothing
            @compile_workload begin
                try
                    precompile_audit(prefix)
                catch e
                    @debug("BinaryBuilderAuditor precompile workload failed", exception=(e, catch_backtrace()))
                end
            end
        end
    finally
        rm(prefix; recursive=true, force=true)
    end
end
