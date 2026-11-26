export CMakeToolchain

struct CMakeToolchain <: AbstractToolchain
    platform::CrossPlatform
    wrapper_prefixes::Vector{String}
    env_prefixes::Vector{String}

    # Prefixes that `find_package()`, `find_library()`, etc... search before CMake's
    # platform-default prefixes.  In BinaryBuilder this is the prefix that this
    # toolchain's dependencies are installed into.
    prefix_paths::Vector{String}

    # Prefixes that `find_*()` never search, even though CMake's platform modules
    # list them by default.  In BinaryBuilder the target toolchain ignores the host
    # prefix `/usr/local`, which CMake searches by default on every Unix-like target
    # (cross-compiling or not), but which holds dependencies built for the host.
    ignore_prefix_paths::Vector{String}

    function CMakeToolchain(platform::CrossPlatform;
                            env_prefixes = [""],
                            wrapper_prefixes = ["\${triplet}-", ""],
                            prefix_paths = String[],
                            ignore_prefix_paths = String[])
        if isempty(wrapper_prefixes)
            throw(ArgumentError("Cannot have empty wrapper prefixes!  Did you mean [\"\"]?"))
        end
        if isempty(env_prefixes)
            throw(ArgumentError("Cannot have empty env prefixes!  Did you mean [\"\"]?"))
        end
        return new(
            platform,
            string.(wrapper_prefixes),
            string.(env_prefixes),
            string.(prefix_paths),
            string.(ignore_prefix_paths),
        )
    end
end


function generate_cmake_toolchain_file(toolchain::CMakeToolchain, io::IO)
    target_triplet = triplet(gcc_platform(toolchain.platform.target))

    function cmake_arch(p::AbstractPlatform)
        if arch(p) == "powerpc64le"
            return "ppc64le"
        else
            return arch(p)
        end
    end
    
    function cmake_os(p::AbstractPlatform)
        if Sys.islinux(p)
            return "Linux"
        elseif Sys.isfreebsd(p)
            return "FreeBSD"
        elseif Sys.isapple(p)
            return "Darwin"
        elseif Sys.iswindows(p)
            return "Windows"
        else
            return "Unknown"
        end
    end
    
    # In order to get the version of the host system we need to call `/bin/uname -r`.
    # Eventually, if we settle on an `os_version` tag, we might avoid the `uname -r`.
    println(io, """
    # CMake toolchain file for $(target_triplet)
    set(CMAKE_HOST_SYSTEM_NAME $(cmake_os(toolchain.platform.host)))
    set(CMAKE_HOST_SYSTEM_PROCESSOR $(cmake_arch(toolchain.platform.host)))
    execute_process(COMMAND /bin/uname -r OUTPUT_VARIABLE CMAKE_HOST_SYSTEM_VERSION OUTPUT_STRIP_TRAILING_WHITESPACE)
    """)

    if toolchain.platform.host != toolchain.platform.target
        # CMake checks whether `SYSTEM_NAME` is set manually to decide whether the current
        # build is a cross-compilation or not:
        # <https://cmake.org/cmake/help/latest/variable/CMAKE_CROSSCOMPILING.html>.  We
        # always set `HOST_SYSTEM_NAME`, but set `SYSTEM_NAME` only for the target
        # toolchain.
        println(io, """
        set(CMAKE_SYSTEM_NAME $(cmake_os(toolchain.platform.target)))
        set(CMAKE_SYSTEM_PROCESSOR $(cmake_arch(toolchain.platform.target)))
        """)

        # macOS has special version variables that we must set
        if Sys.isapple(toolchain.platform.target)
            darwin_ver = macos_target_kernel_version(toolchain.platform.target)
            maj_ver = darwin_ver.major
            min_ver = darwin_ver.minor
            println(io, """
            set(CMAKE_SYSTEM_VERSION $(maj_ver).$(min_ver))
            set(DARWIN_MAJOR_VERSION $(maj_ver))
            set(DARWIN_MINOR_VERSION $(min_ver))
            """)
        else
            println(io, """
            execute_process(COMMAND uname -r OUTPUT_VARIABLE CMAKE_SYSTEM_VERSION OUTPUT_STRIP_TRAILING_WHITESPACE)
            """)
        end
    end

    # Important paths, taken from the environment variables of the `CToolchain` and the
    # install prefix that this toolchain is paired with (e.g. `$HOST_CC` and `$host_prefix`
    # for a toolchain with the `HOST_` environment prefix).
    env_prefix = toolchain.env_prefixes[argmax(length.(toolchain.env_prefixes))]
    println(io, """
    set(CMAKE_INSTALL_PREFIX \$ENV{$(lowercase(env_prefix))prefix})
    execute_process(COMMAND \$ENV{$(env_prefix)CC} -print-sysroot OUTPUT_VARIABLE CMAKE_SYSROOT OUTPUT_STRIP_TRAILING_WHITESPACE)
    """)

    # CMake's platform modules (e.g. `Platform/UnixPaths.cmake`) append `/usr/local`,
    # `/usr`, `/`, etc... to `CMAKE_SYSTEM_PREFIX_PATH` after this file is read, so
    # prepending here puts our prefixes ahead of those, while still leaving them behind
    # anything the user passes in via `CMAKE_PREFIX_PATH`.  The toolchain file may be
    # read more than once per configure, so don't add duplicate entries.
    for path in reverse(toolchain.prefix_paths)
        println(io, """
        if(NOT "$(path)" IN_LIST CMAKE_SYSTEM_PREFIX_PATH)
            list(PREPEND CMAKE_SYSTEM_PREFIX_PATH "$(path)")
        endif()
        """)
    end
    for path in toolchain.ignore_prefix_paths
        println(io, """
        if(NOT "$(path)" IN_LIST CMAKE_SYSTEM_IGNORE_PREFIX_PATH)
            list(APPEND CMAKE_SYSTEM_IGNORE_PREFIX_PATH "$(path)")
        endif()
        """)
    end

    if Sys.isapple(toolchain.platform.target)
        # Set frameworks for macOS
        println(io, """
        set(CMAKE_SYSTEM_FRAMEWORK_PATH
            \${CMAKE_SYSROOT}/System/Library/Frameworks
            \${CMAKE_SYSROOT}/System/Library/PrivateFrameworks
        )
        """)
    end

    # Use `$CC`, `$LD`, etc... from our `CToolchain`'s environment
    # mappings to fill in our `CMAKE_*` toolchain definitions.  This
    # is doubly convenient, as it allows `ccache`, `clang`/`gcc` choices
    # etc... to be centralized in one place.
    cmake_to_env = Dict(
        "CMAKE_C_COMPILER" => "CC",
        "CMAKE_CXX_COMPILER" => "CXX",
        "CMAKE_Fortran_COMPILER" => "FC",
        "CMAKE_LINKER" => "LD",
        "CMAKE_OBJCOPY" => "OBJCOPY",
        "CMAKE_AR" => "AR",
        "CMAKE_NM" => "NM",
        "CMAKE_RANLIB" => "RANLIB",
    )

    for (cmake_var, env_var) in cmake_to_env
        println(io, """
        if(DEFINED ENV{$(env_prefix)$(env_var)})
            set($(cmake_var) \$ENV{$(env_prefix)$(env_var)})
        endif()
        """)
    end
