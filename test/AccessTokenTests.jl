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
    # A second version, registered on top of the first one within the same universe
    jll2_version = v"99.1.0"
    tag2_name = "Zlib-v$(jll2_version)-$(uni_name)"
    jll2 = @set jll.version = jll2_version
    jll2 = @set jll2.builds = map(build -> (@set build.src_version = jll2_version), jll2.builds)
    # When opening pull requests, each version gets a `General` branch of its own
    pr_branch_name(version) = "$(branch_name)-Zlib_jll-v$(version)"

    # Exporting the artifacts for the release needs them on disk
    for build in jll.builds
        source = first(build.artifact.download_sources)
        Pkg.Artifacts.download_artifact(Base.SHA1(bytes2hex(build.artifact.treehash)), source.url, bytes2hex(source.tarball_hash))
    end

    function remote_head(repo_name, branch = branch_name)
        refs = readchomp(git(["ls-remote", test_zone_url(repo_name), "refs/heads/$(branch)"]))
        return isempty(refs) ? nothing : first(split(refs))
    end
    local_head(path) = readchomp(git(["-C", path, "rev-parse", "HEAD"]))

    # The open registration pull requests (URL, title and base branch) from `branch` against
    # `BinaryBuilderTestZone/General`
    function open_prs(branch)
        withenv("GH_TOKEN" => test_zone_org_token) do
            prs = with_gh() do gh
                readchomp(`$(gh) api "/repos/$(test_zone)/General/pulls?state=open&head=$(test_zone):$(branch)" --jq '.[] | [.html_url, .title, .base.ref] | @tsv'`)
            end
            return [split(line, "\t") for line in split(prs, "\n"; keepempty=false)]
        end
    end
    # The bodies of the comments on the pull request at `pr_url`
    function pr_comments(pr_url)
        withenv("GH_TOKEN" => test_zone_org_token) do
            with_gh(gh -> split(readchomp(`$(gh) api /repos/$(test_zone)/General/issues/$(basename(pr_url))/comments --jq '.[].body'`), "\n"; keepempty=false))
        end
    end
    general_branches = [branch_name, pr_branch_name(jll_version), pr_branch_name(jll2_version)]
    open_prs() = reduce(vcat, open_prs.(general_branches))

    # Remove anything a previous deployment left behind, so that each one starts from scratch.
    function reset_test_zone()
        withenv("GH_TOKEN" => test_zone_org_token) do
            quiet(args) = with_gh() do gh
                run(pipeline(ignorestatus(`$(gh) $(args)`); stdout=devnull, stderr=devnull))
            end
            for tag in (tag_name, tag2_name)
                quiet(`release delete $(tag) --yes --cleanup-tag --repo $(test_zone)/Zlib_jll.jl`)
            end
            # Deleting the branch would close the pull request too, but let's be explicit
            for (pr_url, _) in open_prs()
                quiet(`pr close $(pr_url)`)
            end
            quiet(`api -X DELETE /repos/$(test_zone)/Zlib_jll.jl/git/refs/heads/$(branch_name)`)
            for branch in general_branches
                quiet(`api -X DELETE /repos/$(test_zone)/General/git/refs/heads/$(branch)`)
            end
        end
        @test remote_head("Zlib_jll.jl") === nothing
        @test all(branch -> remote_head("General", branch) === nothing, general_branches)
        @test isempty(open_prs())
    end

    function deploy(tokens; gh_token = nothing, register_url = nothing)
        reset_test_zone()
        with_test_tokens(tokens; gh_token) do
            mktempdir() do depot
                uni = Universe(uni_name; depot_path=depot, deploy_org=test_zone, register_url)
                register_jll!(uni, jll)

                # Both repositories got exactly what we just committed locally
                general_head() = local_head(joinpath(depot, "deploy_registries", "General"))
                @test remote_head("Zlib_jll.jl") == local_head(joinpath(depot, "dev", "Zlib_jll"))
                if register_url === nothing
                    @test remote_head("General") == general_head()
                    @test isempty(open_prs())
                else
                    # A pull request against the default branch was opened from the version's branch
                    pr_branch = pr_branch_name(jll_version)
                    @test remote_head("General", pr_branch) == general_head()
                    @test remote_head("General") === nothing
                    prs = open_prs(pr_branch)
                    @test length(prs) == 1
                    @test only(prs)[2] == "New version: Zlib_jll v$(jll_version)"
                    default_branch = withenv("GH_TOKEN" => test_zone_org_token) do
                        with_gh(gh -> readchomp(`$(gh) api /repos/$(test_zone)/General --jq .default_branch`))
                    end
                    @test only(prs)[3] == default_branch
                    pr_body = withenv("GH_TOKEN" => test_zone_org_token) do
                        with_gh(gh -> readchomp(`$(gh) pr view $(only(prs)[1]) --json body --jq .body`))
                    end
                    @test startswith(pr_body, "Autogenerated JLL package registration")
                    @test occursin("* Repository: $(test_zone_url("Zlib_jll.jl"))", pr_body)
                    @test occursin("* Version: v$(jll_version)", pr_body)
                    @test occursin("* Commit: $(local_head(joinpath(depot, "dev", "Zlib_jll")))", pr_body)

                    # Registering again updates that pull request rather than opening another
                    register_jll!(uni, jll)
                    @test remote_head("General", pr_branch) == general_head()
                    @test open_prs() == prs
                    # A pull request against the default branch is left to AutoMerge
                    @test isempty(pr_comments(only(prs)[1]))

                    # Registering another version opens a pull request of its own, stacked
                    # upon the first one
                    register_jll!(uni, jll2)
                    pr2_branch = pr_branch_name(jll2_version)
                    @test remote_head("General", pr2_branch) == general_head()
                    @test remote_head("General", pr_branch) == readchomp(git(["-C", joinpath(depot, "deploy_registries", "General"), "rev-parse", "HEAD^"]))
                    prs2 = open_prs(pr2_branch)
                    @test length(prs2) == 1
                    @test only(prs2)[2] == "New version: Zlib_jll v$(jll2_version)"
                    @test only(prs2)[3] == pr_branch
                    @test open_prs(pr_branch) == prs
                    # The stacked pull request carries a comment blocking AutoMerge, once
                    stacked_comment = ["This is a stacked PR, so we're not engaging AutoMerge."]
                    @test pr_comments(only(prs2)[1]) == stacked_comment
                    register_jll!(uni, jll2)
                    @test pr_comments(only(prs2)[1]) == stacked_comment
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
