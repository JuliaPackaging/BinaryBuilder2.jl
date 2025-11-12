# `BuildTargetSpec`

BinaryBuilder2 supports an extremely flexible (and thereby annoyingly complicated) way of specifying what toolchains to place where within the build environment.
The main usecase for using this feature is when performing a build that requires toolchains for more than one target, e.g. when doing a [canadian cross-build of GCC](https://en.wikipedia.org/wiki/Cross_compiler#Canadian_Cross) you need a `build` toolchain (to make tools used during the build), a `host` toolchain (to make the actual compiler we're building) and a `target` toolchain (to make libraries that the compiler we're building will use).
Concretely, if we are on `x86_64-linux-gnu`, and we're building a GCC to run on `aarch64-linux-gnu` that will generate code for `x86_64-apple-darwin`, we have such a case where we need not two but three toolchains:
* `build`: `x86_64-linux-gnu => x86_64-linux-gnu`.
* `host`: `x86_64-linux-gnu => aarch64-linux-gnu`.
* `target`: `x86_64-linux-gnu => x86_64-apple-darwin`.

Rather than hardcode a "canadian cross" mode into BinaryBuilder2, we instead opted to make a flexible system for specifying build targets, each of which contains information such as a name (used to construct paths and environment variables to find it), toolchains, a target platform, target-specific dependencies, etc...
The `BuildTargetSpec` type composes with the `AbstractToolchain` objects from `BinaryBuilderToolchains` to generate the compilers placed in the `/opt` tree inside the BinaryBuilder build environment.

# Type Usage

The typical way to use a `BuildTargetSpec` is with the `[build_tarballs](@ref)()` keyword argument `build_spec_generator`.
This keyword argument takes in a function that is invoked with `(host, platform)` arguments and is expected to inspect the attributes of those arguments to construct however many `BuildTargetSpec` objects are needed.
Note that within BinaryBuilder, we tend to use the term `host` to refer to the machine that BinaryBuilder2 is running on (see [Platform Naming](@ref) for more).
An example `build_spec_generator` function is as follows:

```julia
# build specification generator for compiler that targets a particular platform
function build_spec_generator(host, platform)
    return [
        # "build" machine, which is the 
        BuildTargetSpec(
            "build",
            # Toolchains that are installed for the `build` BTS will generate code that can be ran during the build
            CrossPlatform(host => host),
            # We need a C compiler, cmake, and the host tools like `make` and `ninja`
            [CToolchain(), CMakeToolchain(), HostToolsToolchain()],
            # Some of our build tools need to compile against libpython
            [JLLSource("Python_jll")],
            # Set the `native` flag for this BTS, which changes a few small minutae.
            Set([:native]),
        ),
        BuildTargetSpec(
            "host",
            # Toolchains that are installed for the `host` BTS will generate code to be run on the user's machine
            CrossPlatform(host => platform.host),
            # Again, we need a C compiler and cmake
            [CToolchain(), CMakeToolchain()],
            # These are all the dependencies our software needs to run.
            [JLLSource("Zlib_jll"), JLLSource("XML2_jll")],
            # Set the `default` flag for this BTS, which means that `$CC` refers to `$HOST_CC`.
            Set([:default]),
        ),
        # We declare a `target` BTS to collect compiler support libraries that are compiled for the `target`, if any.
        BuildTargetSpec(
            "target",
            CrossPlatform(host => platform.target),
            # Again, we need a C compiler and cmake
            [CToolchain(), CMakeToolchain()],
            [],
            Set{Symbol}(),
        ),
    ]
end
```

This can be somewhat simplified by using the [`make_target_spec_plan()`](@ref) and [`apply_spec_plan()`](@ref) functions, which automates construction of either two or three `BuildTargetSpec`'s depending on whether we declare that we are building a cross compiler or not.
The [`make_target_spec_plan()`](@ref) function takes in two sets of toolchains and dependencies (named `host` and `target`, see [Platform Naming](@ref) for details on naming) and a boolean of whether we should create two or three `BuildTargetSpec` objects.
Recreating the same example above using `make_target_spec_plan()`:
```julia
# build specification generator for compiler that targets a particular platform
spec_plan = make_target_spec_plan(;
        host_toolchains = [CToolchain(), CMakeToolchain(), HostToolsToolchain()],
        target_toolchains = [CToolchain(), CMakeToolchain()],
        host_dependencies = [JLLSource("Python_jll")],
        target_dependencies = [JLLSource("Zlib_jll"), JLLSource("XML2_jll")],
        cross_compiler = true)
function build_spec_generator(host, platform)
    return apply_spec_plan(spec_plan, host, platform)
end
```

# Interaction with `build_tarballs()`

When passed to `build_tarballs()` a `build_spec_generator` completely overrides the following keyword arguments, as they are passed to `make_target_spec_plan()` internally:
  * `host_toolchains`
  * `target_toolchains`
  * `host_dependencies`
  * `target_dependencies`
The generator function will be invoked for each `platform` object passed to `build_tarballs`, setting up a per-platform set of compilers and dependencies.
