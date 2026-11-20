# strip determinism

This test ensures that the output of `strip` is deterministic, whether a file is stripped in place, together with other files, or into a separate output with `-o`.

On macOS, the linker signs its output with an ad-hoc code signature that `strip` invalidates.
The auditor re-signs every Mach-O binary at the end of the build, so our wrapper around `strip` suppresses the warning message about this from `strip`; this test also checks that the warning does not appear.
