#!/usr/bin/env bash
# Usage: verify.sh <archive-linked exe> [<fully static exe>...]
#
# Checks that every executable defines `answer()` itself (i.e. `libanswer.a` was
# linked in), and that the fully static executables load no shared libraries
# beyond what the target requires.
set -euo pipefail

fail() {
    echo "$*" >&2
    exit 1
}

for exe in "$@"; do
    syms="$(${NM} "${exe}")"
    if ! grep -Eq '^[0-9a-fA-F]+ T _?answer$' <<<"${syms}"; then
        fail "${exe} does not define 'answer' from libanswer.a"
    fi
done
shift

for exe in "$@"; do
    case "${CC_TARGET}" in
        *-linux-*|*-freebsd*)
            phdrs="$(${READELF} -lW "${exe}")"
            if grep -q 'INTERP' <<<"${phdrs}"; then
                fail "${exe} has a program interpreter:" "$(grep -A1 INTERP <<<"${phdrs}")"
            fi
            dynamic="$(${READELF} -dW "${exe}")"
            if grep -q '(NEEDED)' <<<"${dynamic}"; then
                fail "${exe} depends on shared libraries:" "$(grep '(NEEDED)' <<<"${dynamic}")"
            fi
            ;;
        *-mingw*)
            # Statically-linked Windows executables still import from the system DLLs,
            # but nothing that we would have to ship alongside them.
            headers="$(${OBJDUMP} -p "${exe}")"
            for dll in $(sed -n 's/.*DLL Name: *//p' <<<"${headers}" | tr '[:upper:]' '[:lower:]'); do
                case "${dll}" in
                    kernel32.dll|msvcrt.dll|ucrtbase.dll|api-ms-win-*.dll) ;;
                    *) fail "${exe} imports unexpected DLL ${dll}" ;;
                esac
            done
            ;;
        *)
            fail "Don't know how to verify static executables for ${CC_TARGET}"
            ;;
    esac
done
