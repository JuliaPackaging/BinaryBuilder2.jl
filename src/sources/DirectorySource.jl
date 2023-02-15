"""
    DirectorySource(path; target = "", follow_symlinks=false)

Specify a local directory to mount from `path`.

The contents of the directory will be placed in `\${WORKSPACE}/srcdir`, unless
the optional keyword argument `target` gives a different subdirectory to place
the contents within. Symbolic links are replaced by a copy of their target when
`follow_symlinks` is `true`, allowing for source directories that contain
symlinks to external files, such as when sharing patchsets among a common build
recipe in Yggdrasil.
"""
struct DirectorySource
    source::String
    target::String
    follow_symlinks::Bool
end


function DirectorySource(source; target = "",
                                 follow_symlinks=false)
    noabspath!(target)

    # Only allow real directory, and immediately `abspath()` them
    if !isdir(source)
        throw(ArgumentError("Directory does not exist: '$(source)'"))
    end
    source = abspath(source)
    return DirectorySource(
        string(source),
        string(target),
        Bool(follow_symlinks),
    )
end

# Nothing to prepare!
prepare(ds::DirectorySource) = nothing

function deploy(ds::DirectorySource, prefix::String)
    # We want to be able to merge the contents of `ds.source` into `prefix`,
    # so we can't use a top-level `cp()`, sadly.
    target_dir = joinpath(prefix, ds.target)
    mkpath(target_dir)

    for f in readdir(ds.source)
        # Copy the content of the source directory to the destination
        cp(joinpath(ds.source, f),
           joinpath(target_dir, basename(f));
           follow_symlinks=ds.follow_symlinks,
        )
    end
end

function content_hash(ds::DirectorySource)
    # Because our content hash depends on whether we follow symlinks or not,
    # we deploy the directory source if we do, so that we get files:
    local hash
    if ds.follow_symlinks
        mktempdir() do dir
            deploy(ds, dir)
            hash = SHA1Hash(Pkg.GitTools.tree_hash(dir))
        end
    else
        # Otherwise, we can just directly treehash the source directory.
        hash = SHA1Hash(Pkg.GitTools.tree_hash(ds.source))
    end
    return hash
end
