extern int plus(int, int);

int mult(int a, int b) {
    int accum = a;
    for (int b_idx = 1; b_idx < b; b_idx++ ) {
        accum = plus(accum, a);
    }
    return accum;
}
