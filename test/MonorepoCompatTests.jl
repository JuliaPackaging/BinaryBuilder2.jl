using Test, Pkg, TOML

# Every package this monorepo releases lives in a top-level `Foo.jl/` directory,
# plus BinaryBuilder2 itself at the root.  Nested projects (such as the pinned
# stdlib JLL stubs under `JLLGenerator.jl/contrib/`) are test fixtures, not
# packages we release, so we deliberately only look one directory deep.
function monorepo_projects(repo_root::String)
    project_paths = [joinpath(repo_root, "Project.toml")]
    append!(project_paths, [joinpath(repo_root, d, "Project.toml") for d in sort(readdir(repo_root))])
    return Dict(
        relpath(p, repo_root) => TOML.parsefile(p) for p in project_paths if isfile(p)
    )
end

# Returns a human-readable description of how `compat_str` (`nothing` if there
# is no bound at all) fails to pin `dep` to the copy of it that lives in this
# repository, or `""` if it is a good bound.
function compat_problem(project_rel_path::String, dep::String, compat_str::Union{String,Nothing}, version::VersionNumber)
    suggestion = "expected `$(dep) = \"$(version.major).$(version.minor)\"`"
    if compat_str === nothing
        return "$(project_rel_path): $(dep) has no compat bound; $(suggestion)"
    end

    spec = Pkg.Types.semver_spec(compat_str)
    if version ∉ spec
        return "$(project_rel_path): $(dep) compat `$(compat_str)` excludes the in-repo v$(version); $(suggestion)"
    end

    # `"X.Y"` is caret semantics: everything from `X.Y.0` up to the next breaking
    # release.  A bound any more permissive than that reaches back to a
    # `major.minor` older than the one this repository actually contains.
    from_current_minor = Pkg.Types.semver_spec("$(version.major).$(version.minor)")
    if (spec ∩ from_current_minor) != spec
        return "$(project_rel_path): $(dep) compat `$(compat_str)` allows versions older than the in-repo v$(version.major).$(version.minor); $(suggestion)"
    end
    return ""
end

@testset "compat_problem" begin
    # An exact match, and a bound that pins the patch version too, are both fine.
    @test compat_problem(".", "Foo", "0.2", v"0.2.3") == ""
    @test compat_problem(".", "Foo", "0.2.1", v"0.2.3") == ""
    @test compat_problem(".", "Foo", "1.2", v"1.2.0") == ""

    # Bounds that don't admit the version sitting in the repo.
    @test compat_problem(".", "Foo", "0.2", v"0.3.0") != ""
    @test compat_problem(".", "Foo", "0.2.4", v"0.2.3") != ""
    @test compat_problem(".", "Foo", nothing, v"0.3.0") != ""

    # Bounds that admit the in-repo version, but also older `major.minor`s (or,
    # for a `1.x` package, newer breaking ones) that we don't have a copy of.
    @test compat_problem(".", "Foo", "1.0", v"1.2.0") != ""
    @test compat_problem(".", "Foo", "0.3.8, 0.4", v"0.4.1") != ""
    @test compat_problem(".", "Foo", "1.2, 2", v"1.2.0") != ""
end

@testset "Monorepo compat bounds" begin
    repo_root = dirname(@__DIR__)
    projects = monorepo_projects(repo_root)

    # Map each in-repo package name to the version its `Project.toml` declares.
    versions = Dict{String,VersionNumber}()
    for project in values(projects)
        if haskey(project, "name") && haskey(project, "version")
            versions[project["name"]] = VersionNumber(project["version"])
        end
    end

    # Sanity-check the discovery above, so that a reorganization of the repo
    # can't silently turn this whole testset into a no-op.
    @test "BinaryBuilder2" ∈ keys(versions)
    @test length(versions) > 5
    should_fail = false

    for project_rel_path in sort(collect(keys(projects)))
        project = projects[project_rel_path]

        # `docs/` is a bundle of dependencies rather than a package we release
        # (CI skips it too), so it has no version of its own to keep in sync.
        haskey(project, "version") || continue

        compat = get(Dict{String,Any}, project, "compat")
        deps = keys(get(Dict{String,Any}, project, "deps"))

        # Check every bound that names an in-repo package, no matter which
        # section pulled that package in, and additionally require that real
        # (non-weak, non-test-only) dependencies carry a bound at all.
        checked_deps = union(intersect(deps, keys(versions)), intersect(keys(compat), keys(versions)))

        for dep in sort(collect(checked_deps))
            error_msg = compat_problem(project_rel_path, dep, get(compat, dep, nothing), versions[dep])
            if !isempty(error_msg)
                @warn(error_msg)
                should_fail = true
            end
        end
    end
    if should_fail
        error("Monorepo compat bounds issues detected")
    end
end
