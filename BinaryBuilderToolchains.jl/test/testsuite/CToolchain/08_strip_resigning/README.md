# strip determinism and auto code resigning

On macOS where code signatures are required for execution, `clang` automatically signs its output with a cryptographic signature that is then invalidated if `strip` gets its grubby little hands on the binary.
This test ensures that our wrapper around `strip` properly suppresses the warning message about this from `strip`.
It also tests that the output of `strip` is deterministic.
