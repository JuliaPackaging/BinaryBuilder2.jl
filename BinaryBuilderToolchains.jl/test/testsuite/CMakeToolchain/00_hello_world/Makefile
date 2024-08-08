PROJECT_DIR := $(abspath $(dir $(lastword $(MAKEFILE_LIST))))
include ../../CToolchain/common.mk

HELLO := $(PROJECT_DIR)/build/hello$(exeext)
all: $(HELLO)

$(PROJECT_DIR)/build:
	mkdir -p $@

$(PROJECT_DIR)/build/Makefile: $(PROJECT_DIR)/CMakeLists.txt | $(PROJECT_DIR)/build
	$(CMAKE) -B$(PROJECT_DIR)/build -S$(PROJECT_DIR) >$(PROJECT_DIR)/build/cmake_log.txt

$(HELLO): $(PROJECT_DIR)/hello.c $(PROJECT_DIR)/build/Makefile
	$(MAKE) -C $(PROJECT_DIR)/build

clean:
	rm -rf $(PROJECT_DIR)/build

run: $(HELLO)
	@$(HELLO)

check: $(HELLO)
	@[ "$$($(HELLO))" = "Hello, World!" ]

print-%:
	echo "$*=$($*)"
