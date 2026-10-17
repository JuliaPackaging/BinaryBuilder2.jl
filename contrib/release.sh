#!/usr/bin/env bash
#
# Create a release commit for one of the subprojects in this monorepo.
#
# The commit message collects every commit that touched the subproject's
# directory since the last release tag for that subproject:
#
#     Release Foo.jl v1.2.3
#
#     Release notes:
#      - [abc1234] some commit message
#      - [def5678] some other commit message
#
# Usage:
#     contrib/release.sh [options] <subproject> [version]
#
# `<subproject>` is the subproject directory (`JLLGenerator.jl`, or just
# `JLLGenerator`).  If `[version]` is given, the subproject's `Project.toml`
# is bumped to that version; otherwise the version already recorded in
# `Project.toml` is used (e.g. you bumped it by hand already).
#
# Every other `Project.toml` in the repository whose `[compat]` entry for this
# package does not admit the new version gets that entry widened (e.g.
# `"0.2"` -> `"0.2, 0.3"`), and the change is included in the release commit.
# In `--dry-run` mode the projects that would need widening are only listed.
#
# The release commit is tagged `<name>-v<version>` with an annotated tag that
# carries the commit message.  The tag is only created locally; push it with
# `git push origin HEAD <tag>` once you are happy with it.
#
# Options:
#     -n, --dry-run       Print the commit message, don't touch anything
#     -s, --since <rev>   Collect notes since <rev> instead of the last tag
#     -a, --add <path>    Also stage <path> in the release commit (repeatable)
#     -e, --edit          Open the commit message in your editor
#     -h, --help          Show this message

set -euo pipefail

usage() {
    sed -n '3,36p' "${BASH_SOURCE[0]}" | sed 's/^#\{1,2\} \{0,1\}//'
}

die() {
    echo "ERROR: $*" >&2
    exit 1
}

repo_root="$(git rev-parse --show-toplevel)"

dry_run=false
edit=false
since=""
extra_paths=()
positional=()

while [[ $# -gt 0 ]]; do
    case "$1" in
        -n|--dry-run) dry_run=true; shift ;;
        -e|--edit)    edit=true; shift ;;
        -s|--since)   since="${2:?--since requires a revision}"; shift 2 ;;
        -a|--add)     extra_paths+=("${2:?--add requires a path}"); shift 2 ;;
        -h|--help)    usage; exit 0 ;;
        -*)           die "unknown option '$1'" ;;
        *)            positional+=("$1"); shift ;;
    esac
done

if [[ ${#positional[@]} -lt 1 || ${#positional[@]} -gt 2 ]]; then
    usage >&2
    exit 1
fi

# Normalize the subproject into a directory (`Foo.jl`) relative to the repo root
subproject="${positional[0]%/}"
subproject="$(basename "${subproject}")"
proj_dir="${subproject}"
if [[ ! -f "${repo_root}/${proj_dir}/Project.toml" ]]; then
    proj_dir="${subproject}.jl"
fi
project_toml="${repo_root}/${proj_dir}/Project.toml"
[[ -f "${project_toml}" ]] || die "no such subproject '${subproject}' (looked for ${subproject}{,.jl}/Project.toml)"

# Pull the package name out of `Project.toml`; tags are named `${name}-v${version}`
name="$(sed -n 's/^name *= *"\(.*\)"/\1/p' "${project_toml}" | head -1)"
[[ -n "${name}" ]] || die "could not parse 'name' out of ${project_toml}"

# Either bump the version to what the user asked for, or use what's already there
if [[ ${#positional[@]} -eq 2 ]]; then
    version="${positional[1]#v}"
    [[ "${version}" =~ ^[0-9]+\.[0-9]+\.[0-9]+([-+].*)?$ ]] || die "'${version}' is not a semver version"
else
    version="$(sed -n 's/^version *= *"\(.*\)"/\1/p' "${project_toml}" | head -1)"
    [[ -n "${version}" ]] || die "could not parse 'version' out of ${project_toml}"
fi

# Refuse to cut a release whose tag already exists; the version must be bumped first
tag_name="${name}-v${version}"
if git -C "${repo_root}" rev-parse -q --verify "refs/tags/${tag_name}" >/dev/null; then
    die "tag '${tag_name}' already exists; bump the version (e.g. \`contrib/release.sh ${subproject} <new version>\`)"
fi

# Find every other project in the repo whose `[compat]` entry for this package
# does not admit the new version, and (unless this is a dry run) widen it by
# appending the minimal caret specifier that covers the new version.  Prints one
# `<path>\t<old spec>\t<new spec>` line per project needing a change.
compat_script='
using Pkg, TOML
name, version, fix = ARGS[1], VersionNumber(ARGS[2]), ARGS[3] == "true"
entry = version.major > 0 ? "$(version.major)" :
        version.minor > 0 ? "0.$(version.minor)" : "0.0.$(version.patch)"
for path in ARGS[4:end]
    compat = get(TOML.parsefile(path), "compat", Dict())
    haskey(compat, name) || continue
    old_spec = compat[name]
    version in Pkg.Types.semver_spec(old_spec) && continue
    new_spec = "$(old_spec), $(entry)"
    if !(version in Pkg.Types.semver_spec(new_spec))
        error("appending \"$(entry)\" to $(name) compat in $(path) still does not admit v$(version)")
    end
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
command -v julia >/dev/null || die "julia is required to check compat bounds of dependent projects"
dependent_tomls=()
while IFS= read -r toml; do
    [[ "${toml}" == "${proj_dir}/Project.toml" ]] && continue
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

# Find the point in history to collect release notes from: an explicit `--since`,
# otherwise the most recent `${name}-v*` tag that is actually an ancestor of HEAD.
if [[ -z "${since}" ]]; then
    while read -r tag; do
        [[ -n "${tag}" ]] || continue
        if git merge-base --is-ancestor "${tag}" HEAD 2>/dev/null; then
            since="${tag}"
            break
        fi
    done < <(git -C "${repo_root}" tag --list "${name}-v*" --sort=-v:refname)
fi

if [[ -n "${since}" ]]; then
    range="${since}..HEAD"
else
    echo "WARNING: no '${name}-v*' tag found, collecting notes from the start of history" >&2
    range="HEAD"
fi

# Collect every commit touching the subproject since then, skipping merges and
# skipping previous release commits for this same package.
notes="$(git -C "${repo_root}" log --no-merges --format=' - [%h] %s' "${range}" -- "${proj_dir}" \
         | grep -v -E "^ - \[[0-9a-f]+\] Release ${name}(\.jl)? v" || true)"

message="Release ${name}.jl v${version}"
if [[ -n "${notes}" ]]; then
    message="${message}"$'\n\n'"Release notes:"$'\n'"${notes}"
else
    echo "WARNING: no commits touching ${proj_dir} since ${since:-the start of history}" >&2
fi

if [[ -n "${compat_notes}" ]]; then
    message="${message}"$'\n\n'"Compat bounds widened to admit v${version}:"$'\n'"${compat_notes}"
fi

if ${dry_run}; then
    echo "--- ${proj_dir} (${since:-start of history} -> HEAD) ---"
    echo "${message}"
    exit 0
fi

git -C "${repo_root}" add -- "${proj_dir}/Project.toml"
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
    commit_args+=(--edit)
fi
git -C "${repo_root}" "${commit_args[@]}"

# Tag the release commit, reusing its (possibly edited) message as the tag annotation
git -C "${repo_root}" log -1 --format=%B HEAD | git -C "${repo_root}" tag -a "${tag_name}" -F - HEAD
echo "Tagged ${tag_name}; push with: git push origin HEAD ${tag_name}"
