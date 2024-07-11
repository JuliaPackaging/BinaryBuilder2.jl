using Sandbox

read_write_dir = joinpath(@__DIR__, "sandbox_read_write")
mkpath(read_write_dir)
config = SandboxConfig(
    # Mounts
    Dict(
        "/" => MountInfo(Sandbox.debian_rootfs(), MountType.Overlayed),
        "/read_write" => MountInfo(read_write_dir, MountType.ReadWrite),
    ),
    # Environment
    Dict(
        "FOO" => "foo",
    );
    # Hook up stdin and stdout
    stdin,
    stdout,
)
with_executor() do exe
    run(exe, config, `/bin/bash`)
end
