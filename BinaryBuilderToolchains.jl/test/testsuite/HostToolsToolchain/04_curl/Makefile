PROJECT_DIR := $(abspath $(dir $(lastword $(MAKEFILE_LIST))))

# Clone down an HTTPS repository as our test
run:
	curl -sfL https://julialang.org -o /dev/null

clean:
check: run
