PROJECT_DIR := $(abspath $(dir $(lastword $(MAKEFILE_LIST))))

all:
clean:

# Make sure the interpreter finds its standard library, including extension modules
run:
	python3 -c 'import sys, json, ssl, zlib, bz2, lzma, ctypes, hashlib; print(sys.prefix)'

check: run
