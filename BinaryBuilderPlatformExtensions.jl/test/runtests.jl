using BinaryBuilderPlatformExtensions, Test, Base.BinaryPlatforms, Artifacts
@testset "CrossPlatform" begin
    @testset "Basic properties" begin
        cross_hosts = [
            Platform("x86_64", "linux"),
            Platform("aarch64", "macos"),
            AnyPlatform(),
        ]
        for host in cross_hosts
            for target in [cross_hosts...,
                           Platform("i686", "windows"),
                           Platform("ppc64le", "linux"; libgfortran_version=v"3"),
                           Platform("riscv64", "linux"),
                           AnyPlatform()]
                cp = CrossPlatform(host => target)

                # Early-exit if we're dealing with AnyPlatform's on both sides
                if isa(host, AnyPlatform) && isa(target, AnyPlatform)
                    @test isa(cp, AnyPlatform)
                    continue
                end

                @test isa(cp, CrossPlatform)
                @test cp.host == host
                @test cp.target == target

                if !isa(cp.host, AnyPlatform) && !isa(cp.target, AnyPlatform)
                    @test cp["target_arch"] == target["arch"]
                    @test cp["target_os"] == target["os"]
                    if target["os"] == "linux"
                        @test cp["target_libc"] == target["libc"]
                    else
                        @test !haskey(cp, "target_libc")
                    end
                elseif !isa(cp.host, AnyPlatform) && isa(cp.target, AnyPlatform)
                    @test cp["target"] == "any"
                elseif isa(cp.host, AnyPlatform) && !isa(cp.target, AnyPlatform)
                    @test !any(startswith.(keys(tags(cp)), Ref("target")))
                end

                # Test our string summary
                @test string(cp) == "CrossPlatform($(cp.host) -> $(cp.target))"

                # Test serialization round-trip
                @test parse(CrossPlatform, triplet(cp)) == cp

                # Test `repr()` round-trip
                @test eval(Meta.parse(repr(cp))) == cp

                # Test packing round-trip
                artifact_dict = Dict()
                Artifacts.pack_platform!(artifact_dict, cp)
                if !isa(cp.target, AnyPlatform) && !isa(cp.host, AnyPlatform)
                    @test haskey(artifact_dict, "target_os")
                end
                if isa(cp.target, AnyPlatform)
                    @test haskey(artifact_dict, "target")
                end
                if isa(cp.host, AnyPlatform)
                    @test haskey(artifact_dict, "host")
                end
                p = Artifacts.unpack_platform(artifact_dict, "artifact_name", "")
                @test CrossPlatform(p) == cp
            end
        end
    end

    @testset "platforms_match" begin
        # Let's test CrossPlatform-to-CrossPlatform comparison first
        # First, we check that blatantly different crosses don't match
        glibc_to_m1 = CrossPlatform(
            Platform("x86_64", "linux"; libc="glibc") => Platform("aarch64", "macos")
        )
        glibc_to_m1_libstdcxx = CrossPlatform(
            Platform("x86_64", "linux"; libc="glibc", libstdcxx_version=v"3.4.29") => Platform("aarch64", "macos")
        )
        musl_to_m1 = CrossPlatform(
            Platform("x86_64", "linux"; libc="musl") => Platform("aarch64", "macos")
        )
        win_to_ppc64le_glibc = CrossPlatform(
            Platform("i686", "windows") =>  Platform("ppc64le", "linux"; libc="glibc")
        )

        # Self-matching always works
        @test platforms_match(glibc_to_m1, glibc_to_m1)
        @test platforms_match(musl_to_m1, musl_to_m1)
        @test platforms_match(win_to_ppc64le_glibc, win_to_ppc64le_glibc)

        # Cross-matching doesn't work for any of these
        @test !platforms_match(glibc_to_m1, musl_to_m1)
        @test !platforms_match(glibc_to_m1, win_to_ppc64le_glibc)
        @test !platforms_match(musl_to_m1, glibc_to_m1)
        @test !platforms_match(musl_to_m1, win_to_ppc64le_glibc)
        @test !platforms_match(win_to_ppc64le_glibc, glibc_to_m1)
        @test !platforms_match(win_to_ppc64le_glibc, musl_to_m1)

        # Next, create a cross that should match a more generic cross-compiler
        glibc_libgfortran_to_m1 = CrossPlatform(
            Platform("x86_64", "linux"; libc="glibc", libgfortran_version=v"5"),
            Platform("aarch64", "macos")
        )
        glibc_to_m1_osver = CrossPlatform(
            Platform("x86_64", "linux"; libc="glibc"),
            Platform("aarch64", "macos"; os_version=v"20")
        )
        glibc_libgfortran_to_m1_osver = CrossPlatform(
            Platform("x86_64", "linux"; libc="glibc", libgfortran_version=v"5"),
            Platform("aarch64", "macos"; os_version=v"20"),
        )

        # All these crosses should be compatible, as they are all
        # valid subsets of eachother
        compatible_cps = [
            glibc_to_m1,
            glibc_to_m1_osver,
            glibc_libgfortran_to_m1,
            glibc_libgfortran_to_m1_osver,
        ]
        for a in compatible_cps, b in compatible_cps
            @test platforms_match(a, b)
        end

        # Whereas none of these should be compatible
        incompatible_cps = [
            musl_to_m1,
            win_to_ppc64le_glibc,
        ]
        for a in incompatible_cps, b in compatible_cps
            @test !platforms_match(a, b)
            @test !platforms_match(b, a)
        end


        # Next, let's test `CrossPlatform` -> `Platform` compatibility.
        # When comparing a `CrossPlatform` to a `Platform`, we basically
        # just match the `Platform` to the `target` of the `CrossPlatform`,
        # so that by default we are loading in target binaries to compile against.
        win32 = Platform("i686", "windows")
        ppc64le_glibc = Platform("ppc64le", "linux"; libc="glibc")
        x86_64_glibc = Platform("x86_64", "linux"; libc="glibc")
        x86_64_glibc_libstdcxx = Platform("x86_64", "linux"; libc="glibc", libstdcxx_version=v"3.4.30")
        m1 = Platform("aarch64", "macos")
        m1_osver = Platform("aarch64", "macos"; os_version=v"20")
        m1_osver_newer = Platform("aarch64", "macos"; os_version=v"21")

        # Windows targeting glibc should match windows
        @test platforms_match(win_to_ppc64le_glibc, win32)
        @test platforms_match(win32, win_to_ppc64le_glibc)

        # Targeting glibc should not match M1
        @test !platforms_match(win_to_ppc64le_glibc, m1)
        @test !platforms_match(m1, win_to_ppc64le_glibc)

        @test platforms_match(glibc_to_m1, x86_64_glibc)
        @test platforms_match(glibc_to_m1, x86_64_glibc_libstdcxx)
        @test !platforms_match(glibc_to_m1_libstdcxx, x86_64_glibc_libstdcxx)

        # AnyPlatforms should always match everything, as usual
        for cp in [glibc_libgfortran_to_m1_osver, glibc_to_m1, win_to_ppc64le_glibc]
            @test platforms_match(cp, AnyPlatform())
            @test platforms_match(AnyPlatform(), cp)
        end
    end

    # Ensure that platform selection works as expected
    @testset "select_platform" begin
        # When comparing cross platforms, select the one that matches both host and target
        cp = CrossPlatform(Platform("x86_64", "linux") => Platform("aarch64", "macos"))
        artifacts = Dict(
            cp => true,
            CrossPlatform(Platform("x86_64", "linux") => Platform("aarch64", "linux")) => false,
            CrossPlatform(Platform("aarch64", "macos") => Platform("x86_64", "linux")) => false,
            CrossPlatform(Platform("x86_64", "linux")) => false,
            CrossPlatform(Platform("aarch64", "macos")) => false,
        )
        @test select_platform(artifacts, cp)

        # When given bare platforms, choose the one that matches our host
        artifacts = Dict(
            Platform("aarch64", "macos") => false,
            Platform("x86_64", "linux") => true,
            Platform("i686", "windows") => false,
        )
        @test select_platform(artifacts, cp)
    end

    hash_to_sha1(x) = Base.SHA1(vcat(zeros(UInt8, 12), reinterpret(UInt8, [hash(x)])))
    @testset "select_downloadable_artifacts" begin
        # We'll create a little compiler shard test here:
        cp = CrossPlatform(Platform("x86_64", "linux") => Platform("aarch64", "macos"))
        artifact_dict = Dict(
            "GCC_jll" => [],
        )
        gcc_platforms = [
            # GCC is built with a few "native" builds, as well as a few "cross" builds
            CrossPlatform(Platform("x86_64", "linux")),
            CrossPlatform(Platform("aarch64", "linux")),
            CrossPlatform(Platform("x86_64", "linux") => Platform("x86_64", "windows")),
            CrossPlatform(Platform("x86_64", "linux") => Platform("aarch64", "macos")),
        ]
        for gcc_platform in gcc_platforms
            meta = Dict{String,Any}("download" => true, "git-tree-sha1" => hash_to_sha1(triplet(gcc_platform)))
            Artifacts.pack_platform!(meta, gcc_platform)
            push!(artifact_dict["GCC_jll"], meta)
        end

        downloadable_artifacts = select_downloadable_artifacts(artifact_dict, ""; platform=cp)
        @test haskey(downloadable_artifacts, "GCC_jll")
        @test downloadable_artifacts["GCC_jll"]["git-tree-sha1"] == hash_to_sha1(triplet(cp))
        @test CrossPlatform(Artifacts.unpack_platform(downloadable_artifacts["GCC_jll"], "GCC_jll", "")) == cp
    end
