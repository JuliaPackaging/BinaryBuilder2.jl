# Included by `runtests.jl` into a module that has already loaded `common.jl`.

# In BinaryBuilder, the host prefix is `/usr/local`, which CMake's platform modules put on
# `CMAKE_SYSTEM_PREFIX_PATH` for every Unix-like target, whether cross-compiling or not.
# A target `CMakeToolchain` must find its dependencies in its own prefix and must never
# pick up host dependencies from the host prefix; a host `CMakeToolchain` must still find
# them there.  We can't write to `/usr/local` here, so the test project appends a fake host
# prefix to `CMAKE_SYSTEM_PREFIX_PATH` itself, just like `Platform/UnixPaths.cmake` does.
@testset "CMakeToolchain search paths" begin
    platform = CrossPlatform(BBHostPlatform() => BBHostPlatform())

    mktempdir() do dir
        host_prefix = joinpath(dir, "host")
        target_prefix = joinpath(dir, "target")
        # `libfoo` lives in both prefixes, `libhostonly` only in the host prefix.
        for (prefix, libs) in ((host_prefix, ["foo", "hostonly"]), (target_prefix, ["foo"]))
            mkpath(joinpath(prefix, "lib"))
            mkpath(joinpath(prefix, "include"))
            for lib in libs
                touch(joinpath(prefix, "lib", "lib$(lib).so"))
                touch(joinpath(prefix, "include", "$(lib).h"))
            end
        end

        project_dir = joinpath(dir, "project")
        mkpath(project_dir)
        write(joinpath(project_dir, "CMakeLists.txt"), """
        cmake_minimum_required(VERSION 3.23)
        project(search_paths C)
        list(APPEND CMAKE_SYSTEM_PREFIX_PATH "$(host_prefix)")
        find_library(FOO_LIB foo)
        find_path(FOO_INC foo.h)
        find_library(HOSTONLY_LIB hostonly)
        foreach(var FOO_LIB FOO_INC HOSTONLY_LIB)
            message(STATUS "SEARCH_PATHS \${var}=\${\${var}}")
        endforeach()
        """)

        function configure(cmake_toolchain)
            toolchains = [
                CToolchain(platform; use_ccache=false),
                HostToolsToolchain(platform),
                cmake_toolchain,
            ]
            found = Dict{String,String}()
            with_toolchains(toolchains) do prefix, env
                mktempdir() do build_dir
                    p, output = capture_output(setenv(`bash -c "\$CMAKE -B$(build_dir) -S$(project_dir)"`, env))
                    if !success(p)
                        println(output)
                    end
                    @test success(p)
                    for m in eachmatch(r"SEARCH_PATHS (\w+)=(.*)", output)
                        found[m[1]] = strip(m[2])
                    end
                end
            end
            return found
        end

        # The target toolchain finds `libfoo` in the target prefix, and does not
        # fall back to the host prefix for `libhostonly`.
        found = configure(CMakeToolchain(platform;
            prefix_paths=[target_prefix],
            ignore_prefix_paths=[host_prefix],
        ))
        @test found["FOO_LIB"] == joinpath(target_prefix, "lib", "libfoo.so")
        @test found["FOO_INC"] == joinpath(target_prefix, "include")
        @test found["HOSTONLY_LIB"] == "HOSTONLY_LIB-NOTFOUND"

        # The host toolchain still finds everything in the host prefix.
        found = configure(CMakeToolchain(platform; prefix_paths=[host_prefix]))
        @test found["FOO_LIB"] == joinpath(host_prefix, "lib", "libfoo.so")
        @test found["FOO_INC"] == joinpath(host_prefix, "include")
        @test found["HOSTONLY_LIB"] == joinpath(host_prefix, "lib", "libhostonly.so")
    end

    # The generated toolchain file, and thereby its cache key, depends on the prefixes.
    plain = CMakeToolchain(platform)
    searching = CMakeToolchain(platform; prefix_paths=["/target"], ignore_prefix_paths=["/usr/local"])
    toolchain_file(t) = sprint(io -> BinaryBuilderToolchains.generate_cmake_toolchain_file(t, io))
    @test !occursin("CMAKE_SYSTEM_IGNORE_PREFIX_PATH", toolchain_file(plain))
    @test occursin("list(PREPEND CMAKE_SYSTEM_PREFIX_PATH \"/target\")", toolchain_file(searching))
    @test occursin("list(APPEND CMAKE_SYSTEM_IGNORE_PREFIX_PATH \"/usr/local\")", toolchain_file(searching))
    cache_key(t) = last(toolchain_sources(t)).name_hash
    @test cache_key(plain) != cache_key(searching)
    @test cache_key(searching) != cache_key(CMakeToolchain(platform; prefix_paths=["/target"]))
end
