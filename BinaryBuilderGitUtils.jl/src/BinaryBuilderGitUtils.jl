module BinaryBuilderGitUtils

using Git, MultiHashParsing, gh_cli_jll, Preferences
import Base.BinaryPlatforms: tags
export access_token, url_access_token, set_access_tokens!, iscommit, commit!, init!, fetch!, clone!, checkout!, push!, rebase!, remote_url, remote_url!, tags, tag!, log, log_between, head_branch, branch, branch!, isbranch

# Easy converter of MultiHash objects to strings
to_commit_str(x::String) = x
to_commit_str(x::MultiHash) = bytes2hex(x)

const HashOrString = Union{MultiHash,String}

# Test to see if a string is a commit
iscommit(repo::String, commit::HashOrString) = success(git(["-C", repo, "cat-file", "-e", to_commit_str(commit)]))

# Useful for splatting into an argument list
quiet_args(verbose::Bool) = verbose ? String[] : String["--quiet"]
force_args(force::Bool) = force ? String["--force"] : String[]

const use_gh_auth::Ref{Bool} = Ref(false)
gh_auth_args() = ["-c", "credential.https://github.com.helper=!gh auth git-credential"]

"""
    access_tokens

Tokens used to authenticate to git hosts, as a tree of nested dictionaries keyed by
host, then organization, then repository, e.g.:

    Dict(
        "github.com" => Dict(
            "JuliaBinaryWrappers" => "<token for all of JuliaBinaryWrappers>",
            "JuliaRegistries" => Dict("General" => "<token for JuliaRegistries/General>"),
        ),
    )

A token given in place of a dictionary applies to everything beneath that point, so
mapping `"github.com"` to a token uses it for all of GitHub.  Keys are matched case-
insensitively.  This is loaded from our `access_tokens` preference, and can be set
through `set_access_tokens!()`.
"""
const access_tokens::Ref{Dict{String,Any}} = Ref(Dict{String,Any}())

function check_access_tokens(tree::AbstractDict, depth::Int = 1)
    for (key, val) in tree
        if val isa AbstractDict
            if depth >= 3
                throw(ArgumentError("access_tokens: expected a token for repository '$(key)', got a dictionary"))
            end
            check_access_tokens(val, depth + 1)
        elseif !isa(val, AbstractString)
            throw(ArgumentError("access_tokens: expected a token or dictionary for '$(key)', got a $(typeof(val))"))
        end
    end
end

function set_access_tokens!(tree::AbstractDict)
    check_access_tokens(tree)
    access_tokens[] = Dict{String,Any}(tree)
end

function __init__()
    set_access_tokens!(@load_preference("access_tokens", Dict{String,Any}()))
end

"""
    access_token(host, org = nothing, repo = nothing)

Returns the token configured in `access_tokens` for `host/org/repo`, or `nothing`.
"""
function access_token(host::AbstractString,
                      org::Union{Nothing,AbstractString} = nothing,
                      repo::Union{Nothing,AbstractString} = nothing)
    node = access_tokens[]
    for key in (host, org, repo)
        if node isa AbstractString
            return String(node)
        end
        if key === nothing
            return nothing
        end
        idx = findfirst(k -> lowercase(k) == lowercase(key), collect(keys(node)))
        if idx === nothing
            return nothing
        end
        node = node[collect(keys(node))[idx]]
    end
    return node isa AbstractString ? String(node) : nothing
end

"""
    url_access_token(url)

Returns the token configured in `access_tokens` for the repository `url` points into,
(e.g. `https://github.com/Foo/Bar.git`, `https://github.com/Foo/Bar/releases/...` or
`https://api.github.com/repos/Foo/Bar/...`) or `nothing`.  Only `https` URLs get a token.
"""
function url_access_token(url::AbstractString)
    m = match(r"^https://api\.github\.com/repos/([^/?#]+)/([^/?#]+)", url)
    if m !== nothing
        return access_token("github.com", m.captures[1], strip_dotgit(m.captures[2]))
    end
    m = match(r"^https://(?:[^@/]+@)?([^/:?#]+)(?::\d+)?(?:/([^/?#]+))?(?:/([^/?#]+))?", url)
    if m === nothing
        return nothing
    end
    host, org, repo = m.captures
    return access_token(host, org, repo === nothing ? nothing : strip_dotgit(repo))
end
strip_dotgit(name::AbstractString) = endswith(name, ".git") ? name[1:end-4] : name

# The ambient token that `gh` would use, if any (`gh` prefers `GH_TOKEN` over `GITHUB_TOKEN`)
env_gh_token() = get(ENV, "GH_TOKEN", get(ENV, "GITHUB_TOKEN", nothing))

"""
    scrub_token_env(cmd::Cmd)

Remove the ambient GitHub token variables from `cmd`'s environment, so that they don't
get printed along with `cmd` (e.g. when it fails with a `ProcessFailedException`).
"""
scrub_token_env(cmd::Cmd) = addenv(cmd, "GH_TOKEN" => nothing, "GITHUB_TOKEN" => nothing)

