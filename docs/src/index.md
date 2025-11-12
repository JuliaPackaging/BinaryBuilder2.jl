# BinaryBuilder2.jl


BinaryBuilder is the primary method by which non-Julia packages are built and distributed in the Julia ecosystem such that they are able to be used anywhere the [official Julia distribution](https://julialang.org/downloads) does.  Using BinaryBuilder you will be able to compile your large pre-existing codebases of C, C++, Fortran, Rust, Go, OCaml, etc... software into binaries that can be downloaded and loaded/run on a very wide range of machines.  As it is difficult (and often expensive) to natively compile software packages across the growing number of platforms that the Julia ecosystem supports, we focus on providing a set of Linux-hosted cross-compilers.  BinaryBuilder sets up an environment to perform cross-compilation for all of the major platforms, and does its best to make the compilation process as painless as possible.

Note that at this time, BinaryBuilder itself runs on `x86_64` or `aarch64` Linux and macOS systems only, with Windows support under active development.  On macOS and Windows, you must have `docker` or `podman` installed as the backing virtualization engine.  Note that Docker Desktop is the recommended version; if you have Docker Machine installed it may not work correctly or may need additional configuration.

An overview of the project is also available at [binarybuilder.org](https://binarybuilder.org).
