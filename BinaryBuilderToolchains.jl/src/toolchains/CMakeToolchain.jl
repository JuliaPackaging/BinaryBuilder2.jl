export CMakeToolchain

struct CMakeToolchain <: AbstractToolchain
    platform::CrossPlatform
    wrapper_prefixes::Vector{String}
    env_prefixes::Vector{String}

    # Whether `clang` should use `lld` as its linker or `ld`
    clang_use_lld::Bool

    function CMakeToolchain(platform::CrossPlatform;
                            env_prefixes = [""],
                            wrapper_prefixes = ["\${triplet}-", ""],
                            clang_use_lld = false)
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
            clang_use_lld,
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
            darwin_ver = something(os_version(toolchain.platform.target), v"14.5.0")
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

    # Important paths
    println(io, """
    set(CMAKE_INSTALL_PREFIX \$ENV{prefix})
    execute_process(COMMAND \$ENV{CC} -print-sysroot OUTPUT_VARIABLE CMAKE_SYSROOT OUTPUT_STRIP_TRAILING_WHITESPACE)
    """)

    # Set frameworks for macOS
    if Sys.isapple(toolchain.platform.target)
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

    env_prefix = toolchain.env_prefixes[argmax(length.(toolchain.env_prefixes))]
    for (cmake_var, env_var) in cmake_to_env
        println(io, """
        if(DEFINED ENV{$(env_prefix)$(env_var)})
            set($(cmake_var) \$ENV{$(env_prefix)$(env_var)})
        endif()
        """)
    end
end

function toolchain_sources(toolchain::CMakeToolchain)
    toolchain_prefix = "\$(dirname \"\${WRAPPER_DIR}\")"
    function cmake_wrapper(io)
        # If the user has not already passed in a `CMAKE_TOOLCHAIN_FILE`, insert ours
        flagmatch(io, [!flag"-D[[:space:]]*CMAKE_TOOLCHAIN_FILE[=:].*"r]) do io
            append_flags(io, :PRE, "-DCMAKE_TOOLCHAIN_FILE=$(toolchain_prefix)/wrappers/toolchain.cmake")
        end
    end

    return [
        JLLSource(
            "CMake_jll",
            toolchain.platform.host;
            target="cmake",
        ),
        GeneratedSource(;target="wrappers") do out_dir
            for wrapper_prefix in toolchain.wrapper_prefixes
                tool_prefixed = string(replace(wrapper_prefix, "\${triplet}" => triplet(toolchain.platform.target)), "cmake")
                compiler_wrapper(
                    cmake_wrapper,
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

function toolchain_env(toolchain::CMakeToolchain, deployed_prefix::String)
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
