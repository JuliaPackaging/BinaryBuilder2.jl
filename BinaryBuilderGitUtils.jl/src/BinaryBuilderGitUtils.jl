module BinaryBuilderGitUtils

using Git, MultiHashParsing
export iscommit, commit!, init!, fetch!, clone!, checkout!, push!, log, log_between

# Easy converter of MultiHash objects to strings
to_commit_str(x::String) = x
to_commit_str(x::MultiHash) = bytes2hex(x)

const HashOrString = Union{MultiHash,String}

# Test to see if a string is a commit
iscommit(repo::String, commit::HashOrString) = success(git(["-C", repo, "cat-file", "-e", to_commit_str(commit)]))

# Useful for splatting into an argument list
quiet_args(verbose::Bool) = verbose ? String[] : String["--quiet"]

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
    if isdir(repo_path)
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

function checkout!(repo_path::String, target::String, commit::HashOrString = only(log(repo_path; limit=1)); verbose::Bool = false)
    if !iscommit(repo_path, commit)
        fetch!(repo_path; verbose)
    end
    run(git(["clone", "--shared", repo_path, target, quiet_args(verbose)...]))
    run(git(["-C", target, "checkout", quiet_args(verbose)..., to_commit_str(commit)]))
end

function commit!(checkout_path::String, message::String; verbose::Bool = false)
    run(git(["-C", checkout_path, "add", "--all"]))
    run(git(["-C", checkout_path, "commit", "-av", "-m", message, quiet_args(verbose)...]))
    return only(log(checkout_path; limit=1))
end

function Base.push!(repo_path::String, remote::String = "origin"; verbose::Bool = false)
    run(git(["-C", repo_path, "push", remote,  quiet_args(verbose)...]))
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
