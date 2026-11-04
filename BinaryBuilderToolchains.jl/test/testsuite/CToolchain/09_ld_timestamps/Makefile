PROJECT_DIR := $(abspath $(dir $(lastword $(MAKEFILE_LIST))))
include ../common.mk

COMMA := ,

ifneq (,$(findstring mingw,$(CC_TARGET)))
FOO_O := $(PROJECT_DIR_BUILD)/foo.o
$(FOO_O): foo.c
	@mkdir -p $(dir $@)
	@$(CC) -c -o $@ $(CPPFLAGS) $(CFLAGS) $^

# Link `foo.dll` into `$(PROJECT_DIR_BUILD)/<name>/` with the given command,
# logging the linker's output next to it.
define link_dll
$$(PROJECT_DIR_BUILD)/$(1)/foo.dll: $$(FOO_O)
	@mkdir -p $$(dir $$@)
	@$(2) -o $$@ $$^ >$$@.log 2>&1
endef

LD_FLAGS := -shared -e foo
$(eval $(call link_dll,LD-1,$(LD) $(LD_FLAGS)))
$(eval $(call link_dll,LD-2,sleep 1.1; $(LD) $(LD_FLAGS)))
$(eval $(call link_dll,LD-timestamp,$(LD) --insert-timestamp $(LD_FLAGS)))
$(eval $(call link_dll,ldtriplet-1,ld.$(CC_TARGET) $(LD_FLAGS)))
$(eval $(call link_dll,ldtriplet-2,sleep 1.1; ld.$(CC_TARGET) $(LD_FLAGS)))
$(eval $(call link_dll,ldtriplet-timestamp,ld.$(CC_TARGET) --insert-timestamp $(LD_FLAGS)))
$(eval $(call link_dll,CC-1,$(CC) -shared $(LDFLAGS)))
$(eval $(call link_dll,CC-2,sleep 1.1; $(CC) -shared $(LDFLAGS)))
$(eval $(call link_dll,CC-timestamp,$(CC) -shared -Wl$(COMMA)--insert-timestamp $(LDFLAGS)))

LINKERS := LD ldtriplet CC
DLLS := $(foreach l,$(LINKERS),$(foreach v,1 2 timestamp,$(PROJECT_DIR_BUILD)/$(l)-$(v)/foo.dll))

check: $(DLLS)
	@for l in $(LINKERS); do \
		if ! cmp $(PROJECT_DIR_BUILD)/$${l}-1/foo.dll $(PROJECT_DIR_BUILD)/$${l}-2/foo.dll; then \
			echo "Linking through '$${l}' was non-reproducible!" >&2; \
			false; \
		fi; \
		if cmp -s $(PROJECT_DIR_BUILD)/$${l}-1/foo.dll $(PROJECT_DIR_BUILD)/$${l}-timestamp/foo.dll; then \
			echo "Linking through '$${l}' ignored '--insert-timestamp'!" >&2; \
			false; \
		fi; \
	done
	@for l in LD ldtriplet; do \
		if ! grep -q "please repent" $(PROJECT_DIR_BUILD)/$${l}-timestamp/foo.dll.log; then \
			echo "Lacking call to repentance in $(PROJECT_DIR_BUILD)/$${l}-timestamp/foo.dll.log" >&2; \
			false; \
		fi; \
	done
else
check:
endif

# Nothing is executed, so `compile` can run the full check.
compile: check
run: check

clean:
	rm -rf $(PROJECT_DIR_BUILD)

.PHONY: check compile run clean
