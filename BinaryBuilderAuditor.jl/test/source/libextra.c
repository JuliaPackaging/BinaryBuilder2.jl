// This translation unit references a symbol that nothing provides.  We only ever
// put it into an archive, never into a shared library, so it gives us an archive
// whose undefined symbols are not covered by its dynamic variant.
extern int undefined_extra_symbol(int);

int extra(int a) {
    return undefined_extra_symbol(a);
}
