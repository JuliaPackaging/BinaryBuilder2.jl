dlext ?= so
VERSION ?= 1

# Generate `include/libfoo.h` with the generated version, and build a dynamic library
# with the appropriate version in the given prefix.
install:
	mkdir -p $(prefix)/lib $(prefix)/include
	echo "#define LIBFOO_VERSION $(VERSION)" > $(prefix)/include/libfoo.h
	cat libfoo.h >> $(prefix)/include/libfoo.h
	$(CC) -DLIBFOO_VERSION=$(VERSION) -Wl,-soname,libfoo.$(dlext).$(VERSION) -shared -o $(prefix)/lib/libfoo.$(dlext).$(VERSION) libfoo.c
	ln -s libfoo.$(dlext).$(VERSION) $(prefix)/lib/libfoo.$(dlext)
