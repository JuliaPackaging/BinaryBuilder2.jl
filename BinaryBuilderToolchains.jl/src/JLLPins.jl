using BinaryBuilderSources: tracks_branch

# The commits that the JLLs our toolchains add from `staticfloat/*_jll.jl` repositories
# are pinned to, keyed by JLL name and the `bb2/` branch that the commit was taken from.
# Neither `Pkg` (which doesn't fetch a branch it has already cloned) nor our JLL resolution
# cache (which only knows the branch name) notices a branch that has moved, so a JLL that
# tracks a branch is resolved on every build, and may still be stale.  To move a toolchain
# JLL forward, update its commit here.
const jll_pins = Dict{Tuple{String,String},String}(
    ("Binutils_jll", "bb2/GCCBootstrap-x86_64-linux-gnu")               => "8bb68e39140b59e57deefe8af13e1a3fcb1acd58",
    ("CCTools_jll", "bb2/GCCBootstrap-x86_64-linux-gnu")                => "2d9ab6813a60c4e055c0583ae94a620b65bec15d",
    ("Clang_jll", "bb2/GCCBootstrap-x86_64-linux-gnu")                  => "fc542ea0b8e6ab9614083e5b21b0f341e561aa92",
    ("FreeBSDSysroot_jll", "bb2/GCCBootstrap-x86_64-linux-gnu")         => "38a51488469f4b27c15e32109914d45213865b48",
    ("GCC_crt_objects_jll", "bb2/GCCBootstrap-x86_64-linux-gnu")        => "a2b305b8fbc95bbf34a20f6a2b275a4693a115d4",
    ("GCC_jll", "bb2/GCCBootstrap-x86_64-linux-gnu")                    => "4190f2fa3a328424a3eca583083e972192882e30",
    ("GCC_support_libraries_jll", "bb2/GCCBootstrap-x86_64-linux-gnu")  => "d18de018aad8242527c4d00aa4e902d71371dbf1",
    ("GCCBootstrap_jll", "bb2/GCCBootstrap-aarch64-linux-gnu")          => "8d20e6cbb2fed8d8f4a27ea4d484f07b4d6449ae",
    ("GCCBootstrap_jll", "bb2/GCCBootstrap-x86_64-linux-gnu")           => "ba6b8f743a81b012801d031a31dd3e1031f21cda",
    ("GCCBootstrapManual_jll", "bb2/GCCBootstrap-aarch64-linux-gnu")    => "af907c5086943c7af3181cb1d05496cf72f16d31",
    ("GCCBootstrapManual_jll", "bb2/GCCBootstrap-x86_64-linux-gnu")     => "e5e7fbffdbac657c907cb2dd2ce5297e9001fa0c",
    ("libLLVM_jll", "bb2/GCCBootstrap-x86_64-linux-gnu")                => "f36dd1b43f296b5239151ceade31bfdbbe7f0e85",
    ("libstdcxx_jll", "bb2/GCCBootstrap-x86_64-linux-gnu")              => "5328ccc8adc67ef9e36c9f8537ac5a0febca7a09",
    ("LinuxKernelHeaders_jll", "bb2/GCCBootstrap-x86_64-linux-gnu")     => "e27bfa9d0653e3d682185583111292a6e879df7e",
    ("LLVMBootstrap_Clang_jll", "bb2/GCCBootstrap-aarch64-linux-gnu")   => "b19e567cc04c54f10890368a419c1f73fef305e6",
    ("LLVMBootstrap_Clang_jll", "bb2/GCCBootstrap-x86_64-linux-gnu")    => "05d6642da497ddbeea187988ab1fca1e38364f5f",
    ("LLVMBootstrap_libLLVM_jll", "bb2/GCCBootstrap-aarch64-linux-gnu") => "62fd2c28b11f48366ea8de7dcc9f711a735b8462",
    ("LLVMBootstrap_libLLVM_jll", "bb2/GCCBootstrap-x86_64-linux-gnu")  => "7214cef0c101b668960de5bf364a227f0ca5bfff",
    ("LLVMCompilerRT_jll", "bb2/GCCBootstrap-x86_64-linux-gnu")         => "2ac784f1de40249cb99826c9fc78093bedb4e46c",
    ("LLVMLibcxx_jll", "bb2/GCCBootstrap-x86_64-linux-gnu")             => "de777215c709750f67602edab1e58fe63b8122d1",
    ("LLVMLibunwind_jll", "bb2/GCCBootstrap-x86_64-linux-gnu")          => "9c7433f0a4a1e47a7e6931cc4ed73b1e2d206536",
    ("macOSSDK_jll", "bb2/GCCBootstrap-x86_64-linux-gnu")               => "95728011f030923fde079ac023133644cce1bfa8",
    ("Mingw_jll", "bb2/GCCBootstrap-x86_64-linux-gnu")                  => "0ec20b5d1843c5e23b8599c3f4b4f74641510e44",
    ("Musl_jll", "bb2/GCCBootstrap-x86_64-linux-gnu")                   => "2196af4f29c6371c6eb825e1fcae2d4f055d9a9b",
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
