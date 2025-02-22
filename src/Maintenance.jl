module Maintenance

# This file will collect entrypoints for maintenance of a build system.
using Ccache_jll
import ..BinaryBuilder2: ccache_cache

function ccache_env(cmd::Cmd)
    return addenv(cmd, "CCACHE_DIR" => ccache_cache())
end

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
function ccache_recompress_cache(;compression_level::Int=9)
    run(ccache_env(`$(ccache()) --cleanup --recompress $(compression_level)`))
end

function ccache_clear_cache()
    run(ccache_env(`$(ccache()) --clear`))
end

function ccache_show_stats()
    run(ccache_env(`$(ccache()) --show-stats --show-compression --verbose`))
end

# TODO:
#  - artifact LRU trimming?
#  - Old universe deletion?
#  - DepotCompactor.jl integration?

end # module Maintenance
