PROJECT_DIR := $(abspath $(dir $(lastword $(MAKEFILE_LIST))))
include ../../CToolchain/common.mk

REPO := $(PROJECT_DIR_BUILD)/dltest
all: $(REPO)

# Clone down an HTTPS repository as our test
$(REPO):
	git clone -q https://github.com/staticfloat/dltest $@
	git -C $@ checkout -q anchor

clean:
	rm -rf $(REPO)

run: $(REPO)
	git -C $(REPO) log --format=%H -1

check: $(REPO)
	@[ "$$(git -C $(REPO) log --format=%H -1)" = "3d3967637d1883a010564132ee89accf3afc4c14" ]
