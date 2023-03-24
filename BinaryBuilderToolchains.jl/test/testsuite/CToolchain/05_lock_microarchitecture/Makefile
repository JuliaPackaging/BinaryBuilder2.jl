PROJECT_DIR := $(abspath $(dir $(lastword $(MAKEFILE_LIST))))
include ../common.mk

all: run

$(PROJECT_DIR)/build:
	mkdir -p $@

clean:
	rm -rf $(PROJECT_DIR)/build

run: check
check: lock_march.c | $(PROJECT_DIR)/build
	@# First, try to compile with `-march=native`, which will fail:
	@if $(CC) -c -o $(PROJECT_DIR)/build/lock_march_fail.o $(CPPFLAGS) $(CFLAGS) -march=native $< 2>/dev/null ; then \
		echo 'Compilation with `-march=native` did not fail!' >&2; \
		false; \
	fi
	@# Next, compile normally, this time with `BB_WRAPPERS_VERBOSE` enabled to check that `-march` is added:
	@BB_WRAPPERS_VERBOSE=1 $(CC) -c -o $(PROJECT_DIR)/build/lock_march.o $(CPPFLAGS) $(CFLAGS) $< >$(PROJECT_DIR)/build/lock_march.o.log 2>$(PROJECT_DIR)/build/lock_march.o.log
	@if ! grep -q "\-march" $(PROJECT_DIR)/build/lock_march.o.log; then \
		echo 'No `-march` flag found in compiler output:' >&2; \
		cat $(PROJECT_DIR)/build/lock_march.o.log >&2; \
		false; \
	fi
