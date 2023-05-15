#include <stdio.h>
#include <libfoo.h>

int main() {
    int version = libfoo_version();
    if (version == LIBFOO_VERSION) {
        printf("All is well in the world, libfoo version %d detected\n", LIBFOO_VERSION);
        return 0;
    } else {
        fprintf(stderr, "ERROR: libfoo version %d loaded, but expected %d\n", version, LIBFOO_VERSION);
        return 1;
    }
}
