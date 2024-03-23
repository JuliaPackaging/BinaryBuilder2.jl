# JLLGenerator

This package provides the tools necessary to generate JLLs, the thin wrapper packages the Julia ecosystem uses to provide access to external binaries.
The main datastructure in this package is the `JLLInfo` object, which takes in a single lump, the entire description of the binary objects to be wrapped.

This package is tightly coupled with `JLLWrappers.jl`; the TOML files that this package generates are read in by `JLLWrappers.jl` to auto-generate the necessary bindings.
This package is also tightly coupled with `BinaryBuilderProducts.jl`, as the nature of the binary objects to be wrapped are described by those products.
