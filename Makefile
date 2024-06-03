PROJECTS := $(subst /,,$(dir $(wildcard */Project.toml))) .
JULIA ?= julia
JULIA_v12_OR_HIGHER := $(shell $(JULIA) -e 'if VERSION >= v"1.12.0-DEV"; println("true"); end')

# I love string manipulation in Make.
define logfile_name
$(if $(filter-out .,$(lastword $(subst -, ,$(1)))),$(1),$(firstword $(subst -, ,$(1)))-BinaryBuilder2)
endef
comma:=,

# Blame https://stackoverflow.com/a/16151140 for this
uniq = $(if $1,$(firstword $1) $(call uniq,$(filter-out $(firstword $1),$1)))

ifneq ($(LOG_OUTPUT),)
define run_with_log
	@mkdir -p $(LOG_OUTPUT)
	$(JULIA) --project=$(1) --color=yes -e '$(2)' 2>&1 | tee -a $(LOG_OUTPUT)/$(call logfile_name,$(3)).log
endef
else
define run_with_log
	$(JULIA) --project=$(1) --color=yes -e '$(2)'
endef
endif
# Collect direct dependencies for each project
define project_deps
$(1)_DEPS := $$(patsubst %,%.jl,$$(call uniq,$$(filter $$(patsubst %.jl,%,$$(filter-out $(1),$$(PROJECTS))),$$(shell awk '/\[deps\]/,/^$$$$/' $(1)/Project.toml))))
endef
$(foreach project,$(PROJECTS),$(eval $(call project_deps,$(project))))

# Use that to generate recursive deps
define recursive_project_deps_expand
$($(1)_DEPS) $(foreach dep,$($(1)_DEPS),$(call recursive_project_deps_expand,$(dep)))
endef
define recursive_project_deps
$(1)_RECURSIVE_DEPS := $(call uniq,$(call recursive_project_deps_expand,$(1)))
endef
$(foreach project,$(PROJECTS),$(eval $(call recursive_project_deps,$(project))))

define project_targets
# I'm lazy and I forget to add licenses to things all the time
ifneq ($(1),.)
$(1)/LICENSE: LICENSE
	@cp $$< $$@
endif

# Only test after our dependencies are finished test
test-$(1): $(foreach dep,$($(1)_DEPS),test-$(dep)) $(1)/LICENSE
	@if [ "$${BUILDKITE}" = "true" ]; then \
		if [ "$(1)" = "." ]; then \
			echo "+++ BinaryBuilder2.jl"; \
		else \
			echo "--- $(1)"; \
		fi; \
	fi
	$(call run_with_log,$(1),import Pkg; Pkg.test(),test-$(1))

printsorted-$(1): $(foreach dep,$($(1)_DEPS),printsorted-$(dep))
	@if [ "$(1)" = "." ]; then \
		echo "BinaryBuilder2.jl"; \
	else \
		echo "$(1)"; \
	fi

update-$(1): $(1)/LICENSE
	$(call run_with_log,$(1),import Pkg; Pkg.update(),update-$(1))

resolve-$(1): $(1)/LICENSE
	$(JULIA) --color=yes -e 'import Pkg; Pkg.activate("$(1)"); Pkg.resolve()'

instantiate-$(1): $(1)/LICENSE
	$(call run_with_log,$(1),import Pkg; Pkg.instantiate(),instantiate-$(1))

redev-$(1): $(1)/LICENSE
	if [ -n "$($(1)_DEPS)" ]; then \
		$(call run_with_log,$(1),import Pkg; Pkg.develop([$(foreach dep,$($(1)_DEPS), Pkg.PackageSpec(;path="$(dep)")$(comma))]);,redev-$(1)); \
	fi

testall: test-$(1)
updateall: update-$(1)
resolveall: resolve-$(1)
instantiateall: instantiate-$(1)
printsorted: printsorted-$(1)
.PHONY: test-$(1) update-$(1) printsorted-$(1)

# redevall only does this if running on Julia v1.11-
ifneq ($(JULIA_v12_OR_HIGHER),true)
redevall: redev-$(1)
endif
endef
$(foreach project,$(PROJECTS),$(eval $(call project_targets,$(project))))

ifeq ($(JULIA_v12_OR_HIGHER),true)
redevall:
	$(call run_with_log,.,import Pkg; Pkg.develop([$(foreach dep,$(filter-out .,$(PROJECTS)), Pkg.PackageSpec(;path="$(dep)")$(comma))]);,redev-.)
endif

# Debugging ahoy
print-%:
	echo "$*=$($*)"
