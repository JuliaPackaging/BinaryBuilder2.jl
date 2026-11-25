using NetworkOptions
export HostToolsToolchain
using Pkg.Types: VersionSpec

"""
    HostToolsToolchain

This toolchain contains a large number of useful host tools, such as
`ninja`, `file`, `ccache`, `gawk`, `patch`, `python3`, `vim`, `curl`, etc...
Basically anything that doesn't care about the target triplet gets
put into here.

This toolchain also provides the files and environment variables to
override the compiler support libraries (such as `libstdc++.so`)
within a build environment such that it can run the latest and
greatest binaries built from e.g. GCC 14.  On Linux, the runtime
libraries of our newest compilers (`libstdcxx_jll` and
`GCC_support_libraries_jll`, see `runtime_jlls()`) are deployed into
a `runtime` directory that holds nothing else.  The directories that
contain them (see `runtime_library_dirs()`) are added to
`LD_LIBRARY_PATH`, except within a build sandbox, which provides them
through a dynamic loader cache generated for them instead (see
`toolchain_sources()`).  On macOS and Windows, the
toolchain's `lib` directory is added to `DYLD_FALLBACK_LIBRARY_PATH`/`PATH`.
"""
struct HostToolsToolchain <: AbstractToolchain
    platform::Platform
    deps::Vector{JLLSource}
    runtime_deps::Vector{JLLSource}

    function HostToolsToolchain(platform; overrides::Union{String,Vector{JLLSource}} = JLLSource[])
        platform = host_if_crossplatform(platform)

        # If the user is lazy and only gives us names, just turn them into JLLSource objects
        overrides = map(overrides) do tool
            if isa(tool, String)
                return JLLSource(tool, platform)
            end
            return tool
        end

        default_tools = [
            # Build tools
            # Our wrappers and environment hardcode automake's versioned layout
            # (`bin/automake-1.16`, `share/automake-1.16`, etc.) so it must be pinned
            PackageSpec(;name="automake_jll", version=v"1.16.5+0"),
            # We explicitly ask for this version until this issue is addressed:
            # https://github.com/JuliaPackaging/Yggdrasil/pull/12026#issuecomment-3331916149
            PackageSpec(;name="autoconf_jll", version=v"2.71+2"),
            "Bison_jll",
            "Ccache_jll",
            "file_jll",
            "flex_jll",
            "gawk_jll",
            # We use make v4.3, rather than the latest, because glibc's build system
            # falls into an infinite loop with `make v4.4+`.  Eventually, we'll make
            # it easy enough to customize that we'll just override this choice when
            # building glibc.
            PackageSpec(;name="GNUMake_jll", version=VersionSpec("4.3")),
            # We explcitly ask for a certain version here, because anything earlier
            # may try to use `/bin/sh` instead of `/bin/bash`, which doesn't work.
            # X-ref: https://github.com/JuliaPackaging/Yggdrasil/pull/8923
            PackageSpec(;name="Libtool_jll", version=v"2.4.7+4"),
            "M4_jll",
            "Ninja_jll",

            # We used to version Patchelf with date-based versions, but then
            # we switched to actual upstream version numbers; Pkg chooses the
            # date-based versions because they're higher, so we have to explicitly
            # choose the correct version number here
            PackageSpec(;name="Patchelf_jll", version=v"0.17.2+0"),
            "Perl_jll",
            # Many build systems (and configure scripts) run `python3`
            "Python_jll",
            "patch_jll",
            "patchutils_jll",

            # Networking tools.  Note that since `CURL_jll` relies on `LibCURL_jll`
            # which is a stdlib, if the user is building for a triplet that includes
            # `julia_version` in its tags, that will (hilariously) impact the version
            # of `curl` that is deployed as a host tool.
            "CURL_jll",
            "Git_jll",
            "rsync_jll",
            "MozillaCACerts_jll",

            # Compression tools
            "Tar_jll",
            "Gzip_jll",
            "Bzip2_jll",
            "unzip_jll",
            "Zstd_jll",
            "XZ_jll",
            "Zlib_jll",

            # Editors
            "Vim_jll",

            # Misc. tools
            "strace_jll",
            "libtree_jll",
            "ripgrep_jll",
        ]

        deps = JLLSource[]

        # Add any JLLS from our default tools that are not already in the overrides list, to prevent duplicates.
        override_jlls = filter(e -> isa(e, JLLSource), overrides)
        for tool in default_tools
            if isa(tool, AbstractString)
                tool = PackageSpec(;name=tool)
            end
            if !any(jll.package.name == tool.name for jll in override_jlls)
                push!(deps, JLLSource(tool, platform))
            end
        end

        for override in overrides
            push!(deps, override)
        end

        # Concretize the JLLSource's `PackageSpec`'s version (and UUID) now:
        # Explicitly set `julia_version` to `nothing` unless instructed otherwise
        # via `platform`.
        jll_deps = JLLSource[d for d in deps if isa(d, JLLSource)]
        julia_version = nothing
        if haskey(tags(platform), "julia_version")
            julia_version = VersionNumber(platform["julia_version"])
        end
        resolve_versions!(jll_deps; julia_version)

        return new(
            platform,
            deps,
            runtime_jlls(platform),
        )
    end
