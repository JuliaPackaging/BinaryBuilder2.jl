# `PlatformlessWrapper`

```@docs; canonical=false
PlatformlessWrapper
```

Example usage with a `CToolchain` from `BinaryBuilderToolchains`:

```jldoctest
julia> using BinaryBuilder2, BinaryBuilderToolchains

julia> pw_ct = CToolchain(; vendor=:clang)
CToolchain(...) (platformless wrapper)

julia> platform = CrossPlatform(Platform("x86_64", "linux") => Platform("aarch64", "macos"));
       apply_platform(pw_ct, platform)
CToolchain (CrossPlatform(Platform("x86_64", "linux"; libc = "glibc") -> Platform("aarch64", "macos"; )))
 - macOSSDK v11.1.0
 - Clang v17.0.7
 - libLLVM v17.0.7
 - CCTools v986.0.0
 - libtapi v1300.6.0
 - ldid v2.1.4+0
 - LLVMCompilerRT v17.0.7
```

## Writing new `PlatformlessWrapper` adapters

Adding `PlatformlessWrapper` support to your own type is fairly straightforward, you just need to define how to curry arguments to your types' constructor.
Let us imagine we have the following object that takes in some non-platform data (that we want to be constant across all platforms) and a platform:
```julia
struct ExampleObject
    # This data is required
    data::String
    platform::Platform

    # This data is optional
    optional::Union{Nothing,String}

    function ExampleObject(data::String, platform::Platform; optional::Union{Nothing,String}=nothing)
        return new(data, platform, optional)
    end
end
```

To create a "platformless" variant of this, we want to be able to invoke `ExampleObject("data"; optional="foo")`, so we create that constructor, and then an `apply_platform()` function to concretize back down to an actual `ExampleObject` object:
```julia
function ExampleObject(data::String; optional::Union{Nothing,String}=nothing)
    return PlatformlessWrapper{ExampleObject}(;args=[data], kwargs=Dict(:optional => optional))
end

function apply_platform(pw::PlatformlessWrapper{ExampleObject}, platform::AbstractPlatform)
    return ExampleObject(pw.args..., platform; pw.kwargs...)
end
```
