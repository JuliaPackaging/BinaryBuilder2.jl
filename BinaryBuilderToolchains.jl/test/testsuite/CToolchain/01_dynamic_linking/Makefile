PROJECT_DIR := $(abspath $(dir $(lastword $(MAKEFILE_LIST))))
include ../common.mk

DYNLINK := $(PROJECT_DIR_BUILD)/dynamic_linking$(exeext)
LIBFOO := $(PROJECT_DIR_BUILD)/libfoo/libfoo.$(dlext)

all: $(DYNLINK)

$(PROJECT_DIR_BUILD) $(PROJECT_DIR_BUILD)/libfoo:
	mkdir -p $@

$(LIBFOO): libfoo/libfoo.c libfoo/libfoo.h | $(PROJECT_DIR_BUILD)/libfoo
	$(CC) -shared -o $@ $(CPPFLAGS) $(CFLAGS) $< -fPIC -lm

$(DYNLINK): dynamic_linking.c $(LIBFOO) | $(PROJECT_DIR_BUILD)
	$(CC) -o $@ -I$(PROJECT_DIR)/libfoo $(CPPFLAGS) $(CFLAGS) $< -L$(dir $(LIBFOO)) $(call rpath,libfoo) -lfoo $(LDFLAGS)

compile: $(DYNLINK)

clean:
	rm -rf $(PROJECT_DIR_BUILD)

run: $(DYNLINK)
	@$(DYNLINK)

check: $(DYNLINK)
	@[ "$$($(DYNLINK))" = "foo(2.0) == 2.0" ]

.PHONY: compile
