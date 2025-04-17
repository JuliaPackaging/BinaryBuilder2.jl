PROJECT_DIR := $(abspath $(dir $(lastword $(MAKEFILE_LIST))))
include ../common.mk

all:

$(PROJECT_DIR_BUILD):
	@mkdir -p $@

COUNT_DRACULA := $(PROJECT_DIR_BUILD)/count_dracula$(exeext)
$(COUNT_DRACULA): count_dracula.c | $(PROJECT_DIR_BUILD)
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
RUN_IDX := $(shell bash -c "echo $$(($(RUN_IDX) + 1))")
TARGET_$(RUN_IDX)_PATH := $$(PROJECT_DIR_BUILD)/count_dracula.stripped$(subst $(SPACE),,$(1))

# Direct stripping
$$(TARGET_$(RUN_IDX)_PATH).direct: $$(COUNT_DRACULA) | $(PROJECT_DIR_BUILD)
	@cp $$^ $$@
	@$$(STRIP) $(1) $$@ 3>&2 >$$@.log 2>$$@.log

# Direct stripping of multiple files
$$(TARGET_$(RUN_IDX)_PATH).multidirect: $$(COUNT_DRACULA) | $(PROJECT_DIR_BUILD)
	@cp $$^ $$@
	@cp $$^ $$@.1
	@cp $$^ $$@.2
	@$$(STRIP) $(1) $$@ $$@.1 $$@.2 3>&2 >$$@.log 2>$$@.log

# Indirect stripping (e.g. output is not the same as input)
$$(TARGET_$(RUN_IDX)_PATH).indirect: $$(COUNT_DRACULA) | $(PROJECT_DIR_BUILD)
	@$$(STRIP) -o $$@ $(1) $$^ 3>&2 >$$@.log 2>$$@.log

# Checking for determinism
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

# We allow running this `check` target for `compile`,
# since we just manually inspect the outputs, we don't actually try to run anything.
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

clean:
	rm -rf $(PROJECT_DIR_BUILD)

run: check
	$$(PROJECT_DIR_BUILD)/count_dracula.stripped

print-%:
	@echo "$*=$($*)"
