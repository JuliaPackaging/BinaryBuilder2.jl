// This translation unit references libc symbols that a linked shared library will
// record with a symbol version (e.g. `malloc@GLIBC_2.2.5`), while the relocatable
// object inside an archive references the bare name.  It exists so that the static
// closure check is exercised against versioned symbols.
#include <stdlib.h>
#include <string.h>

void *dup_bytes(const void *src, unsigned long n) {
    void *dst = malloc(n);
    if (dst != NULL) {
        memcpy(dst, src, n);
    }
    return dst;
}
