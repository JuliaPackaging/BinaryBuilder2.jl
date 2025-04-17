PROJECT_DIR := $(abspath $(dir $(lastword $(MAKEFILE_LIST))))
include ../common.mk

all: $(libfoo_path)

$(PROJECT_DIR_BUILD):
	mkdir -p $@

define build_lib
# $(1) is the name (e.g. `foo`), $(2) is the deps, e.g. `baz qux`
lib$(1)_path := $(PROJECT_DIR_BUILD)/lib$(1).$(dlext)
lib$(1)_deps := $(patsubst %,$$(lib%_path),$(2))
$$(lib$(1)_path): lib$(1).c | $$(lib$(1)_deps) $(PROJECT_DIR_BUILD)
	$$(CC) -shared -o $$@ $$(CPPFLAGS) $$(CFLAGS) -L$(PROJECT_DIR_BUILD) $(patsubst %,-l%,$(2)) $$< -fPIC

lib$(1)_path: $$(lib$(1)_path) $$(lib$(1)_deps)
compile: $$(lib$(1)_path)
endef

$(eval $(call build_lib,qux,))
$(eval $(call build_lib,baz,qux))
$(eval $(call build_lib,bar,baz qux))
$(eval $(call build_lib,foo,bar))


clean:
	rm -rf $(PROJECT_DIR_BUILD)

run: $(libfoo_path)
check: $(libfoo_path)
	@[ -f $(libfoo_path) ]

