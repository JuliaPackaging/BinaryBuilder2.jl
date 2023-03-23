# -frandom-seed and LTO

GCC occasionally embeds random numbers into its object files, destroying reproducibility.
One way it does this is by generating random names for LTO.
We get around this by providing `-frandom-seed` as a hash of the input arguments (including input filename).

This test case compiles the same file multiple times with `-fLTO` provided.
It first provides two different random seeds, asserts that the files are nondeterministic, then provides no seed, showing that the default behavior of the compile wrappers is to provide a consistent seed.
NOTE: This test will likely fail if you just run it on your local machine's compiler; it needs something like the compiler flags given in the wrapper scripts!
