using Sandbox, JLLPrefixes, Pkg, Scratch
import JLLPrefixes: PkgSpec

export runshell

function default_glibc_version(target::AbstractPlatform)
    if arch(target) ∈ ("x86_64", "i686")
        return v"2.12.2"
    elseif arch(target) ∈ ("powerpc64le",)
        return v"2.17"
    elseif arch(target) ∈ ("armv6l", "armv7l", "aarch64", "any")
        return v"2.19"
    else
        throw(ArgumentError("Invalid arch for glibc version autodetection: '$(arch(target))'"))
    end
end

function default_kernel_version(target::AbstractPlatform)
    # We always target the same kernel version
    return v"5.15.14"
end


function host_build_tools(platform::CrossPlatform)
    return JLLDependency[
        # TODO: version these?
        JLLDependency("GNUMake_jll"; platform.host),
        JLLDependency("Ccache_jll"; platform.host),
    ]
end










#=
function collect_compiler_artifacts(prefix::String,
                                    platform::CrossPlatform;
                                    kernel_headers_version = default_kernel_version(platform.target),
                                    glibc_version = default_glibc_version(platform.target),
                                    binutils_version = v"2.38.0",
                                    zlib_version = v"1.2.12",
                                    gcc_version = v"9.1.0",)

    art_paths = JLLPrefixes.collect_artifact_paths([
        PkgSpec(;name="LinuxKernelHeaders_jll", version=kernel_headers_version),
        PkgSpec(;name="Glibc_jll", version=glibc_version),
        # Special Binutils_jll to get rid of copy-paste error
        PkgSpec(;name="Binutils_jll", repo=Pkg.Types.GitRepo(rev="ae1dd5078aaf195dd6efe876d2fb0fdde68a6d6e", source="https://github.com/JuliaBinaryWrappers/Binutils_jll.jl")),
        PkgSpec(;name="Zlib_jll", version=zlib_version),
        # Special GCC_jll since we don't actually have one yet
        PkgSpec(;name="GCC_jll", repo=Pkg.Types.GitRepo(rev="6e04e57d78fe742bcc357e7e7349dbe6e8ae4e2f", source="https://github.com/staticfloat/GCC_jll.jl")),
        PkgSpec(;name="GNUMake_jll", version=v"4.4.0"),
    ]; platform)

    # Separate out our compiler artifacts into different install locations:
    gcc_host_subdir = joinpath(prefix, triplet(platform.host))
    gcc_host_subdir_usr = joinpath(gcc_host_subdir, "usr")
    artifacts_by_installation_prefix = Dict{String,Vector{String}}(
        prefix => String[],
        gcc_host_subdir => String[],
        gcc_host_subdir_usr => String[],
    )
    for (pkg, paths) in art_paths
        if pkg.name ∈ ("Glibc_jll",)
            append!(artifacts_by_installation_prefix[gcc_host_subdir], paths)
        elseif pkg.name ∈ ("LinuxKernelHeaders_jll",)
            append!(artifacts_by_installation_prefix[gcc_host_subdir_usr], paths)
        else
            append!(artifacts_by_installation_prefix[prefix], paths)
        end
    end
    for (art_prefix, paths) in artifacts_by_installation_prefix
        JLLPrefixes.hardlink_artifact_paths(art_prefix, paths)
    end
end
=#

function SandboxConfig(platform::CrossPlatform; kwargs...)

end

function runshell(platform::CrossPlatform; kwargs...)
    target_tool_dir = mktempdir(@get_scratch!("target-tool-dir"))
    collect_compiler_artifacts(target_tool_dir, platform; kwargs...)

    workspace = mktempdir()
    open(joinpath(workspace, "hello_world.cpp"), write=true) do io
        println(io, """
        #include <iostream>
        #include <unistd.h>
        #include <stdlib.h>
        #include <time.h>
        
        int main() {
            std::cout << "Hello, World!\\n";
            struct timespec t;
            clock_gettime(CLOCK_REALTIME, &t);
            std::cout << "Current time: " << t.tv_sec << "\\n";
            return 0;
        }
        """)
    end

    open(joinpath(workspace, "Makefile"), write=true) do io
        println(io, """
        all: run

        hello_world: hello_world.cpp
        \t\$(CXX) -o \$@ \$<
        
        run: hello_world
        \t./\$<
        """)
    end

    config = SandboxConfig(
        Dict(
            "/" => Sandbox.debian_rootfs(),
            "/opt/$(triplet(platform.host))" => target_tool_dir,
        ),
        Dict(
            "/workspace" => workspace,
        ),
        Dict{String,String}(
            "PATH" => "/usr/local/bin:/usr/local/sbin:/usr/bin:/usr/sbin:/bin:/sbin:/opt/$(triplet(platform.host))/bin",
            "CC" => "$(triplet(platform.host))-gcc",
            "CXX" => "$(triplet(platform.host))-g++",
            "AR" => "$(triplet(platform.host))-ar",
            "LD" => "$(triplet(platform.host))-ld",
        );
        hostname = "bb8",
        pwd = "/workspace",
        stdin,
        stdout,
        stderr
    )
    with_executor() do exe
        run(exe, config, `/bin/bash`)
    end
end
