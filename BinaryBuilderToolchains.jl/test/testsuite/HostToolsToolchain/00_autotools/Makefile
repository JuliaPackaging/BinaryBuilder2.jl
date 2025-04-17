PROJECT_DIR := $(abspath $(dir $(lastword $(MAKEFILE_LIST))))
include ../../CToolchain/common.mk

HELLO := $(PROJECT_DIR_BUILD)/hello$(exeext)
all: $(HELLO)

$(PROJECT_DIR_BUILD):
	mkdir -p $@

$(PROJECT_DIR_BUILD)/hello$(exeext): $(wildcard $(PROJECT_DIR)/autotools_project/*) | $(PROJECT_DIR_BUILD)
	cp autotools_project/* $(PROJECT_DIR_BUILD)/
	autoreconf -i -f $(PROJECT_DIR_BUILD) >>$(PROJECT_DIR_BUILD)/autoreconf.log 2>>$(PROJECT_DIR_BUILD)/autoreconf.log
	cd $(PROJECT_DIR_BUILD) && $(PROJECT_DIR_BUILD)/configure >>$(PROJECT_DIR_BUILD)/configure.log
	$(MAKE) -C $(PROJECT_DIR_BUILD)

clean:
	rm -rf $(PROJECT_DIR_BUILD)

run: $(HELLO)
	@$(HELLO)

check: $(HELLO)
	@[ "$$($(HELLO))" = "Hello, World!" ]
