PROJECT_DIR := $(abspath $(dir $(lastword $(MAKEFILE_LIST))))

all:
clean:

run:
	file $(PROJECT_DIR)
	file $(PROJECT_DIR)/../Makefile

# Just make sure they run without erroring out
check:
	file $(PROJECT_DIR) >/dev/null
	file $(PROJECT_DIR)/../Makefile >/dev/null
