using BB2, Test, Pkg

@testset "Compressors" begin
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
        for compressor in keys(BB2.Compressors.compressor_magic_bytes)
            mktempdir() do archive_dir
                archive_path = joinpath(archive_dir, "test.archive")
                BB2.Compressors.compress(src_dir, archive_path, compressor)
                @test isfile(archive_path)

                mktempdir() do out_dir
                    BB2.Compressors.decompress(archive_path, out_dir)

                    if compressor == "zip"
                        # If we're dealing with a `zip` file, we need to set the permissions since
                        # they're not saved and can be randomized by `umask`, etc...
                        chmod(joinpath(out_dir, "hello"), 0o644)
                        chmod(joinpath(out_dir, "sub", "zero"), 0o644)
                    end

                    # Ensure that we roundtrip properly
                    @test Pkg.GitTools.tree_hash(out_dir) == src_treehash
                end
            end
        end
    end
end
