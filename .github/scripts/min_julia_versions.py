#!/usr/bin/env python3
"""Print the CI matrix of subprojects to test on their minimum Julia version.

Usage:
    min_julia_versions.py DEFAULT_VERSION PROJECTS_JSON

PROJECTS_JSON is the list printed by affected_projects.py. For each of those
subprojects, the lowest `major.minor` Julia version admitted by its
`[compat] julia` entry is computed; subprojects whose minimum is lower than
DEFAULT_VERSION (the version the main test job uses) are printed as a JSON
list of `{"project": ..., "julia-version": ...}` objects.
"""

import json
import re
import sys
import tomllib
from pathlib import Path

ROOT = Path(__file__).resolve().parents[2]


def parse_version(s):
    parts = [int(p) for p in s.strip().split(".")]
    return tuple((parts + [0, 0, 0])[:3])


def lower_bound(spec):
    """Lowest version admitted by one comma-separated Pkg compat entry."""
    spec = spec.strip()
    m = re.fullmatch(r"(\S+)\s+-\s+\S+", spec)
    if m:
        return parse_version(m.group(1))
    m = re.fullmatch(r"(\^|~|=|>=|≥)?\s*([0-9.]+)", spec)
    if not m:
        sys.exit(f"Unsupported julia compat entry: {spec!r}")
    return parse_version(m.group(2))


def min_julia(compat):
    return min(lower_bound(s) for s in compat.split(","))


def main(argv):
    if len(argv) != 2:
        sys.exit(__doc__)
    default = parse_version(argv[0])[:2]
    matrix = []
    for project in json.loads(argv[1]):
        toml = tomllib.loads((ROOT / project / "Project.toml").read_text())
        compat = toml.get("compat", {}).get("julia")
        if compat is None:
            continue
        lowest = min_julia(compat)[:2]
        if lowest < default:
            matrix.append({
                "project": project,
                "julia-version": f"{lowest[0]}.{lowest[1]}",
            })
    print(json.dumps(matrix, separators=(",", ":")))


if __name__ == "__main__":
    main(sys.argv[1:])
