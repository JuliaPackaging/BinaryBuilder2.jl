# BinaryBuilderProducts.jl

This package provides `Product` objects to represent various types of binary output from the BinaryBuilder build process.
Examples are `ExecutableProduct`, `FileProduct`, `LibraryProduct`, and more.
This package interoperates with `JLLGenerator` to provide easy export of these datastructures to the TOML file that `JLLGenerator` creates.
In general, users will not need to use this package directly, as `BinaryBuilder2` will automatically handle all product-related code.
