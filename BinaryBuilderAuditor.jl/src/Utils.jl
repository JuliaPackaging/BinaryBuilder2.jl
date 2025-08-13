using ObjectFile, ObjectFile.ELF, Base.BinaryPlatforms

"""
    is_for_platform(h::ObjectHandle, platform::AbstractPlatform)

Returns `true` if the given `ObjectHandle` refers to an object of the given
`platform`; E.g. if the given `platform` is for AArch64 Linux, then `h` must
be an `ELFHandle` with `h.header.e_machine` set to `ELF.EM_AARCH64`.

In particular, this method and [`platform_for_object()`](@ref) both exist
because the latter is not smart enough to deal with `:glibc` and `:musl` yet.
"""
function is_for_platform(h::ObjectHandle, platform::AbstractPlatform)
    if Sys.islinux(platform) || Sys.isfreebsd(platform)
        # First off, if h isn't an ELF object, quit out
        if !(h isa ELFHandle)
            return false
        end
        # If the ELF object has an OSABI, check it matches platform
        if h.ei.osabi != ELF.ELF.ELFOSABI_NONE
            if Sys.islinux(platform)
                if h.ei.osabi != ELF.ELFOSABI_LINUX
                    return false
                end
            elseif Sys.isfreebsd(platform)
                if h.ei.osabi != ELF.ELFOSABI_FREEBSD
                    return false
                end
            else
                throw(ArgumentError("Unknown OS ABI type $(typeof(platform))"))
            end
        end
        # Check that the ELF arch matches our own
        m = h.header.e_machine
        if arch(platform) == "i686"
            return m == ELF.EM_386
        elseif arch(platform) == "x86_64"
            # Allow i686 on x86_64, because that's technically ok
            return m == ELF.EM_386 || m == ELF.EM_X86_64
        elseif arch(platform) == "aarch64"
            return m == ELF.EM_AARCH64
        elseif arch(platform) == "powerpc64le"
            return m == ELF.EM_PPC64
        elseif arch(platform) ∈ ("armv7l", "armv6l")
            return m == ELF.EM_ARM
        else
            throw(ArgumentError("Unknown $(os(platform)) architecture $(arch(platform))"))
        end
    elseif Sys.iswindows(platform)
        if !(h isa COFFHandle)
            return false
        end

        if arch(platform) == "x86_64"
            return true
        elseif arch(platform) == "i686"
            return !is64bit(h)
        else
            throw(ArgumentError("Unknown $(os(platform)) architecture $(arch(platform))"))
        end
    elseif Sys.isapple(platform)
        # We'll take any old Mach-O handle
        if !(h isa MachOHandle)
            return false
        end
        return true
    else
        throw(ArgumentError("Unkown platform $(os(platform))"))
    end
end

# Stolen from: https://github.com/JuliaLang/Pkg.jl/blob/20ceec9b8e9174f672debc1591cedc0e09f403ae/src/utils.jl#L66
function safe_realpath(path)
    if isempty(path)
        return path
    end
    if ispath(path)
        try
            return realpath(path)
        catch
            return path
        end
    end
    a, b = splitdir(path)
    return joinpath(safe_realpath(a), b)
end

"""
    capture_output(cmd::Cmd)

Run `cmd`, capturing the output into an `IOBuffer`, return the process object and
the output, converted to a `String`.
"""
function capture_output(cmd::Cmd)
    output = IOBuffer()
    proc = run(pipeline(ignorestatus(cmd); stdout=output, stderr=output))
    return proc, String(take!(output))
end

function with_writable(f::Function, path::String)
    orig_mode = nothing
    try
        if !Sys.iswritable(path)
            orig_mode = stat(path).mode
            # Make it writable by us, the owner
            chmod(path, orig_mode | 0o200)
        end
        return f()
    finally
        if orig_mode !== nothing
            chmod(path, orig_mode)
        end
    end
end
