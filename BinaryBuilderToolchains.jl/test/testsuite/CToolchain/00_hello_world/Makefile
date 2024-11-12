PROJECT_DIR := $(abspath $(dir $(lastword $(MAKEFILE_LIST))))
include ../common.mk

HELLO := $(PROJECT_DIR)/build/hello$(exeext)
all: $(HELLO)

$(PROJECT_DIR)/build:
	mkdir -p $@

$(HELLO): hello.c | $(PROJECT_DIR)/build
	$(CC) -o $@ $(CPPFLAGS) $(CFLAGS) $(LDFLAGS) $^
	$(STRIP) $@

clean:
	rm -rf $(PROJECT_DIR)/build

run: $(HELLO)
	@$(HELLO)

check: $(HELLO)
	@[ "$$($(HELLO))" = "Hello, World!" ]

print-%:
	echo "$*=$($*)"