end

@testset "macos_version" begin
    @test macos_version(Platform("x86_64", "macos")) === nothing
    @test macos_version(Platform("x86_64", "macos"; os_version="14")) === "10.10"
    @test macos_version(Platform("x86_64", "macos"; os_version="20")) === "11.0"
    for idx in 12:24
        p = Platform("aarch64", "macos"; os_version=string(idx))
        @test macos_version(p) !== nothing
        @test macos_kernel_version(p) == idx
        @test macos_kernel_version(macos_version(p)) == idx
    end
end

@testset "nbits" begin
    for p in [Platform("i686", "linux"), Platform("i686", "windows"), Platform("armv7l", "linux")]
        @test nbits(p) == 32
    end

    for p in [Platform("x86_64", "linux"), Platform("x86_64", "windows"), Platform("aarch64", "linux"),
              Platform("powerpc64le", "linux"), Platform("x86_64", "macos"), Platform("riscv64", "linux")]
        @test nbits(p) == 64
    end

    @test nbits(CrossPlatform(Platform("x86_64", "linux") => Platform("i686", "linux"))) == 32
    @test nbits(AnyPlatform()) == 64
end

@testset "proc_family" begin
    for p in [Platform("x86_64", "linux"), Platform("x86_64", "macos"), Platform("i686", "windows")]
        @test proc_family(p) == "intel"
    end
    for p in [Platform("aarch64", "linux"; libc="musl"), Platform("armv7l", "linux")]
        @test proc_family(p) == "arm"
    end
    @test proc_family(Platform("powerpc64le", "linux")) == "power"
    @test proc_family(Platform("riscv64", "linux")) == "riscv"
    @test proc_family(CrossPlatform(Platform("aarch64", "linux") => Platform("i686", "linux"))) == "intel"
    @test proc_family(AnyPlatform()) == "any"
