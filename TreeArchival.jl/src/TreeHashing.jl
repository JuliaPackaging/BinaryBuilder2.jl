using SHA

export treehash

# This file exists for TWO purposes:
#  * First, when treehashing `.zip` files, we basically need to unpack and use this.  Sad.
#  * Second, we re-use this code to do things like merge the content_hash() results of
#    multiple JLLs.

# This code gratefully adapted from https://github.com/JuliaLang/Pkg.jl,
# which in turn adapted it from https://github.com/simonbyrne/GitX.jl
@enum GitMode begin
    mode_dir=0o040000
    mode_normal=0o100644
    mode_executable=0o100755
    mode_symlink=0o120000
    mode_submodule=0o160000
end

Base.string(mode::GitMode) = string(UInt32(mode); base=8)
Base.print(io::IO, mode::GitMode) = print(io, string(mode))

function gitmode(path::AbstractString)
    # Windows doesn't deal with executable permissions in quite the same way,
    # `stat()` gives a different answer than we actually want, so we use
    # `isexecutable()` which uses `uv_fs_access()` internally.  On other
    # platforms however, we just want to check via `stat()`.
    function isexec(p)
        @static if Sys.iswindows()
            return Sys.isexecutable(p)
        end
        return !iszero(filemode(p) & 0o100)
    end
    if islink(path)
        return mode_symlink
    elseif isdir(path)
        return mode_dir
    elseif isexec(path)
        return mode_executable
    else
        return mode_normal
    end
end

"""
    blob_hash(HashType::Type, path::AbstractString)

Calculate the git blob hash of a given path.
"""
function blob_hash(::Type{HashType}, path::AbstractString) where HashType
    ctx = HashType()
    if islink(path)
        datalen = length(readlink(path))
    else
        datalen = filesize(path)
    end

    # First, the header
    SHA.update!(ctx, Vector{UInt8}("blob $(datalen)\0"))

    # Next, read data in in chunks of 4KB
    buff = Vector{UInt8}(undef, 4*1024)

    try
        if islink(path)
            update!(ctx, Vector{UInt8}(readlink(path)))
        else
            open(path, "r") do io
                while !eof(io)
                    num_read = readbytes!(io, buff)
                    update!(ctx, buff, num_read)
                end
            end
        end
    catch e
        if isa(e, InterruptException)
            rethrow(e)
        end
        @warn("Unable to open $(path) for hashing; git-tree-sha1 likely suspect")
    end

    # Finish it off and return the digest!
    return SHA.digest!(ctx)
end
blob_hash(path::AbstractString) = blob_hash(SHA1_CTX, path)

"""
    contains_files(root::AbstractString; mimic_git::Bool = false)

Helper function to determine whether a directory contains files; e.g. it is a
direct parent of a file or it contains some other directory that itself is a
direct parent of a file. This is used to exclude directories from tree hashing.
"""
function contains_files(path::AbstractString; mimic_git::Bool = false)
    st = lstat(path)
    if !ispath(st)
        throw(ArgumentError("non-existent path: $(repr(path))"))
    end
    if !isdir(st)
        return true
    end
    for p in readdir(path)
        if mimic_git && basename(p) == ".git"
            continue
        end
        contains_files(joinpath(path, p)) && return true
    end
    return false
end

function tree_node_hash(::Type{HashType}, entries) where HashType
    content_size = 0
    for (n, h, m) in entries
        content_size += ndigits(UInt32(m); base=8) + 1 + sizeof(n) + 1 + sizeof(h)
    end

    # Return the hash of these entries
    ctx = HashType()
    SHA.update!(ctx, Vector{UInt8}("tree $(content_size)\0"))
    for (name, hash, mode) in entries
        SHA.update!(ctx, Vector{UInt8}("$(mode) $(name)\0"))
        SHA.update!(ctx, hash)
    end
    return SHA.digest!(ctx)
end


"""
    treehash(HashType::Type, root::AbstractString)

Calculate the git tree hash of a given path.
"""
function treehash(::Type{HashType},
                  root::AbstractString;
                  debug_out::Union{IO,Nothing} = nothing,
                  indent::Int=1,
                  mimic_git::Bool = false) where HashType
    entries = Tuple{String, Vector{UInt8}, GitMode}[]

    indent_prefix = "│ "^(max(indent - 1, 0))
    indent_end = "├→"
    indent_str = string(indent_prefix, indent_end)
    container_stream = debug_out === nothing ? nothing : IOBuffer()
    for f in sort(readdir(root; join=true); by = f -> gitmode(f) == mode_dir ? f*"/" : f)
        # Skip `.git` directories if we're mimicking `git`'s behavior
        if mimic_git && basename(f) == ".git"
            continue
        end

        filepath = abspath(f)
        mode = gitmode(filepath)
        if mode == mode_dir
            # If this directory contains no files, then skip it
            contains_files(filepath; mimic_git) || continue

            # Otherwise, hash it up!
            hash = treehash(HashType, filepath; debug_out=container_stream, indent=indent+1, mimic_git)
        else
            hash = blob_hash(HashType, filepath)
            if debug_out !== nothing
                mode_str = mode == mode_normal ? "F" : "X"
                println(container_stream, "$(indent_str)[$(mode_str)] $(basename(filepath)) - $(bytes2hex(hash))")
            end
        end
        push!(entries, (basename(filepath), hash, mode))
    end

    hash = tree_node_hash(HashType, entries)
    if debug_out !== nothing
        println(debug_out, "$(indent_prefix)[D] $(basename(root)) - $(bytes2hex(hash))")
        print(debug_out, String(take!(container_stream)))
    end
    return hash
end
