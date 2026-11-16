using Pkg.Types: semver_spec
export audit_package

# `v"1.11.0"` -> `"1.11"`, `v"1.10.13"` -> `"1.10.13"`
julia_compat_string(v::VersionNumber) = v.patch == 0 ? "$(v.major).$(v.minor)" : "$(v.major).$(v.minor).$(v.patch)"

"""
    minimum_julia_for_libstdcxx(libstdcxx::VersionNumber)

The oldest official Julia release from which on every release bundles a libstdc++
at least as new as `libstdcxx`, or `nothing` if the newest known release doesn't.
"""
function minimum_julia_for_libstdcxx(libstdcxx::VersionNumber)
    floor = nothing
    for (v, e) in reverse(JULIA_LIBSTDCXX_VERSIONS)
        e.libstdcxx >= libstdcxx || break
        floor = v
    end
    return floor
end

# The lower bound of a `Pkg.Types.VersionRange`, e.g. `v"1.6.0"` for the range of `"1.6"`
function range_lower_bound(r)
    t, n = r.lower.t, r.lower.n
    return VersionNumber(n >= 1 ? t[1] : 0, n >= 2 ? t[2] : 0, n >= 3 ? t[3] : 0)
end

"""
    oldest_admitted_libstdcxx(julia_compat::AbstractString)

Among the official Julia releases that `julia_compat` admits, the one that bundles the
oldest libstdc++ (the oldest such release, on a tie), as `v => entry`, or `nothing` if
`julia_compat` admits no release from v1.0 on.  The bundled libstdc++ only changes at the
releases recorded in `JULIA_LIBSTDCXX_VERSIONS`, so only those and the lower bound of each
range of `julia_compat` need checking.
"""
function oldest_admitted_libstdcxx(julia_compat::AbstractString)
    spec = semver_spec(julia_compat)
    candidates = unique(vcat(range_lower_bound.(spec.ranges), first.(JULIA_LIBSTDCXX_VERSIONS)))
    admitted = [v => julia_libstdcxx_entry(v) for v in candidates if v ∈ spec]
    filter!(((v, e),) -> e !== nothing, admitted)
    isempty(admitted) && return nothing
    return first(sort(admitted; by = ((v, e),) -> (e.libstdcxx, v)))
end

"""
    check_julia_libstdcxx!(pass_results, julia_compat, requirements)

Check that every official Julia release that `julia_compat` admits bundles a libstdc++ new
enough for the recorded libstdc++ requirements, adding to `pass_results` under
`"julia_libstdcxx"`.  `requirements` is a collection of `label => RuntimeRequirements`.
Julia's bundled libstdc++ is the one that libraries loaded into Julia, and executables run
through a JLL wrapper, bind to.  Symbol versions that no released Julia's libstdc++
defines always fail.
"""
function check_julia_libstdcxx!(pass_results::Dict{String,Vector{PassResult}}, julia_compat::AbstractString, requirements)
    pass_name = "julia_libstdcxx"
    fail(id, msg) = push_result!(pass_results, pass_name, :fail, id, msg)
    pass(id, msg) = push_result!(pass_results, pass_name, :success, id, msg)

    weakest = oldest_admitted_libstdcxx(julia_compat)
    newest_libstdcxx = maximum(e.libstdcxx for (_, e) in JULIA_LIBSTDCXX_VERSIONS)

    for (label, reqs) in requirements
        for r in reqs.unknown_libstdcxx
            fail("[$(label)] $(r.file)", "needs $(r.value) from libstdc++, which no released Julia bundles " *
                 "(the newest libstdc++ bundled with Julia is $(newest_libstdcxx)); build with an older compiler")
        end

        r = reqs.libstdcxx
        r === nothing && continue
        id = "[$(label)] $(r.file)"
        if weakest === nothing
            push_result!(pass_results, pass_name, :warn, id,
                         "needs $(r.source) (libstdc++ $(r.value)), but julia_compat \"$(julia_compat)\" admits no Julia release from v1.0 on to check it against")
            continue
        end
        weakest_v, weakest_e = weakest
        if r.value > weakest_e.libstdcxx
            floor = minimum_julia_for_libstdcxx(r.value)
            fix = floor === nothing ? "no released Julia bundles a new enough libstdc++; build with an older compiler" :
                                      "set julia_compat=\"$(julia_compat_string(floor))\" (or a newer lower bound) in the recipe"
            fail(id, "needs $(r.source) (libstdc++ $(r.value)), but julia_compat \"$(julia_compat)\" admits Julia v$(weakest_v), " *
                     "which bundles libstdc++ $(weakest_e.libstdcxx); $(fix)")
        else
            pass(id, "needs $(r.source) (libstdc++ $(r.value)), provided by every Julia that julia_compat \"$(julia_compat)\" admits")
        end
    end
    return nothing
end

"""
    audit_package(julia_compat::AbstractString, requirements)

The package-level audit: checks that need packaging information as well as the runtime
requirements that `audit!()` recorded for each extraction.  `requirements` is a
collection of `label => RuntimeRequirements`, one per extraction, where `label` names the
extraction in messages (e.g. its platform triplet).  Returns the pass results; use
`success()` on them to see whether the package passes.

Checks:
- `julia_libstdcxx`: every Julia release that `julia_compat` admits bundles a libstdc++
  new enough for the binaries (see `check_julia_libstdcxx!()`).
"""
function audit_package(julia_compat::AbstractString, requirements)
    pass_results = Dict{String,Vector{PassResult}}()
    check_julia_libstdcxx!(pass_results, julia_compat, requirements)
    return pass_results
end
