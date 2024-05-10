PROJECTS := $(subst /,,$(dir $(wildcard */Manifest.toml))) .
JULIA ?= julia

# I love string manipulation in Make.
define logfile_name
$(if $(filter-out .,$(lastword $(subst -, ,$(1)))),$(1),$(firstword $(subst -, ,$(1)))-BinaryBuilder2)
endef

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
$(1)_DEPS := $$(patsubst %,%.jl,$$(filter $$(patsubst %.jl,%,$$(filter-out $(1),$$(PROJECTS))),$$(shell cat $(1)/Project.toml)))
endef
$(foreach project,$(PROJECTS),$(eval $(call project_deps,$(project))))

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
	$(call run_with_log,$(1),import Pkg; $(foreach dep,$($(1)_DEPS),try Pkg.rm("$(basename $(dep))"); catch; end; Pkg.develop(path="$(dep)"); ),redev-$(1))

testall: test-$(1)
updateall: update-$(1)
resolveall: resolve-$(1)
redevall: redev-$(1)
instantiateall: instantiate-$(1)
printsorted: printsorted-$(1)
.PHONY: test-$(1) update-$(1) printsorted-$(1)
endef
$(foreach project,$(PROJECTS),$(eval $(call project_targets,$(project))))

# Debugging ahoy
print-%:
	echo "$*=$($*)"
