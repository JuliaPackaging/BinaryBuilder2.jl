# BinaryBuilderSources.jl

This package defines a set of `Source` types that represent the various sources that a `BB2` recipe can download and use in the build, such as `GitSource`, `ArchiveSource`, `JLLSource`, `GeneratedSource` and more.
Source objects all support a common API include `prepare()`, `deploy()`, `content_hash()` and more.
See the docstrings in the package for more detail on how to use these in your own package, but as a simple example:

```julia
using BinaryBuilderSources

as = ArchiveSource(url, hash)
prepare(as)
mktempdir() do prefix
    deploy(as, prefix)

    # Now do something with `prefix`, as the archive has been unpacked there
end
```

