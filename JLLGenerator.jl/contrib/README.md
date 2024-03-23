# Example JLLInfo collection

We have generated a few example `JLLInfo` objects in `example_jllinfos`, which are used in these tests as well as higher-level tests.

# Julia stdlib JLLInfo collection

We have collected a set of `JLLInfo` objects in `stdlib_jllinfos`, each stored in a separate `.jl` file.
These files serve as both a test suite and a tool in the initial conversion of Julia's stdlib JLLs from the old to the new format.
These files were first generated via `jll_auto_upgrade_helper.jl`, then manually adjusted to include library dependency information.
To generate actual JLL packages from these files, use `gen_julia_jlls.jl`.
