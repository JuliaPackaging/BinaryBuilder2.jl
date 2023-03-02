using TreeArchival, Test

@testset "TreeHashing" begin
    tree_hash_str(args...; kwargs...) = bytes2hex(tree_hash(args...; kwargs...))
    mktempdir() do dir
        # test "well known" empty tree hash
        @test "4b825dc642cb6eb9a060e54bf8d69288fbee4904" == tree_hash_str(dir)
        # create a text file
        file = joinpath(dir, "hello.txt")
        open(file, write=true) do io
            println(io, "Hello, world.")
        end
        chmod(file, 0o644)
        # reference hash generated with command-line git
        @test "0a890bd10328d68f6d85efd2535e3a4c588ee8e6" == tree_hash_str(dir)
        # test with various executable bits set
        chmod(file, 0o645) # other x bit doesn't matter
        @test "0a890bd10328d68f6d85efd2535e3a4c588ee8e6" == tree_hash_str(dir)
        chmod(file, 0o654) # group x bit doesn't matter
        @test "0a890bd10328d68f6d85efd2535e3a4c588ee8e6" == tree_hash_str(dir)
        chmod(file, 0o744) # user x bit matters
        @test "952cfce0fb589c02736482fa75f9f9bb492242f8" == tree_hash_str(dir)
    end

    # Test for empty directory hashing
    mktempdir() do dir
        @test "4b825dc642cb6eb9a060e54bf8d69288fbee4904" == tree_hash_str(dir)

        # Directories containing other empty directories are also empty
        mkdir(joinpath(dir, "foo"))
        mkdir(joinpath(dir, "foo", "bar"))
        @test "4b825dc642cb6eb9a060e54bf8d69288fbee4904" == tree_hash_str(dir)

        # Directories containing symlinks (even if they point to other directories)
        # are NOT empty:
        symlink("bar", joinpath(dir, "foo", "bar_link"))
        @test "8bc80be82b2ae4bd69f50a1a077a81b8678c9024" == tree_hash_str(dir)
    end

    # Test for directory with .git hashing
    mktempdir() do dir
        function generate_fake_package(dir::String; with_git_dir::Bool = false)
            mkdir(joinpath(dir))
            open(joinpath(dir, "Project.toml"); write=true) do io
                println(io, "name=\"Foo\"")
                println(io, "version=\"1.0.0\"")
            end
            chmod(joinpath(dir, "Project.toml"), 0o664)

            mkdir(joinpath(dir, "src"))
            open(joinpath(dir, "src", "Foo.jl"); write=true) do io
                print(io, """
                module Foo
                include("foo_utils.jl")
                include("bar/bar.jl")
                end # module
                """)
            end
            chmod(joinpath(dir, "src", "Foo.jl"), 0o664)

            open(joinpath(dir, "src", "foo_utils.jl"); write=true) do io
                print(io, """
                foo(::Int) = 1
                """)
            end
            chmod(joinpath(dir, "src", "foo_utils.jl"), 0o664)

            mkdir(joinpath(dir, "src", "bar"))
            open(joinpath(dir, "src", "bar", "bar.jl"); write=true) do io
                print(io, """
                include("subbar/subbar.jl)
                """)
            end
            chmod(joinpath(dir, "src", "bar", "bar.jl"), 0o664)

            mkdir(joinpath(dir, "src", "bar", "subbar"))
            open(joinpath(dir, "src", "bar", "subbar", "subbar.jl"); write=true) do io
                print(io, """
                include("subbar_utils.jl)
                """)
            end
            chmod(joinpath(dir, "src", "bar", "subbar", "subbar.jl"), 0o664)
            open(joinpath(dir, "src", "bar", "subbar", "subbar_utils.jl"); write=true) do io
                print(io, """
                bar(::Int) = 2
                """)
            end
            chmod(joinpath(dir, "src", "bar", "subbar", "subbar_utils.jl"), 0o664)

            # Empty directory, should get pruned
            mkdir(joinpath(dir, "src", "deps"))

            # Executable files
            mkdir(joinpath(dir, "bin"))
            open(joinpath(dir, "bin", "fooify.jl"); write=true) do io
                print(io, """
                using Foo
                foo()
                """)
            end
            chmod(joinpath(dir, "bin", "fooify.jl"), 0o775)

            # Generate some junk in `.git` that should be ignored
            if with_git_dir
                mkdir(joinpath(dir, ".git"))
                open(joinpath(dir, ".git", "config"); write=true) do io
                    print(io, """
                    This is a git config, supposedly!
                    """)
                end
                chmod(joinpath(dir, ".git", "config"), 0o664)

                mkdir(joinpath(dir, ".git", "remotes"))
                open(joinpath(dir, ".git", "remotes", "origin"); write=true) do io
                    print(io, """
                    # This is how git works, right?
                    https://github.com/JuliaLang/julia.git
                    """)
                end
                chmod(joinpath(dir, ".git", "remotes", "origin"), 0o664)

                # Also create a `.git` folder inside of an empty directory, and show that
                # they get trimmed away properly when mimicking the git hashing algorithm

                mkdir(joinpath(dir, "src", "deps", ".git"))
                open(joinpath(dir, "src", "deps", ".git", "config"); write=true) do io
                    print(io, """
                    To hash or not to hash?
                    """)
                end
                chmod(joinpath(dir, "src", "deps", ".git", "config"), 0o664)
            end
        end

        generate_fake_package(joinpath(dir, "Foo"))
        generate_fake_package(joinpath(dir, "FooGit"); with_git_dir=true)

        tree_hash_str(joinpath(dir, "Foo"))
        tree_hash_str(joinpath(dir, "FooGit"); mimic_git=true)

        debug_out_foo = IOBuffer()
        debug_out_foogit = IOBuffer()
        @test tree_hash_str(joinpath(dir, "Foo"); debug_out=debug_out_foo) ==
                tree_hash_str(joinpath(dir, "FooGit"); debug_out=debug_out_foogit, mimic_git=true) ==
                "3cfb0b26b00661acbf0def94d76a6e65bcda4832"
        # Ignore name of top-level directory
        debug_out_foo_lines = split(String(take!(debug_out_foo)), "\n")[2:end]
        debug_out_foogit_lines = split(String(take!(debug_out_foogit)), "\n")[2:end]
        @test all(debug_out_foo_lines .== debug_out_foogit_lines)

        @test any(occursin("[X] fooify.jl - 84c6327750130f6adba28c24babd90c5ff62b00a", l) for l in debug_out_foo_lines)
        @test any(occursin("[D] subbar - de5e1c952bc0e1047150dae3dfb81c58c46a1ab4", l) for l in debug_out_foo_lines)
        @test any(occursin("[F] foo_utils.jl - f9bf3b890cac93687ca04ed59492ff1f6090e9d7", l) for l in debug_out_foo_lines)
    end

    # Test for symlinks that are a prefix of another directory, causing sorting issues
    mktempdir() do dir
        mkdir(joinpath(dir, "5.28.1"))
        write(joinpath(dir, "5.28.1", "foo"), "")
        chmod(joinpath(dir, "5.28.1", "foo"), 0o644)
        symlink("5.28.1", joinpath(dir, "5.28"))

        @test tree_hash_str(dir) == "5e50a4254773a7c689bebca79e2954630cab9c04"
    end
end

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
        src_treehash = tree_hash(src_dir)

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
                    @test tree_hash(out_dir) == src_treehash
                end
            end
        end
    end
end
