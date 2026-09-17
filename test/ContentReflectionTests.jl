using Test, BinaryBuilder2, Pkg
using BinaryBuilder2: bb_package_treehashes

@testset "bb_package_treehashes" begin
    ctx = Pkg.Types.Context()
    package_treehashes = bb_package_treehashes()
    
    # Walk over all manifest entries
    for (uuid, pkg) in ctx.env.manifest
        # If it's not stored in our monorepo, skip it
        if !isdir(joinpath(pkgdir(BinaryBuilder2), "$(pkg.name).jl"))
            continue
        end

        # Purposefully skip these packages, we don't track their treehashes
        # because they don't impact build output.
        pkgs_to_skip = [
            "JLLWrappers",
        ]
        if pkg.name ∈ pkgs_to_skip
            continue
        end

        if pkg.name ∉ keys(package_treehashes)
            @error("$(pkg.name) is a subproject of BB2, but not listed in bb_package_treehashes()!")
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
