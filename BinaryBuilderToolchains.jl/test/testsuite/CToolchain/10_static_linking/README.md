# Static linking

This test builds a static archive (`libanswer.a`) and links it into three executables:

 - `archive_c`: a C program linked normally against the system libraries, with `libanswer.a` linked in statically.
 - `static_c`: the same C program, linked fully statically with `-static`.
 - `static_cxx`: a C++ program that throws and catches an exception, linked fully statically with `-static`, so that the static C++ runtime and unwinder get exercised.

Static linking pulls in the toolchain's static libraries (`libc.a`, `libgcc.a`, `libgcc_eh.a`, `libstdc++.a`, `libc++.a`, ...), so it catches broken or missing archives that dynamic links never touch.

`verify.sh` inspects the outputs without running them, so `compile` checks them as well:
 - every executable must define `answer()` itself, i.e. `libanswer.a` was really linked in;
 - on Linux and FreeBSD, the static executables must have no program interpreter (`PT_INTERP`) and no `NEEDED` entries;
 - on Windows, the static executables may only import system DLLs (`kernel32.dll`, `msvcrt.dll`, `ucrtbase.dll`, `api-ms-win-*.dll`), not `libgcc_s`, `libstdc++`, `libwinpthread` and the like.

macOS does not support fully static executables, so there only `archive_c` is built.
