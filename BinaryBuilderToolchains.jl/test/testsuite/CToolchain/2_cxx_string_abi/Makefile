PROJECT_DIR := $(abspath $(dir $(lastword $(MAKEFILE_LIST))))
include ../common.mk

CXXABI := $(PROJECT_DIR)/build/cxx_string_abi$(exeext)
LIBSTR := $(PROJECT_DIR)/build/libstring$(dlext)

all: $(CXXABI)

$(PROJECT_DIR)/build $(PROJECT_DIR)/build/libfoo:
	mkdir -p $@

$(LIBSTR): libstring.cpp libstring.h | $(PROJECT_DIR)/build
	$(CXX) -shared -o $@ $(CPPFLAGS) $(CFLAGS) $< -fPIC

$(CXXABI): cxx_string_abi.cpp $(LIBSTR) | $(PROJECT_DIR)/build
	$(CXX) -o $@ -I$(PROJECT_DIR)/libfoo $(CPPFLAGS) $(CFLAGS) $< -L$(dir $(LIBSTR)) $(call rpath,.) -lstring $(LDFLAGS)

clean:
	rm -rf $(PROJECT_DIR)/build

run: $(CXXABI)
	@$(CXXABI)

check: $(CXXABI)
	@[ "$$($(CXXABI))" = "This is outrageous, it's unfair! Take a seat, young Skywalker." ]