"""
    with_token_dir(f::Function, files::Pair{String,String}...)

Call `f(dir)` with a freshly-created private directory holding the given
`name => contents` files, and delete it as soon as `f` returns.  This is how we hand
tokens to `git` and `gh` without placing them within the command line or environment
of the `Cmd`, so that they never get printed alongside it, and so that they only sit
on the filesystem while the command that needs them is running.
"""
function with_token_dir(f::Function, files::Pair{String,String}...)
    # `mktempdir()` creates the directory readable only by us
    return mktempdir() do dir
        for (name, contents) in files
            path = joinpath(dir, name)
            touch(path)
            chmod(path, 0o600)
            write(path, contents)
        end
        return f(dir)
    end
end

"""
    git_authed(f::Function, url, args; kwargs...)

Call `f(cmd)` with a `git` command running `args` against the remote at `url`,
authenticating with its token from `access_tokens` if there is one, otherwise through
`gh` if `use_gh_auth[]` is set.  The token is written to a `git-credential-store` file
that only exists while `f` runs, so `f` should do nothing more than run `cmd`.
"""
function git_authed(f::Function, url::AbstractString, args; kwargs...)
    token = url_access_token(url)
    m = match(r"^https://(?:[^@/]+@)?(.*)$", url)
    if token === nothing && use_gh_auth[] && m !== nothing && startswith(m.captures[1], "github.com/")
        # Hand an ambient token over through the credential file as well, as the
        # environment gets scrubbed of it below.
        token = env_gh_token()
    end

    if token !== nothing && m !== nothing
        credentials = string("https://x-access-token:", token, "@", m.captures[1], "\n")
        return with_token_dir("credentials" => credentials) do dir
            # The empty `credential.helper` resets the list of helpers, so that ours
            # takes precedence over any that the user has configured.
            cmd = git(vcat(
                ["-c", "credential.helper=", "-c", "credential.helper=store --file=$(joinpath(dir, "credentials"))"],
                args,
            ); kwargs...)
            return f(scrub_token_env(cmd))
        end
    end

    if use_gh_auth[]
        args = vcat(gh_auth_args(), args)
    end
    cmd = git(args; kwargs...)
    if use_gh_auth[]
        # Push `gh` onto the front of the PATH, as of this writing it has no LIBPATH.
        path_idx = findfirst(e -> startswith(e, "PATH="), cmd.env)
        pathsep = Sys.iswindows() ? ";" : ":"
        cmd.env[path_idx] = string("PATH=", gh_cli_jll.PATH[], pathsep, cmd.env[path_idx][6:end])
    end
    return f(scrub_token_env(cmd))
end

function fetch!(repo_path::String; verbose::Bool = false)
    url = "origin" ∈ remotes(repo_path) ? remote_url(repo_path) : ""
    return git_authed(run, url, ["-C", repo_path, "fetch", "-a", quiet_args(verbose)...])
end

function init!(repo_path::String; initial_branch::String = "main", verbose::Bool = false)
    mkpath(repo_path)
    run(git(["-C", repo_path, "init", "--bare", "--initial-branch=$(initial_branch)", quiet_args(verbose)...]))

    # We always add a single commit as otherwise other commands like `log` don't work.
    # We'll just add an empty `.gitignore` file, which should be pretty safe.
    if !iscommit(repo_path, "HEAD")
        mktempdir() do checkout_dir
            if verbose
                run(git(["clone", "--shared", repo_path, checkout_dir]))
            else
                # `git` unconditionally warns you when cloning an empty repository,
                # even if we say `--quiet`, so we manually redirect `stderr` to `devnull` here.
                run(pipeline(git(["clone", "--shared", repo_path, checkout_dir, "--quiet"]); stdout=devnull, stderr=devnull))
            end
            touch(joinpath(checkout_dir, ".gitignore"))
            commit!(checkout_dir, "Initial commit"; verbose)
            push!(checkout_dir; verbose)
        end
    end
end

function clone!(url::String, repo_path::String;
                commit::Union{Nothing,HashOrString} = nothing,
                verbose::Bool = false)
    if ispath(joinpath(repo_path, "HEAD"))
        if verbose
            @info("Using cached git repository", url, repo_path)
        end
        
        # In some cases, we know the hash we're looking for, so only fetch() if
        # this git repository doesn't contain the hash we're seeking.
        if commit === nothing || !iscommit(repo_path, commit)
            fetch!(repo_path; verbose)
        end

        if commit !== nothing && !iscommit(repo_path, commit)
            throw(ArgumentError("Invalid commit specified: '$(commit)'"))
        end
    else
        if verbose
            @info("Cloning git repository", url, repo_path)
        end
        # If there is no repo_path yet, clone it down into a bare repository
        git_authed(run, url, ["clone", "--mirror", url, repo_path, quiet_args(verbose)...])
    end
end

