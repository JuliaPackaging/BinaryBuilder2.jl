using Test, BinaryBuilder2, Pkg, JLLGenerator, Accessors, BinaryBuilderGitUtils, Random
using BinaryBuilder2: register_jll!, with_gh, with_gh_token, exported_artifact_filename
using BinaryBuilderGitUtils: access_tokens, git_authed, git

# Fine-grained tokens for the dummy `BinaryBuilderTestZone` organization, which holds forks
# of `General` and `Zlib_jll.jl`.  The first can push to every repository in the
# organization, the second can only push to `General`.
const test_zone = "BinaryBuilderTestZone"

# We obfuscate the tokens a bit here to dodge automated scanners:
const test_zone_org_token = join(["github", "pat", "11AAA762A0b5NwceSIEAQq", "kqr3YuohK8t7QtBgZwVyxJQEOzKEMqhZ3nmtr2JMF343FNUPVGTngPnm6fC"], "_")
const test_zone_general_token = join(["github", "pat", "11AAA762A0FYVrbyI5WYTr", "8HHcNzRqrL8rH9wy0Vwtuc1HPmQ6x7DAMwXtg4UIxi3WQRZCDNYy90tNvqP"], "_")
test_zone_url(repo) = "https://github.com/$(test_zone)/$(repo)"

# Run `f()` with only the given `access_tokens`, and no ambient GitHub credentials.
function with_test_tokens(f::Function, tokens::AbstractDict; gh_token = nothing)
    old_tokens = access_tokens[]
    set_access_tokens!(tokens)
    try
        return withenv(f, "GH_TOKEN" => gh_token, "GITHUB_TOKEN" => nothing)
    finally
        access_tokens[] = old_tokens
    end
end
org_tokens(token) = Dict("github.com" => Dict(test_zone => token))

@testset "Access tokens: pushing" begin
    mktempdir() do repo
        run(git(["init", "--quiet", repo]))
        run(git(["-C", repo, "-c", "user.name=bb2", "-c", "user.email=bb2@example.com",
                 "commit", "--quiet", "--allow-empty", "-m", "probe"]))

        # `--dry-run` still has to authenticate as someone allowed to push
        function can_push(repo_name, token)
            with_test_tokens(org_tokens(token)) do
                url = test_zone_url(repo_name)
                return git_authed(url, ["-C", repo, "push", "--dry-run", url, "HEAD:refs/heads/bb2-access-token-probe"]) do cmd
                    success(pipeline(addenv(cmd, "GIT_TERMINAL_PROMPT" => "0"); stdout=devnull, stderr=devnull))
                end
            end
        end
        @test can_push("General", test_zone_org_token)
        @test can_push("General", test_zone_general_token)
        @test can_push("Zlib_jll.jl", test_zone_org_token)
        @test !can_push("Zlib_jll.jl", test_zone_general_token)
    end
end

@testset "Access tokens: hidden from commands" begin
    # `gh` gets its token from a config directory that only exists while it runs, and
    # neither that token nor an ambient one shows up in the `Cmd` (and thus in errors).
    token = "bb2_fake_token"
    ambient_token = "bb2_fake_ambient_token"
    with_test_tokens(Dict("github.com" => Dict("Foo" => token)); gh_token=ambient_token) do
        config_dir = with_gh_token("Foo/Bar") do
            with_gh() do gh
                @test !occursin(token, repr(gh))
                @test !occursin(ambient_token, repr(gh))
                @test readchomp(`$(gh) auth token`) == token

                # Even a failing invocation doesn't leak the token
                err = try
                    run(pipeline(`$(gh) definitely-not-a-command`; stdout=devnull, stderr=devnull))
                    nothing
                catch e
                    sprint(showerror, e)
                end
                @test err !== nothing && occursin("failed process", err)
                @test !occursin(token, something(err, ""))
                @test !occursin(ambient_token, something(err, ""))

                dir = only(filter(e -> startswith(e, "GH_CONFIG_DIR="), gh.env))[length("GH_CONFIG_DIR=")+1:end]
                @test filemode(joinpath(dir, "hosts.yml")) & 0o077 == 0
                return dir
            end
        end
        @test !ispath(config_dir)

        # Outside of `with_gh_token()`, the ambient token gets handed over the same way
        with_gh() do gh
            @test !occursin(ambient_token, repr(gh))
            @test readchomp(`$(gh) auth token`) == ambient_token
        end

        # `git` also gets the ambient token through its credentials file
        old_use_gh_auth = BinaryBuilderGitUtils.use_gh_auth[]
        BinaryBuilderGitUtils.use_gh_auth[] = true
        try
            git_authed("https://github.com/Baz/Qux.git", ["version"]) do cmd
                @test !occursin(ambient_token, repr(cmd))
                helper = only(filter(arg -> startswith(arg, "credential.helper=store --file="), cmd.exec))
                @test occursin(ambient_token, read(helper[length("credential.helper=store --file=")+1:end], String))
            end
        finally
            BinaryBuilderGitUtils.use_gh_auth[] = old_use_gh_auth
        end
    end
