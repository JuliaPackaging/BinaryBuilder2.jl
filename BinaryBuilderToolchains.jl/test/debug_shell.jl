using BinaryBuilderToolchains

# Because I so often need to debug issues with the CToolchain tests, this is a
# convenient wrapper to get me into a state similar to what the tests run in.

target = Platform("aarch64", "macos")
target_platform = CrossPlatform(BBHostPlatform() => target)
vendor = :auto

htt_toolchain = HostToolsToolchain(BBHostPlatform())
toolchain = CToolchain(target_platform; vendor, use_ccache=false)
with_toolchains([toolchain, htt_toolchain]) do prefix, env
    cd(joinpath(@__DIR__, "testsuite", "CToolchain")) do
        run(setenv(`/bin/bash -l`, env))
    end
end
