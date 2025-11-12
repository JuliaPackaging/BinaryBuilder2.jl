# Nomenclature

Terminology is difficult to agree upon, especially when you have a project like BinaryBuilder that encompasses multiple ecosystems, each of which has its own accepted but slightly unique set of terms.
Here we attempt to clear up any ambiguities, and link to them from other places in the documentation.

### Platform Naming

When talking about cross-compilers, there are three terms often used: `build`, `host` and `target`.
In the most verbose case (the [canadian cross](https://en.wikipedia.org/wiki/Cross_compiler#Canadian_Cross)) all three of those terms refer to different machines.
Concretely, if we are on `x86_64-linux-gnu`, and we're building a GCC to run on `aarch64-linux-gnu` that will generate code for `x86_64-apple-darwin`, we need three compilers, which are typically named:
* `build`: `x86_64-linux-gnu => x86_64-linux-gnu`.
* `host`: `x86_64-linux-gnu => aarch64-linux-gnu`.
* `target`: `x86_64-linux-gnu => x86_64-apple-darwin`.

This is the [autotools](https://en.wikipedia.org/wiki/GNU_Autotools) naming convention, and is what you may remember when seeing command line invocations such as `./configure --build=xxx --target=xxx`.

Unfortunately for us when not building a compiler itself, most other software tends to use `host` to refer to the machine the build is running on, and `target` to refer to the machine the compiled software will run on.
This means that `host` refers to autotools' `build`, and `target` refers to autotools' `host`.

In BinaryBuilder, we have a further complication which is that our `AbstractPlatform` object allows us to specify the build platform as either a typical `Platform()`, or as a `CrossPlatform()`, to denote that we're building a cross compiler.
This means that we always only ever have two objects that completely specify the platform attributes of what we're building (the machine the build is happening on, and the output of the build) and so we typically refer to the first as `host`, and the second as `platform`.  BinaryBuilder does 
