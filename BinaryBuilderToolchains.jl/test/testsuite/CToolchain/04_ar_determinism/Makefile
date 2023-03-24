PROJECT_DIR := $(abspath $(dir $(lastword $(MAKEFILE_LIST))))
include ../common.mk

all: $(LIBSPLIT)

$(PROJECT_DIR)/build:
	mkdir -p $@

$(PROJECT_DIR)/build/libsplit%.o: libsplit%.c | $(PROJECT_DIR)/build
	$(CC) -c -o $@ $(CPPFLAGS) $(CFLAGS) $^

OBJS += $(PROJECT_DIR)/build/libsplit1.o
OBJS += $(PROJECT_DIR)/build/libsplit2.o
OBJS += $(PROJECT_DIR)/build/libsplit3.o

# Test assembling libsplit with `-r -U`, and `-U -r`, and `rU` and `Ur`
# and `-rU` and `-Ur`.  All six should give similar (broken) results,
# and should emit warnings that we'll save to the `.log` files

# Helper function to define build rules for one of our (many)
# libsplit variants, and append it to a list of libraries
define gen_libsplit
$$(PROJECT_DIR)/build/libsplit$(subst $(SPACE),,$(2)).a: $$(OBJS)
	$$(AR) $(2) $$@ $$^ >$$@.log 2>$$@.log
$(1) += $$(PROJECT_DIR)/build/libsplit$(subst $(SPACE),,$(2)).a
endef

$(eval $(call gen_libsplit,FAIL_LIBS,-r -U))
$(eval $(call gen_libsplit,FAIL_LIBS,-rU))
$(eval $(call gen_libsplit,FAIL_LIBS,rU))
$(eval $(call gen_libsplit,FAIL_LIBS,-U -r))
$(eval $(call gen_libsplit,FAIL_LIBS,-Ur))
$(eval $(call gen_libsplit,FAIL_LIBS,Ur))

# Test assembling libsplit with just `-r` and ensure it's the same as `-r -D`
# and `-rD`, and `-Dr`, and `rD` and `Dr`....:
$(eval $(call gen_libsplit,PASS_LIBS,-r))
$(eval $(call gen_libsplit,PASS_LIBS,r))
$(eval $(call gen_libsplit,PASS_LIBS,-r -D))
$(eval $(call gen_libsplit,PASS_LIBS,-rD))
$(eval $(call gen_libsplit,PASS_LIBS,rD))
$(eval $(call gen_libsplit,PASS_LIBS,-D -r))
$(eval $(call gen_libsplit,PASS_LIBS,-Dr))
$(eval $(call gen_libsplit,PASS_LIBS,Dr))

clean:
	rm -rf $(PROJECT_DIR)/build

run: check
check: $(PASS_LIBS) $(FAIL_LIBS)
	@# First, check that all PASS_LIBS are identical
	@for LIB in $(PASS_LIBS); do \
		if ! cmp $${LIB} $(firstword $(PASS_LIBS)); then \
			echo "Reproducible library mismatch: $${LIB}" >&2; \
			false; \
		fi; \
	done
	@# Next, check that not all FAIL_LIBS are identical
	@MISMATCH=0; \
	for LIB in $(FAIL_LIBS); do \
		if ! cmp -s $${LIB} $(firstword $(PASS_LIBS)); then \
			MISMATCH=1; \
		fi; \
	done; \
	if [ "$${MISMATCH}" != "1" ]; then \
		echo "Non-reproducible libraries all matching?!" >&2; \
		false; \
	fi
	@for LIB in $(FAIL_LIBS); do \
		if ! grep -q "please repent" $${LIB}.log; then \
			echo "Lacking call to repentance in $${LIB}.log" >&2; \
			false; \
		fi; \
	done

print-%:
	@echo "$*=$($*)"
