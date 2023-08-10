export gcc_platform, gcc_target_triplet

"""
    gcc_platform(p::AbstractPlatform)

Strip out any tags that are not the basic annotations like `libc` and `call_abi`.
"""
function gcc_platform(p::Platform)
    keeps = ("libc", "call_abi", "os_version")
    filtered_tags = Dict{Symbol,String}(Symbol(k) => v for (k, v) in tags(p) if k ∈ keeps)
    return Platform(arch(p)::String, os(p)::String; filtered_tags...)
end
gcc_platform(p::CrossPlatform) = CrossPlatform(gcc_platform(p.host), gcc_platform(p.target))
gcc_platform(p::AnyPlatform) = p

"""
    gcc_target_triplet(p::AbstractPlatform)

Return the kind of triplet that gcc would give for the given platform.  For a
`CrossPlatform`, applies to the `target`.
"""
gcc_target_triplet(target::AbstractPlatform) = triplet(gcc_platform(target))
gcc_target_triplet(platform::CrossPlatform) = gcc_target_triplet(platform.target)

