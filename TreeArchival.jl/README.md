# TreeArchival.jl

This package provides common functionality for archiving a directory tree as a compressed tarball, and for obtaining the treehash of that tarball.
Internally, the package uses `Tar.jl` and `p7zip_jll` to perform compression/decompression and packing/treehashing.
Most usage is performed via the `archive()`, `unarchive()` and `treehash()` methods.
Note that in most cases, the correct compression type can be guessed from the header of the file being unarchived or treehashed.
This package also allows calculating the treehash of a directory.
