# BinaryBuilderPlatformExtensions.jl

This package contains extensions on `Base.BinaryPlatforms`, new `AbstractPlatform` types and helper functions for adding tags to `Platform` objects.

## AnyPlatform

The simplest new `AbstractPlatform` type is `AnyPlatform`, which is used for platform-agnostic artifacts in `BinaryBuilder2`.
The platform matches any host, and serializes to the triplet `"any"`.

## CrossPlatform

Because `BinaryBuilder2` deals with cross-platform objects (such as compilers that run on `x86_64-linux-gnu` but target `aarch64-apple-darwin`), we express this as a `CrossPlatform()` that contains both a host triplet and a target triplet (encoded as tags within the triplet).
In practice, this looks something like `x86_64-linux-gnu-target_arch+aarch64-target_os+macos`.
`CrossPlatform` objects can be matched against other `Platform` objects, in which case the target of the `CrossPlatform` is used for the comparison.