end

function toolchain_sources(toolchain::CMakeToolchain; build_sandbox_prefix::Union{Nothing,String} = nothing)
    toolchain_prefix = "\$(dirname \"\${WRAPPER_DIR}\")"
    function cmake_wrapper(io)
        # Insert our `CMAKE_TOOLCHAIN_FILE` only when `cmake` is being invoked to
        # configure a project and the user has not already passed one in.  Modes
        # such as `--build`, `--install`, `--open`, `-E` and `--workflow` must be
        # the first argument, and cmake either rejects a leading `-D` for them or
        # falls back to configure mode.  An invocation with no arguments at all
        # just prints usage, but would configure the current directory if we
        # added a `-D` flag to it.
        no_cmake_mode = string(
            "! \"\${ARGS[0]}\" =~ ",
            "^(--build|--install|--open|-E|--workflow)\$",
        )
        bash_if_statement(io, ["\${#ARGS[@]} -gt 0", no_cmake_mode]) do io
            flagmatch(io, [!flag"-D[[:space:]]*CMAKE_TOOLCHAIN_FILE[=:].*"r]) do io
                append_flags(io, :PRE, "-DCMAKE_TOOLCHAIN_FILE=$(toolchain_prefix)/wrappers/toolchain.cmake")
            end
        end
    end

    cache_key = string(
        "CMake-",
        bytes2hex(sha256(string(
            triplet(toolchain.platform),
            toolchain.env_prefixes...,
            toolchain.wrapper_prefixes...,
            "prefix_paths", toolchain.prefix_paths...,
            "ignore_prefix_paths", toolchain.ignore_prefix_paths...,
        ))),
    )
    return [
        JLLSource(
            "CMake_jll",
            toolchain.platform.host;
            version=VersionSpec("3.30.2"),
            target="cmake",
        ),
        CachedGeneratedSource(cache_key; target="wrappers") do out_dir
            for wrapper_prefix in toolchain.wrapper_prefixes
                tool_prefixed = string(replace(wrapper_prefix, "\${triplet}" => triplet(toolchain.platform.target)), "cmake")
                compiler_wrapper(
                    cmake_wrapper,
                    identity,
                    joinpath(out_dir, tool_prefixed),
                    "$(toolchain_prefix)/cmake/bin/cmake",
                )
            end
            open(joinpath(out_dir, "toolchain.cmake"); write=true) do io
                generate_cmake_toolchain_file(toolchain, io)
            end
        end,
    ]
end

function toolchain_env(toolchain::CMakeToolchain, deployed_prefix::String;
                       build_sandbox_prefix::Union{Nothing,String} = nothing)
    env = Dict{String,String}()
    insert_PATH!(env, :PRE, [
        joinpath(deployed_prefix, "wrappers"),
        joinpath(deployed_prefix, "bin"),
    ])

    # We can have multiple wrapper prefixes, we always use the longest one
    # as that's typically the most specific.
    wrapper_prefixes = replace.(toolchain.wrapper_prefixes, ("\${triplet}" => triplet(toolchain.platform.target),))
    wrapper_prefix = wrapper_prefixes[argmax(length.(wrapper_prefixes))]
    for env_prefix in toolchain.env_prefixes
        env["$(env_prefix)CMAKE"] = "$(wrapper_prefix)cmake"
        env["CMAKE_$(env_prefix)TOOLCHAIN"] = "$(deployed_prefix)/wrappers/toolchain.cmake"
    end
    return env
end

# We just sub off to our underlying CToolchain here.
function supported_platforms(::Type{CMakeToolchain}; experimental::Bool = false)
    return supported_platforms(CToolchain; experimental)
end
