PROJECT_DIR := $(abspath $(dir $(lastword $(MAKEFILE_LIST))))
include ../common.mk

all: $(OBJS)

$(PROJECT_DIR_BUILD):
	mkdir -p $@

$(PROJECT_DIR_BUILD)/libsplit%.o: libsplit%.c | $(PROJECT_DIR_BUILD)
	$(CC) -c -o $@ $(CPPFLAGS) $(CFLAGS) $^

OBJS += $(PROJECT_DIR_BUILD)/libsplit1.o
OBJS += $(PROJECT_DIR_BUILD)/libsplit2.o
OBJS += $(PROJECT_DIR_BUILD)/libsplit3.o

# Test assembling libsplit with `-r -U`, and `-U -r`, and `rU` and `Ur`
# and `-rU` and `-Ur`.  All six should give similar (broken) results,
# and should emit warnings that we'll save to the `.log` files

# Helper function to define build rules for one of our (many)
# libsplit variants, and append it to a list of libraries
define gen_libsplit
$$(PROJECT_DIR_BUILD)/libsplit$(subst $(SPACE),,$(2)).a: $$(OBJS)
	$$(AR) $(2) $$@ $$^ >$$@.log 2>$$@.log
$(1) += $$(PROJECT_DIR_BUILD)/libsplit$(subst $(SPACE),,$(2)).a
endef

define index_libsplit
$$(PROJECT_DIR_BUILD)/libsplit-indexed$(subst $(SPACE),,$(2)).a: $$(PROJECT_DIR_BUILD)/libsplit-r-D.a
	@cp "$$<" "$$@"
	$$(RANLIB) $(2) $$@ >$$@.log 2>$$@.log
$(1) += $$(PROJECT_DIR_BUILD)/libsplit-indexed$(subst $(SPACE),,$(2)).a
endef

$(eval $(call gen_libsplit,FAIL_AR_LIBS,-r -U))
$(eval $(call gen_libsplit,FAIL_AR_LIBS,-rU))
$(eval $(call gen_libsplit,FAIL_AR_LIBS,rU))
$(eval $(call gen_libsplit,FAIL_AR_LIBS,-U -r))
$(eval $(call gen_libsplit,FAIL_AR_LIBS,-Ur))
$(eval $(call gen_libsplit,FAIL_AR_LIBS,Ur))

# Test assembling libsplit with just `-r` and ensure it's the same as `-r -D`
# and `-rD`, and `-Dr`, and `rD` and `Dr`....:
$(eval $(call gen_libsplit,PASS_AR_LIBS,-r))
$(eval $(call gen_libsplit,PASS_AR_LIBS,r))
$(eval $(call gen_libsplit,PASS_AR_LIBS,-r -D))
$(eval $(call gen_libsplit,PASS_AR_LIBS,-rD))
$(eval $(call gen_libsplit,PASS_AR_LIBS,rD))
$(eval $(call gen_libsplit,PASS_AR_LIBS,-D -r))
$(eval $(call gen_libsplit,PASS_AR_LIBS,-Dr))
$(eval $(call gen_libsplit,PASS_AR_LIBS,Dr))

# Test that using `-u` gets dropped as long as we're in deterministic mode:
$(eval $(call gen_libsplit,PASS_AR_LIBS,-r -u -D))
$(eval $(call gen_libsplit,PASS_AR_LIBS,-ruD))
$(eval $(call gen_libsplit,PASS_AR_LIBS,ruD))

# Next, do the same tests, but for `ranlib` on copies of the `ar -r -D` invocation's output:
$(eval $(call index_libsplit,FAIL_RANLIB_LIBS,-U))
$(eval $(call index_libsplit,FAIL_RANLIB_LIBS,-UU))
$(eval $(call index_libsplit,PASS_RANLIB_LIBS,-D))
$(eval $(call index_libsplit,PASS_RANLIB_LIBS,-DD))

clean:
	rm -rf $(PROJECT_DIR_BUILD)

compile: $(PASS_AR_LIBS) $(FAIL_AR_LIBS) $(PASS_RANLIB_LIBS) $(FAIL_RANLIB_LIBS)

run: check
check: $(PASS_AR_LIBS) $(FAIL_AR_LIBS) $(PASS_RANLIB_LIBS) $(FAIL_RANLIB_LIBS)
	@# First, we check that all passing libs are identical
	@# Next, we check that all failing libs are _not_ identical
	@# Finally, we check that the logs have a call to repentance in them.
	@check_libs() { \
		for LIB in $${1}; do \
			if ! cmp $${LIB} $${3}; then \
				echo "Reproducible library mismatch: $${LIB}" >&2; \
				false; \
			fi; \
		done; \
		MISMATCH=0; \
		for LIB in $${2}; do \
			if ! cmp -s $${LIB} $${3}; then \
				MISMATCH=1; \
			fi; \
		done; \
		if [ "$${MISMATCH}" != "1" ]; then \
			echo "Non-reproducible libraries all matching?!" >&2; \
			false; \
		fi; \
		for LIB in $${2}; do \
			if ! grep -q "please repent" $${LIB}.log; then \
				echo "Lacking call to repentance in $${LIB}.log" >&2; \
				false; \
			fi; \
		done; \
	}; \
	check_libs "$(PASS_AR_LIBS)" "$(FAIL_AR_LIBS)" "$(firstword $(PASS_AR_LIBS))"; \
	check_libs "$(PASS_RANLIB_LIBS)" "$(FAIL_RANLIB_LIBS)" "$(firstword $(PASS_RANLIB_LIBS))"; \

.PHONY: compile
