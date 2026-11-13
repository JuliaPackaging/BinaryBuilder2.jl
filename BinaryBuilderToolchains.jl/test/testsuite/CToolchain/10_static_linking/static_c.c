#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include "libanswer.h"

int main(int argc, char ** argv) {
    char * buf = malloc(64);
    snprintf(buf, 64, "answer(%d) == %d", 7, answer(7));
    printf("%s\n", buf);
    free(buf);
    return 0;
}
