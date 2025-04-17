PROJECT_DIR := $(abspath $(dir $(lastword $(MAKEFILE_LIST))))
include ../../CToolchain/common.mk

CXXABI := $(PROJECT_DIR_BUILD)/cxx_string_abi$(exeext)
LIBSTR := $(PROJECT_DIR_BUILD)/libstring.$(dlext)

all: $(CXXABI)

$(PROJECT_DIR_BUILD):
	mkdir -p $@

$(PROJECT_DIR_BUILD)/Makefile: $(PROJECT_DIR)/CMakeLists.txt | $(PROJECT_DIR_BUILD)
	$(CMAKE) -B$(PROJECT_DIR_BUILD) -S$(PROJECT_DIR) >$(PROJECT_DIR_BUILD)/cmake_log.txt

$(LIBSTR): $(PROJECT_DIR_BUILD)/Makefile
	@# Note that we say `string` here, because cmake automatically puts `lib` on libraries.
	$(MAKE) -C$(PROJECT_DIR_BUILD) string

$(CXXABI): $(PROJECT_DIR_BUILD)/Makefile $(LIBSTR)
	$(MAKE) -C$(PROJECT_DIR_BUILD) cxx_string_abi
compile: $(CXXABI)

clean:
	rm -rf $(PROJECT_DIR_BUILD)

run: $(CXXABI)
	@$(CXXABI)

check: $(CXXABI)
	@[ "$$($(CXXABI))" = "This is outrageous, it's unfair! Take a seat, young Skywalker." ]

.PHONY: libstring cxx_string_abi
