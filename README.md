# BinaryBuilder2

`BinaryBuilder2` represents the next evolution of [`BinaryBuilder.jl`](https://github.com/JuliaPackaging/BinaryBuilder.jl).
It is a greenfield rewrite of the entire stack, from the isolation layer now using [`Sandbox.jl`](https://github.com/staticfloat/Sandbox.jl), git utilities, tree archival, binary object analysis and more being provided in separate modular packages.
The `BinaryBuilder2.jl` package itself is the top-level project that includes all these sub-packages, but each sub-package itself is useful and independently tested.

## Current status

BinaryBuilder2 is still under active development.
See `TODO.md` for the current worklist.

## Quickstart

1. Install `BinaryBuilder2` (requires Julia 1.12+):
```julia
using Pkg
Pkg.add(url="https://github.com/JuliaPackaging/BinaryBuilder2.jl")
```

2. Define a build recipe. The core API revolves around a `BuildMeta` object (analogous to the old `build_tarballs()` call) that describes the sources, toolchains, and extraction targets for your package:
```julia
using BinaryBuilder2

meta = BuildMeta(; verbose=true)
build_config = BuildConfig(
    meta,
    "Zlib",
    v"1.3.1",
    [
        ArchiveSource("https://zlib.net/zlib-1.3.1.tar.gz",
                      "sha256:9a93b2b7dfdac77ceba5a558a580e74667dd6fede4585b91eefb60f03b72df23"),
    ];
    script = raw"""
        cd ${WORKSPACE}/srcdir/zlib-1.3.1
        ./configure --prefix=${prefix} --libdir=${libdir} --includedir=${includedir}
        make install
    """,
    toolchains=[CToolchain()],
    platforms=supported_platforms(),
    products=[LibraryProduct("libz", :libz)],
)
build!(build_config)
extract!(build_config, ExtractConfig(meta, build_config, build_config.products))
package!(meta)
```

3. The output is a JLL package that can be added to any Julia project just like any other package. The JLL will export bindings for all declared products.

For more context, see the [`JuliaCon2024`](JuliaCon2024/) directory for slides and examples from the JuliaCon 2024 presentation.

## Sub-packages

BinaryBuilder2 is organized as a workspace of independently-usable packages:

| Package | Description |
|---------|-------------|
| [`BinaryBuilderSources.jl`](BinaryBuilderSources.jl/) | Downloading and verifying source archives, git repos, and directory trees |
| [`BinaryBuilderToolchains.jl`](BinaryBuilderToolchains.jl/) | C/C++/Fortran/Rust cross-compilation toolchains with relocatable wrapper scripts |
| [`BinaryBuilderProducts.jl`](BinaryBuilderProducts.jl/) | Declaring and auditing build outputs (libraries, executables, files) |
| [`BinaryBuilderAuditor.jl`](BinaryBuilderAuditor.jl/) | Binary object analysis — checking linkage, SONAME, and platform compatibility |
| [`BinaryBuilderPlatformExtensions.jl`](BinaryBuilderPlatformExtensions.jl/) | Extended platform objects including `CrossPlatform` and BB-specific tags |
| [`BinaryBuilderGitUtils.jl`](BinaryBuilderGitUtils.jl/) | Git utilities for content-addressed storage and registry manipulation |
| [`JLLGenerator.jl`](JLLGenerator.jl/) | Generating JLL wrapper packages from build artifacts |
| [`LazyJLLWrappers.jl`](LazyJLLWrappers.jl/) | Runtime glue for JLL packages (lazy artifact loading, preference overrides) |
| [`TreeArchival.jl`](TreeArchival.jl/) | Content-addressed tarball packing/unpacking |
| [`MultiHashParsing.jl`](MultiHashParsing.jl/) | Parsing and verifying multiple hash formats |

## Philosophy

Cross-compiling binary packages is hard.
BinaryBuilder2 follows the same philosophy as its predecessor: when you want something done right, you do it yourself.
All packages are cross-compiled inside a reproducible Linux sandbox, then packaged as tarballs and distributed as JLL packages that Julia's package manager can install without any compilation on the user's machine — no `cmake`, no `sudo`, no system package manager.

Where BinaryBuilder.jl was a single monolithic package, BinaryBuilder2 decomposes the problem into a workspace of focused sub-packages.
Each sub-package has its own tests and can be used independently; the top-level `BinaryBuilder2` package simply re-exports everything for convenience.
This makes the stack easier to audit, easier to extend, and easier to embed into other tools.
