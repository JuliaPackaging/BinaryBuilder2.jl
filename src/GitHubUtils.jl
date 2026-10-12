using gh_cli_jll, BinaryBuilderGitUtils

# Results are cached per-token, since e.g. `gh_user()` depends on which token is active.
const gh_cache::Dict{Tuple{UInt,String},Any} = Dict{Tuple{UInt,String},Any}()
gh_cache_get!(f::Function, key::AbstractString) = get!(f, gh_cache, (hash(gh_env_token()), String(key)))

# `gh` prefers `GH_TOKEN` over `GITHUB_TOKEN`; `nothing` means it uses its stored login.
gh_env_token() = get(ENV, "GH_TOKEN", get(ENV, "GITHUB_TOKEN", nothing))

"""
    with_gh_token(f::Function, owner, repo)
    with_gh_token(f::Function, "owner[/repo]")

Run `f()` with `gh` using the token configured for `github.com/owner/repo` in the
`access_tokens` preference, if any.  Otherwise `f()` runs with the current token.
"""
function with_gh_token(f::Function, owner::AbstractString, repo::Union{Nothing,AbstractString})
    token = access_token("github.com", owner, repo)
    if token === nothing
        return f()
    end
    return withenv(f, "GH_TOKEN" => token)
end
function with_gh_token(f::Function, path::AbstractString)
    parts = split(path, "/"; limit=2)
    return with_gh_token(f, parts[1], get(parts, 2, nothing))
end

function ensure_gh_authenticated()
    stderr_io = IOBuffer()
    try
        if success(pipeline(`$(gh()) auth token`; stdout=devnull, stderr=stderr_io))
            BinaryBuilderGitUtils.use_gh_auth[] = true
            return
        end
    catch
        if String(take!(stderr_io)) != "no oauth token"
            rethrow()
        end
    end

    # A token given through the environment can't be fixed by logging in interactively.
    if gh_env_token() !== nothing
        error("GitHub token provided through the environment is not valid!")
    end

    # If we fall through here, we must authenticate
    @info("Must authenticate to github, please complete authentication flow")
    run(`$(gh()) auth login`)
    empty!(gh_cache)
    BinaryBuilderGitUtils.use_gh_auth[] = true
end

function gh_logout()
    run(`$(gh()) auth logout`)
    empty!(gh_cache)
end

function gh_user()
    gh_cache_get!("user") do
        return String(readchomp(`$(gh()) api /user --jq .login`))
    end
end

function gh_orgs()
    gh_cache_get!("orgs") do
        return split(readchomp(`$(gh()) org list --limit 1000`), "\n")
    end
end

"""
    gh_can_deploy_to(owner::AbstractString)

Returns whether the current token can create and push to repositories owned by
`owner`.  This is true if `owner` is our user, or an organization we are an active
member of.  Membership is checked through `/user/memberships/orgs/{org}`, which
(unlike `gh_orgs()`) also sees private memberships, such as `jlbuild`'s membership
in `JuliaBinaryWrappers`.  If the token lacks the `read:org` scope needed for that,
we fall back to checking for push access to a repository within the organization.
"""
function gh_can_deploy_to(owner::AbstractString)
    with_gh_token(owner) do
        gh_cache_get!("can_deploy_to_$(owner)") do
            if owner == gh_user()
                return true
            end

            state = gh_api_jq("/user/memberships/orgs/$(owner)", ".state")
            if state !== nothing
                return state == "active"
            end

            push = gh_api_jq("/orgs/$(owner)/repos?per_page=1", "[.[].permissions.push] | any")
            return push == "true"
        end
    end
end

# Query `endpoint`, returning `jq` applied to the result, or `nothing` if the request fails.
function gh_api_jq(endpoint::AbstractString, jq::AbstractString)
    out = IOBuffer()
    if !success(pipeline(`$(gh()) api $(endpoint) --jq $(jq)`; stdout=out, stderr=devnull))
        return nothing
    end
    return chomp(String(take!(out)))
end

function gh_repo_exists(repo::AbstractString)
    with_gh_token(repo) do
        gh_cache_get!("repo_exists_$(repo)") do
            return success(pipeline(`$(gh()) api /repos/$(repo)`; stdout=devnull, stderr=devnull))
        end
    end
end

function gh_push_access(repo::AbstractString)
    with_gh_token(repo) do
        gh_cache_get!("push_access_$(repo)") do
            return gh_api_jq("/repos/$(repo)", ".permissions.push") == "true"
        end
    end
end

# Turns `https://github.com/Foo/Bar.git` into `Foo/Bar`
function gh_repo_name(url::AbstractString)
    m = match(r"^(?:https://github\.com/|git@github\.com:)([^/]+/[^/]+?)(?:\.git)?/?$", url)
    if m === nothing
        throw(ArgumentError("Not a GitHub repository URL: '$(url)'"))
    end
    return String(m.captures[1])
end

function gh_fork(source::String, target_org::String)
    # Fork `source` to the target organization (or our user), using the token for the fork
    fork_name = BinaryBuilderGitUtils.strip_dotgit(basename(rstrip(source, '/')))
    with_gh_token(target_org, fork_name) do
        org_args = target_org != gh_user() ? ["--org", target_org] : []
        run(`$(gh()) repo fork $(source) $(org_args) --clone=false --remote=false`)
    end
end

function gh_create(target::String)
    with_gh_token(target) do
        run(`$(gh()) repo create --public --disable-issues --disable-wiki --license MIT $(target)`)
    end
end
