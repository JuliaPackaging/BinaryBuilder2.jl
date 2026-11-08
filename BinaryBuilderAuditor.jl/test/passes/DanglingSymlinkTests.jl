using Test, BinaryBuilderAuditor, Base.BinaryPlatforms
using BinaryBuilderAuditor: dangling_symlinks

function dangling_results(prefix::String; prefix_alias::String = prefix)
    result = AuditResult(scan_files(prefix, HostPlatform()))
    dangling_symlinks(result, prefix_alias)
    return result, Dict(r.identifier => r for r in get(result.pass_results, "dangling_symlinks", PassResult[]))
end

@testset "dangling_symlinks" begin
    mktempdir() do prefix
        mkpath(joinpath(prefix, "lib", "sub"))
        touch(joinpath(prefix, "lib", "libfoo.a"))
        touch(joinpath(prefix, "lib", "sub", "libbar.a"))

        # Valid links: same directory, into a subdirectory, to a directory, via `..`
        symlink("libfoo.a", joinpath(prefix, "lib", "libvalid.a"))
        symlink(joinpath("sub", "libbar.a"), joinpath(prefix, "lib", "libbar.a"))
        symlink("sub", joinpath(prefix, "lib", "subdir_link"))
        symlink(joinpath("..", "libfoo.a"), joinpath(prefix, "lib", "sub", "libup.a"))
        # Valid chain through a directory symlink
        symlink(joinpath("subdir_link", "libbar.a"), joinpath(prefix, "lib", "libchain.a"))
        # Absolute links outside of the prefix are left to other checks
        symlink("/nonexistent/system/path", joinpath(prefix, "lib", "libsystem.a"))

        result, rs = dangling_results(prefix)
        @test isempty(rs)
        @test success(result)

        # The FreeBSDSysroot case: `libpthread.a -> libthr.a` without `libthr.a`
        symlink("libthr.a", joinpath(prefix, "lib", "libpthread.a"))
        # Dangling link into a subdirectory
        symlink(joinpath("sub", "libmissing.a"), joinpath(prefix, "lib", "libmissing.a"))
        # Dangling link through a nonexistent subdirectory
        symlink(joinpath("nosuchdir", "libbaz.a"), joinpath(prefix, "lib", "libbaz.a"))
        # Directory symlink to a nonexistent directory
        symlink("nosuchdir", joinpath(prefix, "lib", "dangling_dir"))
        # Link whose target is itself a dangling link
        symlink("libpthread.a", joinpath(prefix, "lib", "libpthread_chain.a"))
        # Symlink loop
        symlink("libloop2.a", joinpath(prefix, "lib", "libloop1.a"))
        symlink("libloop1.a", joinpath(prefix, "lib", "libloop2.a"))

        # Relative link that climbs out of the prefix to a file that exists
        result, rs = mktempdir() do outside
            touch(joinpath(outside, "libescape.a"))
            symlink(
                relpath(joinpath(realpath(outside), "libescape.a"), realpath(joinpath(prefix, "lib"))),
                joinpath(prefix, "lib", "libescape.a"),
            )
            dangling_results(prefix)
        end
        @test !success(result)
        @test all(r.status == :fail for r in values(rs))
        @test Set(keys(rs)) == Set(joinpath("lib", f) for f in [
            "libpthread.a", "libmissing.a", "libbaz.a", "dangling_dir",
            "libpthread_chain.a", "libescape.a", "libloop1.a", "libloop2.a",
        ])
        @test occursin("dangling", rs[joinpath("lib", "libpthread.a")].message)
        @test occursin("libthr.a", rs[joinpath("lib", "libpthread.a")].message)
        @test occursin("outside", rs[joinpath("lib", "libescape.a")].message)
        @test occursin("loop", rs[joinpath("lib", "libloop1.a")].message)
    end

    # Absolute links into the prefix alias are checked against the prefix
    mktempdir() do prefix
        alias = "/workspace/destdir"
        mkpath(joinpath(prefix, "lib"))
        touch(joinpath(prefix, "lib", "libfoo.a"))
        symlink(joinpath(alias, "lib", "libfoo.a"), joinpath(prefix, "lib", "libvalid.a"))
        symlink(joinpath(alias, "lib", "libthr.a"), joinpath(prefix, "lib", "libpthread.a"))

        result, rs = dangling_results(prefix; prefix_alias=alias)
        @test Set(keys(rs)) == Set([joinpath("lib", "libpthread.a")])
        @test !success(result)
    end

    # `audit!()` runs the pass and fails on dangling links
    mktempdir() do prefix
        mkpath(joinpath(prefix, "share", "licenses", "Foo"))
        touch(joinpath(prefix, "share", "licenses", "Foo", "LICENSE"))
        mkpath(joinpath(prefix, "lib"))
        touch(joinpath(prefix, "lib", "libfoo.a"))
        symlink("libfoo.a", joinpath(prefix, "lib", "libvalid.a"))
        @test success(audit!(prefix, AbstractProduct[], AuditInfo(); readonly=true))

        symlink("libthr.a", joinpath(prefix, "lib", "libpthread.a"))
        result = audit!(prefix, AbstractProduct[], AuditInfo(); readonly=true)
        @test !success(result)
        @test only(result.pass_results["dangling_symlinks"]).identifier == joinpath("lib", "libpthread.a")
    end
end
