# Included by `runtests.jl` into a module that has already loaded `common.jl`.

@testset "CToolchain" begin
    # A sanitized target builds with clang against the uninstrumented libc, crt objects and
    # support libraries of the untagged target and compiler-rt's sanitizer runtime, but
    # needs C++ runtimes built for that platform
    @testset "strict tags" begin
        sanitized_target = deepcopy(HostPlatform())
        sanitized_target["sanitize"] = "memory"
        sanitized_cp = CrossPlatform(BBHostPlatform() => sanitized_target)
        @test_throws ArgumentError CToolchain(sanitized_cp; use_ccache=false, vendor=:gcc)
        @test_throws ArgumentError CToolchain(sanitized_cp; use_ccache=false, vendor=:gcc_bootstrap)

        needs_sanitized_build = ("Clang_jll", "libLLVM_jll", "libstdcxx_jll", "LLVMLibcxx_jll", "LLVMLibunwind_jll")
        for config in (Dict(), Dict(:compiler_runtime => :compiler_rt, :cxx_runtime => :libcxx), Dict(:cxx_runtime => :unsanitized_libstdcxx))
            sanitized = CToolchain(sanitized_cp; use_ccache=false, config...)
            @test BinaryBuilderToolchains.get_vendor(sanitized) == :clang
            for jll in sanitized.deps
                unsanitized = jll.package.name == "libstdcxx_jll" && get(config, :cxx_runtime, :auto) == :unsanitized_libstdcxx
                @test jll.exempt_from_strict_tags == (unsanitized || jll.package.name ∉ needs_sanitized_build)
            end
            if !isdefined(Base.BinaryPlatforms, :strict_presence_tags)
                # This Julia's platform matching would pick uninstrumented artifacts
                @test_throws r"needs a Julia whose platform matching implements strict tags" prepare(sanitized.deps)
                continue
            end
            prepare(sanitized.deps)
            compiler_rt = only(filter(j -> j.package.name == "LLVMCompilerRT_jll", sanitized.deps))
            @test any(isfile(joinpath(path, "lib", "linux", "libclang_rt.msan-x86_64.a")) for path in compiler_rt.artifact_paths)

            # The C++ runtime is instrumented (it calls into the msan runtime) unless
            # `:unsanitized_libstdcxx` was asked for.
            cxx_jll, cxx_lib = if get(config, :cxx_runtime, :auto) == :libcxx
                "LLVMLibcxx_jll", "libc++.so.1"
            else
                "libstdcxx_jll", "libstdc++.so.6"
            end
            cxx_paths = only(filter(j -> j.package.name == cxx_jll, sanitized.deps)).artifact_paths
            cxx_libs = String[]
            for path in cxx_paths, (root, _, files) in walkdir(path)
                append!(cxx_libs, joinpath.(root, filter(==(cxx_lib), files)))
            end
            @test !isempty(cxx_libs)
            instrumented = get(config, :cxx_runtime, :auto) != :unsanitized_libstdcxx
            @test all(occursin("__msan_", read(lib, String)) == instrumented for lib in cxx_libs)
        end
    end
end
