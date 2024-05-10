using Test, BinaryBuilderAuditor, Base.BinaryPlatforms
using BinaryBuilderAuditor: absolute_to_relative_symlinks!

@testset "absolute_to_relative_symlinks" begin
    mktempdir() do src_dir
        touch(joinpath(src_dir, "target"))
        # Create within-prefix absolute symlink
        symlink(joinpath(src_dir, "target"), joinpath(src_dir, "in_prefix_symlink"))
        # Create outside-of-prefix absolute symlink
        symlink(tempdir(), joinpath(src_dir, "out_of_prefix_symlink"))
        # Create already-relative symlink
        symlink("target", joinpath(src_dir, "relative_symlink"))

        # Copy `src_dir` to `dest_dir`, then fixup the symlinks:
        mktempdir() do dest_dir
            cp(src_dir, dest_dir; force=true, follow_symlinks=false)
            scan = scan_files(dest_dir, HostPlatform(); prefix_alias=src_dir)
            @test "in_prefix_symlink" ∈ keys(scan.symlinks)

            absolute_to_relative_symlinks!(scan, src_dir; verbose=true)

            @test readlink(joinpath(dest_dir, "in_prefix_symlink")) == "target"
            @test readlink(joinpath(dest_dir, "relative_symlink")) == "target"
            @test readlink(joinpath(dest_dir, "out_of_prefix_symlink")) == "/tmp"
        end
    end
end
