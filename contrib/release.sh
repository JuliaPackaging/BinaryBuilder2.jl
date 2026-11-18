#!/usr/bin/env bash
#
# Create a release commit for one of the subprojects in this monorepo.
#
# The commit message collects every commit that touched the subproject's
# directory since the last release tag for that subproject, after a
# JuliaRegistrator trigger for the release:
#
#     Release Foo.jl v1.2.3
#
#     @JuliaRegistrator register subdir=Foo.jl
#
#     Release notes:
#      - [abc1234] some commit message
#      - [def5678] some other commit message
#
# A release is breaking when the new version is not compatible with the
# previous release under Julia's semver rules for `[compat]`: a major bump for
# 1.x and later, a minor bump for 0.x, and any bump for 0.0.x.  The previous
# release is the tag that notes are collected from (see `--since`), or else
# the version in `Project.toml` before it is bumped; with neither, there is no
# previous release and the release is not breaking.  General's AutoMerge
# rejects a breaking release unless its notes mention breaking changes, so a
# breaking release needs at least one `--breaking "<text>"`, and the notes then
# read:
#
#     Release notes:
#
#     ## Breaking changes
#
#     - <text>
#
#     ## Changes
#
#      - [abc1234] some commit message
#
# The top-level package's trigger is a bare `@JuliaRegistrator register`.
# Registrator takes everything after `Release notes:` to the end of the comment
# as the release notes, so the trigger and the notes come last.  Once the
# release commit is pushed, register it by posting everything from the trigger
# line onwards as a comment on the commit; the script prints that comment body
# when it finishes, and `--registrator-comment <rev>` reprints it for any
# release commit.
#
# Usage:
#     contrib/release.sh [options] <subproject> [version]
#
# `<subproject>` is the subproject directory (`JLLGenerator.jl`, or just
# `JLLGenerator`), or `BinaryBuilder2` (or `.`) for the top-level package.
# If `[version]` is given, the subproject's `Project.toml` is bumped to that
# version; otherwise the version already recorded in `Project.toml` is used
# (e.g. you bumped it by hand already).
#
# Every other `Project.toml` in the repository whose `[compat]` entry for this
# package does not admit the new version, or also admits versions older than
# its `major.minor`, gets that entry replaced by the new version's `major.minor`
# (e.g. `"0.2"` -> `"0.3"`, or `"1.2"` -> `"1.3"`), so that it only admits the
# in-repo copy (as `test/MonorepoCompatTests.jl` requires), and the change is
# included in the release commit.  In `--dry-run` mode the projects that would
# need updating are only listed.
# These changes are listed in a "Compat bounds updated" section placed before
# the trigger, so they are recorded in the commit but stay out of the
# package's release notes.
#
# Before anything is changed, the package's `[deps]` and `[compat]` are
# resolved against the registered versions in the General registry, the same
# way AutoMerge's `Pkg.add` check does.  If that fails (typically because a
# sibling subproject's compat bump has not been released yet), the script
# stops; release the missing dependencies first.
#
# The release commit is tagged `<name>-v<version>` (or just `v<version>` for
# the top-level BinaryBuilder2 package) with an annotated tag that
# carries the commit message.  The tag is only created locally; push it with
# `git push origin HEAD <tag>` once you are happy with it.
#
# Options:
#     -n, --dry-run       Print the commit message, don't touch anything
#     -s, --since <rev>   Collect notes since <rev> instead of the last tag
#     -a, --add <path>    Also stage <path> in the release commit (repeatable)
#     -b, --breaking <text>
#                         Describe a breaking change in the release notes
#                         (repeatable, one list item each); required when the
#                         release is breaking
#     -e, --edit          Open the commit message in your editor
#         --no-registry-check
#                         Skip checking that the package's [deps]/[compat]
#                         resolve against already-registered versions
#     -r, --registrator-comment <rev>
#                         Print the JuliaRegistrator comment body of release
#                         commit <rev> (e.g. `HEAD`) and exit; post it with
#                         `gh api 'repos/{owner}/{repo}/commits/<sha>/comments' -F body=@-`
#     -h, --help          Show this message

set -euo pipefail

usage() {
    sed -n '3,/^[^#]/{/^#/p}' "${BASH_SOURCE[0]}" | sed 's/^#\{1,2\} \{0,1\}//'
}

die() {
    echo "ERROR: $*" >&2
    exit 1
}

# Print the JuliaRegistrator comment body (the trigger line and everything after
# it) out of commit <rev>'s message
registrator_comment() {
    local comment
    comment="$(git -C "${repo_root}" log -1 --format=%B "$1" | sed -n '/^@JuliaRegistrator register/,$p')"
    [[ -n "${comment}" ]] || die "commit $1 has no '@JuliaRegistrator register' line"
    echo "${comment}"
}

