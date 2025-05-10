SHELL = /bin/bash
VERSION = 20250509
OUTPUT = out
PLATFORM = $(shell uname -s)-$(shell uname -m)
SIZE_HEADER = 8192
PYTHON_VERSION = 3.13
IMAGE_BASE = ubuntu:24.04
TAG = tutteinstitute/$(1)$(and $(2),:$(2))
