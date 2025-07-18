using BinaryBuilderSources: _source_download_cache, _generated_source_cache

function with_temp_storage_locations(f::Function)
    old_source_download_cache = _source_download_cache[]
    old_generated_source_cache = _generated_source_cache[]
    mktempdir() do dir
        try
            _source_download_cache[] = name -> joinpath(dir, "source_download", name)
            _generated_source_cache[] = name -> joinpath(dir, "generated_sources", name)
            f()
        finally
            _source_download_cache[] = old_source_download_cache
            _generated_source_cache[] = old_generated_source_cache
        end
    end
end

# Set a file to have a particular timestamp
# X-ref: https://discourse.julialang.org/t/how-to-adjust-file-modification-times/52337/3
function setmtime(path::AbstractString, mtime::Real, atime::Real=mtime)
    req = Libc.malloc(Base._sizeof_uv_fs)
    try
        ret = ccall(:uv_fs_utime, Cint,
            (Ptr{Cvoid}, Ptr{Cvoid}, Cstring, Cdouble, Cdouble, Ptr{Cvoid}),
            C_NULL, req, path, atime, mtime, C_NULL)
        ccall(:uv_fs_req_cleanup, Cvoid, (Ptr{Cvoid},), req)
        ret < 0 && Base.uv_error("utime($(repr(path)))", ret)
    finally
        Libc.free(req)
    end
end
