#!/usr/bin/env python3
"""Print the JSON list of subprojects whose tests CI should run.

Subprojects are `.` (BinaryBuilder2.jl itself) plus every top-level directory
holding a `Project.toml`, except `docs` (built by documentation.yml).

Usage:
    affected_projects.py --all
        Every subproject.
    affected_projects.py BASE_REF [HEAD_REF]
        Only subprojects affected by `git diff BASE_REF...HEAD_REF`
        (HEAD_REF defaults to HEAD).
    affected_projects.py --files FILE...
        Only subprojects affected by the given repo-relative paths.

A changed path selects subprojects as follows:
  * Paths in RUN_ALL (CI configuration) select every subproject.
  * The root Project.toml selects `.` and every subproject listed in its
    [workspace], since its [sources] and [compat] apply to all of them.
  * Paths inside a subproject's directory select that subproject.
  * Paths in IGNORED (docs, prose, unrelated workflows) select nothing.
  * Any other path belongs to the root package (`src/`, `test/`, `share/`,
    `bootstrap/`, `contrib/`, ...) and selects `.`.
Every selected subproject then also selects each subproject that depends on
it, transitively. A dependency is any sibling package named in a subproject's
[deps], [weakdeps] or [extras] (test-only deps count, since a change to them
can break the dependent's tests).
"""

import json
import subprocess
import sys
import tomllib
from fnmatch import fnmatch
from pathlib import Path

ROOT = Path(__file__).resolve().parents[2]

EXCLUDED_DIRS = {"docs"}

RUN_ALL = [
    ".github/workflows/CI.yml",
    ".github/scripts/*",
]

IGNORED = [
    "docs/*",
    "*.md",
    "LICENSE",
    "JuliaCon2024/*",
    ".github/*",
    ".gitignore",
    ".vscode/*",
]


def discover_projects():
    """Map each subproject directory to its parsed Project.toml."""
    projects = {".": tomllib.loads((ROOT / "Project.toml").read_text())}
    for toml in sorted(ROOT.glob("*/Project.toml")):
        d = toml.parent.name
        if d in EXCLUDED_DIRS:
            continue
        projects[d] = tomllib.loads(toml.read_text())
    return projects


def reverse_deps(projects):
    """Map each subproject directory to the directories that depend on it."""
    by_name = {p["name"]: d for d, p in projects.items() if "name" in p}
    rdeps = {d: set() for d in projects}
    for d, p in projects.items():
        for section in ("deps", "weakdeps", "extras"):
            for name in p.get(section, {}):
                dep = by_name.get(name)
                if dep is not None and dep != d:
                    rdeps[dep].add(d)
    return rdeps


def matches(path, patterns):
    return any(fnmatch(path, pat) for pat in patterns)


def directly_affected(files, projects):
    selected = set()
    for f in files:
        if matches(f, RUN_ALL):
            return set(projects)
        if f == "Project.toml":
            members = projects["."].get("workspace", {}).get("projects", [])
            selected.update(m for m in members if m in projects)
            selected.add(".")
            continue
        top = f.split("/", 1)[0]
        if "/" in f and top in projects:
            selected.add(top)
        elif matches(f, IGNORED):
            continue
        else:
            selected.add(".")
    return selected


def close_over_dependents(selected, rdeps):
    todo = list(selected)
    result = set(selected)
    while todo:
        for dependent in rdeps[todo.pop()]:
            if dependent not in result:
                result.add(dependent)
                todo.append(dependent)
    return result


def changed_files(base, head):
    out = subprocess.run(
        ["git", "-C", str(ROOT), "diff", "--name-only", f"{base}...{head}"],
        check=True, capture_output=True, text=True,
    ).stdout
    return [line for line in out.splitlines() if line]


def ordered(selected):
    # `.` first, then alphabetical, matching the order of the full list.
    return sorted(selected, key=lambda d: (d != ".", d.lower()))


def main(argv):
    projects = discover_projects()
    if argv == ["--all"]:
        selected = set(projects)
    else:
        if argv[:1] == ["--files"]:
            files = argv[1:]
        elif 1 <= len(argv) <= 2:
            files = changed_files(argv[0], argv[1] if len(argv) == 2 else "HEAD")
        else:
            sys.exit(__doc__)
        for f in files:
            print(f"changed: {f}", file=sys.stderr)
        selected = close_over_dependents(
            directly_affected(files, projects), reverse_deps(projects))
    print(json.dumps(ordered(selected), separators=(",", ":")))


if __name__ == "__main__":
    main(sys.argv[1:])
