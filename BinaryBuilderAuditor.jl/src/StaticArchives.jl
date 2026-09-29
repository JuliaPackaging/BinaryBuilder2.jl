using ObjectFile

# Reading static archives: the `ar` container, and the symbols its object members
# define and leave undefined.  This is analysis only; what the auditor makes of it
# lives in `passes/StaticLibraries.jl`.

"""
    ArchiveMember

A single member of an `ar` archive, holding its (already long-name-resolved) name
and its raw bytes.
"""
struct ArchiveMember
    name::String
    data::Vector{UInt8}
end

const AR_MAGIC = "!<arch>\n"
const AR_THIN_MAGIC = "!<thin>\n"

"""
    is_static_archive(path::String)

Returns `true` if the file at `path` begins with the `ar` archive magic.
"""
function is_static_archive(path::String)
    magic = open(path, "r") do io
        n = length(AR_MAGIC)
        filesize(path) < n ? UInt8[] : read(io, n)
    end
    return length(magic) == length(AR_MAGIC) && String(magic) ∈ (AR_MAGIC, AR_THIN_MAGIC)
end

"""
    is_symbol_index_name(name::AbstractString)

Returns `true` for the names under which the various `ar` flavors store their symbol
index; we recompute symbol information from the members themselves, so we skip it.
"""
function is_symbol_index_name(name::AbstractString)
    name = strip(String(name))
    return name ∈ ("/", "/SYM64/") || startswith(name, "__.SYMDEF")
end

"""
    read_archive_members(path::String)

Parse an `ar` archive into its member objects, resolving both the GNU (`//` long
name table, `/N` references) and BSD (`#1/N` inline names) naming schemes, and
dropping the symbol table and long name table pseudo-members.

Returns `nothing` if `path` is not an `ar` archive, and throws an `ArgumentError`
if it is a *thin* archive (whose members live outside the file, and so cannot be
audited from the archive alone).
"""
function read_archive_members(path::String)
    data = read(path)
    if length(data) < length(AR_MAGIC)
        return nothing
    end
    magic = String(data[1:length(AR_MAGIC)])
    if magic == AR_THIN_MAGIC
        throw(ArgumentError("Refusing to audit thin archive '$(path)'; its members are not self-contained"))
    end
    if magic != AR_MAGIC
        return nothing
    end

    members = ArchiveMember[]
    long_names = UInt8[]
    pos = length(AR_MAGIC) + 1
    while pos + 60 <= length(data) + 1
        header = data[pos:pos+59]
        # The file size lives at offset 48 (1-indexed 49) and is 10 ASCII bytes
        size_str = strip(String(header[49:58]))
        member_size = tryparse(Int, size_str)
        if member_size === nothing || member_size < 0 || pos + 60 + member_size > length(data) + 1
            throw(ArgumentError("Corrupt `ar` header in '$(path)' at offset $(pos-1)"))
        end
        name = strip(String(header[1:16]))
        body_start = pos + 60
        body = data[body_start:body_start+member_size-1]

        # Members are aligned to even offsets
        pos = body_start + member_size + (isodd(member_size) ? 1 : 0)

        if name == "//"
            # GNU long name table; referenced by the `/N` members below
            long_names = body
            continue
        elseif is_symbol_index_name(name)
            # Symbol index; we recompute symbol information ourselves
            continue
        elseif startswith(name, "/") && length(name) > 1
            offset = tryparse(Int, name[2:end])
            if offset === nothing || offset >= length(long_names)
                throw(ArgumentError("Corrupt long name reference '$(name)' in '$(path)'"))
            end
            terminator = findfirst(c -> c == UInt8('/') || c == UInt8('\n'), long_names[offset+1:end])
            name = terminator === nothing ?
                   String(long_names[offset+1:end]) :
                   String(long_names[offset+1:offset+terminator-1])
        elseif startswith(name, "#1/")
            # BSD-style archive with the name stored in the first `n` bytes of the body
            n = tryparse(Int, name[4:end])
            if n === nothing || n > length(body)
                throw(ArgumentError("Corrupt BSD name length '$(name)' in '$(path)'"))
            end
            name = replace(String(body[1:n]), "\0" => "")
            # BSD archives store the symbol index under a long name, so it only
            # becomes recognizable once the name has been resolved.
            if is_symbol_index_name(name)
                continue
            end
            body = body[n+1:end]
        else
            name = rstrip(name, '/')
        end
        push!(members, ArchiveMember(String(name), body))
    end
    return members
