cleancheck-all:

define make_test_group
run-$(1):
	@$$(MAKE) -C $(1) run
check-$(1):
	@$$(MAKE) -C $(1) check
clean-$(1):
	@$$(MAKE) -C $(1) clean
cleancheck-$(1):
	@$$(MAKE) clean-$(1)
	@$$(MAKE) check-$(1)
	@echo "$(1): ✓"
	@$$(MAKE) clean-$(1)
check-all: check-$(1)
clean-all: clean-$(1)
cleancheck-all: cleancheck-$(1)
endef

SUBDIRS = $(sort $(notdir $(shell find . -mindepth 1 -maxdepth 1 -type d)))
$(foreach DIR,$(SUBDIRS),$(eval $(call make_test_group,$(DIR))))

print-%:
	@echo "$*=$($*)"
