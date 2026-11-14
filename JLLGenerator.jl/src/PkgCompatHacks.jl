# X-ref: https://github.com/JuliaLang/Pkg.jl/pull/3580
using Pkg
workaround_string(x) = string(x)

# Parse a `JLLPackageDependency` compat string, in which `"*"` means "no bound"
compat_spec(compat::AbstractString) = compat == "*" ? Pkg.Types.VersionSpec("*") : Pkg.Types.semver_spec(compat)
function workaround_string(r::Pkg.Types.VersionRange)
    m, n = r.lower.n, r.upper.n
    if (m, n) == (0, 0)
        return "*"
    elseif m == 0
        return string(
            "0 - ",
            join(string.(r.upper.t), "."),
        )
    elseif n == 0
        return string(
            join(string.(r.lower.t), "."),
            " - *",
        )
    else
        # Always a hyphen range: a bare `X.Y` would be read as the caret specifier
        # `[X.Y.0, (X+1).0.0)`, while the range `[X.Y, X.Y]` means `[X.Y.0, X.(Y+1).0)`.
        return string(
            join(string.(r.lower.t[1:m]), "."),
            " - ",
            join(r.upper.t[1:n], "."),
        )
    end
end

function workaround_string(s::Pkg.Types.VersionSpec)
    if isempty(s)
        throw(ArgumentError("An empty version specifier has no compat string"))
    end
    # A compat entry with several comma-separated specifiers allows the union of them.
    return join(workaround_string.(s.ranges), ", ")
end