function head_branch(repo_path::String; default::String="main")
    try
        head_branch = readchomp(git(["-C", repo_path, "symbolic-ref", "HEAD"]))
        if startswith(head_branch, "refs/heads/")
            head_branch = head_branch[length("refs/heads/")+1:end]
        end
        return string(head_branch)
    catch
        return default
    end
end

function checkout!(repo_path::String, target::String, commit::HashOrString = head_branch(repo_path); verbose::Bool = false)
    if !iscommit(repo_path, commit)
        fetch!(repo_path; verbose)
    end
    run(git(["clone", "--shared", repo_path, target, quiet_args(verbose)...]))
    run(git(["-C", target, "checkout", quiet_args(verbose)..., to_commit_str(commit)]))
end

function branch(repo_path::String)
    readchomp(git(["-C", repo_path, "rev-parse", "--abbrev-ref", "HEAD"]))
end

function branch!(repo_path::String, branch::String; verbose::Bool = false)
    run(git(["-C", repo_path, "checkout", "-B", branch, quiet_args(verbose)...]))
end

function isbranch(repo_path::String, branch::String)
    return success(git(["-C", repo_path, "rev-parse", "--verify", branch]))
end

function commit!(checkout_path::String, message::String; verbose::Bool = false)
    run(git(["-C", checkout_path, "add", "--all"]))
    run(git(["-C", checkout_path, "commit", "-av", "-m", message, quiet_args(verbose)...]))
    return only(log(checkout_path; limit=1))
end

function Base.push!(repo_path::String, remote::String = "origin"; verbose::Bool = false, force::Bool = false)
    url = remote_url(repo_path, remote)
    git_authed(run, url, ["-C", repo_path, "push", remote, force_args(force)..., quiet_args(verbose)...])
    git_authed(run, url, ["-C", repo_path, "push", "--tags", remote, force_args(force)..., quiet_args(verbose)...])
end

function rebase!(checkout_path::String, target::HashOrString, verbose::Bool = false, atomic::Bool = true)
    cmd = git(["-C", checkout_path, "rebase", to_commit_str(target), quiet_args(verbose)...])
    if atomic
        cmd = ignorestatus(cmd)
    end
    # Someday, we may get a git that is smart enoguh that we can provide something
    # like `advice.resolveConflict=false` to avoid the `pipeline` here.
    if !verbose
        cmd = pipeline(cmd; stdout=devnull, stderr=devnull)
    end
    rebase_proc = run(cmd)
    if atomic && !success(rebase_proc)
        run(git(["-C", checkout_path, "rebase", "--abort"]))
    end
    return rebase_proc
end

function remotes(repo_path::String)
    return filter(!isempty, split(readchomp(git(["-C", repo_path, "remote"])), "\n"))
end

function remote_url(repo_path::String, remote::String = "origin")
    return readchomp(git(["-C", repo_path, "remote", "get-url", remote]))
end

function remote_url!(repo_path::String, remote::String, url::String)
    verb = remote ∈ remotes(repo_path) ? "set-url" : "add"
    run(git(["-C", repo_path, "remote", verb, remote, url]))
end

function tags(repo_path::String)
    return filter(!isempty, split(readchomp(git(["-C", repo_path, "tag"])), "\n"))
end

function tag!(repo_path::String, name::String, target::HashOrString = "HEAD"; force::Bool = false)
    run(git(["-C", repo_path, "tag", force_args(force)..., name, to_commit_str(target)]))
end

function Base.log(repo_path::String, tip::HashOrString = "HEAD"; limit::Union{Int,Nothing} = nothing, reverse::Bool = false)
    # Fetch once if we don't have the `tip` on disk already
    if !iscommit(repo_path, tip)
        fetch!(repo_path)
    end
    if !iscommit(repo_path, tip)
        throw(ArgumentError("Invalid commit specified: '$(to_commit_str(tip))'"))
    end

    limit_args = limit === nothing ? String[] : String["--max-count=$(limit)"]
    reverse_args = reverse ? String["--reverse"] : String[]
    lines = readchomp(git([
        "-C", repo_path,
        "rev-list",
        reverse_args...,
        limit_args...,
        to_commit_str(tip)
    ]))
    return MultiHash.(split(lines))
end

function log_between(repo_path::String, before::HashOrString, after::HashOrString)
    # Fetch once if we don't have the `after` commit, just in case we have a stale clone
    if !iscommit(repo_path, after)
        fetch!(repo_path)
    end

    # If we still can't find either of the commits, complain
    if !iscommit(repo_path, before)
        throw(ArgumentError("Cannot find commit '$(before)' in repo '$(repo_path)'"))
    end
    if !iscommit(repo_path, after)
        throw(ArgumentError("Cannot find commit '$(after)' in repo '$(repo_path)'"))
    end

    # Use `git log` to get the list of commit hashes (including the first one)
    lines = readchomp(git(["-C", repo_path, "rev-list", "--reverse", string(to_commit_str(before), "^!"), to_commit_str(after)]))
    return MultiHash.(split(lines))
end

end # module
