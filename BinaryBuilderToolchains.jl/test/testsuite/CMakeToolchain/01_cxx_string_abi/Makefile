PROJECT_DIR := $(abspath $(dir $(lastword $(MAKEFILE_LIST))))
include ../../CToolchain/common.mk

CXXABI := $(PROJECT_DIR)/build/cxx_string_abi$(exeext)
LIBSTR := $(PROJECT_DIR)/build/libstring.$(dlext)

all: $(CXXABI)

$(PROJECT_DIR)/build:
	mkdir -p $@

$(PROJECT_DIR)/build/Makefile: $(PROJECT_DIR)/CMakeLists.txt | $(PROJECT_DIR)/build
	$(CMAKE) -B$(PROJECT_DIR)/build -S$(PROJECT_DIR) >$(PROJECT_DIR)/build/cmake_log.txt

$(LIBSTR): $(PROJECT_DIR)/build/Makefile
	@# Note that we say `string` here, because cmake automatically puts `lib` on libraries.
	$(MAKE) -C$(PROJECT_DIR)/build string

$(CXXABI): $(PROJECT_DIR)/build/Makefile $(LIBSTR)
	$(MAKE) -C$(PROJECT_DIR)/build cxx_string_abi

clean:
	rm -rf $(PROJECT_DIR)/build

run: $(CXXABI)
	@$(CXXABI)

check: $(CXXABI)
	@[ "$$($(CXXABI))" = "This is outrageous, it's unfair! Take a seat, young Skywalker." ]

.PHONY: libstring cxx_string_abi
