# This file will collect entrypoints for maintenance of a build system.
using Ccache_jll

"""
    recompress_ccache_cache(;compression_level::Int=19)

We maintain a `ccache` cache, which compresses its contents using `zstd` at a default
level of `1`, which provides a decent balance between compression time and ratio,
however for build machines that have some downtime, recompressing the cache with a
higher compression level can improve the compression ratio on-disk.

Note; this can take a little while, depending on the provided `compression_level`
and the size of the `ccache`.  As a datapoint, recompressing a cache of 4.0GB,
with 32 cores and at level 19, took ~3 minutes and squashed the cache down to a
total of 3.4 GB compressed (12.3 GB uncompressed).
"""
function recompress_ccache_cache(;compression_level::Int=9)
    run(addenv(`$(ccache()) --recompress $(compression_level)`, "CCACHE_DIR" => ccache_cache()))
end

function clear_ccache_cache()
    run(addenv(`$(ccache()) -C`, "CCACHE_DIR" => ccache_cache()))
end

# TODO:
#  - artifact LRU trimming?
#  - Old universe deletion?
#  - DepotCompactor.jl integration?
