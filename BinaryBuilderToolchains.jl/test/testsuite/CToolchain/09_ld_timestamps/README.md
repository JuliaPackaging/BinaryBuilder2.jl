# `ld` timestamps

On Windows, GNU `ld` embeds a link timestamp in PE images unless it is given `--no-insert-timestamp`.
This test links a DLL through the `$(LD)` and `ld.$(CC_TARGET)` wrappers and through `$(CC)`, twice each with a pause in between, and checks that both links give identical files.
It also checks that asking for `--insert-timestamp` is honored (the output changes), and that the `ld` wrappers answer it with a non-reproducibility warning.
Each DLL is linked under the same file name in its own directory, since a DLL's export table records its own file name.

Other targets have no PE timestamps, so there this test does nothing.