repo_root="$(git rev-parse --show-toplevel)"

dry_run=false
edit=false
registry_check=true
since=""
extra_paths=()
breaking_notes=()
positional=()

while [[ $# -gt 0 ]]; do
    case "$1" in
        -n|--dry-run) dry_run=true; shift ;;
        -e|--edit)    edit=true; shift ;;
        --no-registry-check) registry_check=false; shift ;;
        -s|--since)   since="${2:?--since requires a revision}"; shift 2 ;;
        -a|--add)     extra_paths+=("${2:?--add requires a path}"); shift 2 ;;
        -b|--breaking) breaking_notes+=("${2:?--breaking requires a description}"); shift 2 ;;
        -r|--registrator-comment)
                      registrator_comment "${2:?--registrator-comment requires a revision}"; exit 0 ;;
        -h|--help)    usage; exit 0 ;;
        -*)           die "unknown option '$1'" ;;
        *)            positional+=("$1"); shift ;;
    esac
done

if [[ ${#positional[@]} -lt 1 || ${#positional[@]} -gt 2 ]]; then
    usage >&2
    exit 1
fi

# Normalize the subproject into a directory (`Foo.jl`) relative to the repo root;
# the top-level package lives in the repo root itself (`.`).
root_name="$(sed -n 's/^name *= *"\(.*\)"/\1/p' "${repo_root}/Project.toml" | head -1)"
subproject="${positional[0]%/}"
subproject="$(basename "${subproject}")"
if [[ "${subproject}" == "." || "${subproject%.jl}" == "${root_name}" ]]; then
    proj_dir="."
else
    proj_dir="${subproject}"
    if [[ ! -f "${repo_root}/${proj_dir}/Project.toml" ]]; then
        proj_dir="${subproject}.jl"
    fi
fi
project_rel="${proj_dir#.}"
project_rel="${project_rel:+${project_rel}/}Project.toml"
project_toml="${repo_root}/${project_rel}"
[[ -f "${project_toml}" ]] || die "no such subproject '${subproject}' (looked for ${subproject}{,.jl}/Project.toml)"

# Pull the package name out of `Project.toml`; subproject tags are named
# `${name}-v${version}`, while the top-level package uses bare `v${version}` tags.
name="$(sed -n 's/^name *= *"\(.*\)"/\1/p' "${project_toml}" | head -1)"
[[ -n "${name}" ]] || die "could not parse 'name' out of ${project_toml}"
if [[ "${proj_dir}" == "." ]]; then
    tag_prefix="v"
else
    tag_prefix="${name}-v"
fi

# Either bump the version to what the user asked for, or use what's already there
if [[ ${#positional[@]} -eq 2 ]]; then
    version="${positional[1]#v}"
    [[ "${version}" =~ ^[0-9]+\.[0-9]+\.[0-9]+([-+].*)?$ ]] || die "'${version}' is not a semver version"
else
    version="$(sed -n 's/^version *= *"\(.*\)"/\1/p' "${project_toml}" | head -1)"
    [[ -n "${version}" ]] || die "could not parse 'version' out of ${project_toml}"
fi

# Refuse to cut a release whose tag already exists; the version must be bumped first
tag_name="${tag_prefix}${version}"
if git -C "${repo_root}" rev-parse -q --verify "refs/tags/${tag_name}" >/dev/null; then
    die "tag '${tag_name}' already exists; bump the version (e.g. \`contrib/release.sh ${subproject} <new version>\`)"
fi

# Find the point in history to collect release notes from: an explicit `--since`,
# otherwise the most recent `${tag_prefix}*` tag that is actually an ancestor of HEAD.
if [[ -z "${since}" ]]; then
    while read -r tag; do
        [[ -n "${tag}" ]] || continue
        if git -C "${repo_root}" merge-base --is-ancestor "${tag}" HEAD 2>/dev/null; then
            since="${tag}"
            break
        fi
    done < <(git -C "${repo_root}" tag --list "${tag_prefix}*" --sort=-v:refname)
fi

# The previous release's version: that of the tag notes are collected from, or
# else the `Project.toml` version before any bump.
semver_re='^([0-9]+)\.([0-9]+)\.([0-9]+)([-+].*)?$'
prev_version=""
if [[ "${since}" == "${tag_prefix}"* && "${since#"${tag_prefix}"}" =~ ${semver_re} ]]; then
    prev_version="${since#"${tag_prefix}"}"
elif [[ ${#positional[@]} -eq 2 ]]; then
    prev_version="$(sed -n 's/^version *= *"\(.*\)"/\1/p' "${project_toml}" | head -1)"
fi

# Print the `[compat]` range a version belongs to under Julia's semver rules
# (`2`, `0.3` or `0.0.4`); two versions are compatible iff these match.
compat_range() {
    [[ "$1" =~ ${semver_re} ]] || return 1
    local major="${BASH_REMATCH[1]}" minor="${BASH_REMATCH[2]}" patch="${BASH_REMATCH[3]}"
    if (( 10#${major} > 0 )); then
        echo "$((10#${major}))"
    elif (( 10#${minor} > 0 )); then
        echo "0.$((10#${minor}))"
    else
        echo "0.0.$((10#${patch}))"
    fi
}

breaking=false
if [[ -n "${prev_version}" ]]; then
    prev_range="$(compat_range "${prev_version}")" \
        || die "previous version '${prev_version}' is not a semver version"
    if [[ "${prev_range}" != "$(compat_range "${version}")" ]]; then
        breaking=true
    fi
fi
if ${breaking} && [[ ${#breaking_notes[@]} -eq 0 ]]; then
    die "v${version} is a breaking release (previous release v${prev_version}), and AutoMerge rejects breaking releases whose notes don't mention it. Describe each breaking change with --breaking \"<text>\" (repeatable), e.g. \`contrib/release.sh --breaking \"Drop support for Julia 1.9\" ${subproject}${positional[1]:+ ${positional[1]}}\`."
fi

# Check that the package's `[deps]` and `[compat]` can be satisfied by versions
# that are already registered, which is what AutoMerge checks with
# `Pkg.add(...)`.  This catches releases whose compat requires a version of a
# dependency (or a dependency's dependency) that has not been registered yet,
# e.g. a sibling subproject whose compat bump has not been released.
registry_check_script='
using Pkg, TOML
project = TOML.parsefile(ARGS[1])
deps = get(project, "deps", Dict{String,Any}())
compat = filter(p -> p.first == "julia" || haskey(deps, p.first), get(project, "compat", Dict{String,Any}()))
mktempdir() do dir
    open(joinpath(dir, "Project.toml"), "w") do io
        TOML.print(io, Dict("deps" => deps, "compat" => compat))
    end
    Pkg.activate(dir; io=devnull)
    Pkg.Registry.update(; io=devnull)
    try
        Pkg.resolve(; io=devnull)
    catch err
        err isa Pkg.Resolve.ResolverError || rethrow()
        println(stderr, sprint(showerror, err))
        exit(1)
    end
end
'
command -v julia >/dev/null || die "julia is required to check compat bounds against the registry"
if ${registry_check}; then
    echo "Checking that ${name}'s dependencies resolve against registered versions..." >&2
    JULIA_PKG_GC_AUTO=0 julia --startup-file=no --history-file=no -e "${registry_check_script}" "${project_toml}" >&2 \
        || die "${name}'s [deps]/[compat] cannot be satisfied by registered versions, so AutoMerge's \`Pkg.add(\"${name}\")\` would fail. Release the dependencies it needs first (see the resolver log above), or pass --no-registry-check to skip this check."
fi

# Find every other project in the repo whose `[compat]` entry for this package
# does not admit the new version or reaches below its `major.minor` (`"1.2"`
# when releasing v1.3.0), and (unless this is a dry run) replace it with
# the new version's `major.minor` (`0.0.patch` for `0.0.x` versions, where every
# patch release is breaking).  Prints one `<path>\t<old spec>\t<new spec>`
# line per project needing a change.
compat_script='
using Pkg, TOML
name, version, fix = ARGS[1], VersionNumber(ARGS[2]), ARGS[3] == "true"
new_spec = version.major == version.minor == 0 ? "0.0.$(version.patch)" : "$(version.major).$(version.minor)"
floor_spec = Pkg.Types.semver_spec(new_spec)
for path in ARGS[4:end]
    compat = get(TOML.parsefile(path), "compat", Dict())
    haskey(compat, name) || continue
    old_spec = compat[name]
    spec = Pkg.Types.semver_spec(old_spec)
    version in spec && (spec ∩ floor_spec) == spec && continue
    println(path, "\t", old_spec, "\t", new_spec)
    fix || continue
    # Rewrite just the matching line within the `[compat]` section to preserve formatting
    section, found = "", false
    lines = map(readlines(path)) do line
        m = match(r"^\s*\[(.*)\]\s*$", line)
        if m !== nothing
            section = strip(m[1])
        elseif section == "compat" && occursin(Regex("^\\s*\"?\\Q$(name)\\E\"?\\s*="), line)
            found = true
            return "$(name) = \"$(new_spec)\""
        end
        return line
    end
    found || error("could not locate $(name) compat line in $(path)")
    write(path, join(lines, "\n") * "\n")
end
'
dependent_tomls=()
while IFS= read -r toml; do
    [[ "${toml}" == "${project_rel}" ]] && continue
    dependent_tomls+=("${repo_root}/${toml}")
done < <(git -C "${repo_root}" ls-files -- 'Project.toml' '*/Project.toml')
compat_changes="$(julia --startup-file=no --history-file=no -e "${compat_script}" \
                  "${name}" "${version}" "$(! ${dry_run} && echo true || echo false)" \
                  ${dependent_tomls+"${dependent_tomls[@]}"})" \
    || die "failed to check compat bounds of dependent projects"
compat_paths=()
compat_notes=""
while IFS=$'\t' read -r path old_spec new_spec; do
    [[ -n "${path}" ]] || continue
    path="${path#"${repo_root}/"}"
    compat_paths+=("${path}")
    compat_notes+=" - ${path}: ${name} = \"${old_spec}\" -> \"${new_spec}\""$'\n'
done <<< "${compat_changes}"
compat_notes="${compat_notes%$'\n'}"

if [[ ${#positional[@]} -eq 2 ]] && ! ${dry_run}; then
    # Only rewrite the `version` key in the top-level (pre-`[section]`) block
    awk -v v="${version}" '
        /^\[/ { in_sections = 1 }
        !in_sections && !done && /^version *=/ { print "version = \"" v "\""; done = 1; next }
        { print }
    ' "${project_toml}" > "${project_toml}.tmp"
    mv "${project_toml}.tmp" "${project_toml}"
fi

if [[ -n "${since}" ]]; then
    range="${since}..HEAD"
else
    echo "WARNING: no '${tag_prefix}*' tag found, collecting notes from the start of history" >&2
    range="HEAD"
fi

# Collect every commit touching the subproject since then, skipping merges and
# skipping previous release commits for this same package.
# The top-level package lives in the repo root, so leave out the subproject directories.
pathspecs=("${proj_dir}")
if [[ "${proj_dir}" == "." ]]; then
    while IFS= read -r toml; do
        pathspecs+=(":(exclude)${toml%/Project.toml}")
    done < <(git -C "${repo_root}" ls-files -- '*.jl/Project.toml')
fi
notes="$(git -C "${repo_root}" log --no-merges --format=' - [%h] %s' "${range}" -- "${pathspecs[@]}" \
         | grep -v -E "^ - \[[0-9a-f]+\] Release ${name}(\.jl)? v" || true)"

if [[ "${proj_dir}" == "." ]]; then
    trigger="@JuliaRegistrator register"
else
    trigger="@JuliaRegistrator register subdir=${proj_dir}"
fi

message="Release ${name}.jl v${version}"
if [[ -n "${compat_notes}" ]]; then
    message="${message}"$'\n\n'"Compat bounds updated to admit v${version}:"$'\n'"${compat_notes}"
fi
message="${message}"$'\n\n'"${trigger}"
if [[ -z "${notes}" ]]; then
    echo "WARNING: no commits touching ${proj_dir} since ${since:-the start of history}" >&2
fi
if [[ ${#breaking_notes[@]} -gt 0 ]]; then
    message="${message}"$'\n\n'"Release notes:"$'\n\n'"## Breaking changes"$'\n'
    for item in "${breaking_notes[@]}"; do
        message="${message}"$'\n'"- ${item}"
    done
    if [[ -n "${notes}" ]]; then
        message="${message}"$'\n\n'"## Changes"$'\n\n'"${notes}"
    fi
elif [[ -n "${notes}" ]]; then
    message="${message}"$'\n\n'"Release notes:"$'\n'"${notes}"
fi

if ${dry_run}; then
    echo "--- ${proj_dir} (${since:-start of history} -> HEAD) ---"
    echo "${message}"
    exit 0
fi

git -C "${repo_root}" add -- "${project_rel}"
for path in ${compat_paths+"${compat_paths[@]}"}; do
    git -C "${repo_root}" add -- "${path}"
done
for path in ${extra_paths+"${extra_paths[@]}"}; do
    git -C "${repo_root}" add -- "${path}"
done

if git -C "${repo_root}" diff --cached --quiet; then
    die "nothing staged; bump a version or pass --add <path>"
fi

commit_args=(commit -m "${message}")
if ${edit}; then
    # Strip only git's instructions below the scissors line, keeping the
    # `## ...` headings that the default cleanup would drop as comments
    commit_args+=(--edit --cleanup=scissors)
fi
git -C "${repo_root}" "${commit_args[@]}"

# Tag the release commit, reusing its (possibly edited) message as the tag annotation
git -C "${repo_root}" log -1 --format=%B HEAD | git -C "${repo_root}" tag -a --cleanup=whitespace "${tag_name}" -F - HEAD
echo "Tagged ${tag_name}; push with: git push origin HEAD ${tag_name}"
echo "Then register it by posting this comment on the pushed commit:"
echo "    contrib/release.sh -r ${tag_name} | gh api 'repos/{owner}/{repo}/commits/$(git -C "${repo_root}" rev-parse HEAD)/comments' -F body=@-"
echo "-----"
registrator_comment HEAD
