PROJECT_DIR := $(abspath $(dir $(lastword $(MAKEFILE_LIST))))
include ../common.mk

HELLO := $(PROJECT_DIR_BUILD)/hello$(exeext)
all: $(HELLO)

$(PROJECT_DIR_BUILD):
	mkdir -p $@

$(HELLO): hello.c | $(PROJECT_DIR_BUILD)
	$(CC) -o $@ $(CPPFLAGS) $(CFLAGS) $(LDFLAGS) $^
	$(STRIP) $@
compile: $(HELLO)

clean:
	rm -rf $(PROJECT_DIR_BUILD)

run: $(HELLO)
	@$(HELLO)

check: $(HELLO)
	@[ "$$($(HELLO))" = "Hello, World!" ]

.PHONY: compile
