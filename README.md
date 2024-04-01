# BB2

`BB2` represents the next evolution of [`BinaryBuilder.jl`](https://github.com/JuliaPackaging/BinaryBuilder.jl).
It is a greenfield rewrite of the entire stack, from the isolation layer now using [`Sandbox.jl`](https://github.com/staticfloat/Sandbox.jl), git utilities, tree archival, binary object analysis and more being provided in separate modular packages.
The `BB2.jl` package itself is the top-level project that includes all these sub-packages, but each sub-package itself is useful and independently tested.

## Current status

Status as of April 2024 is that BB2 is still under heavy development and lacks full feature platform support.
Current development target is for full feature parity with original `BinaryBuilder.jl` by JuliaCon 2024.
See `TODO.md` for the current worklist to be completed.
