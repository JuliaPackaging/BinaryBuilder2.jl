module BinaryBuilderGitUtils

using Git, MultiHashParsing, gh_cli_jll
import Base.BinaryPlatforms: tags
export iscommit, commit!, init!, fetch!, clone!, checkout!, push!, rebase!, remote_url, remote_url!, tags, tag!, log, log_between, head_branch, branch, branch!, isbranch

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
function git_authed(args; kwargs...)
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
    return cmd
end

function fetch!(repo_path::String; verbose::Bool = false)
    return run(git(["-C", repo_path, "fetch", "-a", quiet_args(verbose)...]))
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
        run(git(["clone", "--mirror", url, repo_path, quiet_args(verbose)...]))
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
    run(git_authed(["-C", repo_path, "push", remote, force_args(force)..., quiet_args(verbose)...]))
    run(git_authed(["-C", repo_path, "push", "--tags", remote, force_args(force)..., quiet_args(verbose)...]))
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
