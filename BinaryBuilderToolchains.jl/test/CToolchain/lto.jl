# Included by `runtests.jl` into a module that has already loaded `common.jl`.

@testset "CToolchain" begin
    # clang links with `lld` by default, and LTO links use it even with `linker = :ld`, as
    # `lld` is the only linker we ship that reads LLVM bitcode on every target.
    @testset "clang lld and LTO" begin
        lto_targets = [
            (HostPlatform(), :clang, :auto),
            (HostPlatform(), :clang, :ld),
            (HostPlatform(), :clang_bootstrap, :auto),
            (Platform("aarch64", "linux"), :clang, :ld),
            (Platform("x86_64", "linux"; libc="musl"), :clang, :auto),
            (Platform("x86_64", "freebsd"; os_version="14.1"), :clang, :auto),
            (Platform("aarch64", "macos"; os_version="20"), :clang, :auto),
            (Platform("x86_64", "macos"; os_version="20"), :clang, :ld),
            (Platform("x86_64", "windows"), :clang, :auto),
            (Platform("i686", "windows"), :clang, :ld),
        ]
        if !bootstrap_vendors_available()
            filter!(((_, vendor, _),) -> vendor ∉ (:gcc_bootstrap, :clang_bootstrap), lto_targets)
        end
        for (target, vendor, linker) in lto_targets
            target_cp = CrossPlatform(BBHostPlatform() => target)
            native = target == HostPlatform()
            toolchain = CToolchain(target_cp; vendor, linker, use_ccache=false)
            with_toolchains([toolchain, htt_toolchain]) do prefix, env
                @testset "$(triplet(target)) - $(vendor) - $(linker)" begin
                    cc = joinpath(prefix, "wrappers", env["CC"])
                    cxx = joinpath(prefix, "wrappers", env["CXX"])
                    mktempdir() do dir
                        write(joinpath(dir, "foo.c"), "int foo(void) { return 42; }\n")
                        write(joinpath(dir, "main.c"), "int foo(void);\nint main(void) { return foo() - 42; }\n")
                        write(joinpath(dir, "hello.cpp"), "#include <iostream>\nint main() { std::cout << 42 << std::endl; }\n")

                        function lto_link(cmd)
                            p, output = capture_output(setenv(cmd, env; dir))
                            if !success(p)
                                println(output)
                            end
                            return success(p)
                        end

                        # A link selects `lld` when `linker` resolves to it, and an LTO link
                        # always does, leaving a user's choice of linker alone.
                        uses_lld(output) = occursin(r"ld(64)?\.lld\"", output)
                        p, output = capture_output(setenv(`$(cc) -\#\#\# foo.c main.c -o main`, env; dir))
                        @test success(p)
                        @test uses_lld(output) == (linker == :auto)
                        p, output = capture_output(setenv(`$(cc) -\#\#\# -flto foo.c main.c -o main`, env; dir))
                        @test success(p)
                        @test uses_lld(output)
                        p, output = capture_output(setenv(`$(cc) -\#\#\# -flto -fuse-ld=bfd foo.c main.c -o main`, env; dir))
                        @test !uses_lld(output)

                        # Both `ld64` and `ld64.lld` get the deployment target and SDK version
                        # with `-platform_version`; `ld64.lld` doesn't implement `-sdk_version`.
                        if Sys.isapple(target)
                            p, output = capture_output(setenv(`$(cc) -\#\#\# foo.c main.c -o main`, env; dir))
                            @test occursin("\"-platform_version\"", output)
                            @test !occursin("sdk_version", output)
                            @test !occursin("macosx_version_min", output)
                            p, output = capture_output(setenv(`$(cc) -O2 -flto foo.c main.c -o main`, env; dir))
                            @test success(p)
                            @test !occursin("sdk_version", output)
                        end

                        # Plain C and C++ links
                        @test lto_link(`$(cc) -O2 foo.c main.c -o main_plain`)
                        @test lto_link(`$(cxx) -O2 hello.cpp -o hello_plain`)
                        if Sys.isapple(target)
                            # The binary records the deployment target as both its minimum
                            # macOS version and its SDK version.
                            p, output = capture_output(setenv(`$(env["OBJDUMP"]) --macho --private-headers main_plain`, env; dir))
                            mver = BinaryBuilderToolchains.macos_version(BinaryBuilderToolchains.macos_target_kernel_version(target))
                            @test occursin(Regex("\\bsdk $(mver)\\b"), output)
                            @test occursin(Regex("\\bminos $(mver)\\b"), output)
                        end
                        @test lto_link(`$(cc) -O2 -shared -fPIC foo.c -o libplain.$(platform_dlext(target))`)

                        # Full and thin LTO executables, C and C++
                        @test lto_link(`$(cc) -O2 -flto foo.c main.c -o main_full`)
                        @test lto_link(`$(cc) -O2 -flto=thin foo.c main.c -o main_thin`)
                        @test lto_link(`$(cxx) -O2 -flto hello.cpp -o hello`)

                        # A shared library built from bitcode still defines its symbols
                        libfoo = "libfoo.$(platform_dlext(target))"
                        @test lto_link(`$(cc) -O2 -flto -shared -fPIC foo.c -o $(libfoo)`)
                        p, output = capture_output(setenv(`$(env["NM"]) $(libfoo)`, env; dir))
                        @test occursin(r"\b_?foo\b", output)

                        # Bitcode objects in a static archive, whose index must list their
                        # symbols (`lld` for COFF looks symbols up in it), whether `ar` or
                        # `ranlib` writes it.  `nm` reads bitcode too.
                        @test lto_link(`$(cc) -O2 -flto -c foo.c -o foo.o`)
                        p, output = capture_output(setenv(`$(env["NM"]) foo.o`, env; dir))
                        @test success(p)
                        @test occursin(r"\b_?foo\b", output)
                        @test lto_link(`$(env["AR"]) rcs libfoo.a foo.o`)
                        @test lto_link(`$(cc) -O2 -flto main.c libfoo.a -o main_ar`)
                        @test lto_link(`$(env["AR"]) cr libfoo_ranlib.a foo.o`)
                        @test lto_link(`$(env["RANLIB"]) libfoo_ranlib.a`)
                        @test lto_link(`$(cc) -O2 -flto main.c libfoo_ranlib.a -o main_ranlib`)

                        if Sys.islinux(target) || Sys.isfreebsd(target)
                            # A version script may name symbols that the link doesn't define
                            write(joinpath(dir, "foo.map"), "FOO_1 { global: foo; missing_symbol; local: *; };\n")
                            @test lto_link(`$(cc) -O2 -shared -fPIC -Wl,--version-script=foo.map foo.c -o libfoo_versioned.so`)
                        end

                        if native
                            for exe in ("main_plain", "hello_plain", "main_full", "main_thin", "main_ar", "main_ranlib", "hello")
                                @test success(setenv(`./$(exe)`, env; dir))
                            end
                        end
                    end
                end
            end
        end
    end
end
