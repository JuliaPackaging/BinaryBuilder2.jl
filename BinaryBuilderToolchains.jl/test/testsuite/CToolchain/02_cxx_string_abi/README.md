# C++11 `std::string` ABI change

This test suite builds an executable and library that pass `std::string` objects around.
This is generally considered a dangerous thing to do, as [`libstdc++` changed the string ABI](https://gcc.gnu.org/onlinedocs/libstdc++/manual/using_dual_abi.html) back around the GCC 5.X timeframe, and 7 major versions later we are _still_ running into problems with it.
However, you need not fear, for as long as the appropriate `_GLIBCXX_USE_CXX11_ABI` macros have been defined during the build of all objects to be linked together, everything should Just Work (TM).

Our compiler wrappers automatically insert `_GLIBCXX_USE_CXX11_ABI` when we have a `cxxstring` tag applied to a platform object.
This test suite is used to generate code that should require such a thing, and we test to ensure that the invoked compilers have such a macro defined, however actually testing the generated binary code is left as an exercise for the BB auditor.
This test suite also happens to be the first one to be complex enough to catch when our kernel headers are missing.
