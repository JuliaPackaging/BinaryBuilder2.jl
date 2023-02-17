using Git, MultiHashParsing

# Some simple utilities for dealing with Git repositories using `Git.jl`

iscommit(repo::String, commit::String) = success(git(["-C", repo, "cat-file", "-e", commit]))
iscommit(repo::String, commit::MultiHash) = iscommit(repo, bytes2hex(commit))

function cached_git_clone(url::String, repo_path::String;
                          desired_commit::Union{Nothing,String,MultiHash} = nothing,
                          verbose::Bool = false)
    quiet_args = String[]
    if !verbose
        push!(quiet_args, "-q")
    end
    if isdir(repo_path)
        if verbose
            @info("Using cached git repository", url, repo_path)
        end
        
        # If we didn't just mercilessly obliterate the cached git repo, use it!
        # In some cases, we know the hash we're looking for, so only fetch() if
        # this git repository doesn't contain the hash we're seeking.
        # this is not only faster, it avoids race conditions when we have
        # multiple builders on the same machine all fetching at once.
        if desired_commit === nothing || !iscommit(repo_path, desired_commit)
            run(git(["-C", repo_path, "fetch", quiet_args...]))
        end
    else
        if verbose
            @info("Cloning git repository", url, repo_path)
        end
        # If there is no repo_path yet, clone it down into a bare repository
        run(git(["clone", "--bare", url, repo_path, quiet_args...]))
    end
end

function git_checkout(repo::String, target::String, commit::SHA1Hash; verbose::Bool = false)
    quiet_args = String[]
    if !verbose
        push!(quiet_args, "-q")
    end

    run(git(["clone", "--shared", repo, target, quiet_args...]))
    run(git(["-C", target, "checkout", bytes2hex(commit), quiet_args...]))
end
