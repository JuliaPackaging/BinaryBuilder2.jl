# Library dependency graph

This example creates a library dependency graph where `libfoo` depends on `libbar`, `libbar` depends on `libbaz` and `libqux`, and `libbaz` depends solely on `libqux`:

```
 ┌──────┐  ┌───────┐  ┌──────┐  ┌──────┐
 │libfoo├─►│libbar ├─►│libbaz├─►│libqux│
 └──────┘  └────┬──┘  └──────┘  └──────┘
                │                   ▲
                └───────────────────┘
```

While this is rather trivial for a C toolchain to generate, this dependency structure is useful for downstream tests that require a non-trivial dependency structure graph.
