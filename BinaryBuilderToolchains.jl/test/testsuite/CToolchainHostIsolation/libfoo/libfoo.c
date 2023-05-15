// Usually, we'd `#include "libfoo.h"` here, but since we're defining the
// value of `LIBFOO_VERSION` on the command-line, we don't really need to.

int libfoo_version() {
    return LIBFOO_VERSION;
}
