# C Toolchain test suite

This test suite contains a variety of C programs that are meant to stress test our compiler wrappers.
The stack of context that you must keep in your head to properly stress-test a Julia program that collects compiled executables, generates `bash` scripts, that then invoke the executables to create new executables is.... daunting, I know.
To that end, we have attempted to collect simple, reproducible programs that can be built with said stack and each exercise a discrete component of the toolchain stack.

Each of these test cases contains the following `make` targets:

 - `run`: Build and run the test executable, printing output to `stdout`.
 - `check`: Build and run the test executable, capturing output and ensuring it matches expectation.
 - `clean`: Remove all built objects.

In addition, there is a handly top-level `make` executable that can run the `cleancheck-all` target to clean, then run all outputs, printing happy little checkmarks next to each test that passes, and suppresses much of the typical Make build output.
It also automatically cleans again at the end, to leave your build tree pristine and beautiful.
