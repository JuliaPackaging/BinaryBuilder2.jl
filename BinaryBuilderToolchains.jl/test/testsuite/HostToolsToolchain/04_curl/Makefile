PROJECT_DIR := $(abspath $(dir $(lastword $(MAKEFILE_LIST))))

# Get an HTTPS site to prove that all our environment variables are working
run:
	if ! curl -I -sfL https://julialang.org -o /dev/null; then \
		curl -I -vfL https://julialang.org; \
		echo "CURL related environment variables:"; \
		set | grep --color "CURL"; \
	fi

clean:
check: run
