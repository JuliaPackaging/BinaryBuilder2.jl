PROJECT_DIR := $(abspath $(dir $(lastword $(MAKEFILE_LIST))))

HELLO := $(PROJECT_DIR)/build/hello$(exeext)
all: $(HELLO)

$(PROJECT_DIR)/build:
	mkdir -p $@

$(PROJECT_DIR)/build/hello$(exeext): $(wildcard $(PROJECT_DIR)/autotools_project/*) | $(PROJECT_DIR)/build
	cp autotools_project/* $(PROJECT_DIR)/build/
	autoreconf -i -f $(PROJECT_DIR)/build >>$(PROJECT_DIR)/build/autoreconf.log 2>>$(PROJECT_DIR)/build/autoreconf.log
	cd $(PROJECT_DIR)/build && $(PROJECT_DIR)/build/configure >>$(PROJECT_DIR)/build/configure.log
	$(MAKE) -C $(PROJECT_DIR)/build

clean:
	rm -rf $(PROJECT_DIR)/build

run: $(HELLO)
	@$(HELLO)

check: $(HELLO)
	@[ "$$($(HELLO))" = "Hello, World!" ]
