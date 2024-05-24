using Test, BinaryBuilder2, Pkg
using BinaryBuilder2: bb_package_treehashes

@testset "bb_package_treehashes" begin
    ctx = Pkg.Types.Context()
    package_treehashes = bb_package_treehashes()
    
    for (uuid, pkg) in ctx.env.manifest
        # If it's not a BB-related package, skip it
        if !occursin("BinaryBuilder", pkg.name) && !occursin("JLL", pkg.name)
            continue
        end

        # Purposefull skip JLLWrappers, that's not one we want to pay attention to
        pkgs_to_skip = [
            "JLLWrappers",
        ]
        if pkg.name ∈ pkgs_to_skip
            continue
        end

        @test pkg.name ∈ keys(package_treehashes)
        #=
        # This used to be true, but no longer because we now hash only `src/*`.
        # This is both a correctness measure (we'd rather not cachebust every time we
        # change the test suite, for instance) as well as a performance optimization
        # to prevent precompilation of BinaryBuilder2 from taking forever due to
        # treehashing `.git/`, for example.
        if pkg.tree_hash !== nothing
            # Most of these dependencies should be dev'ed out, since they're in the same
            # directory as BB2, but for those that are not, ensure we match Pkg's treehash.
            @test SHA1Hash(pkg.tree_hash) == package_treehashes[pkg.name]
        end
        =#
    end
end
