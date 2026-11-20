#include <stdio.h>
#include <stdlib.h>

void count_dracula(int N) {
    printf("Count with me!\n");
    for (int i=0; i<N; ++i) {
        printf("  %d ", i);
        for (int j=0; j<i; ++j) {
            printf("ha");
        }
        printf("\n");
    }
}

int main(int argc, char **argv) {
    if (argc != 1) {
        printf("Usage: count_dracula <N>\n");
        return 1;
    }

    count_dracula(atoi(argv[1]));
    return 0;
}
