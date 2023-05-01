PROJECT_DIR := $(abspath $(dir $(lastword $(MAKEFILE_LIST))))

all: run

$(PROJECT_DIR)/build:
	mkdir -p $@

$(PROJECT_DIR)/build/resolv.tar: /etc/resolv.conf | $(PROJECT_DIR)/build
	tar -C /etc -cf $@ resolv.conf --no-same-owner

# Extract the file, update its timestamp so that we don't extract it every time
$(PROJECT_DIR)/build/resolv.conf: $(PROJECT_DIR)/build/resolv.tar
	tar -C $(PROJECT_DIR)/build -xf $<
	touch --no-create $@

clean:
	rm -rf $(PROJECT_DIR)/build

# Ensure that we have the correct UID
run: $(PROJECT_DIR)/build/resolv.conf
	find $< -user $$(id -u) -print -prune -o -prune
check: $(PROJECT_DIR)/build/resolv.conf
	@[ "$$(find $< -user $$(id -u) -print -prune -o -prune)" = $< ]
	