end

function Base.show(io::IO, toolchain::HostToolsToolchain)
    println(io, "HostToolsToolchain ($(triplet(toolchain.platform)))")
    for dep in vcat(toolchain.deps, toolchain.runtime_deps)
        println(io, " - $(dep.package.name[1:end-4]) v$(dep.package.version)")
    end
end

"""
    toolchain_sources(toolchain::HostToolsToolchain; build_sandbox_prefix = nothing)

The sources that make up `toolchain`.  When the toolchain gets deployed at
`build_sandbox_prefix` within a Linux build sandbox, they include `etc/ld.so.cache`, a
dynamic loader cache of the sandbox rootfs in which the runtime libraries take
precedence over the rootfs's own; the sandbox should mount it at `/etc/ld.so.cache`
(see `toolchain_env()`'s `BB_LD_SO_CACHE`).
"""
function toolchain_sources(toolchain::HostToolsToolchain;
                           build_sandbox_prefix::Union{Nothing,String} = nothing)
    sources = AbstractSource[]

    push!(sources, CachedGeneratedSource("HostToolchainCertificates"; target="etc/certs") do out_dir
        src = ca_roots_path()
        if isdir(src)
            cp(src, out_dir; force=true, follow_symlinks=true)
        else
            cp(src, joinpath(out_dir, basename(src)); force=true, follow_symlinks=true)
        end
    end)

    push!(sources, CachedGeneratedSource("HostTools"; target="wrappers") do out_dir
        toolchain_prefix = "\$(dirname \"\${WRAPPER_DIR}\")"
        if any(jll.package.name == "Tar_jll" for jll in toolchain.deps)
            # Forcibly insert --no-same-owner into every tar invocation,
            # since we run in a single-user environment.
            compiler_wrapper(joinpath(out_dir, "tar"), "$(toolchain_prefix)/bin/tar") do io
                append_flags(io, :POST, "--no-same-owner")
            end
        end
        if any(jll.package.name == "Libtool_jll" for jll in toolchain.deps)
            # Libtool is annoying enough that I want it to show up when using `BB_WRAPPERS_VERBOSE=1`.
            compiler_wrapper(identity, joinpath(out_dir, "libtool"), "$(toolchain_prefix)/bin/libtool")
        end
        if any(jll.package.name == "GNUMake_jll" for jll in toolchain.deps)
            compiler_wrapper(identity, joinpath(out_dir, "make"), "$(toolchain_prefix)/bin/make")
            compiler_wrapper(identity, joinpath(out_dir, "gmake"), "$(toolchain_prefix)/bin/make")
            compiler_wrapper(identity, joinpath(out_dir, "gnumake"), "$(toolchain_prefix)/bin/make")
        end
        if any(jll.package.name == "file_jll" for jll in toolchain.deps)
            compiler_wrapper(joinpath(out_dir, "file"), "$(toolchain_prefix)/bin/file") do io
                # Fix relocatability issues
                println(io, """
                export MAGIC=$(toolchain_prefix)/share/misc/magic.mgc
                """)
            end
        end
        if any(jll.package.name == "Git_jll" for jll in toolchain.deps)
            compiler_wrapper(joinpath(out_dir, "git"), "$(toolchain_prefix)/bin/git") do io
                # Fix relocatability issues
                println(io, """
                export GIT_EXEC_PATH=\"$(toolchain_prefix)/libexec/git-core\"
                export GIT_SSL_CAPATH=\"\${SSL_CERT_DIR}\"
                export GIT_SSL_CAINFO=\"\${SSL_CERT_FILE}\"
                export GIT_TEMPLATE_DIR=\"$(toolchain_prefix)/share/git-core/templates\"
                """)
            end
        end
        if any(jll.package.name == "automake_jll" for jll in toolchain.deps)
            # tell `aclocal` and `automake` how to find its own files
            for name in ("aclocal", "aclocal-1.16")
                compiler_wrapper(joinpath(out_dir, name), "$(toolchain_prefix)/bin/$(name)") do io
                    append_flags(io, :PRE, "--automake-acdir=$(toolchain_prefix)/share/aclocal-1.16")
                    append_flags(io, :PRE, "--system-acdir=$(toolchain_prefix)/share/aclocal")
                end
            end
            for name in ("automake", "automake-1.16")
                compiler_wrapper(joinpath(out_dir, name), "$(toolchain_prefix)/bin/$(name)") do io
                    append_flags(io, :PRE, "--libdir=$(toolchain_prefix)/share/automake-1.16")
                end
            end
        end
        if any(jll.package.name == "autoconf_jll" for jll in toolchain.deps)
            compiler_wrapper(joinpath(out_dir, "autom4te"), "$(toolchain_prefix)/bin/autom4te") do io
                println(io, """
                # Fix relocatability issues
                export AC_MACRODIR=$(toolchain_prefix)/share/autoconf
                export autom4te_perllibdir=$(toolchain_prefix)/share/autoconf
                """)
            end

            for name in ("autoconf", "autoreconf")
                compiler_wrapper(joinpath(out_dir, name), "$(toolchain_prefix)/bin/$(name)") do io
                    println(io, """
                    # Fix relocatability issues
                    export autom4te_perllibdir=$(toolchain_prefix)/share/autoconf
                    """)
                end
            end
        end
        if any(jll.package.name == "M4_jll" for jll in toolchain.deps)
            compiler_wrapper(identity, joinpath(out_dir, "m4"), "$(toolchain_prefix)/bin/m4")
        end
        if any(jll.package.name == "Ninja" for jll in toolchain.deps)
            compiler_wrapper(identity, joinpath(out_dir, "ninja"), "$(toolchain_prefix)/bin/ninja")
        end
        if any(jll.package.name == "CURL_jll" for jll in toolchain.deps)
            compiler_wrapper(joinpath(out_dir, "curl"), "$(toolchain_prefix)/bin/curl") do io
                println(io, """
                # Ensure CURL can find its certificates
                export CURL_CA_BUNDLE=\"\${SSL_CERT_FILE}\"
                """)
            end
        end
        if any(jll.package.name == "Vim_jll" for jll in toolchain.deps)
            # Teach `vim` how to find `defaults.vim`
            for name in ("vim", "vimdiff")
                compiler_wrapper(joinpath(out_dir, name), "$(toolchain_prefix)/bin/$(name)") do io
                    println(io, """
                    # Ensure vim tools can find their data files
                    export VIMRUNTIME=\"\$(compgen -G \"$(toolchain_prefix)/share/vim/*/\")\"
                    """)
                end
            end

            # Also create a `vi` symlink
            symlink("vim", joinpath(out_dir, "vi"))
        end
    end)

    append!(sources, toolchain.deps)
    append!(sources, toolchain.runtime_deps)

    if build_sandbox_prefix !== nothing && Sys.islinux()
        # The cache records the absolute paths of the libraries, so it is specific to the
        # prefix, as well as to the rootfs and the runtime JLLs.  The rootfs is keyed by
        # its artifact tree hash (the basename of its path), not by its path, which
        # depends on the depot it lives in.  `prepare()` prepares the runtime JLLs
        # before this generator runs.
        rootfs = Sandbox.debian_rootfs(; platform=toolchain.platform)
        runtime_dirs = runtime_library_dirs(toolchain, build_sandbox_prefix)
        cache_key = bytes2hex(sha1(string(
            build_sandbox_prefix,
            basename(rootfs),
            runtime_dirs,
            [jll.input_block for jll in toolchain.runtime_deps]...,
        )))
        push!(sources, CachedGeneratedSource("HostToolsLoaderCache-$(cache_key)"; target="etc") do out_dir
            generate_ld_so_cache(out_dir, rootfs, toolchain.platform, build_sandbox_prefix, toolchain.runtime_deps, runtime_dirs)
        end)
    end
    return sources
