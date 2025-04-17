PROJECT_DIR := $(abspath $(dir $(lastword $(MAKEFILE_LIST))))

# Get an HTTPS site to prove that all our environment variables are working
run:
	curl -sfL https://julialang.org -o /dev/null

clean:
check: run
