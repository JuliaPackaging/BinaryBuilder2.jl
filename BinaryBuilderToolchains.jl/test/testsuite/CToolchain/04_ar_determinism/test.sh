#!/bin/bash

ARGS=( "$@" )
for ((i=0; i<"${#ARGS[@]}"; ++i)); do
    if [[ "${ARGS[i]}" == "-u" ]]; then
        unset ARGS[i]
	fi
done

echo "ARGS: ${ARGS[@]}"
