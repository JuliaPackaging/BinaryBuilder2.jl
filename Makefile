PROJECTS := $(subst /,,$(dir $(wildcard */Manifest.toml))) .
JULIA ?= julia

# Collect direct dependencies for each project
define project_deps
$(1)_DEPS := $$(patsubst %,%.jl,$$(filter $$(patsubst %.jl,%,$$(filter-out $(1),$$(PROJECTS))),$$(shell cat $(1)/Project.toml)))
endef
$(foreach project,$(PROJECTS),$(eval $(call project_deps,$(project))))

define project_targets
# Only test after our dependencies are finished test
test-$(1): $(foreach dep,$($(1)_DEPS),test-$(dep))
	$(JULIA) --project=$(1) -e 'import Pkg; Pkg.test()'

# Updating can happen in massively parallel
update-$(1):
	$(JULIA) --project=$(1) -e 'import Pkg; Pkg.update()'

testall: test-$(1)
updateall: update-$(1)
.PHONY: test-$(1) update-$(1)
endef
$(foreach project,$(PROJECTS),$(eval $(call project_targets,$(project))))

# Debugging ahoy
print-%:
	echo "$*=$($*)"
