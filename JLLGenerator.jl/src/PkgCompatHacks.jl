# X-ref: https://github.com/JuliaLang/Pkg.jl/pull/3580
using Pkg
workaround_string(x) = string(x)
function workaround_string(r::Pkg.Types.VersionRange)
    m, n = r.lower.n, r.upper.n
    if (m, n) == (0, 0)
        return "*"
    elseif m == 0
        return string(
            "0 -",
            join(string.(r.upper.t), "."),
        )
    elseif n == 0
        return string(
            join(string.(r.lower.t), "."),
            " - *",
        )
    else
        lower = join(string.(r.lower.t[1:m]), ".")
        if r.lower == r.upper
            return lower
        else
            return string(
                lower,
                " - ",
                join(r.upper.t[1:n], "."),
            )
        end
    end
end

function workaround_string(s::Pkg.Types.VersionSpec)
    isempty(s) && return workaround_string(Pkg.Types._empty_symbol)
    length(s.ranges) == 1 && return workaround_string(s.ranges[1])
    return string("[", join(workaround_string.(s.ranges), ", "), "]",)
end

