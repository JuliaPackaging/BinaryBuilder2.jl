PROJECT_DIR := $(abspath $(dir $(lastword $(MAKEFILE_LIST))))
include ../common.mk

LIBANSWER := $(PROJECT_DIR_BUILD)/libanswer.a
ARCHIVE_C := $(PROJECT_DIR_BUILD)/archive_c$(exeext)
STATIC_C := $(PROJECT_DIR_BUILD)/static_c$(exeext)
STATIC_CXX := $(PROJECT_DIR_BUILD)/static_cxx$(exeext)

# macOS does not support fully static executables, so there we only link the
# static archive into an otherwise normally-linked executable.
ifneq (,$(findstring darwin,$(CC_TARGET)))
STATIC_EXES :=
else
STATIC_EXES := $(STATIC_C) $(STATIC_CXX)
endif
EXES := $(ARCHIVE_C) $(STATIC_EXES)

all: $(EXES)

$(PROJECT_DIR_BUILD):
	mkdir -p $@

$(PROJECT_DIR_BUILD)/libanswer.o: libanswer.c libanswer.h | $(PROJECT_DIR_BUILD)
	$(CC) -c -o $@ $(CPPFLAGS) $(CFLAGS) $<

$(LIBANSWER): $(PROJECT_DIR_BUILD)/libanswer.o
	rm -f $@
	$(AR) rcs $@ $^

$(ARCHIVE_C): static_c.c $(LIBANSWER)
	$(CC) -o $@ $(CPPFLAGS) $(CFLAGS) $< -L$(PROJECT_DIR_BUILD) -lanswer $(LDFLAGS)

$(STATIC_C): static_c.c $(LIBANSWER)
	$(CC) -static -o $@ $(CPPFLAGS) $(CFLAGS) $< -L$(PROJECT_DIR_BUILD) -lanswer $(LDFLAGS)

$(STATIC_CXX): static_cxx.cpp $(LIBANSWER)
	$(CXX) -static -o $@ $(CPPFLAGS) $(CFLAGS) $< -L$(PROJECT_DIR_BUILD) -lanswer $(LDFLAGS)

# Inspecting the executables does not require running them, so `compile` does it too.
verify: $(EXES)
	@CC_TARGET="$(CC_TARGET)" NM="$(NM)" READELF="$(READELF)" OBJDUMP="$(OBJDUMP)" \
		$(PROJECT_DIR)/verify.sh $(ARCHIVE_C) $(STATIC_EXES)
compile: verify

clean:
	rm -rf $(PROJECT_DIR_BUILD)

run: $(EXES)
	@for exe in $(EXES); do $${exe}; done

check: verify
	@[ "$$($(ARCHIVE_C))" = "answer(7) == 42" ]
ifneq (,$(STATIC_EXES))
	@[ "$$($(STATIC_C))" = "answer(7) == 42" ]
	@[ "$$($(STATIC_CXX))" = "$$(printf 'caught: negative input -1\nanswer(7) == 42')" ]
endif

.PHONY: all compile verify clean run check
