using Pkg.Types: VersionSpec

"""
    AbstractToolchain

An `AbstractToolchain` represents a set of JLLs that should be downloaded to
provide some kind of build capability; an example of which is the C toolchain
which is used in almost every recipe, but fortran, go, rust, etc.. are all
other toolchains which can be included in the build environment.

All toolchains must define the following methods:

* Constructor
    - used to configure tool versions, etc...
* toolchain_deps(::T, platform)
    - (returns a vector of `AbstractDependency`'s representing the dependencies
       needed to run this toolchain)

TODO: express compiler wrappers as an AbstractDependency called a ComputedDependency
that gets the `config` object (or similar) and generates the wrappers out to a
directory which then gets mounted in!
"""
abstract type AbstractToolchain; end

# C/C++ cross-compilers!  Both GCC and Clang!
include("toolchains/c_toolchain.jl")

# Biting off more than I can chew?  I don't even know what that means...
#include("toolchains/fortran_toolchain.jl")
#include("toolchains/go_toolchain.jl")
#include("toolchains/rust_toolchain.jl")

# General host tools that are target-independent, like `Make`, `ccache`, etc...
include("toolchains/host_toolchain.jl")


function default_toolchains()
    return AbstractToolchain[CToolchain(), HostToolchain()]
end
