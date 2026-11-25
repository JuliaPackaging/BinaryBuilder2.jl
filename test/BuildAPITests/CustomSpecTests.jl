using BinaryBuilder2, Test
using BinaryBuilder2: get_default_target_spec, get_target_spec_by_name, BuildTargetSpec, ExtractSpec, get_package_result

if !isdefined(@__MODULE__, :TestingUtils)
    include(joinpath(pkgdir(BinaryBuilder2), "test", "TestingUtils.jl"))
end

# Make a test where we fake out building cross-compilers
# with target JLLs and such to ensure that we can adjust the
# output platforms as necessary
@testset "Custom Specs" begin
    meta = BuildMeta(;verbose=true, debug_modes=["build-error", "extract-error"])
    build_tarballs(;
        meta,
        src_name = "libcxxstring",
        src_version = v"1.2.3",
        sources = [cxx_string_abi_source],
        script = raw"""
        cd 02_cxx_string_abi

        # First, build it for "host" (which is the default, in this case)
        make libstring
        mkdir -p ${shlibdir}
        cp build/*.so ${shlibdir}/
        mkdir -p ${includedir}
        cp libstring.h ${includedir}/

        # Next, build it for `target`:
        make clean
        make libstring CC=${TARGET_CC} CXX=${TARGET_CXX}
        mkdir -p ${target_shlibdir}
        cp build/*.so ${target_shlibdir}/
        mkdir -p ${target_includedir}
        cp libstring.h ${target_includedir}/

        # Finally, put something into `build`'s prefix:
        mkdir -p ${build_prefix}/src
        cp libstring.cpp libstring.h ${build_prefix}/src

        # Each spec's `pkg-config` only finds the `.pc` files in that spec's prefix
        for spec in build host target; do
            prefix_var="${spec}_prefix"
            mkdir -p ${!prefix_var}/lib/pkgconfig
            printf 'Name: %s\nDescription: %s\nVersion: 1.0\n' ${spec} ${spec} > ${!prefix_var}/lib/pkgconfig/pc_${spec}.pc
        done
        for pc in "BUILD_PKG_CONFIG build" "PKG_CONFIG host" "HOST_PKG_CONFIG host" "TARGET_PKG_CONFIG target"; do
            read pc_var spec <<<"${pc}"
            for other in build host target; do
                if ${!pc_var} --exists pc_${other}; then found=${other}; else found=""; fi
                if [[ ( "${other}" == "${spec}" && -z "${found}" ) || ( "${other}" != "${spec}" && -n "${found}" ) ]]; then
                    echo "\$${pc_var} (${!pc_var}) finding pc_${other}: '${found}'" >&2
                    exit 1
                fi
            done
        done
        rm -rf ${build_prefix}/lib/pkgconfig ${host_prefix}/lib/pkgconfig ${target_prefix}/lib/pkgconfig

        for install_prefix in ${build_prefix} ${host_prefix} ${target_prefix}; do
            mkdir -p ${install_prefix}/share/licenses/libstring
            echo "public domain" > ${install_prefix}/share/licenses/libstring/LICENSE.md
        done
        """,
        platforms = [CrossPlatform(native_linux => alien_linux)],
        # Skip `rpaths_consistent!` for the extraction that runs on the cross platform only
        audit_config = p -> isa(p, CrossPlatform) ? AuditConfig(; rpaths_consistent = false) : AuditConfig(),

        # Create a BuildTargetSpec generator that sets up a cross-compiler
        # `build`/`host`/`target` set of CToolchains:
        build_spec_generator = (host, platform) -> begin
            return [
                BuildTargetSpec(
                    "build",
                    CrossPlatform(host => host),
                    [CToolchain(;vendor=:bootstrap), HostToolsToolchain()],
                    [],
                    [],
                    Set([:native]),
                ),
                BuildTargetSpec(
                    "host",
                    CrossPlatform(host => platform.host),
                    [CToolchain(;vendor=:bootstrap)],
                    [],
                    [],
                    Set([:default]),
                ),
                BuildTargetSpec(
                    "target",
                    CrossPlatform(host => platform.target),
                    [CToolchain(;vendor=:bootstrap)],
                    [],
                    [],
                    Set([]),
                ),
            ]
        end,
        # Create an extraction
        extract_spec_generator = (build_config, platform) -> begin
            return ExtractSpec[
                ExtractSpec(
                    raw"extract ${host_prefix}/**",
                    [LibraryProduct("libstring", :libstring)],
                    get_default_target_spec(build_config);
                    jll_name = "libcxxstring_cross",
                    platform,
                ),
                ExtractSpec(
                    raw"extract ${target_prefix}/**",
                    [LibraryProduct("libstring", :libstring)],
                    get_target_spec_by_name(build_config, "target");
                    jll_name = "libcxxstring_target",
                ),
                ExtractSpec(
                    raw"extract ${build_prefix}/**",
                    [
                        FileProduct("src/libstring.h", :libstring_h),
                        FileProduct("src/libstring.cpp", :libstring_cpp),
                    ],
                    get_target_spec_by_name(build_config, "build");
                    jll_name = "libcxxstring_source",
                    platform=AnyPlatform(),
                    audit_config = AuditConfig(; licenses_present = false),
                ),
            ]
        end,
    )

    # Ensure that each extraction targeted the correct platform
    target_jll = get_package_result(meta, "libcxxstring_target")
    target_extraction = target_jll.config.named_extractions["libcxxstring_target"][1]
    @test target_extraction.config.platform == alien_linux

    cross_jll = get_package_result(meta, "libcxxstring_cross")
    cross_extraction = cross_jll.config.named_extractions["libcxxstring_cross"][1]
    @test cross_extraction.config.platform == CrossPlatform(native_linux => alien_linux)

    source_jll = get_package_result(meta, "libcxxstring_source")
    source_extraction = source_jll.config.named_extractions["libcxxstring_source"][1]
    @test source_extraction.config.platform == AnyPlatform()

    # The recipe's `audit_config` is resolved per extraction platform, and an
    # `ExtractSpec`'s own `audit_config` overrides it
    skipped(extraction, pass_name) = any(r.status == :skipped for r in get(extraction.audit_result.pass_results, pass_name, []))
    @test cross_extraction.config.audit_config == AuditConfig(; rpaths_consistent = false)
    @test skipped(cross_extraction, "rpaths_consistent!")
    @test target_extraction.config.audit_config == AuditConfig()
    @test !skipped(target_extraction, "rpaths_consistent!")
    @test source_extraction.config.audit_config == AuditConfig(; licenses_present = false)
    @test skipped(source_extraction, "licenses_present")
end
