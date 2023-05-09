Useful features I want to add before I call this rewrite "done":

* Product re-design
  - Build DAG among products, encode in machine-readable JLL info
  - Get rid of dlopen checks completely
* JLL output metadata
  - Discussion here: https://github.com/JuliaPackaging/BinaryBuilder.jl/issues/639
  - Break version number equivalency
  - Build BinaryBuilderJLLWriter.jl
  - Build BinaryBuilderVersionTool.jl?
* Create `GeneratedDependency`
  - Takes in the `BuildConfig` object, generates a directory as a dependency (e.g. compiler wrappers)
  - Resultant directory gets hashed, just like a `DirectorySource`
  - Should dependencies and sources be the same thing?!
* Parallel/much faster Auditor
* Auto-install license as a Julia audit pass, not as a bash `trap` statement
* Shared read-only depot that we can "compact" compiler shards and whatnot into (perhaps this should be a buildkite plugin?)
  - Create torture-test-suite to run a bunch of builds in parallel on a new depot, to make sure that we can share resources properly
* Create mappings from all old style syntax to new style
  - `build_tarballs()` -> `BuildMeta()`, `BuildConfig()`, `build()`, `extract()`, `package()`, etc...
  - `compilers = [:c]` => `toolchains = [CToolchain()]`.
  - `HostBuildDependency()` => `JLLDependency` with appropriate platforms
* Copy over as many tests as possible from BB.jl and BBB.jl
* Test all toolchain executables; at least `--version` to ensure they are still running.
* https://github.com/JuliaLang/julia/pull/45631#issuecomment-1529628736

Things that would be nice to have, but we don't _need_:
* Capture the environment at the end of the build, use it to interpolate products
* LRU cache of specific size for `downloads` folder
* Progress bars for _everything_
  - JLL downloads
  - Source tarball unpacking
  - Auditing
* https://github.com/JuliaPackaging/BinaryBuilderBase.jl/pull/288
