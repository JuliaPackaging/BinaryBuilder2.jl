extern int baz(int);
extern int qux(int);
int bar(int a) {
    return baz(a) - qux(a);
}
