# Locking microarchitectures

When building redistributable software, you need to ensure that you only use processor instructions that match the processor that it will be run on.
Since in general, you do not know precisely what processor your software will be run on, you typically have to build for the lowest common denominator.
We support building multiple binaries for different microarchitectures, but most software does not benefit that much from advanced instruction sets, and so by default we target a very conservative instruction set.
This test case ensures that the `-march` flag is disallowed and is properly added in by our compiler wrappers.
