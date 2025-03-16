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

"""
    filter_non_lazy_libraries(libs::Vector)

If we have a LazyJLLWrapper-using JLL that uses a non-lazy JLL, this
method filters out attempting to add those non-`LazyLibrary` library
objects to our `LazyLibrary`'s deps field.  Not only will this cause
a type error, it's also unnecessary, because those `JLLWrapper`-using
JLLs always eagerly load all of their libraries.
"""
function filter_non_lazy_libraries(libs::Vector)
    lazy_libraries = LazyLibrary[]
    for lib in libs
        if isa(lib, LazyLibrary)
            push!(lazy_libraries, lib)
        end
    end
    return lazy_libraries
end