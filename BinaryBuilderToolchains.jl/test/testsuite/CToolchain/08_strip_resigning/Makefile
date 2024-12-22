PROJECT_DIR := $(abspath $(dir $(lastword $(MAKEFILE_LIST))))
include ../common.mk

all:

$(PROJECT_DIR)/build:
	@mkdir -p $@

COUNT_DRACULA := $(PROJECT_DIR)/build/count_dracula$(exeext)
$(COUNT_DRACULA): count_dracula.c | $(PROJECT_DIR)/build
	@$(CC) -o $@ $(CPPFLAGS) $(CFLAGS) $^ $(LDFLAGS) 3>&2

export BB_WRAPPERS_VERBOSE_FD = 3

# Figure out if we're using GNU Binutils strip or CCTools strip
ifneq (,$(findstring GNU,$(shell $(STRIP) --version 2>/dev/null)))
STRIP_KIND := GNU
else
STRIP_KIND := CCTools
endif

RUN_IDX := 0
define run_strip
RUN_IDX := $(shell echo "$(RUN_IDX) + 1" | bc)
TARGET_$(RUN_IDX)_PATH := $$(PROJECT_DIR)/build/count_dracula.stripped$(subst $(SPACE),,$(1))
$$(TARGET_$(RUN_IDX)_PATH).direct: $$(COUNT_DRACULA) | $(PROJECT_DIR)/build
	@cp $$^ $$@
	@$$(STRIP) $(1) $$@ 3>&2 >$$@.logn 2>$$@.log

$$(TARGET_$(RUN_IDX)_PATH).multidirect: $$(COUNT_DRACULA) | $(PROJECT_DIR)/build
	@cp $$^ $$@
	@cp $$^ $$@.1
	@cp $$^ $$@.2
	@$$(STRIP) $(1) $$@ $$@.1 $$@.2 3>&2 >$$@.log 2>$$@.log

$$(TARGET_$(RUN_IDX)_PATH).indirect: $$(COUNT_DRACULA) | $(PROJECT_DIR)/build
	@$$(STRIP) -o $$@ $(1) $$^ 3>&2 >$$@.log 2>$$@.log

$$(TARGET_$(RUN_IDX)_PATH)-check: $$(TARGET_$(RUN_IDX)_PATH).direct $$(TARGET_$(RUN_IDX)_PATH).multidirect $$(TARGET_$(RUN_IDX)_PATH).indirect
	@# Test for determinism
	@if ! cmp $$(TARGET_$(RUN_IDX)_PATH).direct $$(TARGET_$(RUN_IDX)_PATH).indirect; then \
		echo "Running 'strip $(1)' was non-reproducible!  Check these files for differences:" >&2; \
		echo "  $$(TARGET_$(RUN_IDX)_PATH).direct" >&2; \
		echo "  $$(TARGET_$(RUN_IDX)_PATH).indirect" >&2; \
		false; \
	fi
	@if ! cmp $$(TARGET_$(RUN_IDX)_PATH).multidirect $$(TARGET_$(RUN_IDX)_PATH).indirect; then \
		echo "Running 'strip $(1)' was non-reproducible!  Check these files for differences:" >&2; \
		echo "  $$(TARGET_$(RUN_IDX)_PATH).multidirect" >&2; \
		echo "  $$(TARGET_$(RUN_IDX)_PATH).indirect" >&2; \
		false; \
	fi
	@# Test for no codesigning warning
	@for flavor in direct multidirect indirect; do \
		if grep -q "invalidate the code signature" $$(TARGET_$(RUN_IDX)_PATH).$$$${flavor}.log; then \
			echo "Code invalidation warning found in $$(TARGET_$(RUN_IDX)_PATH).$$$${flavor}.log" >&2; \
			false; \
		fi; \
	done


.PHONY: $$(TARGET_$(RUN_IDX)_PATH)-check
all: $$(TARGET_$(RUN_IDX)_PATH).direct $$(TARGET_$(RUN_IDX)_PATH).indirect
check: $$(TARGET_$(RUN_IDX)_PATH)-check
compile: $$(TARGET_$(RUN_IDX)_PATH)-check
endef

# No options should always work :)
$(eval $(call run_strip,))

# Test removal of debugging symbols
$(eval $(call run_strip,-S))

ifeq ($(STRIP_KIND),GNU)
$(eval $(call run_strip,-g))
$(eval $(call run_strip,-X))
$(eval $(call run_strip,--strip-unneeded))
endif

ifeq ($(STRIP_KIND),CCTools)
$(eval $(call run_strip,-u))
$(eval $(call run_strip,-u -r))
$(eval $(call run_strip,-x))
$(eval $(call run_strip,-x -r -u))
$(eval $(call run_strip,-xru))
endif

# Also add a special test for stripping multiple files at once:
MO_OUT := $(PROJECT_DIR)/build/count_dracula.stripped-multiout.direct
$(MO_OUT): $(COUNT_DRACULA) | $(PROJECT_DIR)/build
	@cp $^ $(MO_OUT).0
	@cp $^ $(MO_OUT).1
	@cp $^ $(MO_OUT).2
	@$$(STRIP) $(1) $$@ >$$@.log 2>$$@.log



clean:
	rm -rf $(PROJECT_DIR)/build

run: check
	$$(PROJECT_DIR)/build/count_dracula.stripped

print-%:
	@echo "$*=$($*)"
