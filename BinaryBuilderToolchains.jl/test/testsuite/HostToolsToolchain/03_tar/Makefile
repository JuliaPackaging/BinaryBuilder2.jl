PROJECT_DIR := $(abspath $(dir $(lastword $(MAKEFILE_LIST))))
include ../../CToolchain/common.mk

all: run

$(PROJECT_DIR_BUILD):
	mkdir -p $@

$(PROJECT_DIR_BUILD)/resolv.tar: /etc/resolv.conf | $(PROJECT_DIR_BUILD)
	tar -C /etc -cf $@ resolv.conf --no-same-owner

# Extract the file, update its timestamp so that we don't extract it every time
$(PROJECT_DIR_BUILD)/resolv.conf: $(PROJECT_DIR_BUILD)/resolv.tar
	tar -C $(PROJECT_DIR_BUILD) -xf $<
	touch --no-create $@

clean:
	rm -rf $(PROJECT_DIR_BUILD)

# Ensure that we have the correct UID
run: $(PROJECT_DIR_BUILD)/resolv.conf
	find $< -user $$(id -u) -print -prune -o -prune
check: $(PROJECT_DIR_BUILD)/resolv.conf
	@[ "$$(find $< -user $$(id -u) -print -prune -o -prune)" = $< ]
	
