PROJECT_DIR := $(abspath $(dir $(lastword $(MAKEFILE_LIST))))
include ../common.mk

CXXABI := $(PROJECT_DIR_BUILD)/cxx_string_abi$(exeext)
LIBSTR := $(PROJECT_DIR_BUILD)/libstring.$(dlext)

all: $(CXXABI)

$(PROJECT_DIR_BUILD):
	mkdir -p $@

$(LIBSTR): libstring.cpp libstring.h | $(PROJECT_DIR_BUILD)
	$(CXX) -shared -o $@ $(CPPFLAGS) $(CFLAGS) $< -fPIC
libstring: $(LIBSTR)

$(CXXABI): cxx_string_abi.cpp $(LIBSTR) | $(PROJECT_DIR_BUILD)
	$(CXX) -o $@ $(CPPFLAGS) $(CFLAGS) $< -L$(dir $(LIBSTR)) $(call rpath,.) -lstring $(LDFLAGS)
cxx_string_abi: $(CXXABI)
compile: $(CXXABI)

clean:
	rm -rf $(PROJECT_DIR_BUILD)

run: $(CXXABI)
	@$(CXXABI)

check: $(CXXABI)
	@[ "$$($(CXXABI))" = "This is outrageous, it's unfair! Take a seat, young Skywalker." ]

.PHONY: libstring cxx_string_abi compile
