using gh_cli_jll, BinaryBuilderGitUtils

const gh_cache::Dict{String,Any} = Dict{String,Any}()

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
    get!(gh_cache, "user") do
        auth_lines = split(readchomp(`$(gh()) auth status`), "\n")
        name_match = only(filter(!isnothing, [match(r"Logged in to [^ ]+ as ([^ ]+)", l) for l in auth_lines]))
        return name_match.captures[1]
    end
end

function gh_orgs()
    get!(gh_cache, "orgs") do
        return split(readchomp(`$(gh()) org list --limit 1000`), "\n")
    end
end

function gh_fork(source::String, target_org::String)
    # Fork `source` to the target organization (or our user)
    org_args = target_org != gh_user() ? ["--org", target_org] : []
    run(`$(gh()) repo fork $(source) $(org_args) --clone=false --remote=false`)
end

function gh_create(target::String)
    run(`$(gh()) repo create --public --disable-issues --disable-wiki --license MIT $(target)`)
end

