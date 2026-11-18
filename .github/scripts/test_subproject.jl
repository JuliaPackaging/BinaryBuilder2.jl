# Usage: julia test_subproject.jl SUBPROJECT_DIR
#
# Tests one subproject without relying on the repository's `[workspace]` and
# `[sources]`, which Julia older than 1.12 ignores. A temporary environment
# `develop`s the subproject together with every in-repo package it needs,
# directly or transitively, through `[deps]`, `[weakdeps]` or `[extras]`, so
# that both the package and its test dependencies resolve to the code in this
# checkout rather than to registered releases. Then the subproject is tested.

using Pkg
const TOML = isdefined(Pkg, :TOML) ? Pkg.TOML : Base.require(Base.PkgId(
    Base.UUID("fa267f1f-6049-4f14-aa54-33bafae1ed76"), "TOML"))

const ROOT = dirname(dirname(@__DIR__))

function in_repo_packages()
    pkgs = Dict{String,String}()
    for d in readdir(ROOT)
        toml = joinpath(ROOT, d, "Project.toml")
        isfile(toml) || continue
        name = get(TOML.parsefile(toml), "name", nothing)
        name === nothing || (pkgs[name] = joinpath(ROOT, d))
    end
    return pkgs
end

function needed_packages(dir, pkgs)
    needed = String[]
    todo = [dir]
    while !isempty(todo)
        d = pop!(todo)
        d in needed && continue
        push!(needed, d)
        project = TOML.parsefile(joinpath(d, "Project.toml"))
        for section in ("deps", "weakdeps", "extras"), name in keys(get(project, section, Dict()))
            haskey(pkgs, name) && push!(todo, pkgs[name])
        end
    end
    return needed
end

length(ARGS) == 1 || error("Usage: julia test_subproject.jl SUBPROJECT_DIR")
const dir = abspath(joinpath(ROOT, ARGS[1]))
const name = TOML.parsefile(joinpath(dir, "Project.toml"))["name"]
const paths = needed_packages(dir, in_repo_packages())

const env = mktempdir()
Pkg.activate(env)
println("Developing into $(env):")
foreach(p -> println("  ", relpath(p, ROOT)), paths)
Pkg.develop([PackageSpec(path = p) for p in paths])
Pkg.precompile()
Pkg.test(name)
