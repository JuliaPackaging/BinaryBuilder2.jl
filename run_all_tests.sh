#!/bin/bash
set -euo pipefail

SORTED_PROJECTS=(
    "MultiHashParsing.jl"
    "TreeArchival.jl"
    "BinaryBuilderGitUtils.jl"
    "BinaryBuilderSources.jl"
    "BinaryBuilderToolchains.jl"
)

for PROJECT in "${SORTED_PROJECTS[@]}"; do
    julia --project="${PROJECT}" -e 'import Pkg; Pkg.test()'
done
