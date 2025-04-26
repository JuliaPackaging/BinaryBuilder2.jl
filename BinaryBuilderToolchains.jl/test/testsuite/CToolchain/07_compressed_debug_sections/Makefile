PROJECT_DIR := $(abspath $(dir $(lastword $(MAKEFILE_LIST))))
include ../common.mk

# We compare `.debug_abbrev` because `.debug_str` contains the command line invocation
# line, which obviously differs due to `-gz`.
DEBUG_SECTION=debug_abbrev


UNCOMPRESSED := $(PROJECT_DIR_BUILD)/uncompressed$(exeext)
COMPRESSED := $(PROJECT_DIR_BUILD)/compressed$(exeext)
all: $(UNCOMPRESSED) $(COMPRESSED)

$(PROJECT_DIR_BUILD):
	mkdir -p $@

$(UNCOMPRESSED): main.c | $(PROJECT_DIR_BUILD)
	$(CC) -o $@ $(CPPFLAGS) $(CFLAGS) -O0 -g $(LDFLAGS) $^

$(COMPRESSED): main.c | $(PROJECT_DIR_BUILD)
	$(CC) -o $@ $(CPPFLAGS) $(CFLAGS) -O0 -g -gz $(LDFLAGS) $^

clean:
	rm -rf $(PROJECT_DIR_BUILD)

run: $(UNCOMPRESSED) $(COMPRESSED)
	@$(UNCOMPRESSED)
	@$(COMPRESSED)

compile: $(UNCOMPRESSED) $(COMPRESSED)
	@$(OBJCOPY) --dump-section .$(DEBUG_SECTION)=$(PROJECT_DIR_BUILD)/uncompressed.$(DEBUG_SECTION) $(UNCOMPRESSED)
	@$(OBJCOPY) --dump-section .$(DEBUG_SECTION)=$(PROJECT_DIR_BUILD)/compressed.$(DEBUG_SECTION) $(COMPRESSED)
	@$(OBJCOPY) --dump-section .$(DEBUG_SECTION)=$(PROJECT_DIR_BUILD)/decompressed.$(DEBUG_SECTION) --decompress-debug-sections $(COMPRESSED)
	@# Assert that the 'uncompressed' and 'compressed' debug strings are not identical.
	@if cmp -s "$(PROJECT_DIR_BUILD)/uncompressed.$(DEBUG_SECTION)" "$(PROJECT_DIR_BUILD)/compressed.$(DEBUG_SECTION)"; then \
		echo "uncompressed and compressed .$(DEBUG_SECTION) sections identical?!" >&2; \
		exit 1; \
	fi
	@# Assert that the 'uncompressed' and `decompressed' debug strings are identical
	@if ! cmp -s "$(PROJECT_DIR_BUILD)/uncompressed.$(DEBUG_SECTION)" "$(PROJECT_DIR_BUILD)/decompressed.$(DEBUG_SECTION)"; then \
		echo "uncompressed and decompressed .$(DEBUG_SECTION) sections differ?!" >&2; \
		exit 1; \
	fi

check: compile
	@# Assert that the output of each is as expected
	@[ "$$($(COMPRESSED) foo)" = "I was invoked with 2 arguments!" ]
	@[ "$$($(UNCOMPRESSED))" = "I was invoked with 1 arguments!" ]

print-%:
	echo "$*=$($*)"
