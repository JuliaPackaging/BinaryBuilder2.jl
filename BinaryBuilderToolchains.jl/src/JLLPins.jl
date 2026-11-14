using BinaryBuilderSources: tracks_branch

# The commits that the JLLs our toolchains add from `staticfloat/*_jll.jl` repositories
# are pinned to, keyed by JLL name and the `bb2/` branch that the commit was taken from.
# Neither `Pkg` (which doesn't fetch a branch it has already cloned) nor our JLL resolution
# cache (which only knows the branch name) notices a branch that has moved, so a JLL that
# tracks a branch is resolved on every build, and may still be stale.  To move a toolchain
# JLL forward, update its commit here.
const jll_pins = Dict{Tuple{String,String},String}(
    ("BBJobserver_jll", "bb2/BBJobserver")                              => "dcf9d154784cef2d057f428def7644fdf9d00418",
    ("Binutils_jll", "bb2/GCCBootstrap-x86_64-linux-gnu")               => "7f82db93e8a01af50123509b04676a913c606326",
    ("CCTools_jll", "bb2/GCCBootstrap-x86_64-linux-gnu")                => "2d9ab6813a60c4e055c0583ae94a620b65bec15d",
    ("Clang_jll", "bb2/GCCBootstrap-x86_64-linux-gnu")                  => "fc542ea0b8e6ab9614083e5b21b0f341e561aa92",
    ("GCC_crt_objects_jll", "bb2/GCCBootstrap-x86_64-linux-gnu")        => "1c6f56fd5471f56f46f7b46e5859ae480b6b4104",
    ("GCC_jll", "bb2/GCCBootstrap-x86_64-linux-gnu")                    => "181c76956103befe66bb9fd4a424c259f71777e1",
    ("GCC_support_libraries_jll", "bb2/GCCBootstrap-x86_64-linux-gnu")  => "bd35c7ff60f26aef389e6094ce4229dbc85528d6",
    ("GCCBootstrap_jll", "bb2/GCCBootstrap-aarch64-linux-gnu")          => "8d20e6cbb2fed8d8f4a27ea4d484f07b4d6449ae",
    ("GCCBootstrap_jll", "bb2/GCCBootstrap-x86_64-linux-gnu")           => "dd01ef390f652b38876fd181832ed024d7cb2262",
    ("GCCBootstrapManual_jll", "bb2/GCCBootstrap-aarch64-linux-gnu")    => "af907c5086943c7af3181cb1d05496cf72f16d31",
    ("GCCBootstrapManual_jll", "bb2/GCCBootstrap-x86_64-linux-gnu")     => "e5e7fbffdbac657c907cb2dd2ce5297e9001fa0c",
    ("libLLVM_jll", "bb2/GCCBootstrap-x86_64-linux-gnu")                => "f36dd1b43f296b5239151ceade31bfdbbe7f0e85",
    ("libstdcxx_jll", "bb2/GCCBootstrap-x86_64-linux-gnu")              => "636a940505a67f597bf22c18bb0fd2dbbae2b45c",
    ("LLVMBootstrap_Clang_jll", "bb2/GCCBootstrap-aarch64-linux-gnu")   => "b19e567cc04c54f10890368a419c1f73fef305e6",
    ("LLVMBootstrap_Clang_jll", "bb2/GCCBootstrap-x86_64-linux-gnu")    => "05d6642da497ddbeea187988ab1fca1e38364f5f",
    ("LLVMBootstrap_libLLVM_jll", "bb2/GCCBootstrap-aarch64-linux-gnu") => "62fd2c28b11f48366ea8de7dcc9f711a735b8462",
    ("LLVMBootstrap_libLLVM_jll", "bb2/GCCBootstrap-x86_64-linux-gnu")  => "7214cef0c101b668960de5bf364a227f0ca5bfff",
    ("LLVMCompilerRT_jll", "bb2/GCCBootstrap-x86_64-linux-gnu")         => "6906d5e391b23af8f2486c5350e9e4392944de65",
    ("LLVMLibcxx_jll", "bb2/GCCBootstrap-x86_64-linux-gnu")             => "cae8f7a4b36bb5ea06c1ff48dfeb08ee2a38c8c8",
    ("LLVMLibunwind_jll", "bb2/GCCBootstrap-x86_64-linux-gnu")          => "a2d527dc0159edf7cd4f11fc319bdceae781cd17",
)

"""
    pinned_rev(jll_name::String, branch::String)

Return the commit that `jll_name` is pinned to from `branch` (see `jll_pins`), or
`branch` itself if there is no such pin, which `check_jll_pins()` will then warn about.
"""
pinned_rev(jll_name::String, branch::String) = get(jll_pins, (jll_name, branch), branch)

"""
    check_jll_pins(jlls::Vector{JLLSource})

Warn (once per session) about each of `jlls` that tracks a branch rather than being
pinned to a commit.  Toolchains run this upon construction.
"""
function check_jll_pins(jlls::Vector{JLLSource})
    for jll in jlls
        if tracks_branch(jll.package)
            source, rev = jll.package.repo.source, jll.package.repo.rev
            @warn("Toolchain JLL tracks a branch rather than a commit; pin it in `jll_pins`",
                  jll=jll.package.name, source, rev, _id=Symbol(source, "@", something(rev, "")), maxlog=1)
        end
    end
    return jlls
end
