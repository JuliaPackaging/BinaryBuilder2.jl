using Test
using BinaryBuilderGitUtils

@testset "Basics" begin
    mktempdir() do dir
        pkg_path = joinpath(dir, "Pkg-master")
        clone!("https://github.com/JuliaLang/Pkg.jl", pkg_path)
        @test isdir(pkg_path)

        our_head = "bffd0633cb73a20aacb39c641591fa9035c434a3"
        head = only(log(pkg_path, our_head; limit=1))
        @test iscommit(pkg_path, head)

        head_1 = only(log(pkg_path, "$(bytes2hex(head))~1"; limit=1))
        @test head_1 != head
        @test iscommit(pkg_path, head_1)

        head_5 = first(log(pkg_path, our_head; limit=5, reverse=true))
        @test head != head_5
        @test iscommit(pkg_path, head_5)

        last_5 = log_between(pkg_path, head_5, head)
        @test length(last_5) == 5
        @test first(last_5) == head_5
        @test last(last_5) == head

        pkg_5_path = joinpath(dir, "Pkg-master~5")
        checkout!(pkg_path, pkg_5_path, head_5)
        @test isdir(pkg_5_path)
        @test only(log(pkg_5_path; limit=1)) == head_5

        # Check out various branches
        r160_path = joinpath(dir, "Pkg-v1.6.0")
        r161_path = joinpath(dir, "Pkg-v1.6.1")
        checkout!(pkg_path, r160_path, "v1.6.0")
        checkout!(pkg_path, r161_path, "v1.6.1")
        @test isfile(r160_path, "Project.toml")
        @test isfile(r161_path, "Project.toml")

        @test only(log(r160_path; limit=1)) == "sha1:05fa7f93f73afdabd251247d03144de9f7b36b50"
        @test only(log(r161_path; limit=1)) == "sha1:c78a8be9af8aa0944b74f297791e10933f223aad" 

        # `clone!()` with a bad commit fails, but `nothing` succeeds:
        @test_throws ArgumentError clone!("https://github.com/JuliaLang/Pkg.jl", pkg_path; commit="0"^40)
        clone!("https://github.com/JuliaLang/Pkg.jl", pkg_path; commit=nothing)
        @test_throws ArgumentError log(pkg_path, "0"^40)

        # Test `commit!()` on the `master` branch
        local new_commit_hash
        mktempdir() do pkg_checkout
            checkout!(pkg_path, pkg_checkout, "master")
            project_toml_path = joinpath(pkg_checkout, "Project.toml")
            @test isfile(project_toml_path)
            open(project_toml_path, write=true) do io
                seekend(io)
                println(io, "foo")
            end
            new_commit_hash = commit!(pkg_checkout, "Appended `foo`")
            # This pushes back to the bare clone that we checked out from
            push!(pkg_checkout)

            # Make a second commit to this checkout, but don't push it
            open(project_toml_path, write=true) do io
                seekend(io)
                println(io, "bar")
            end
            commit!(pkg_checkout, "Appended `bar`")
        end
        
        # Test that checking out that same git repository has the appropriate changes:
        mktempdir() do pkg_checkout
            checkout!(pkg_path, pkg_checkout, "master")
            @test only(log(pkg_checkout; limit=1)) == new_commit_hash
            project_toml_path = joinpath(pkg_checkout, "Project.toml")
            @test isfile(project_toml_path)
            @test endswith(String(read(project_toml_path)), "foo\n")
        end
    end
end

@testset "init() and remotes" begin
    mktempdir() do dir
        bare_dir = joinpath(dir, "bare")
        init!(bare_dir; initial_branch="main")
        working_dir = joinpath(dir, "working_dir")
        checkout!(bare_dir, working_dir, "main")
        open(joinpath(working_dir, "foo.txt"), write=true) do io
            println(io, "foo!")
        end
        commit!(working_dir, "added foo.txt")
        push!(working_dir)
        @test length(log(bare_dir)) == 2

        mktempdir() do second_working_dir
            checkout!(bare_dir, second_working_dir)
            @test isfile(joinpath(second_working_dir, "foo.txt"))
        end

        mktempdir() do second_bare_clone
            rm(second_bare_clone)
            clone!(bare_dir, second_bare_clone)

            mktempdir() do second_working_dir
                checkout!(second_bare_clone, second_working_dir, "main")
                @test remote_url(second_working_dir) == second_bare_clone

                open(joinpath(second_working_dir, "foo.txt"), write=true) do io
                    println(io, "foo2!")
                end
                update_hash = commit!(second_working_dir, "updated foo.txt")
                tag!(second_working_dir, "v1.0.0")
                @test tags(second_working_dir) == ["v1.0.0"]
                @test first(log(second_working_dir, "v1.0.0")) == update_hash
                push!(second_working_dir)
                @test first(log(second_bare_clone)) == update_hash
                @test first(log(bare_dir)) != update_hash
                @test tags(second_bare_clone) == ["v1.0.0"]
                @test isempty(tags(bare_dir))

                open(joinpath(second_working_dir, "foo.txt"), write=true) do io
                    println(io, "foo3!")
                end
                final_hash = commit!(second_working_dir, "finalized foo.txt")
                remote_url!(second_working_dir, "upstream/blah", bare_dir)
                @test remote_url(second_working_dir, "upstream/blah") == bare_dir
                push!(second_working_dir, "upstream/blah")
                @test first(log(second_bare_clone)) == update_hash
                @test first(log(bare_dir)) == final_hash
            end
        end
    end
end
