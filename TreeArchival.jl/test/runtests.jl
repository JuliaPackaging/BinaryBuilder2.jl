using TreeArchival, Test, Pkg

@testset "TreeArchival" begin
    mktempdir() do src_dir
        # Generate sample file tree
        open(joinpath(src_dir, "hello"), write=true) do io
            println(io, "there")
        end
        chmod(joinpath(src_dir, "hello"), 0o644)
        mkdir(joinpath(src_dir, "sub"))
        open(joinpath(src_dir, "sub", "zero"), write=true) do io
            println(io, "so chilly")
        end
        chmod(joinpath(src_dir, "sub", "zero"), 0o644)
        symlink(joinpath("sub", "zero"), joinpath(src_dir, "linky"))

        # Calculate its treehash
        src_treehash = Pkg.GitTools.tree_hash(src_dir)

        # For each compressor, create an archive of that type, then decompress it
        for compressor in keys(TreeArchival.compressor_magic_bytes)
            # Skip `.zip`, we refuse to create these
            if compressor == "zip"
                continue
            end

            mktempdir() do archive_dir
                archive_path = joinpath(archive_dir, "test.$(compressor)")
                archive(src_dir, archive_path, compressor)
                @test isfile(archive_path)

                # Test that we can in-situ treehash:
                @test treehash(archive_path) == src_treehash

                # Ensure that we unpack properly
                mktempdir() do out_dir
                    unarchive(archive_path, out_dir)
                    @test Pkg.GitTools.tree_hash(out_dir) == src_treehash
                end
            end
        end
    end
end
