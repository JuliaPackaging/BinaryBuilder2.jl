module BinaryBuilderGitUtils

using Git, MultiHashParsing
export iscommit, fetch!, clone!, checkout!, log, log_between

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

        if !iscommit(repo_path, commit)
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

function checkout!(repo_path::String, target::String, commit::HashOrString; verbose::Bool = false)
    if !iscommit(repo_path, commit)
        fetch!(repo_path; verbose)
    end
    run(git(["clone", "--shared", repo_path, target, quiet_args(verbose)...]))
    run(git(["-C", target, "checkout", quiet_args(verbose)..., to_commit_str(commit)]))
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
