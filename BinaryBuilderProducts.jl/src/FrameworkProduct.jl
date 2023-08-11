using Base.BinaryPlatforms

@warn("TODO: Implement FrameworkProduct")

#=
struct FrameworkProduct <: AbstractProduct
    lp::LibraryProduct
end

function FrameworkProduct(args...; kwargs...)
    return new(LibraryProduct(args...; kwargs...))
end

function default_product_dir(::FrameworkProduct, platform::AbstractPlatform)
    return "lib"
end

function locate(fp::FrameworkProduct, prefix::String; platform::AbstractPlatform = HostPlatform(), verbose::Bool = false, kwargs...)
    dir_paths = joinpath.(prefix.path, template.(fp.libraryproduct.dir_paths, Ref(platform)))
    append!(dir_paths, libdirs(prefix, platform))
    for dir_path in dir_paths
        if !isdir(dir_path)
            continue
        end
        for libname in fp.libraryproduct.libnames
            framework_dir = joinpath(dir_path,libname*".framework")
            if isdir(framework_dir)
                currentversion = joinpath(framework_dir, "Versions", "Current")
                if islink(currentversion)
                    currentversion = joinpath(framework_dir, "Versions", readlink(currentversion))
                end
                if isdir(currentversion)
                    dl_path = abspath(joinpath(currentversion, libname))
                    if isfile(dl_path)
                        if verbose
                            @info("$(dl_path) matches our search criteria of framework $(libname)")
                        end
                        return dl_path
                    end
                end
            end
        end
    end

    if verbose
        @info("No match found for $fp")
    end
    return nothing
end
=#
