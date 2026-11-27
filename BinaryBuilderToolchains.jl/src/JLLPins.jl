using BinaryBuilderSources: tracks_branch

# The commits that the JLLs our toolchains add from `staticfloat/*_jll.jl` repositories
# are pinned to, keyed by JLL name and the `bb2/` branch that the commit was taken from.
# Neither `Pkg` (which doesn't fetch a branch it has already cloned) nor our JLL resolution
# cache (which only knows the branch name) notices a branch that has moved, so a JLL that
# tracks a branch is resolved on every build, and may still be stale.  To move a toolchain
# JLL forward, update its commit here.
const jll_pins = Dict{Tuple{String,String},String}(
    ("Clang_jll", "bb2/GCCBootstrap-x86_64-linux-gnu")                  => "fc542ea0b8e6ab9614083e5b21b0f341e561aa92",
    ("GCC_crt_objects_jll", "bb2/GCCBootstrap-x86_64-linux-gnu")        => "1c6f56fd5471f56f46f7b46e5859ae480b6b4104",
    ("GCC_jll", "bb2/GCCBootstrap-x86_64-linux-gnu")                    => "181c76956103befe66bb9fd4a424c259f71777e1",
    ("GCC_support_libraries_jll", "bb2/GCCBootstrap-x86_64-linux-gnu")  => "bd35c7ff60f26aef389e6094ce4229dbc85528d6",
    ("libLLVM_jll", "bb2/GCCBootstrap-x86_64-linux-gnu")                => "f36dd1b43f296b5239151ceade31bfdbbe7f0e85",
    # TODO: When this moves to a General release of libstdcxx_jll, built from GCC >= 14.3 or
    # with the PR116159 patch (`<iostream>` references `std::ios_base_library_init()` only
    # on ELF), remove the `/alternatename:_ZSt21ios_base_library_initv` workaround in
    # `clang_wrappers()`.
    ("libstdcxx_jll", "bb2/GCCBootstrap-x86_64-linux-gnu")              => "636a940505a67f597bf22c18bb0fd2dbbae2b45c",
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
