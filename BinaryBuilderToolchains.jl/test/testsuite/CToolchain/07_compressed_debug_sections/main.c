#include <stdio.h>

volatile int a;

int func(int a) {
    printf("I was invoked with %d arguments!\n", a);
    return a/1000;
}

int main(int argc, char ** argv) {
    a = argc;
    return func(a);
}
