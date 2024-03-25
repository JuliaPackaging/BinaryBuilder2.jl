const JULIA_LIBDIRS = String[]
"""
    get_julia_libpaths()

Return the library paths that e.g. libjulia and such are stored in.
"""
function get_julia_libpaths()
    if isempty(JULIA_LIBDIRS)
        append!(JULIA_LIBDIRS, [joinpath(Sys.BINDIR::String, Base.LIBDIR, "julia"), joinpath(Sys.BINDIR::String, Base.LIBDIR)])
        # Windows needs to see the BINDIR as well
        @static if Sys.iswindows()
            push!(JULIA_LIBDIRS, Sys.BINDIR)
        end
    end
    return JULIA_LIBDIRS
end
