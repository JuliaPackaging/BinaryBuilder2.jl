using Test, BinaryBuilderAuditor, Base.BinaryPlatforms
using BinaryBuilderAuditor: relocate_pkgconfig_files!

@testset "relocate_pkgconfig_files!" begin
    alias = "/workspace/destdir/target-x86_64-linux-gnu"
    mktempdir() do prefix
        pc(path) = joinpath(prefix, path)
        mkpath(pc("lib/pkgconfig"))
        mkpath(pc("share/pkgconfig"))

        # zlib's CMake-generated file
        write(pc("lib/pkgconfig/zlib.pc"), """
        prefix=$(alias)
        exec_prefix=\${prefix}
        libdir=\${exec_prefix}/lib
        Libs: -L\${libdir} -lz
        """)
        # Paths written out in full
        write(pc("share/pkgconfig/foo.pc"), """
        libdir=$(alias)/lib
        Libs: -L$(alias)/lib -lfoo
        """)
        # Neither the system nor a path that merely starts with `alias` is touched
        write(pc("lib/pkgconfig/sys.pc"), "prefix=/usr\nother=$(alias)-other/lib\n")
        # Symlinks are left alone; their target is relocated
        symlink("zlib.pc", pc("lib/pkgconfig/libz.pc"))

        result = AuditResult(scan_files(prefix, HostPlatform(); prefix_alias=alias))
        relocate_pkgconfig_files!(result, alias)
        @test success(result)
        @test sort([r.identifier for r in result.pass_results["relocate_pkgconfig_files!"]]) ==
              [joinpath("lib", "pkgconfig", "zlib.pc"), joinpath("share", "pkgconfig", "foo.pc")]

        @test read(pc("lib/pkgconfig/zlib.pc"), String) == """
        prefix=\${pcfiledir}/../..
        exec_prefix=\${prefix}
        libdir=\${exec_prefix}/lib
        Libs: -L\${libdir} -lz
        """
        @test read(pc("share/pkgconfig/foo.pc"), String) == """
        libdir=\${pcfiledir}/../../lib
        Libs: -L\${pcfiledir}/../../lib -lfoo
        """
        @test read(pc("lib/pkgconfig/sys.pc"), String) == "prefix=/usr\nother=$(alias)-other/lib\n"
        @test islink(pc("lib/pkgconfig/libz.pc"))
    end

    # `audit!()` relocates pkg-config files, unless `readonly`
    mktempdir() do prefix
        mkpath(joinpath(prefix, "share", "licenses", "Foo"))
        touch(joinpath(prefix, "share", "licenses", "Foo", "LICENSE"))
        mkpath(joinpath(prefix, "lib", "pkgconfig"))
        foo_pc = joinpath(prefix, "lib", "pkgconfig", "foo.pc")
        write(foo_pc, "prefix=$(alias)\n")

        @test success(audit!(prefix, AbstractProduct[], AuditInfo(); prefix_alias=alias, readonly=true))
        @test read(foo_pc, String) == "prefix=$(alias)\n"

        @test success(audit!(prefix, AbstractProduct[], AuditInfo(); prefix_alias=alias))
        @test read(foo_pc, String) == "prefix=\${pcfiledir}/../..\n"
    end
end