end

"""
    generate_ld_so_cache(out_dir, rootfs, platform, prefix, runtime_jlls, runtime_dirs)

Write `out_dir/ld.so.cache`: the dynamic loader cache of `rootfs` (a rootfs for
`platform`) with `runtime_dirs` (where `runtime_jlls`, which must already be prepared,
get deployed when `prefix` is mounted inside the sandbox) taking precedence over the
rootfs's own libraries.  `ldconfig` runs within a sandbox, emulated through QEMU when
`platform` cannot run natively.
"""
function generate_ld_so_cache(out_dir::String, rootfs::String, platform::Platform, prefix::String,
                              runtime_jlls::Vector{JLLSource}, runtime_dirs::Vector{String})
    mktempdir() do tmp
        prefix_dir = joinpath(tmp, "prefix")
        deploy(runtime_jlls, prefix_dir)
        conf_dir = joinpath(tmp, "conf")
        mkpath(conf_dir)
        open(joinpath(conf_dir, "ld.so.conf"); write=true) do io
            foreach(dir -> println(io, dir), runtime_dirs)
            println(io, "include /etc/ld.so.conf.d/*.conf")
        end
        mounts = Dict{String,Sandbox.MountInfo}(
            "/" => Sandbox.MountInfo(rootfs, Sandbox.MountType.Overlayed),
            prefix => Sandbox.MountInfo(prefix_dir, Sandbox.MountType.ReadOnly),
            "/workspace/ldconfig" => Sandbox.MountInfo(conf_dir, Sandbox.MountType.ReadOnly),
            "/workspace/out" => Sandbox.MountInfo(out_dir, Sandbox.MountType.ReadWrite),
        )
        sandbox_config = Sandbox.SandboxConfig(
            mounts,
            Dict("PATH" => "/usr/sbin:/usr/bin:/sbin:/bin");
            multiarch=[platform],
        )
        Sandbox.with_executor() do exe
            run(exe, sandbox_config, `/sbin/ldconfig -X -f /workspace/ldconfig/ld.so.conf -C /workspace/out/ld.so.cache`)
        end
    end