end

"""
    member_object_handle(member::ArchiveMember)

Read an archive member as an object file, returning `nothing` if it isn't one
(archives can legitimately contain non-object members).
"""
function member_object_handle(member::ArchiveMember)
    try
        return first(readmeta(IOBuffer(member.data)))
    catch e
        if isa(e, ObjectFile.MagicMismatch) || isa(e, EOFError)
            return nothing
        end
        rethrow(e)
    end
end

"""
    symbol_base_name(name::AbstractString)

Strip the ELF symbol version from a symbol name, turning both `malloc@GLIBC_2.2.5`
(a reference to a specific version) and `malloc@@GLIBC_2.2.5` (the definition of the
default version) into `malloc`.
"""
function symbol_base_name(name::AbstractString)
    at = findfirst('@', name)
    return at === nothing ? String(name) : String(name[1:prevind(name, at)])
end

"""
    object_symbols(oh::ObjectHandle; only_external::Bool = true)

Return `(defined, undefined, weak_undefined)` sets of symbol names for a single
object.  Objects without a symbol table at all yield three empty sets.

By default only externally-visible definitions (global and weak) are reported as
`defined`, since a file-local definition cannot satisfy a reference from another
object.  Pass `only_external=false` to also report local definitions, which is
useful when treating an already-linked shared library as an oracle.
"""
function object_symbols(oh::ObjectHandle; only_external::Bool = true)
    defined = Set{String}()
    undefined = Set{String}()
    weak_undefined = Set{String}()
    syms = try
        Symbols(oh)
    catch
        # Some objects (e.g. empty `.o` stubs) have no symbol table whatsoever
        return (defined, undefined, weak_undefined)
    end
    for sym in syms
        name = try
            symbol_name(sym)
        catch
            continue
        end
        name = replace(name, "\0" => "")
        if isempty(name)
            continue
        end
        # Symbols in a linked ELF object carry their version (`malloc@GLIBC_2.2.5`),
        # while the relocatable objects inside an archive reference the bare name,
        # so record both spellings and let the caller match on either.
        names = unique([name, symbol_base_name(name)])
        if isundef(sym)
            union!(undefined, names)
            if isweak(sym)
                union!(weak_undefined, names)
            end
        elseif !only_external || isglobal(sym) || isweak(sym)
            union!(defined, names)
        end
    end
    return (defined, undefined, weak_undefined)
end

"""
    ArchiveContents

The result of scanning a static archive: the symbols it defines, and the symbols
it needs from elsewhere (with the weak ones among them, which may legitimately
stay unresolved).
"""
struct ArchiveContents
    defined::Set{String}
    undefined::Set{String}
    weak_undefined::Set{String}
    num_members::Int
    num_objects::Int
end

"""
    scan_static_archive(path::String)

Parse the archive at `path`, gathering symbol information from each of its object
members.  Returns `nothing` if `path` is not an archive.
"""
function scan_static_archive(path::String)
    members = read_archive_members(path)
    if members === nothing
        return nothing
    end

    defined = Set{String}()
    undefined = Set{String}()
    weak_undefined = Set{String}()
    num_objects = 0
    for member in members
        oh = member_object_handle(member)
        if oh === nothing
            continue
        end
        num_objects += 1
        member_defined, member_undefined, member_weak_undefined = object_symbols(oh)
        union!(defined, member_defined)
        union!(undefined, member_undefined)
        union!(weak_undefined, member_weak_undefined)
    end

    # Symbols defined elsewhere in the same archive are not external references
    setdiff!(undefined, defined)
    setdiff!(weak_undefined, defined)
    return ArchiveContents(defined, undefined, weak_undefined, length(members), num_objects)
end

"""
    linker_synthesized_symbols

Symbols that never need a definition from any library: the linker either
synthesizes them or they are section boundary markers it fills in itself.
"""
const linker_synthesized_symbols = Set{String}([
    "_GLOBAL_OFFSET_TABLE_",
    "_DYNAMIC",
    "_PROCEDURE_LINKAGE_TABLE_",
    "__dso_handle",
    "__ehdr_start",
    "__executable_start",
    "__init_array_start",
    "__init_array_end",
    "__fini_array_start",
    "__fini_array_end",
    "__preinit_array_start",
    "__preinit_array_end",
    "__start___libc_atexit",
    "__stop___libc_atexit",
    "__TMC_END__",
    "__bss_start",
    "_edata",
    "_end",
    "etext",
    "edata",
    "end",
])
