# BinaryBuilderToolchains.jl

This package contains the various toolchains used in BinaryBuilder.
Toolchains are a primarily a collection of JLL packages, however the binaries contained within each JLL package often need some extra options or environment variables in order to be made properly relocatable.
These options and environment variables are inserted through the use of wrapper scripts, which are `bash` scripts injected onto the `$PATH` just before the tools themselves.
While these toolchains are used by BinaryBuilder, they are perfectly usable for other purposes.
One way to gain access to the toolchains is by using the `runshell()` method:

```
using BinaryBuilderToolchains, Base.BinaryPlatforms
platform = CrossPlatform(BBHostPlatform() => HostPlatform())
runshell([CToolchain(platform), HostToolsToolchain(platform)])
```
