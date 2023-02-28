using Test
using BinaryBuilderGitUtils

@testset "cached_git_clone" begin
    mktempdir() do dir
        pkg_path = joinpath(dir, "Pkg-master")
        clone!("https://github.com/JuliaLang/Pkg.jl", pkg_path)
        @test isdir(pkg_path)

        head = only(log(pkg_path; limit=1))
        @test iscommit(pkg_path, head)

        head_1 = only(log(pkg_path, "$(bytes2hex(head))~1"; limit=1))
        @test head_1 != head
        @test iscommit(pkg_path, head_1)

        head_5 = first(log(pkg_path; limit=5, reverse=true))
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
    end
end
