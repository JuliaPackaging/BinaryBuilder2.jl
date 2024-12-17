PROJECT_DIR := $(abspath $(dir $(lastword $(MAKEFILE_LIST))))
include ../common.mk

all: run

$(PROJECT_DIR)/build:
	mkdir -p $@

clean:
	rm -rf $(PROJECT_DIR)/build

$(PROJECT_DIR)/build/lock_march.o: lock_march.c | $(PROJECT_DIR)/build
	@BB_WRAPPERS_VERBOSE=1 $(CC) -c -o $@ $(CPPFLAGS) $(CFLAGS) $< >$@.log 2>$@.log

$(PROJECT_DIR)/build/lock_march_fail.o.log: lock_march.c | $(PROJECT_DIR)/build
	-@BB_WRAPPERS_VERBOSE=1 $(CC) -c -o $(PROJECT_DIR)/build/lock_march_fail.o $(CPPFLAGS) $(CFLAGS) -march=native $< >$@ 2>$@

compile: $(PROJECT_DIR)/build/lock_march.o $(PROJECT_DIR)/build/lock_march_fail.o.log

run: check
check: compile
	@# First, ensure that compiling with `-march` failed:
	@if [ -f $(PROJECT_DIR)/build/lock_march_fail.o ]; then \
		echo 'Compilation with `-march=native` did not fail!' >&2; \
		cat $(PROJECT_DIR)/build/lock_march_fail.o.log >&2; \
		false; \
	fi
	@# Next, ensure that when run with `BB_WRAPPERS_VERBOSE`, `-march` was automatically added:
	@if ! grep -q "\-march" $(PROJECT_DIR)/build/lock_march.o.log; then \
		echo 'No `-march` flag found in compiler output:' >&2; \
		cat $(PROJECT_DIR)/build/lock_march.o.log >&2; \
		false; \
	fi
