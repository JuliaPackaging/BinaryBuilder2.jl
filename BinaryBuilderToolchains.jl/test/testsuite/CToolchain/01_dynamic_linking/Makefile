PROJECT_DIR := $(abspath $(dir $(lastword $(MAKEFILE_LIST))))
include ../common.mk

DYNLINK := $(PROJECT_DIR)/build/dynamic_linking$(exeext)
LIBFOO := $(PROJECT_DIR)/build/libfoo/libfoo.$(dlext)

all: $(DYNLINK)

$(PROJECT_DIR)/build $(PROJECT_DIR)/build/libfoo:
	mkdir -p $@

$(LIBFOO): libfoo/libfoo.c libfoo/libfoo.h | $(PROJECT_DIR)/build/libfoo
	$(CC) -shared -o $@ $(CPPFLAGS) $(CFLAGS) $< -fPIC -lm

$(DYNLINK): dynamic_linking.c $(LIBFOO) | $(PROJECT_DIR)/build
	$(CC) -o $@ -I$(PROJECT_DIR)/libfoo $(CPPFLAGS) $(CFLAGS) $< -L$(dir $(LIBFOO)) $(call rpath,libfoo) -lfoo $(LDFLAGS)

compile: $(DYNLINK)

clean:
	rm -rf $(PROJECT_DIR)/build

run: $(DYNLINK)
	@$(DYNLINK)

check: $(DYNLINK)
	@[ "$$($(DYNLINK))" = "foo(2.0) == 2.0" ]

.PHONY: compile
