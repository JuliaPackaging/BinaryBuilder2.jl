#!/usr/bin/env bash
#
# Update the commits that our toolchain JLLs are pinned to in
# `BinaryBuilderToolchains.jl/src/JLLPins.jl` to the current heads of the
# branches they were taken from.
#
# Each entry of `jll_pins` looks like:
#
#     ("GCC_jll", "bb2/GCCBootstrap-x86_64-linux-gnu") => "<commit>",
#
# and is looked up in `https://github.com/<org>/GCC_jll.jl`, where `<org>`
# defaults to `staticfloat`.
#
# Usage:
#     contrib/update_jll_pins.sh [options] [jll_name...]
#
# If any `jll_name`s are given (e.g. `GCC_jll`), only their pins are updated.
#
# Options:
#     -n, --dry-run       Print what would change, don't touch anything
#     -c, --check         Like `--dry-run`, but exit non-zero if anything is
#                         out of date (e.g. for CI)
#     -o, --org <org>     GitHub organization the JLL repositories live in
#     -h, --help          Show this message

set -euo pipefail

# A repository that doesn't exist looks private to GitHub; fail instead of prompting
export GIT_TERMINAL_PROMPT=0

REPO_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
PINS_FILE="${REPO_ROOT}/BinaryBuilderToolchains.jl/src/JLLPins.jl"

usage() {
    sed -n '2,/^$/s/^# \{0,1\}//p' "${BASH_SOURCE[0]}"
}

DRY_RUN=false
CHECK=false
ORG="staticfloat"
ONLY=()
while [[ $# -gt 0 ]]; do
    case "$1" in
        -n|--dry-run) DRY_RUN=true; shift ;;
        -c|--check) DRY_RUN=true; CHECK=true; shift ;;
        -o|--org) ORG="$2"; shift 2 ;;
        -h|--help) usage; exit 0 ;;
        -*) echo "Unknown option '$1'" >&2; usage >&2; exit 1 ;;
        *) ONLY+=("$1"); shift ;;
    esac
done

PIN_REGEX='^[[:space:]]*\("([^"]+)", "([^"]+)"\)[[:space:]]*=>[[:space:]]*"([0-9a-f]{40})",'

wanted() {
    [[ ${#ONLY[@]} -eq 0 ]] && return 0
    local name
    for name in "${ONLY[@]}"; do
        [[ "${name}" == "$1" ]] && return 0
    done
    return 1
}

NEW_PINS="$(mktemp)"
trap 'rm -f "${NEW_PINS}"' EXIT

num_found=0
num_changed=0
num_failed=0
while IFS= read -r line; do
    if [[ "${line}" =~ ${PIN_REGEX} ]] && wanted "${BASH_REMATCH[1]}"; then
        name="${BASH_REMATCH[1]}"
        branch="${BASH_REMATCH[2]}"
        old="${BASH_REMATCH[3]}"
        url="https://github.com/${ORG}/${name}.jl"
        num_found=$((num_found + 1))

        # Retry a couple of times, as GitHub occasionally resets connections
        new=""
        for attempt in 1 2 3; do
            if refs="$(git ls-remote "${url}" "refs/heads/${branch}")"; then
                new="$(cut -f1 <<< "${refs}")"
                break
            fi
            sleep "${attempt}"
        done
        if [[ -z "${new}" ]]; then
            echo "  ! ${name} (${branch}): unable to find branch in ${url}" >&2
            num_failed=$((num_failed + 1))
        elif [[ "${new}" != "${old}" ]]; then
            echo "  * ${name} (${branch}): ${old:0:10} -> ${new:0:10}"
            line="${line/${old}/${new}}"
            num_changed=$((num_changed + 1))
        fi
    fi
    printf '%s\n' "${line}" >> "${NEW_PINS}"
done < "${PINS_FILE}"

if [[ ${#ONLY[@]} -gt 0 && ${num_found} -eq 0 ]]; then
    echo "No pins found for: ${ONLY[*]}" >&2
    exit 1
fi

echo "${num_changed} of ${num_found} pins out of date"
if [[ ${num_failed} -gt 0 ]]; then
    echo "${num_failed} pins could not be looked up" >&2
    exit 1
fi

if [[ "${DRY_RUN}" == "true" ]]; then
    if [[ "${CHECK}" == "true" && ${num_changed} -gt 0 ]]; then
        exit 1
    fi
    exit 0
fi

if [[ ${num_changed} -gt 0 ]]; then
    cp "${NEW_PINS}" "${PINS_FILE}"
    echo "Updated ${PINS_FILE#"${REPO_ROOT}/"}"
fi