end

"""
    runtime_jlls(platform)

The JLLs that provide the runtime libraries (`libstdc++`, `libgcc_s`, `libgomp`, ...)
needed by programs built with our newest compilers, deployed for `platform` into the
`runtime` directory of a `HostToolsToolchain`.
"""
function runtime_jlls(platform::AbstractPlatform)
    jll(name, uuid) = JLLSource(
        name,
        platform;
        uuid=Base.UUID(uuid),
        repo=Pkg.Types.GitRepo(
            rev=pinned_rev(name, "bb2/GCCBootstrap-x86_64-linux-gnu"),
            source="https://github.com/staticfloat/$(name).jl",
        ),
        version=v"14.2.0",
        exempt_from_strict_tags=true,
        target="runtime",
    )
    return [
        jll("libstdcxx_jll", "3ba1ab17-c18f-5d2d-9d5a-db37f286de95"),
        jll("GCC_support_libraries_jll", "465c4c53-7f13-5720-b733-07d6cbd50c3b"),
    ]
end

"""
    runtime_library_dirs(toolchain::HostToolsToolchain, deployed_prefix::String)

The directories, below `deployed_prefix`, that hold the libraries of `runtime_jlls()`.
"""
function runtime_library_dirs(toolchain::HostToolsToolchain, deployed_prefix::String)
    return [joinpath(deployed_prefix, "runtime", triplet(gcc_platform(toolchain.platform)), "lib64")]
