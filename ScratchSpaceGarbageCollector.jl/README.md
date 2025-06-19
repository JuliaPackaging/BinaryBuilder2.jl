# ScratchSpaceGarbageCollection.jl

This package provides an API for managing large numbers of scratch spaces and cleaning them up more aggressively than `Pkg.gc()` would.
While designed for `BinaryBuilder.jl`, it can be used by any package that has a need for creating scratch spaces with particular retention policies, and is willing to proactively garbage collect every now and then.

## Quickstart

To start with, you must define a scratchspace arena and a policy to control garbage collection:

```
using ScratchSpaceGarbageCollection, Dates

arena = Arena(@pkg_uuid(), "build_dirs", MaxAgePolicy(Day(5)))
```

Next, you allocated scratch spaces within that arena:
```
build_space = get_scratch!(arena, "builds")
```

Do your work inside those scratch spaces, then later you can garbage collect them according to the policies defined in the arena:
```
garbage_collect!(arena)
```

The garbage collector reads information from the `scratch_usage.toml` logfile in the depot the arena is located within, so it can be run in a separate julia session from the session that created the scratch spaces.

### Policies

We have two policies so far:

* `MaxAgePolicy` - This GCs any scratch spaces that haven't been accessed since the time duration stored within it.
* `MaxSizeLRUDropPolicy` - This calculates the total storage of the arena and if it is over the limit stored within it, it starts deleting scratch spaces that were least recently accessed.

You can give an arena a vector of policies, in which case it will garbage collect _all_ scratch spaces identified by _any_ of its policies.

