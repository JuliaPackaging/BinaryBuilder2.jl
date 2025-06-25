using TreeArchival, Random

export GeneratedSource

"""
    GeneratedSource(generator::Function, name::String; target = "")

Call a function with a directory as its argument, allowing the function to
dynamically generate the source that will be deployed within the build
environment.  `GeneratedSource` is implemented as a wrapper around
`DirectorySource`.  The `name` argument must be globally unique as the
generator function will not run again if the `name` is shared with
another `GeneratedSource`.  This allows for caching beyond the current
Julia session.
"""
struct GeneratedSource <: AbstractSource
    generator::Function
    ds::DirectorySource
end

function GeneratedSource(generator::Function, name::String = randstring(8); target::String = "")
    noabspath!(target)
    return GeneratedSource(
        generator,
        DirectorySource(generated_source_cache(name); target, allow_missing_dir=true),
    )
end

# This is just used to check whether we've run `prepare()` yet
verify(gs::GeneratedSource) = isdir(gs.ds.source)

function retarget(gs::GeneratedSource, new_target::String)
    noabspath!(new_target)
    return GeneratedSource(gs.generator, retarget(gs.ds, new_target))
end

function prepare(gs::GeneratedSource; verbose::Bool = false)
    if verify(gs)
        @debug("Not preparing", gs)
        return
    end

    # Run the generator on the source
    mkpath(gs.ds.source)
    gs.generator(gs.ds.source)

    # As of the time of this writing, `DirectorySource` has no `prepare()` function,
    # but let's be forward-thinking in case we end up adding something here.
    @debug("Preparing", gs)
    prepare(gs.ds; verbose)
end

# Deployment for us is just deploying our wrapped `DirectorySource`
function deploy(gs::GeneratedSource, prefix::String)
    checkprepared!("deploy", gs)
    deploy(gs.ds, prefix)
end

function content_hash(gs::GeneratedSource)
    checkprepared!("content_hash", gs)
    return content_hash(gs.ds)
end

source(gs::GeneratedSource) = "<generated>"
