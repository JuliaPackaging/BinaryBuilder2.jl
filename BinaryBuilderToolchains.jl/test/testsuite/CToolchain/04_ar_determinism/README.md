# `ar` determinism

The `ar` tool often likes to embed timestamps within files, breaking determinism.
We work hard inside of our compiler wrappers to disallow flags that would cause this, instead opting to gently encourage you to use the `-D` flag (`D` stands for Determinism; everybody say it together now!)
This test case ensures that the compiler wrappers properly enforce this property.
This test case explicitly searches for warning messages emitted by the compiler wrappers, so this test will not pass on a vanilla `ar` executable.