end

@testset "Access tokens: deployment" begin
    # Deploy a `Zlib_jll` (really `HelloWorldC_jll`, trimmed to two platforms) at a version
    # `General` doesn't have, to `BinaryBuilderTestZone/Zlib_jll.jl`, and register it in
    # `BinaryBuilderTestZone/General`.  A named universe pushes only to its own branch.
    # The universe name lands in the branch and tag names, so tag it with the BB2 content
    # hash and a random nonce to keep simultaneous test runs from clobbering each other.
    bb2_hash = bytes2hex(BinaryBuilder2.bb_package_treehashes()["BinaryBuilder2"].hash)[1:8]
    uni_name = "bb2_access_token_tests_$(bb2_hash)_$(randstring(['a':'z'; '0':'9'], 6))"
    branch_name = "bb2/$(uni_name)"
    jll_version = v"99.0.0"
    tag_name = "Zlib-v$(jll_version)-$(uni_name)"

    jll = include(joinpath(pkgdir(JLLGenerator), "contrib", "example_jllinfos", "HelloWorldC_jll.jl"))
    jll = @set jll.name = "Zlib"
    jll = @set jll.version = jll_version
    jll = @set jll.builds = map(jll.builds[1:2]) do build
        build = @set build.src_version = jll_version
        build = @set build.name = "Zlib"
        return build
    end
    # Exporting the artifacts for the release needs them on disk
    for build in jll.builds
        source = first(build.artifact.download_sources)
        Pkg.Artifacts.download_artifact(Base.SHA1(bytes2hex(build.artifact.treehash)), source.url, bytes2hex(source.tarball_hash))
    end

    function remote_head(repo_name)
        refs = readchomp(git(["ls-remote", test_zone_url(repo_name), "refs/heads/$(branch_name)"]))
        return isempty(refs) ? nothing : first(split(refs))
    end
    local_head(path) = readchomp(git(["-C", path, "rev-parse", "HEAD"]))

    # The open registration pull requests from our branch against `BinaryBuilderTestZone/General`
    function open_prs()
        withenv("GH_TOKEN" => test_zone_org_token) do
            prs = with_gh() do gh
                readchomp(`$(gh) api "/repos/$(test_zone)/General/pulls?state=open&head=$(test_zone):$(branch_name)" --jq '.[] | [.html_url, .title] | @tsv'`)
            end
            return [split(line, "\t") for line in split(prs, "\n"; keepempty=false)]
        end
    end

    # Remove anything a previous deployment left behind, so that each one starts from scratch.
    function reset_test_zone()
        withenv("GH_TOKEN" => test_zone_org_token) do
            quiet(args) = with_gh() do gh
                run(pipeline(ignorestatus(`$(gh) $(args)`); stdout=devnull, stderr=devnull))
            end
            quiet(`release delete $(tag_name) --yes --cleanup-tag --repo $(test_zone)/Zlib_jll.jl`)
            # Deleting the branch would close the pull request too, but let's be explicit
            for (pr_url, _) in open_prs()
                quiet(`pr close $(pr_url)`)
            end
            for repo_name in ("Zlib_jll.jl", "General")
                quiet(`api -X DELETE /repos/$(test_zone)/$(repo_name)/git/refs/heads/$(branch_name)`)
            end
        end
        @test remote_head("Zlib_jll.jl") === nothing
        @test remote_head("General") === nothing
        @test isempty(open_prs())
    end

    function deploy(tokens; gh_token = nothing, register_url = nothing)
        reset_test_zone()
        with_test_tokens(tokens; gh_token) do
            mktempdir() do depot
                uni = Universe(uni_name; depot_path=depot, deploy_org=test_zone, register_url)
                register_jll!(uni, jll)

                # Both repositories got exactly what we just committed locally
                @test remote_head("Zlib_jll.jl") == local_head(joinpath(depot, "dev", "Zlib_jll"))
                @test remote_head("General") == local_head(joinpath(depot, "deploy_registries", "General"))

                if register_url === nothing
                    @test isempty(open_prs())
                else
                    # A pull request was opened from our branch
                    prs = open_prs()
                    @test length(prs) == 1
                    @test only(prs)[2] == "New version: Zlib_jll v$(jll_version)"
                    pr_body = withenv("GH_TOKEN" => test_zone_org_token) do
                        with_gh(gh -> readchomp(`$(gh) pr view $(only(prs)[1]) --json body --jq .body`))
                    end
                    @test startswith(pr_body, "Autogenerated JLL package registration")
                    @test occursin("* Repository: $(test_zone_url("Zlib_jll.jl"))", pr_body)
                    @test occursin("* Version: v$(jll_version)", pr_body)
                    @test occursin("* Commit: $(local_head(joinpath(depot, "dev", "Zlib_jll")))", pr_body)

                    # Registering again updates that pull request rather than opening another
                    register_jll!(uni, jll)
                    @test remote_head("General") == local_head(joinpath(depot, "deploy_registries", "General"))
                    @test open_prs() == prs
                end
            end

            # The release holds both artifacts
            assets = withenv("GH_TOKEN" => test_zone_org_token) do
                with_gh(gh -> split(readchomp(`$(gh) release view $(tag_name) --repo $(test_zone)/Zlib_jll.jl --json assets --jq '.assets[].name'`)))
            end
            expected_assets = [exported_artifact_filename(jll.name, build.name, jll.version, build.platform) for build in jll.builds]
            @test sort(assets) == sort(expected_assets)
        end
    end

    old_allow = BinaryBuilder2.allow_github_authentication[]
    BinaryBuilder2.allow_github_authentication[] = true
    try
        # The organization-wide token deploys to both repositories
        deploy(org_tokens(test_zone_org_token))

        # The `General` token deploys to `General`.  As on Yggdrasil, the JLL is pushed with
        # an ambient `GH_TOKEN` (here, the organization-wide token), as nothing is configured for it.
        deploy(Dict("github.com" => Dict(test_zone => Dict("General" => test_zone_general_token)));
               gh_token = test_zone_org_token)

        # Registering into the `General` fork within `BinaryBuilderTestZone` (the default
        # for a bare `--register`) opens a pull request within that fork.
        deploy(org_tokens(test_zone_org_token); register_url=test_zone_url("General"))

        # The `General` token cannot deploy the JLL, so nothing gets pushed anywhere
        reset_test_zone()
        with_test_tokens(org_tokens(test_zone_general_token)) do
            mktempdir() do depot
                uni = Universe(uni_name; depot_path=depot, deploy_org=test_zone)
                @test_throws ProcessFailedException register_jll!(uni, jll)
            end
        end
        @test remote_head("Zlib_jll.jl") === nothing
        @test remote_head("General") === nothing
        @test isempty(open_prs())
    finally
        BinaryBuilder2.allow_github_authentication[] = old_allow
        reset_test_zone()
    end
end
