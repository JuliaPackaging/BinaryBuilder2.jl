PROJECT_DIR := $(abspath $(dir $(lastword $(MAKEFILE_LIST))))
include ../common.mk

all: $(OBJS)

$(PROJECT_DIR_BUILD):
	mkdir -p $@

# These two are built with a consistent seed:
OBJS += $(PROJECT_DIR_BUILD)/frandom_seed.good_seed.o.1
OBJS += $(PROJECT_DIR_BUILD)/frandom_seed.good_seed.o.2
$(PROJECT_DIR_BUILD)/frandom_seed.good_seed.o.%: frandom_seed.c | $(PROJECT_DIR_BUILD)
	$(CC) -c -flto -frandom-seed=0xdeadbeef -o $(PROJECT_DIR_BUILD)/temp.o $(CPPFLAGS) $(CFLAGS) $<
	mv $(PROJECT_DIR_BUILD)/temp.o $@

# These two are built with an inconsistent seed specified
OBJS += $(PROJECT_DIR_BUILD)/frandom_seed.bad_seed.o.1
OBJS += $(PROJECT_DIR_BUILD)/frandom_seed.bad_seed.o.2
$(PROJECT_DIR_BUILD)/frandom_seed.bad_seed.o.1: frandom_seed.c | $(PROJECT_DIR_BUILD)
	$(CC) -c -flto -frandom-seed=0xdeadbeef -o $(PROJECT_DIR_BUILD)/temp.o $(CPPFLAGS) $(CFLAGS) $<
	mv $(PROJECT_DIR_BUILD)/temp.o $@
$(PROJECT_DIR_BUILD)/frandom_seed.bad_seed.o.2: frandom_seed.c | $(PROJECT_DIR_BUILD)
	$(CC) -c -flto -frandom-seed=0xdeadbeee -o $(PROJECT_DIR_BUILD)/temp.o $(CPPFLAGS) $(CFLAGS) $<
	mv $(PROJECT_DIR_BUILD)/temp.o $@

# These two are built with no seed specified (and so should be consistent)
OBJS += $(PROJECT_DIR_BUILD)/frandom_seed.no_seed.o.1
OBJS += $(PROJECT_DIR_BUILD)/frandom_seed.no_seed.o.2
$(PROJECT_DIR_BUILD)/frandom_seed.no_seed.o.%: frandom_seed.c | $(PROJECT_DIR_BUILD)
	$(CC) -c -flto -o $(PROJECT_DIR_BUILD)/temp.o $(CPPFLAGS) $(CFLAGS) $<
	mv $(PROJECT_DIR_BUILD)/temp.o $@

compile: $(OBJS)

clean:
	rm -rf $(PROJECT_DIR_BUILD)

run: check
check: $(OBJS)
	@if ! cmp $(PROJECT_DIR_BUILD)/frandom_seed.good_seed.o.1 $(PROJECT_DIR_BUILD)/frandom_seed.good_seed.o.2; then \
		echo "Good seeds still not reproducible!" >&2; \
		false; \
	fi
	@if ! "${CC}" --version | grep -q "clang"; then \
		if cmp -s $(PROJECT_DIR_BUILD)/frandom_seed.bad_seed.o.1 $(PROJECT_DIR_BUILD)/frandom_seed.bad_seed.o.2; then \
			echo "Bad seeds reproducible?!" >&2; \
			false; \
		fi; \
	fi
	@if ! cmp $(PROJECT_DIR_BUILD)/frandom_seed.no_seed.o.1 $(PROJECT_DIR_BUILD)/frandom_seed.no_seed.o.2; then \
		echo "No good default seed!" >&2; \
		false; \
	fi

.PHONY: compile