end

@testset "exeext" begin
    for p in [Platform("x86_64", "linux"), Platform("x86_64", "freebsd"), Platform("powerpc64le", "linux"), Platform("x86_64", "macos")]
        @test exeext(p) == ""
    end
    @test exeext(Platform("x86_64", "windows")) == ".exe"
    @test exeext(Platform("i686", "windows")) == ".exe"
    @test exeext(CrossPlatform(Platform("aarch64", "linux") => Platform("i686", "windows"))) == ".exe"
    @test exeext(AnyPlatform()) == ""
end

@testset "dlext" begin
    @test dlext(Platform("aarch64", "linux")) == ".so"
    @test dlext(Platform("x86_64", "freebsd")) == ".so"
    @test dlext(Platform("x86_64", "macos")) == ".dylib"
    @test dlext(Platform("i686", "windows")) == ".dll"
    @test dlext(CrossPlatform(Platform("aarch64", "linux") => Platform("i686", "windows"))) == ".dll"

    # You shouldn't be creating any dynamic libraries in an `AnyPlatform!`
    @test dlext(AnyPlatform()) == ""
end

@testset "march flags" begin
    # test one that is common between gcc and clang
    @test get_march_flags("x86_64", "avx", "gcc") == ["-march=sandybridge", "-mtune=sandybridge"]

    # Test one that is different between gcc and clang
    @test get_march_flags("aarch64", "apple_m1", "gcc") == ["-march=armv8.5-a+aes+sha2+sha3+fp16fml+fp16+rcpc+dotprod", "-mcpu=cortex-a76"]
    @test get_march_flags("aarch64", "apple_m1", "clang") == ["-mcpu=apple-m1"]

    for compiler in ("gcc", "clang")
        # Make sure we get the right base microarchitecture for all compilers
        @test get_march_flags("aarch64", nothing, compiler) == get_march_flags("aarch64", "armv8_0",  compiler)
        @test get_march_flags("armv7l",  nothing, compiler) == get_march_flags("armv7l",  "armv7l",   compiler)
        @test get_march_flags("i686",    nothing, compiler) == get_march_flags("i686",    "pentium4", compiler)
        @test get_march_flags("x86_64",  nothing, compiler) == get_march_flags("x86_64",  "x86_64",   compiler)
    end

    # Get all architectures and all microarchitectures for the different architectures
    @test sort(get_all_arch_names()) == ["aarch64", "armv6l", "armv7l", "i686", "powerpc64le", "riscv64", "x86_64"]
    @test sort(get_all_march_names("x86_64")) == ["avx", "avx2", "avx512", "x86_64"]
    @test sort(get_all_march_names("armv7l")) == ["armv7l", "neonvfpv4"]
end