end

"""
    toolchain_env(toolchain::HostToolsToolchain, deployed_prefix::String;
                  build_sandbox_prefix = nothing)

The environment for using `toolchain` deployed at `deployed_prefix`.  On Linux, the
runtime libraries are added to `LD_LIBRARY_PATH`, except within a build sandbox (when
`build_sandbox_prefix` is given): that provides them through the dynamic loader cache
named by `BB_LD_SO_CACHE` (see `toolchain_sources()`), which, unlike `LD_LIBRARY_PATH`,
neither overrides a program's own `RUNPATH` nor exposes them to the linker.
"""
function toolchain_env(toolchain::HostToolsToolchain, deployed_prefix::String;
                       build_sandbox_prefix::Union{Nothing,String} = nothing)
    env = Dict{String,String}()
    
    insert_PATH!(env, :PRE, [
        joinpath(deployed_prefix, "wrappers"),
        joinpath(deployed_prefix, "bin"),
    ])
    env["PATCHELF"] = joinpath(deployed_prefix, "bin", "patchelf")
    insert_PATH!(env, :PRE, [
        joinpath(deployed_prefix, "share", "aclocal-1.16"),
        joinpath(deployed_prefix, "share", "automake-1.16"),
        joinpath(deployed_prefix, "share", "autoconf"),
    ]; varname="PERLLIB")
    # Tell automake not to try and use its baked-in paths
    env["AUTOMAKE_UNINSTALLED"] = "true"
    env["AUTOCONF"] = joinpath(deployed_prefix, "wrappers", "autoconf")
    env["AUTOM4TE"] = joinpath(deployed_prefix, "wrappers", "autom4te")
    env["M4"] = joinpath(deployed_prefix, "wrappers", "m4")

    # Use the bundled CA root file
    env["SSL_CERT_DIR"] = joinpath(deployed_prefix, "etc", "certs")
    if isfile(ca_roots_path())
        env["SSL_CERT_FILE"] = joinpath(deployed_prefix, "etc", "certs", basename(ca_roots_path()))
    end

    # Make the runtime libraries findable by programs built with our compilers
    if Sys.iswindows()
        insert_PATH!(env, :PRE, [joinpath(deployed_prefix, "lib")]; varname="PATH", pathsep=";")
    elseif Sys.isapple()
        insert_PATH!(env, :PRE, [joinpath(deployed_prefix, "lib")]; varname="DYLD_FALLBACK_LIBRARY_PATH")
    elseif build_sandbox_prefix !== nothing
        env["BB_LD_SO_CACHE"] = joinpath(build_sandbox_prefix, "etc", "ld.so.cache")
    else
        insert_PATH!(env, :PRE, runtime_library_dirs(toolchain, deployed_prefix); varname="LD_LIBRARY_PATH")
    end
    return env
end

function platform(toolchain::HostToolsToolchain)
    return toolchain.platform
end

function supported_platforms(::Type{HostToolsToolchain}; experimental::Bool = false)
    # Theoretically we can support way more than this, but let's just be conservative.
    return [
        Platform("x86_64", "linux"),
        Platform("aarch64", "linux"),
    ]
end
