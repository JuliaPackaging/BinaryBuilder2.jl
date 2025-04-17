PROJECT_DIR := $(abspath $(dir $(lastword $(MAKEFILE_LIST))))
include ../../CToolchain/common.mk

HELLO := $(PROJECT_DIR_BUILD)/hello$(exeext)
all: $(HELLO)

$(PROJECT_DIR_BUILD):
	mkdir -p $@

$(PROJECT_DIR_BUILD)/Makefile: $(PROJECT_DIR)/CMakeLists.txt | $(PROJECT_DIR_BUILD)
	$(CMAKE) -B$(PROJECT_DIR_BUILD) -S$(PROJECT_DIR) >$(PROJECT_DIR_BUILD)/cmake_log.txt

$(HELLO): $(PROJECT_DIR)/hello.c $(PROJECT_DIR_BUILD)/Makefile
	$(MAKE) -C $(PROJECT_DIR_BUILD)
compile: $(HELLO)

clean:
	rm -rf $(PROJECT_DIR_BUILD)

run: $(HELLO)
	@$(HELLO)

check: $(HELLO)
	@[ "$$($(HELLO))" = "Hello, World!" ]

print-%:
	echo "$*=$($*)"
